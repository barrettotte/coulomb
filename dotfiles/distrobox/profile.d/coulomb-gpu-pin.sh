# Pin steady-state rendering inside distrobox containers to the NVIDIA RTX
# 3090 Ti (PCI 0000:0d:00.0). Keeps containerised GUI apps using a stable
# GPU regardless of where they would otherwise default.
#
# NOTE: these env vars do NOT prevent Chromium/Electron-based apps (e.g.
# VS Code) from crashing when the AMD Radeon RX 7600 (PCI 0000:07:00.0) is
# unbound for the Win10 VM. Chromium opens every /dev/dri/renderDN for GPU
# enumeration regardless of these pins — the open fd to AMD's render node
# errors out when the device disappears, killing the GPU process. Mirrors
# the equivalent pin in dotfiles/flatpak/overrides/com.brave.Browser for
# the host's Brave flatpak; same caveat applies.
#
# Sourced by /etc/profile.d/ at login shell start. distrobox-enter spawns a
# login shell when launching commands, so this applies to anything started
# via the distrobox-exported .desktop files (e.g. "Visual Studio Code (on
# dev-box)").

export DRI_PRIME=pci-0000_0d_00_0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export MESA_VK_DEVICE_SELECT=10de:2203
