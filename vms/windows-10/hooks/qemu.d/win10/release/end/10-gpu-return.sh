#!/usr/bin/env bash
# Return the secondary GPU (PCI 0000:07:00.0) to the host's amdgpu driver
# after the VM shuts down.
#
# Uses PCI hot-remove + rescan instead of unbind + drivers_probe. The
# straightforward `unbind from vfio-pci → echo > drivers_probe` path fails
# on AMD RDNA3 because amdgpu leaks sysfs entries (e.g. mem_info_preempt_used)
# on first unbind; the re-probe attempt collides with the leftover entries
# and exits with -EEXIST. PCI remove tears the device down entirely and
# rescan creates a fresh pci_dev with no leftover state, which amdgpu
# probes cleanly.
#
# Trade-off: rescan creates a brand-new /dev/dri/cardN that kwin (on
# Wayland) does not pick up mid-session. The GPU binds to amdgpu fine and
# the host stays usable, but the monitors connected to the secondary GPU
# stay dark until kwin restarts (logout/login). Documented in setup.md.
#
# The audio function (0000:07:00.1) is not touched — it's left on
# snd_hda_intel for the lifetime of the host. See 10-gpu-attach.sh.
#
# CRITICAL DEPENDENCY: this hook only runs if the vfio-navi-livepatch
# bundle is active. The PCI remove path runs through vfio_pci_remove
# which calls vfio_pci_core_sriov_configure on a possibly-stale pdev —
# Fix 1 of the bundle NULL-checks that path. Without the livepatch the
# remove would oops the kernel and require a hard host reboot. See:
#   https://github.com/barrettotte/vfio-navi-livepatch
#
# If the livepatch is not active, the hook skips the remove and the GPU
# stays on vfio-pci until next host reboot — same fallback behavior as
# the earlier "neutered" version of this hook. Host monitors stay dark
# but the host stays alive.

set -euo pipefail

GPU_PCI="0000:07:00.0"

USER_NAME="barrett"
USER_ID="$(id -u "$USER_NAME")"
USER_RUNTIME="/run/user/${USER_ID}"

LOG_TAG="win10-gpu-return"
log() { logger -t "$LOG_TAG" "$*"; echo "[$LOG_TAG] $*"; }

# Gate on hostdev XML so a VM without GPU passthrough doesn't log noise.
gpu_bus="${GPU_PCI#*:}"; gpu_bus="${gpu_bus%%:*}"
gpu_slot="${GPU_PCI##*:}"; gpu_slot="${gpu_slot%.*}"
gpu_func="${GPU_PCI##*.}"
xml_match="bus='0x${gpu_bus}' slot='0x${gpu_slot}' function='0x${gpu_func}'"
if ! grep -qF "$xml_match"; then
  log "domain XML has no hostdev for $GPU_PCI; skipping (VM not using GPU)"
  exit 0
fi

# Safety gate: do not touch the device unless the vfio-navi-livepatch bundle
# is loaded and enabled. Without it, the PCI remove path oopses the kernel.
LP_ENABLED="/sys/kernel/livepatch/vfio_navi_livepatch/enabled"
if [ ! -f "$LP_ENABLED" ] || [ "$(cat "$LP_ENABLED" 2>/dev/null)" != "1" ]; then
  log "WARNING: vfio-navi-livepatch not active - skipping GPU return"
  log "GPU will stay on vfio-pci until next host reboot (monitors stay dark)"
  log "install the livepatch from https://github.com/barrettotte/vfio-navi-livepatch"
  exit 0
fi

# Capture the current connector set BEFORE remove+rescan. Post-rescan the
# kernel may rename or re-number /dev/dri/cardN; this list lets us still
# attempt kscreen-doctor enable with the pre-rescan connector names.
mapfile -t connectors < <(
  for conn in /sys/class/drm/card*-*; do
    [ -d "$conn" ] || continue
    pci=$(readlink "$conn/../device" 2>/dev/null | grep -oE '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]')
    [ "$pci" = "$GPU_PCI" ] || continue
    basename "$conn" | sed 's/^card[0-9]*-//'
  done | sort -u
)

log "PCI hot-remove of $GPU_PCI (clears RDNA3 sysfs leftover state)"
echo "" > "/sys/bus/pci/devices/${GPU_PCI}/driver_override"
echo 1   > "/sys/bus/pci/devices/${GPU_PCI}/remove"

# PCI rescan can emit a non-fatal kernel WARN in amdgpu's TTM init that
# takes out the calling userspace process via SIGSEGV (preempt_count
# imbalance). Run in a subshell with `|| true` so the parent script
# survives even if the kernel signals us.
log "PCI rescan"
( echo 1 > /sys/bus/pci/rescan ) || true

# Wait for amdgpu to claim the freshly-enumerated device.
for _ in $(seq 1 10); do
  driver=$(basename "$(readlink -f "/sys/bus/pci/devices/${GPU_PCI}/driver" 2>/dev/null)" 2>/dev/null || true)
  case "$driver" in nvidia|amdgpu) break ;; esac
  sleep 1
done
log "GPU driver bound: ${driver:-unknown}"

# Attempt to re-enable the secondary monitors. Note: KWin on Wayland
# enumerates DRM devices at session start and does not pick up new cards
# mid-session, so this call typically no-ops or fails after a rescan.
# The user has to logout/login to recover the monitors. Tried anyway in
# case kwin happens to pick them up (or in case kscreen-doctor has been
# enhanced for hot-plug since this was written).
if [ "${#connectors[@]}" -gt 0 ]; then
  log "enabling KDE outputs (likely no-op until kwin restart): ${connectors[*]}"
  args=()
  for c in "${connectors[@]}"; do args+=("output.${c}.enable"); done
  sudo -u "$USER_NAME" \
    XDG_RUNTIME_DIR="$USER_RUNTIME" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=${USER_RUNTIME}/bus" \
    WAYLAND_DISPLAY="wayland-0" \
    kscreen-doctor "${args[@]}" || log "kscreen-doctor enable failed (expected after rescan — logout/login to restore monitors)"
fi

log "done"
