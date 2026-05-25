#!/usr/bin/env bash
# Return the secondary GPU (PCI 0000:07:00.0) AND its audio function
# (0000:07:00.1) to their host drivers (amdgpu / snd_hda_intel) after the
# VM shuts down.
#
# Plain unbind + drivers_probe path (no PCI hot-remove). Empirically this
# probes amdgpu cleanly on this setup — the previously-feared
# mem_info_preempt_used sysfs leak (which forced PCI remove + rescan in an
# earlier version of this hook) does not manifest with the audio function
# also passed through (the wedged-GPU preconditions for that leak don't
# arise on a clean release). This path is faster and avoids the rescan's
# kernel-WARN-in-TTM-init quirk that took out the calling userspace
# process via SIGSEGV.
#
# amdgpu's new instance gets a renumbered /dev/dri/cardN and renumbered DRM
# connectors (DP-1 -> DP-7, etc). Two pieces make the cycle recover cleanly
# without logout:
#   1. KWIN_DRM_DEVICES (set in the systemd user unit override in dotfiles)
#      uses /dev/dri/by-path/pci-...-card symlinks with escaped colons.
#      KWin canonicalizes these at event time, so they re-resolve to the
#      current cardN per event - hardcoded cardN would filter out the new
#      card after VFIO release and the GPU never re-attaches.
#   2. A 3-second sleep below before kscreen-doctor enable, so kscreen-doctor
#      finds the connector names in KWin's model (which take a moment to
#      register after addGpu).
#
# Audio function: snd_hda_intel may not re-bind cleanly if the function
# came back from the guest in D3 — non-fatal here (host doesn't use HDMI
# audio), the audio rebind state is logged but the script continues.

set -euo pipefail

GPU_PCI="0000:07:00.0"
GPU_AUDIO_PCI="0000:07:00.1"

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

log "unbind audio function $GPU_AUDIO_PCI from vfio-pci"
echo "" > "/sys/bus/pci/devices/${GPU_AUDIO_PCI}/driver_override" 2>/dev/null || true
echo "${GPU_AUDIO_PCI}" > /sys/bus/pci/drivers/vfio-pci/unbind 2>/dev/null || \
  log "(audio unbind failed — may already be unbound)"

log "unbind VGA $GPU_PCI from vfio-pci"
echo "" > "/sys/bus/pci/devices/${GPU_PCI}/driver_override"
echo "${GPU_PCI}" > /sys/bus/pci/drivers/vfio-pci/unbind

log "drivers_probe $GPU_PCI (let kernel pick amdgpu via modalias)"
echo "${GPU_PCI}" > /sys/bus/pci/drivers_probe

log "drivers_probe $GPU_AUDIO_PCI (let kernel pick snd_hda_intel via modalias)"
echo "${GPU_AUDIO_PCI}" > /sys/bus/pci/drivers_probe || true

# Wait for amdgpu to claim the VGA function.
for _ in $(seq 1 10); do
  driver=$(basename "$(readlink -f "/sys/bus/pci/devices/${GPU_PCI}/driver" 2>/dev/null)" 2>/dev/null || true)
  case "$driver" in nvidia|amdgpu) break ;; esac
  sleep 1
done
log "GPU driver bound: ${driver:-unknown}"

audio_driver=$(basename "$(readlink -f "/sys/bus/pci/devices/${GPU_AUDIO_PCI}/driver" 2>/dev/null)" 2>/dev/null || true)
log "audio driver bound: ${audio_driver:-unbound (host HDMI audio stays dark until reboot — acceptable)}"

# Give KWin time to register the freshly-rebound DRM device before the
# kscreen-doctor enable call below. Without this delay, kscreen-doctor's
# `output.<name>.enable` runs before KWin has finished addGpu(), the
# connector names are not yet in KWin's model, the enable silently fails,
# and the AMD outputs come back DISABLED in kwin even though kwin has the
# GPU. 3s is empirically sufficient on this hardware.
#
# Required companion: KWIN_DRM_DEVICES env (set via systemd user override
# in dotfiles/systemd/user/plasma-kwin_wayland.service.d/override.conf)
# uses by-path symlinks with escaped colons so KWin's explicit-GPU
# allowlist re-resolves to the *current* cardN per udev event. Without
# that, post-VFIO-release events get filtered out by KWin and addGpu is
# never even attempted for the new card.
log "wait 3s for kwin to register new DRM device before kscreen-doctor enable"
sleep 3

# Capture connector names AFTER amdgpu rebinds (post-rebind connector
# numbers are stable for the new amdgpu instance — e.g. DP-7, DP-8 — and
# differ from pre-cycle names since amdgpu allocates fresh connector IDs).
mapfile -t connectors < <(
  for conn in /sys/class/drm/card*-*; do
    [ -d "$conn" ] || continue
    pci=$(readlink "$conn/../device" 2>/dev/null | grep -oE '[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-9]')
    [ "$pci" = "$GPU_PCI" ] || continue
    [ "$(cat "$conn/status" 2>/dev/null)" = "connected" ] || continue
    basename "$conn" | sed 's/^card[0-9]*-//'
  done | sort -u
)

# kscreen-doctor enable on the post-rebind connector names. With KWIN_DRM_DEVICES
# in place (see header), KWin does attach the new GPU and this call DOES recover
# the AMD outputs in-session. May silently fail if connector enumeration is racing
# the addGpu — the kwinoutputconfig.json safeguard below catches that case.
if [ "${#connectors[@]}" -gt 0 ]; then
  log "attempting kscreen-doctor enable: ${connectors[*]} (expected no-op until kwin restart)"
  args=()
  for c in "${connectors[@]}"; do args+=("output.${c}.enable"); done
  sudo -u "$USER_NAME" \
    XDG_RUNTIME_DIR="$USER_RUNTIME" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=${USER_RUNTIME}/bus" \
    WAYLAND_DISPLAY="wayland-0" \
    kscreen-doctor "${args[@]}" 2>&1 | sed "s/^/[$LOG_TAG] kscreen-doctor: /" || true
fi

# Safeguard: directly force-enable AMD outputs in kwin's persisted output
# config. The attach hook's kscreen-doctor disable gets autosaved by kscreend
# to ~/.config/kwinoutputconfig.json; if the user reboots or hard-power-offs
# without kwin processing the post-release re-enable (e.g. logout itself hung
# because of the kwin hot-plug bug), the disabled state persists across boot
# → AMD monitors come up dark → potential recovery loop where each
# hard-power-off compounds the problem. This direct edit ensures the on-disk
# state is correct regardless of whether kwin's in-session enable succeeded.
log "safeguard: force-enable AMD outputs in kwinoutputconfig.json"
sudo -u "$USER_NAME" python3 - "${connectors[@]:-}" <<'PYEOF' 2>&1 | sed "s/^/[$LOG_TAG] kscreen-config: /"
import json, os, sys, tempfile

config_path = os.path.expanduser('~/.config/kwinoutputconfig.json')
if not os.path.exists(config_path):
    print('no kwinoutputconfig.json — nothing to do')
    sys.exit(0)

# Target AMD GPU's connectors. Connector names get renumbered across amdgpu
# rebinds (DP-1 → DP-7 etc), but kwin stores by EDID, so the original DP-1/2
# entries in the config persist regardless of the current kernel-side names.
# Hardcoded for this hardware; update if monitor wiring changes.
amd_connectors = {'DP-1', 'DP-2', 'DP-3', 'HDMI-A-1'}

with open(config_path) as f:
    data = json.load(f)

# Two top-level configs: "outputs" (per-output details with connectorName)
# and "setups" (multi-monitor topologies with enabled/position state).
amd_indices = set()
for cfg in data:
    if cfg.get('name') == 'outputs':
        for i, output in enumerate(cfg.get('data', [])):
            if output.get('connectorName') in amd_connectors:
                amd_indices.add(i)

if not amd_indices:
    print(f'no AMD outputs in config (none matching {amd_connectors})')
    sys.exit(0)

modified = 0
for cfg in data:
    if cfg.get('name') == 'setups':
        for setup in cfg.get('data', []):
            for output_ref in setup.get('outputs', []):
                if output_ref.get('outputIndex') in amd_indices:
                    if not output_ref.get('enabled', True):
                        output_ref['enabled'] = True
                        modified += 1

if modified == 0:
    print(f'AMD outputs already enabled in all setups (no edit needed)')
    sys.exit(0)

# Atomic write — temp file in same dir, rename.
dir_ = os.path.dirname(config_path)
with tempfile.NamedTemporaryFile('w', dir=dir_, delete=False) as tf:
    json.dump(data, tf, indent=4)
    tmp = tf.name
os.chmod(tmp, 0o644)
os.rename(tmp, config_path)
print(f'force-enabled {modified} AMD output reference(s) in {config_path}')
PYEOF

log "done"
