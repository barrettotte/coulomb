# Windows 10 VM Setup

A Windows 10 QEMU/KVM VM for apps that don't run on Linux (Fusion 360, etc.), 
with the secondary GPU passed through dynamically - bound to the VM on start, returned to the host on shutdown.

## Hardware

Current setup (re-converged on this after three failed configurations - see [Hardware History](#hardware-history-rejected-configurations) below):

- **Primary GPU (host):** NVIDIA RTX 3090 Ti (Ampere/GA102) at PCI `0000:0d:00.0`, HDMI audio at `0000:0d:00.1`. Drives the host the whole time. On the `nvidia` open kernel module.
- **Secondary GPU (passthrough):** AMD Radeon RX 7600 (Navi 33, `amdgpu`) at PCI `0000:07:00.0`. Both functions are passed through together as a multifunction device — GPU at `0000:07:00.0` (function 0) and HDMI/DP audio at `0000:07:00.1` (function 1). Each is alone in its own IOMMU group (26 and 27). The AMD Windows driver expects to own both functions; with audio left on `snd_hda_intel` the Windows driver init fails with Device Manager Code 43 even though the VGA function passes through cleanly.
- **Host image:** `bazzite-nvidia-open` (open kernel module - works fine with a single Ampere card; nvidia-open's multi-GPU dmabuf issues only surface when *both* GPUs are NVIDIA).
- **Host audio:** AMD HD Audio at `0f:00.4` - unaffected by any of this.

While the VM runs, monitors connected to the secondary GPU go dark - libvirt hooks disable their KDE outputs before unbinding `amdgpu`. On VM shutdown the release hook unbinds both functions from `vfio-pci`, lets the kernel rebind `amdgpu` + `snd_hda_intel` via modalias, sleeps briefly to let KWin register the new GPU, then re-enables outputs via `kscreen-doctor`. **The AMD monitors come back automatically** — no logout/login required, no manual intervention.

**Status:** working end-to-end with no kernel patches. The previously-feared `vfio_pci_remove` NULL-deref cleanup chain only fires when the GPU is wedged from incomplete passthrough (audio function held by host while VGA goes to VM); passing both functions through together avoids the wedge preconditions, so the release cycle is clean on stock kernels.

A separate `vfio_pci_core_runtime_resume` `down_write` oops still happens after ~10 successful start/stop cycles per host boot — see [Known limitations](#known-limitations) for the cycle cap and other operational quirks discovered after this setup was declared working.

### The KWin hot-plug recovery (two pieces)

After VFIO release, `amdgpu` gets a new `/dev/dri/cardN` minor (e.g. `card1 → card3`) and renumbered DRM connectors (e.g. `DP-1 → DP-7`). Getting KWin to re-attach the GPU and re-enable its outputs needs two pieces working together:

**1. `KWIN_DRM_DEVICES` with by-path symlinks (escaped colons).** KWin's DRM backend filters udev events against an explicit allowlist if `KWIN_DRM_DEVICES` is set. The allowlist entries are canonicalized at *each event* via `QFileInfo::canonicalFilePath()`, so by-path symlinks re-resolve to whatever cardN is current. With hardcoded `/dev/dri/cardN`, post-VFIO events for a renumbered minor get filtered out and the GPU never re-attaches.

The override lives at `dotfiles/systemd/user/plasma-kwin_wayland.service.d/override.conf`. The PCI address colons must be `\\:` in the systemd unit file (systemd's parser turns `\\` into `\`, kwin's `splitPathList` then sees `\:` and treats it as a literal colon, not a path-list delimiter). A bare unescaped `:` would split each by-path entry into 3 fragments and break kwin startup with "No suitable DRM devices have been found."

**2. A 3-second sleep before `kscreen-doctor enable`.** After `amdgpu` rebinds, KWin's `addGpu` succeeds (the kernel-fired add event eventually wins the file-creation race), but KWin needs a moment to register the new GPU's connector names in its model. Without the sleep, the hook's `kscreen-doctor output.DP-N.enable` runs before the connector names exist in KWin → silent "output not found" → AMD outputs come back to KWin but **stay disabled**, requiring a manual `kscreen-doctor` enable. 3s is empirically sufficient.

KWin source references for the curious: [`drm_backend.cpp`](https://github.com/KDE/kwin/blob/master/src/backends/drm/drm_backend.cpp) (`splitPathList`, `handleUdevEvent`, `addGpu`), [`session_logind.cpp`](https://github.com/KDE/kwin/blob/master/src/core/session_logind.cpp) (`openRestricted` / `TakeDevice`).

### Fallback safeguard + recovery

The release hook also force-edits `~/.config/kwinoutputconfig.json` to ensure AMD outputs are marked `enabled=true` after each cycle. Plasma 6 persists per-EDID output state in this file. The attach hook's `kscreen-doctor disable` (to free outputs for `amdgpu` unbind) gets autosaved by kscreend; if a cycle gets interrupted before the release's re-enable propagates (e.g. by a hard power-off), the *disabled* state could persist across the reboot → AMD monitors dark on next boot. The safeguard prevents this by directly writing the on-disk state.

If the safeguard ever fails (e.g. kscreend autosaves over our edit before reboot) and you end up with AMD monitors dark on boot, recover from any working terminal (NVIDIA-side Konsole, SSH, or TTY):

```sh
kscreen-doctor output.DP-1.enable output.DP-2.enable
```

If no graphical terminal is reachable, drop to TTY with `Ctrl+Alt+F3`, log in as your user, then run with the env explicitly:

```sh
XDG_RUNTIME_DIR=/run/user/$(id -u) \
DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus \
WAYLAND_DISPLAY=wayland-0 \
kscreen-doctor output.DP-1.enable output.DP-2.enable
```

Then `Ctrl+Alt+F2` back to the wayland session.

## Hardware history (rejected configurations)

Three configurations were tried before re-settling on AMD secondary + NVIDIA primary. Do not repeat these without checking whether the underlying root cause has been fixed.

### 1. AMD Radeon RX 7600 (Navi 33) + RTX 3090 Ti - reattempting

- **Bug:** every VM shutdown oopses the kernel in `vfio_pci_core_sriov_configure+0x2b` (NULL pointer deref at `[rdi+0x450]`) inside `vfio_pci_remove`'s SR-IOV cleanup. Both `unbind` and PCI `remove` sysfs paths funnel through the same `vfio_pci_remove` → same crash. Wedges the PCI device for the GPU; host requires a hard power-off to recover.
- **Scope:** AMD-Navi specific. Confirmed by other users on RX 7600 (Navi 33), RX 7900 series, RX 9070 (Navi 48). See the [CachyOS forum thread](https://discuss.cachyos.org/t/vfio-pci-core-sriov-configure-null-pointer-dereference-with-amd-radeon-rx-9070-navi-48-1002-7550-on-vfio-passthrough/28545).
- **Status:** open. Different from the unrelated Feb-2025 LKML patch "PCI: Fix NULL dereference in SR-IOV VF creation error path" (different function, different offset).
- **Why retrying:** of the three configs, this is the only one where the KWin Wayland multi-GPU model works fine (different vendor drivers don't share state). The remaining failure is a well-defined kernel bug that's amenable to either a patched kernel (CachyOS) or a runtime workaround (kprobe module).

### 2. NVIDIA GTX 1070 (Pascal/GP104) + RTX 3090 Ti, proprietary driver - DO NOT REPEAT

- **Why tried:** to eliminate the AMD bug. Pascal cards forced a fallback to the proprietary `nvidia` driver because nvidia-open supports Turing and newer only.
- **Bug:** at VM start, KWin Wayland still held framebuffer references on the secondary card (cross-GPU dmabuf sharing). When the hook tried to unbind nvidia for the VM, the driver couldn't release framebuffers cleanly → `drm_WARN_ON(!list_empty(&fb->filp_head))` + `NVRM: Attempting to remove device with non-zero usage count!` + `nv_pci_remove_helper` in dmesg → full host session freeze, hard power-off required.
- **Root cause:** proprietary nvidia shares state across cards bound to the same driver instance. Cannot be patched - closed source, architectural.
- **Conclusion:** dual NVIDIA + proprietary driver is structurally incompatible with KWin Wayland dynamic passthrough.

### 3. NVIDIA RTX 3050 6GB (Ampere/GA107) + RTX 3090 Ti, nvidia-open - DO NOT REPEAT

- **Why tried:** both Ampere → both supported by nvidia-open. Documentation indicates nvidia-open keeps per-card state isolated and should support multi-NVIDIA dynamic passthrough.
- **Bug:** identical crash to the proprietary attempt. Pre-VM-start dmesg already showed `Failed to import NVKMS memory to GEM object` errors during normal desktop use. Hook unbind triggered the same `drm_WARN_ON(!list_empty(&fb->filp_head))` + non-zero usage count crash → full host session freeze.
- **Root cause:** KWin Wayland's multi-NVIDIA-GPU dmabuf path is unstable on both driver variants on the current Plasma version. The "isolated per-card state" promise of nvidia-open doesn't extend to the dmabuf/GEM layer that KWin actually uses for cross-GPU composition.
- **Conclusion:** dual NVIDIA + KWin Wayland dynamic passthrough is broken regardless of driver variant on this software stack. May change in future Plasma/nvidia-open versions but not worth retesting without explicit upstream confirmation.

### Key takeaways for future hardware decisions

- **Don't pair two NVIDIA GPUs for passthrough on KWin Wayland.** Either driver variant freezes the host on hot-unbind. The "nvidia-open fixes multi-GPU" guidance you'll see online is not borne out on this stack.
- **Different vendor drivers (NVIDIA primary + non-NVIDIA secondary) is the only configuration where KWin handles dynamic switching cleanly.**
- **AMD secondary is the most practical choice today** despite the SR-IOV kernel bug, because the bug is specific and patchable rather than architectural. Intel Arc as secondary would also avoid the dual-NVIDIA problem; not tried here.
- See git history for hooks/XML tweaks from each era if any card returns.

## Critical rules

> **Add the GPU *after* Windows is fully installed and provisioned**, not during
> the install wizard. Windows installer reboots multiple times. Each reboot is
> a chance for the libvirt `release/end` and `prepare/begin` hooks to race,
> leaving the GPU in a half-bound state that requires a host reboot to unwedge.
> Install Windows on a vanilla VirtIO VM first, snapshot, then add the PCI
> hostdevs.

> **Always shut the VM down from inside Windows** (Start → Shut Down). A
> force-poweroff (virt-manager "Force Off" or `virsh destroy`) skips orderly
> guest device release; the GPU may end up in a state the kernel can't unwind,
> requiring a host reboot. Hit by this once in initial setup - don't repeat it.

## Prerequisites

- libvirt modular daemons (`virtqemud`/`virtstoraged`/`virtnetworkd`) enabled via socket activation - done by the host-setup playbook.
- AMD-V/IOMMU enabled in BIOS. Verify with `ls /sys/class/iommu/` (should show `ivhd0`).
- Secondary GPU function alone in its IOMMU group (no unrelated devices). Audio function `0000:07:00.1` doesn't need to be in any particular group since it's not passed through — it stays on `snd_hda_intel` on the host. Verify:
  ```sh
  for d in /sys/kernel/iommu_groups/*/devices/0000:07:00.0; do echo "GPU group: $d"; done
  ```
  Nothing unrelated should share the GPU's IOMMU group.
- `vfio_pci` module loaded (default on Bazzite).
- Host on `bazzite-nvidia-open` image. The host's 3090 Ti is the only NVIDIA card; the passthrough card is AMD, so the nvidia driver only manages one card and there's no cross-NVIDIA dmabuf risk. (If a second NVIDIA card is ever added, see Hardware History before retrying - dual-NVIDIA dynamic passthrough is broken on this stack.)
- Windows 10 ISO: https://www.microsoft.com/software-download/windows10ISO
- VirtIO drivers ISO: https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

## 1. Install passthrough hooks

Do this **before** creating the VM - libvirt validates host devices when the domain is defined, and the 
GPU stays bound to its host driver until the hooks detach it on VM start.

```sh
sudo bash hooks/install.sh
```

Installs:

- `/etc/libvirt/hooks/qemu` - dispatcher
- `/etc/libvirt/hooks/qemu.d/win10/prepare/begin/10-gpu-attach.sh`
- `/etc/libvirt/hooks/qemu.d/win10/release/end/10-gpu-return.sh`

Then restarts `virtqemud.service`.

Also enable XML editing in virt-manager (one-time): **Edit** > **Preferences** > **General** > check **Enable XML editing**.

## 2. Create the VM (no GPU yet)

### Initial wizard (virt-manager)

1. Open virt-manager, click "Create a new virtual machine".
2. Select the Windows 10 ISO.
3. Set RAM to **16384 MiB** and CPUs to **16** (8 cores × 2 threads - topology configured below).
4. For storage, select "Select or create custom storage" and set the path to `~/storage/code/vms/win10.qcow2` (100GB+ recommended, qcow2 format).
5. Check "Customize configuration before install".

### Pre-install configuration

In the customize view (no PCI hostdevs yet - those come after provisioning):

- **Overview** > Chipset: Q35.
- **CPUs** > Model: `host-passthrough` (or check "Copy host CPU configuration"). Required for sane GPU perf later; default `qemu64` tanks it.
- **CPUs** > **Topology** > check "Manually set CPU topology" and set Sockets `1`, Cores `8`, Threads `2`.
  Windows sees one 8-core / 16-thread CPU rather than 16 single-thread cores, which is what the licensing and scheduler want.
- **Memory** > set Current and Max allocation to `16384`. Disable ballooning if present (or set memory mode to `strict`) so Windows sees a consistent 16 GiB.
- **Disk** > Bus: VirtIO.
- **NIC** > Model: virtio.
- **Add Hardware** > **Storage** > select `virtio-win.iso` as a CDROM (so VirtIO drivers can be loaded during install).

No TPM or Secure Boot required for Windows 10.

### During Windows install

When Windows asks "Where do you want to install Windows?" and shows no drives:

1. Click "Load driver".
2. Uncheck "Hide drivers that aren't compatible with this computer's hardware".
3. Browse to the virtio-win CDROM - `amd64\w10`.
4. Select "Red Hat VirtIO SCSI controller" (`viostor.inf`) - not the SCSI pass-through one.
5. The VirtIO disk appears; proceed with install.

Don't touch virt-manager during install reboots. Just let it run.

### Post-install setup

1. Mount the virtio-win ISO inside Windows.
2. Run `virtio-win-gt-x64.msi` to install all VirtIO guest drivers (network, display, etc.).
3. Download and run [SPICE guest tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe)
   for clipboard sharing, mouse cursor sync, and dynamic resolution.
4. Run the provisioning script in elevated PowerShell - installs packages (including WinFsp for virtiofs), applies Windows settings, debloats, installs fonts:
   ```powershell
   Invoke-WebRequest -Uri https://raw.githubusercontent.com/barrettotte/coulomb/master/vms/windows-10/provision.ps1 -OutFile provision.ps1
   Set-ExecutionPolicy Bypass -Scope Process -Force
   .\provision.ps1
   ```
5. **Run Windows Update to completion** - Settings > Update & Security > Check for updates. Loop: install everything, reboot, check again, repeat until "You're up to date" with no pending reboot.
   Usually 2–4 reboots on a fresh Win10. Do this *before* adding the GPU because every install-time reboot is a chance for the prepare/begin and release/end hooks to race 
   (see Critical rules). With no `<hostdev>` in the XML yet, the attach hook gates out and reboots are safe.
6. In virt-manager: **View** > **Scale Display** > check **Auto resize VM with window**.

### Snapshot: `clean-no-gpu`

Shut down the VM cleanly (Start → Shut Down inside Windows), then:

```sh
virsh -c qemu:///system snapshot-create-as win10 clean-no-gpu
```

This is the rebuild target if GPU passthrough later breaks - far faster than reinstalling Windows.

## 3. Add GPU passthrough

Done **after** the VM is installed, provisioned, and snapshotted clean. Adding hostdevs mid-install is the leading cause of hook races and host wedges.
Shut down the VM, then open it in virt-manager and click the lightbulb icon (Show Virtual Hardware Details).

### Attach the GPU

Only the GPU function (`0000:07:00.0`) is passed through. The HDMI/DP audio function (`0000:07:00.1`) is left on `snd_hda_intel` on the host — Windows uses SPICE virtio audio (or USB) and never needs the AMD card's audio path. Keeping audio off the passthrough chain also avoids a snd_hda_intel rebind failure that requires a host reboot to recover from. The two functions sit in separate IOMMU groups, so this split is allowed.

In the hardware details view, **Add Hardware** > **PCI Host Device** > select:

- `0000:07:00:0 ... Navi 33 [Radeon RX 7600 ...]` - the GPU

Click Finish. A new entry appears in the left hardware pane (e.g. `PCI 0000:07:00.0`).

### Patch the hostdev XML

virt-manager's Add Hardware wizard doesn't expose `managed`, `<driver>`, or `<rom bar>`, so set those in the XML tab.
(Enable XML editing in virt-manager Preferences if you haven't - see section 1.)

Click the new GPU entry (`PCI 0000:07:00.0`) and switch to the **XML** tab. Three edits:

1. Change `managed='yes'` to `managed='no'` on the `<hostdev>` line.
2. Add `<driver name='vfio'/>` as the first child of `<hostdev>`.
3. Add `<rom bar='off'/>` immediately after the `<driver>` line. Suppresses option-ROM mapping — Windows AMD driver tends to behave better when QEMU doesn't try to expose the GPU's vBIOS to the guest, and it removes one source of guest-side Code 43.

Click **Apply**. Final XML:

```xml
<hostdev mode='subsystem' type='pci' managed='no'>
  <driver name='vfio'/>
  <rom bar='off'/>
  <source>
    <address domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
  </source>
  <address type='pci' domain='0x0000' bus='0x09' slot='0x00' function='0x0'/>
</hostdev>
```

The guest `bus`/`slot` values (here `0x09:0x00`) are whatever virt-manager auto-assigned — leave them alone in the common case. There's no `multifunction='on'` because nothing else shares that guest slot.

### Hypervisor hide (Windows-side hygiene)

Even on AMD (where Code 43 is less famous than NVIDIA's), the AMD driver in Windows is touchier about hypervisor presence on RDNA3 with passthrough. Two additions to the `<features>` block reduce the frequency of Code 43 + driver state corruption:

```xml
<features>
  <acpi/>
  <apic/>
  <hyperv mode='custom'>
    ... existing entries ...
    <vendor_id state='on' value='1234567890ab'/>   <!-- add -->
  </hyperv>
  <kvm>                                            <!-- add block -->
    <hidden state='on'/>
  </kvm>
  <vmport state='off'/>
</features>
```

Edit via virt-manager **Overview** → **XML** tab, or directly with `sudo virsh -c qemu:///system edit win10`. Apply, then start the VM as normal.

If Code 43 still recurs after this, the next step is uninstall the AMD driver via [DDU](https://www.guru3d.com/files-details/display-driver-uninstaller-download.html) in Windows Safe Mode + reinstall the AMD WHQL driver (not Preview/Optional builds) fresh. Most AMD-Code-43 cases trace to corrupted Windows-side driver state, not the host config.

### First boot with GPU

Start the VM (the play button in virt-manager). The prepare/begin hook will:
1. Disable the secondary GPU's KDE outputs.
2. PCI hot-remove + bus rescan the GPU. This forces a fresh `pci_dev` for amdgpu to re-probe so any leftover SMU/firmware state from a prior cycle gets cleared — defense in depth against the "SMU stuck" failure mode at next shutdown.
3. Unbind the host `amdgpu` driver and bind vfio-pci on `0000:07:00.0`. (The audio function `0000:07:00.1` is not touched — it stays on `snd_hda_intel` for the lifetime of the host.)

The monitors connected to the secondary GPU will go dark and stay dark until the guest GPU driver is installed - Windows has no driver for the passed-through card yet.
Drive the VM through the **virt-manager SPICE window** in the meantime (software-rendered, fine for installing a driver).
Keyboard and mouse stay with the host; clicking/typing goes into the SPICE window, not the physical monitors. Set up evdev passthrough (section 4) if that gets awkward.

> **SPICE cursor disappearing in regions of the window?** Windows is treating the uninitialized passthrough GPU as a second display adapter and extending the desktop onto it.
> The cursor "leaves" Display 1 when it crosses into the virtual Display 2 space. Quick fix in Windows: **Settings** > **System** > **Display** > **Multiple displays** > **Show only on 1**.
> Goes away on its own once the guest GPU driver is installed.

Inside the guest, Windows detects new PCI hardware. Install the AMD driver from https://www.amd.com/en/support → Graphics > Radeon RX 7000 Series > RX 7600 > Windows 10 64-bit. Use the **full offline installer**, not the auto-detect / streaming one (which often hangs on "Downloading & Extracting minimal build"). **Skip the AMD chipset driver bundle** if offered - the VM uses Q35, not an AMD motherboard chipset, and the chipset installer hangs trying to find hardware that doesn't exist.

> **Don't shut down the VM before the AMD driver is installed.** Without a guest driver Windows can't gracefully release the GPU, which compounds the host-side SR-IOV kernel bug on shutdown. Install the driver during the first SPICE session and only shut down afterward.

After driver install, **shut the VM down from inside Windows** (Start > Shut Down), then start it again from virt-manager. Don't use Windows' "Restart" - the VM XML has `<on_reboot>restart</on_reboot>` (libvirt default), which destroys and re-launches the domain on every guest reboot. That fires `release/end` and `prepare/begin` back-to-back with no gap, exactly the hook race the Critical Rules warn about. Shutdown + manual start gives a human-paced gap between the two hook events.

Monitors physically connected to the secondary GPU should now show the Windows desktop at native resolution.

### Snapshot: `with-gpu`

```sh
virsh -c qemu:///system snapshot-create-as win10 with-gpu
```

You now have two checkpoints:

- `clean-no-gpu` - rebuild target if passthrough breaks.
- `with-gpu` - rebuild target if the guest itself misbehaves.

## 4. Input passthrough (evdev hotkey toggle) - optional

Pass the host keyboard + mouse through to the VM via evdev event nodes, with
a hotkey that toggles ownership between host and guest. Cleaner than SPICE
grab (Ctrl+Alt) once the secondary-GPU monitor is the VM's real display, and
cleaner than USB redirection because the hardware never moves between USB
ports - single keypress to switch sides.

### Identify input devices

```sh
ls -la /dev/input/by-id/ | grep -E "event-(kbd|mouse)$"
```

Pick the symlinks for your physical keyboard and mouse. Examples:

- `usb-Logitech_USB_Receiver-if01-event-kbd`
- `usb-Logitech_USB_Receiver-if02-event-mouse`

If unsure which is which, confirm with `sudo evtest /dev/input/by-id/<candidate>`
- press a key, see events.

### Add to VM XML

VM must be shut down first (XML changes don't apply to a running domain).
`sudo virsh -c qemu:///system edit win10` and add inside `<devices>`:

```xml
<input type='evdev'>
  <source dev='/dev/input/by-id/usb-Corsair_CORSAIR_K70_RGB_PRO_..._-event-kbd'
          grab='all' repeat='on' grabToggle='scrolllock'/>
</input>
<input type='evdev'>
  <source dev='/dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-mouse'/>
</input>
```

Substitute your actual device paths. Notable attributes:

- `grab='all'` (keyboard only) - captures all key events including the hotkey
  itself. Required for the toggle to work.
- `grabToggle='scrolllock'` - **use `scrolllock`, not `ctrl-ctrl`**. The K70
  RGB PRO (and other gaming keyboards with custom firmware) can send the two
  Ctrls with slight timing offsets that qemu's "both simultaneous" detector
  doesn't accept reliably - this manifests as a stuck grab that the toggle
  won't release. Scroll Lock is a single dedicated key, can't fail.
  Other valid values: `alt-alt`, `shift-shift`, `meta-meta`, `ctrl-ctrl`,
  `ctrl-scrolllock`.
- `repeat='on'` - passes key-repeat events to the guest. Without this, holding
  a key in the VM registers only one press.

The mouse entry needs no `grab` - it follows the keyboard's grab state.

### Permissions: cgroup_device_acl in qemu.conf

libvirt's qemu user needs to open `/dev/input/event*`. On Bazzite / Fedora
Atomic, the `input` group is defined in `sysusers.d` (not `/etc/group`), so
`sudo usermod -aG input qemu` silently no-ops - that approach does NOT work.

The correct approach is `cgroup_device_acl` in `/etc/libvirt/qemu.conf` -
grants per-VM access without group membership. The host-setup.yml playbook
manages this via `blockinfile` (look for `BEGIN ANSIBLE MANAGED: evdev
cgroup_device_acl`). Resulting config:

```
cgroup_device_acl = [
    "/dev/null", "/dev/full", "/dev/zero",
    "/dev/random", "/dev/urandom",
    "/dev/ptmx", "/dev/kvm",
    "/dev/rtc", "/dev/hpet",
    "/dev/vfio/vfio",
    "/dev/userfaultfd",
    "/dev/input/by-id/usb-Corsair_..._-event-kbd",
    "/dev/input/by-id/usb-Logitech_USB_Receiver-if02-event-mouse"
]
```

**CRITICAL:** when `cgroup_device_acl` is set, the *defaults must be
re-listed explicitly* or KVM VMs lose access to `/dev/kvm` and
`/dev/vfio/vfio` and refuse to start. Don't omit any of the defaults above.

Restart virtqemud after editing: `sudo systemctl restart virtqemud`.

### Usage

- Start the VM. Initially the host owns keyboard and mouse.
- Press **Scroll Lock** → input flows into the VM (cursor appears on AMD
  monitors via the Windows AMD driver).
- Press **Scroll Lock** again → input returns to the host.
- The hotkey is keyboard-only; mouse follows automatically.
- Status is silent - no on-screen indicator. You'll know which side has it by
  where typing/clicking goes (and where the cursor visually is).

### Recovery if grab gets stuck (NO ssh on this host by policy)

If Scroll Lock somehow fails to release the grab and the host appears frozen
(it's not actually frozen - just has no input):

1. **Physically unplug your keyboard and mouse USB cables.** The kernel sees
   the disconnect, qemu's evdev file descriptors close, the grab releases,
   and the VM keeps running (just temporarily without input). Plug them back
   in and Linux re-detects automatically.

2. As a last resort, hard power-off the host. This was the recovery in
   earlier attempts and is what we want to avoid - hence option 1 first.

DO NOT enable `sshd` "just in case" - this host's policy is no SSH daemon.

### Gotchas

- Anything else reading `/dev/input/event*` directly conflicts (`evtest`,
  `xinput test`, certain accessibility tools). Wayland/KDE go through libinput
  at a higher layer, so the compositor itself is fine.
- If you also pass through USB devices (e.g., game controllers), don't double-
  grab the same device via both evdev and USB redirection - pick one path.
- The hotkey works only while qemu is running and reading the event node. If
  qemu crashes with input grabbed, the host gets it back automatically.

## 5. Shared directory (virtiofs) - optional

Share `~/storage/code/vms/share` with the VM as a drive letter. WinFsp is already installed by `provision.ps1`.

### Host side

- `<memoryBacking><source type='memfd'/><access mode='shared'/></memoryBacking>` on the domain (set during initial creation) — required for virtiofs.
- `<filesystem type='mount' accessmode='passthrough'><driver type='virtiofs'/>
  <source dir='/var/home/barrett/storage/code/vms/share'/>
  <target dir='vmshare'/></filesystem>` device on the domain.
- Share dir labeled `virt_image_t` so virtiofsd can read through enforcing SELinux. The label is persistent via `semanage fcontext`:
  ```sh
  sudo semanage fcontext -a -t virt_image_t '/var/home/barrett/storage/code/vms/share(/.*)?'
  sudo restorecon -RFv /var/home/barrett/storage/code/vms/share
  ```

If rebuilding from scratch, add the filesystem with `virt-xml` (VM shut down):

```sh
sudo virt-xml win10 --add-device --filesystem \
  type=mount,accessmode=passthrough,driver.type=virtiofs,\
source.dir=/var/home/barrett/storage/code/vms/share,target.dir=vmshare
```

### Guest side (Windows, one-time)

1. Mount the virtio-win ISO inside Windows, browse to `viofs\w10\amd64`, right-click `viofs.inf` and **Install**. This registers `VirtIO-FS Service`.
2. Open **Services** (`services.msc`), find **VirtIO-FS Service**, set startup to **Automatic**, click **Start**.
3. The share appears as a new drive letter (typically `Z:`). The `target.dir` tag (`vmshare`) is the share name virtiofs.exe uses internally; it isn't visible in Explorer.

## Known limitations

Things that are confirmed-broken or sub-optimal in the current setup. None block daily use; document so future-you doesn't spend a session re-discovering each. Listed in order of how likely you are to notice.

### Brave force-closes on VM start

When the attach hook unbinds `amdgpu` for VM passthrough, Brave (flatpak) exits immediately — losing open tabs and any unsaved state.

**Root cause:** Chromium's GPU process opens every `/dev/dri/renderDN` node at startup for GPU enumeration (vendor IDs, extensions, capabilities), regardless of `DRI_PRIME`, `__GLX_VENDOR_LIBRARY_NAME`, `MESA_VK_DEVICE_SELECT`, `--render-node-override`, or `--gpu-active-vendor-id`. Those env vars and flags pin *rendering* to NVIDIA, but Brave still holds an open fd on AMD's `renderD130` for enumeration. When the hook hot-removes the AMD GPU, the open fd errors out → GPU process crashes → browser dies. Verified 2026-05-24 via `/proc/PID/fd` inspection.

The `dotfiles/flatpak/overrides/com.brave.Browser` env vars are kept for steady-state rendering pinning (NVIDIA only when both GPUs are present) but they explicitly do NOT prevent this crash. Brave's own header comment was updated to say so.

**Workarounds (not implemented; pick one if it bothers you):**

- **`--disable-gpu`** added to `dotfiles/flatpak/config/com.brave.Browser/brave-flags.conf` — software rendering everywhere; noticeable on heavy pages but Brave survives. Documented "standard fix" from the Chromium/VFIO community.
- **FLATPAK_BWRAP wrapper** — write a custom bwrap wrapper that filters `/dev/dri` to NVIDIA-only inside the flatpak sandbox, set via the `FLATPAK_BWRAP` env var on Brave's `.desktop` launch. Preserves GPU accel; ~1-2hr of fiddly bwrap-arg-juggling and edge-case debugging.
- **Auto-quit before VM start** — modify the attach hook to send SIGTERM to Brave (and reopen it after release). Preserves GPU accel; clunky workflow.

**Daily reality:** just re-launch Brave after VM session. It restores the previous tabs via Brave's "continue where you left off" behavior.

### VS Code in dev-box freezes on VM start

Same root cause as Brave — VS Code is Electron-based, so Electron = Chromium underneath. Same `/dev/dri/renderDN` enumeration → same crash. VS Code freezes hard and must be terminated via process manager.

`dotfiles/distrobox/profile.d/coulomb-gpu-pin.sh` (installed into every container's `/etc/profile.d/` via the `container_init_hook` in `dotfiles/distrobox/distrobox.conf`) exports the same NVIDIA-pinning env vars — same caveat: it pins rendering, doesn't prevent the crash.

**Workarounds (same as Brave):** `--disable-gpu` flag added to the distrobox-exported `dev-box-code.desktop` Exec lines, or sandbox filtering (harder for distrobox than for flatpak), or auto-quit in the attach hook. None implemented.

**Daily reality:** save your VS Code state before launching the VM, kill VS Code afterward, re-open.

### ~10-cycle limit per host boot before kernel oops

The setup is multi-cycle-stable for the first ~10 VM start/stop cycles per host boot. On approximately the 11th cycle, the kernel oopses on VM start with:

```
RIP: down_write+0x20/0x60
 vfio_pci_core_runtime_resume+0x1e/0xa0 [vfio_pci_core]
 vfio_pci_core_enable+0x47/0x350 [vfio_pci_core]
 vfio_pci_open_device+0x20/0x80 [vfio_pci]
 vfio_df_open+0x8a/0x160 [vfio]
 vfio_group_ioctl_get_device_fd+0x11c/0x270 [vfio]
```

**Symptoms:** VM transitions to `paused` state mid-startup; `qemu-system-x86_64` becomes a defunct zombie; `sudo virsh destroy win10` hangs because libvirt is stuck on the kernel-tainted vfio path. Recovery requires a hard reboot (`sudo systemctl reboot` or sysrq REISUB).

**Root cause:** amdgpu's BO accounting leaks on each release cycle (visible as `amdgpu: leaking bo va (-19)` in dmesg every cycle). The PCI rescan in the attach hook gives a fresh `pci_dev` but doesn't reset amdgpu's residual BO state. After many cycles, a stale rwsem reference in `vfio_pci_core` trips on the next `vfio_pci_open_device`.

**Workarounds (none implemented; daily reboot avoids hitting this):**

- **`vendor-reset` kernel module** (github.com/gnif/vendor-reset) — passive DKMS module that intercepts the PCI reset path and applies the AMD-proper sequence (BACO/BU/FLR). Most plausible long-term fix; Navi 33 support is newer/experimental. ~30 min trial cost.
- **Surgical livepatch of `vfio_pci_core_runtime_resume`** — NULL-guard the specific function that oopses. Same risks as previous livepatch attempts (may expose next-in-line bug).
- **Wait for upstream amdgpu fix** — the BO leak is a real upstream bug; Bazzite kernel updates may eventually include the fix.

**Daily reality:** if you reboot at least every 1-2 days you'll never hit this. The cycle counter on `scripts/win10-vm-launch` could warn at 8 cycles (not implemented).

### VM boot screens go to SPICE not physical monitors

OVMF firmware logo, Windows boot logo, and Windows pre-login UI are rendered on the emulated QXL display (visible in the virt-manager SPICE window). The physical monitors connected to the passthrough GPU stay dark until Windows loads the AMD driver at the login screen.

**Why:** libvirt requires exactly one primary `<video>` device; with QXL present and primary, OVMF outputs to QXL during firmware/boot. Attempts to fix on 2026-05-24:

1. `<video><model type='none'/></video>` (kept SPICE) — monitors stayed dark
2. Removed both QXL and SPICE, added `<rom bar='on'/>` to the GPU hostdev — monitors stayed dark
3. Removed both QXL and SPICE, dumped VBIOS from `/sys/bus/pci/devices/0000:07:00.0/rom` to `/var/lib/libvirt/images/win10-vbios.rom` (file kept in place), added `<rom file='...'/>` to hostdev — monitors stayed dark

Per [passthroughpo.st "shadow VBIOS" article](https://passthroughpo.st/explaining-csm-efifboff-setting-boot-gpu-manually/), the sysfs ROM dump is almost certainly the "shadow copy" — the in-memory VBIOS modified by host UEFI + amdgpu during boot. OVMF's GOP driver expects a pristine VBIOS and fails silently when it gets the shadow → no display output, no fallback (since QXL/SPICE are removed).

**Workaround candidates (not implemented; in order of least-effort):**

1. **Clean VBIOS from TechPowerUp's database** — look up the exact RX 7600 model, download the manufacturer-shipped VBIOS, swap into `/var/lib/libvirt/images/win10-vbios.rom`. The XML for option 3 above is already documented; just file-swap.
2. **`video=efifb:off` kernel karg** (via `rpm-ostree kargs --append=video=efifb:off`) — prevents host EFI framebuffer from touching the AMD GPU; redump from sysfs may produce a cleaner ROM. Requires reboot.
3. **Set NVIDIA RTX 3090 Ti as explicit primary in host motherboard BIOS** — AMD GPU is never host-initialized so never gets a shadow VBIOS at all. Most invasive (manual BIOS work) but most reliable.

**Daily reality:** the SPICE window shows boot progress; the physical monitors light up at the login screen. Accepted as the standard VFIO Win10 experience.

## Reference

### Snapshot commands

```sh
# List
virsh -c qemu:///system snapshot-list win10

# Create
virsh -c qemu:///system snapshot-create-as win10 <name>

# Revert (VM must be shut off)
virsh -c qemu:///system snapshot-revert win10 <name>
```

Reverting `clean-no-gpu` is the fast rebuild path if passthrough breaks - strip
the hostdevs from the XML, revert, re-add the hostdevs, reinstall the guest
driver.

### Useful commands

```sh
# Disk image size on host
du -h ~/storage/code/vms/win10.qcow2

# Watch disk growth during provisioning
watch -n 5 du -h ~/storage/code/vms/win10.qcow2

# Driver currently bound to the secondary GPU
lspci -nnk -s 07:00.0 | grep "Kernel driver"

# Hook logs
journalctl -t win10-gpu-attach -t win10-gpu-return
```

### Troubleshooting

- **VM start fails with "Failed to mmap" / BAR errors**: check that nothing
  rebound the GPU after detach. `lspci -nnk -s 07:00.0` should show
  `Kernel driver in use: vfio-pci` while the VM runs. (The audio function
  `07:00.1` stays on `snd_hda_intel` — it's not passed through.)

- **VM start hangs ~10 minutes, then fails; virtqemud unresponsive (F44+)**:
  the journal will show repeated `End of file while reading data: Input/output
  error` followed by `unsupported configuration: pci backend driver type
  'default' is not supported` and `Failed to allocate PCI device list`. Root
  cause is a libvirt 12.0.0 RPC hang in the modular-daemon nodedev path.
  Two-part fix, both in this repo:
  1. Domain XML uses `managed='no'` plus `<driver name='vfio'/>` on each
     `<hostdev>` (see section 3).
  2. The attach hook binds vfio-pci via sysfs (`driver_override` + unbind
     from the prior driver + `drivers_probe`) instead of
     `virsh nodedev-detach`.

  Recovery from a wedged session: usually a reboot - both the libvirt RPC and
  the hook bash process end up uninterruptible. After reboot, re-enable KDE
  outputs with `kscreen-doctor output.<name>.enable` if they didn't come back.

- **Monitors stay dark after shutdown** (no longer expected — both the
  by-path `KWIN_DRM_DEVICES` and the post-rebind sleep need to be in
  place). If they don't come back automatically, check the release hook
  log via `journalctl -t win10-gpu-return` and KWin's hot-plug behavior
  via `journalctl _COMM=kwin_wayland --since "5 minutes ago"`. Manual
  recovery: `kscreen-doctor output.DP-1.enable output.DP-2.enable`
  (substitute your AMD connector names).

- **Manual GPU recovery (host monitors dark + GPU has no driver)**: the
  release hook already does this; only needed if the hook didn't run or
  failed mid-way. Manually:
  ```sh
  echo 1 | sudo tee /sys/bus/pci/devices/0000:07:00.0/remove
  echo 1 | sudo tee /sys/bus/pci/rescan
  ```
  If the `remove` write itself hangs, the device is stuck in a half-
  initialized state and only a host reboot recovers.

- **AMD Navi `vfio_pci_core_sriov_configure` NULL deref on VM shutdown**:
  AMD-Navi-specific kernel bug (RX 7600 / Navi 33 here, also RX 7900, RX
  9070 reported by others on multiple distros). Without a workaround,
  every VM shutdown oopses the kernel and wedges the GPU until host
  reboot. The preconditions for this fault (and the related
  `amdgpu_discovery_sysfs_fini` NULL deref) only fire when the GPU is in
  a wedged state — typically from incomplete passthrough where only the
  VGA function is passed and the audio function is held by the host.
  Passing both functions through together (this setup) avoids the wedge,
  so the bugs don't trigger on the working path. If you hit them after a
  hard power-off or other unusual state, a host reboot recovers.
