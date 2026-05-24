#!/usr/bin/env bash
# Hand the secondary GPU (PCI 0000:07:00.0) AND its paired audio function
# (0000:07:00.1) to the win10 VM. Disables the GPU's outputs in KDE so the
# host driver releases the device, hot-removes + rescans both PCI functions
# for clean pci_devs, then binds both to vfio-pci.
#
# Audio function rationale: AMD GPU drivers (both inbox and Adrenalin) expect
# to own BOTH functions of the multifunction GPU device. With the audio
# function held by snd_hda_intel on the host, the Windows AMD driver init
# fails with Device Manager Code 43 even though the VGA function passes
# through cleanly. Validated empirically: Code 43 was less prevalent when
# audio passthrough was previously enabled, more prevalent after we removed
# it. The two functions are in separate IOMMU groups (26 and 27) so isolation
# is fine; multifunction='on' in the guest hostdev tells Windows they're
# paired. Trade-off: snd_hda_intel may not re-bind cleanly on release (HDMI
# audio function may stay in D3) — acceptable since this host doesn't use
# HDMI/DP audio.
#
# Why sysfs instead of `virsh nodedev-detach`: libvirt 12.0.0 (Fedora 44+)
# has an RPC hang in the modular-daemon nodedev path that wedges virtqemud
# for ~10 minutes on detach, leaves the device in a half-bound state, and
# requires a host reboot to recover. Direct sysfs `driver_override` +
# unbind + drivers_probe avoids the daemon roundtrip entirely.
#
# Why pre-start hot-remove + rescan (defense-in-depth): if a prior cycle's
# release-side cleanup ran but didn't fully drain the GPU's SMU state, the
# GPU can carry that weirdness into the next VM start. Doing a fresh
# remove + rescan here forces a clean pci_dev for amdgpu to probe before
# we hand the card to vfio-pci, reducing the "SMU stuck" failure mode at
# next VM shutdown. Empirically the strongest predictor of release-side
# reliability per the Navi VFIO community.
#
# Pairs with `<hostdev managed='no'>` in the VM XML - libvirt assumes the
# device is already bound to vfio-pci by VM start, and never tries its own
# detach.

set -euo pipefail

GPU_PCI="0000:07:00.0"
GPU_AUDIO_PCI="0000:07:00.1"

USER_NAME="barrett"
USER_ID="$(id -u "$USER_NAME")"
USER_RUNTIME="/run/user/${USER_ID}"

LOG_TAG="win10-gpu-attach"
log() { logger -t "$LOG_TAG" "$*"; echo "[$LOG_TAG] $*"; }

# libvirt passes domain XML on stdin for prepare/begin. Skip the bind dance
# if the VM doesn't actually request the GPU as a hostdev - relevant during
# initial Windows install before the passthrough hostdevs are added to the
# domain XML.
gpu_bus="${GPU_PCI#*:}"; gpu_bus="${gpu_bus%%:*}"
gpu_slot="${GPU_PCI##*:}"; gpu_slot="${gpu_slot%.*}"
gpu_func="${GPU_PCI##*.}"
xml_match="bus='0x${gpu_bus}' slot='0x${gpu_slot}' function='0x${gpu_func}'"
if ! grep -qF "$xml_match"; then
  log "domain XML has no hostdev for $GPU_PCI; skipping (VM not using GPU)"
  exit 0
fi

bind_to_vfio() {
  local pci="$1"
  local cur
  cur=$(basename "$(readlink -f "/sys/bus/pci/devices/$pci/driver" 2>/dev/null)" 2>/dev/null || true)
  if [ "$cur" = "vfio-pci" ]; then
    log "$pci already bound to vfio-pci"
    return 0
  fi
  log "binding $pci to vfio-pci (was: ${cur:-unbound})"
  echo vfio-pci > "/sys/bus/pci/devices/$pci/driver_override"
  if [ -n "$cur" ] && [ -e "/sys/bus/pci/drivers/$cur/$pci" ]; then
    echo "$pci" > "/sys/bus/pci/drivers/$cur/unbind"
  fi
  echo "$pci" > "/sys/bus/pci/drivers_probe"
  local new
  new=$(basename "$(readlink -f "/sys/bus/pci/devices/$pci/driver" 2>/dev/null)" 2>/dev/null || true)
  if [ "$new" != "vfio-pci" ]; then
    log "ERROR: $pci ended up on '${new:-unbound}', expected vfio-pci"
    return 1
  fi
}

# Discover kernel connectors on the secondary GPU and disable them in KDE
# so DRM clients release the device before unbind.
mapfile -t connectors < <(
  for conn in /sys/class/drm/card*-*; do
    [ -d "$conn" ] || continue
    pci=$(readlink "$conn/../device" 2>/dev/null | grep -oE '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]')
    [ "$pci" = "$GPU_PCI" ] || continue
    [ "$(cat "$conn/status" 2>/dev/null)" = "connected" ] || continue
    basename "$conn" | sed 's/^card[0-9]*-//'
  done | sort -u
)

if [ "${#connectors[@]}" -gt 0 ]; then
  log "disabling KDE outputs: ${connectors[*]}"
  args=()
  for c in "${connectors[@]}"; do args+=("output.${c}.disable"); done
  sudo -u "$USER_NAME" \
    XDG_RUNTIME_DIR="$USER_RUNTIME" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=${USER_RUNTIME}/bus" \
    WAYLAND_DISPLAY="wayland-0" \
    kscreen-doctor "${args[@]}" || log "kscreen-doctor disable failed (continuing)"
  sleep 1
else
  log "no connected outputs found on $GPU_PCI"
fi

# Defense-in-depth: hot-remove + rescan before vfio-pci bind. Forces a clean
# pci_dev so any leftover SMU/firmware state from a prior cycle gets cleared.
# Same caveat as the release hook: rescan may emit a TTM WARN that kills the
# calling userspace process; wrap in subshell with `|| true` so we survive.
# Remove both functions so the rescan re-enumerates the whole device fresh.
log "pre-start hot-remove of $GPU_AUDIO_PCI"
echo 1 > "/sys/bus/pci/devices/${GPU_AUDIO_PCI}/remove" 2>/dev/null || \
  log "(audio function already absent, skipping)"
log "pre-start hot-remove of $GPU_PCI (fresh pci_dev for clean cycle)"
echo 1 > "/sys/bus/pci/devices/${GPU_PCI}/remove"
log "pre-start PCI rescan"
( echo 1 > /sys/bus/pci/rescan ) || true
# Wait briefly for amdgpu/snd_hda_intel to re-claim via modalias before we steal them.
for _ in $(seq 1 10); do
  drv=$(basename "$(readlink -f "/sys/bus/pci/devices/${GPU_PCI}/driver" 2>/dev/null)" 2>/dev/null || true)
  case "$drv" in amdgpu|nvidia) break ;; esac
  sleep 1
done
log "post-rescan driver: ${drv:-unknown}"

bind_to_vfio "$GPU_PCI"
bind_to_vfio "$GPU_AUDIO_PCI"

log "done"
