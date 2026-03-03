# Windows 10 VM Setup

A Windows 10 QEMU/KVM VM for applications that don't run on Linux (Fusion 360, etc.).

## Prerequisites

- libvirtd enabled (done by host-setup playbook)
- Windows 10 ISO from https://www.microsoft.com/software-download/windows10ISO
- VirtIO drivers ISO from https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso

## Create VM

### Via virt-manager (Recommended)

1. Open virt-manager, click "Create a new virtual machine"
2. Select the Windows 10 ISO
3. Set RAM (8GB+) and CPUs (4+)
4. For storage, select "Select or create custom storage" and set the path to `~/storage/code/vms/win10.qcow2` (100GB+ recommended, qcow2 format)
5. Check "Customize configuration before install"

Before starting the install, configure:

- **Overview** > Chipset: Q35
- **Disk** > Bus: VirtIO (for better performance)
- **NIC** > Model: virtio
- **Add Hardware** > Storage > Select `virtio-win.iso` as a CDROM (so VirtIO drivers can be loaded during install)

No TPM or Secure Boot required for Windows 10.

### During Windows install

When Windows asks "Where do you want to install Windows?" and shows no drives:
1. Click "Load driver"
2. Uncheck "Hide drivers that aren't compatible with this computer's hardware"
3. Browse to the virtio-win CDROM - `amd64\w10`
4. Select "Red Hat VirtIO SCSI controller" (`viostor.inf`) - not the SCSI pass-through one
5. The VirtIO disk will appear, proceed with install

### After Windows install

1. Mount the virtio-win ISO inside Windows
2. Run `virtio-win-gt-x64.msi` to install all VirtIO guest drivers (network, display, etc.)
3. Download and run [SPICE guest tools](https://www.spice-space.org/download/windows/spice-guest-tools/spice-guest-tools-latest.exe) for clipboard sharing and dynamic resolution
4. Reboot
5. In virt-manager: **View** > **Scale Display** > check **Auto resize VM with window**

## Provision

Transfer `provision.ps1` to the VM and run in elevated PowerShell:

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/barrettotte/coulomb/master/vms/windows-10/provision.ps1 -OutFile provision.ps1
Set-ExecutionPolicy Bypass -Scope Process -Force
.\provision.ps1
```

This installs all packages (including WinFsp), applies Windows settings, debloats, and installs fonts.

## Shared Directory

Uses virtiofs to share a host directory with the VM.
WinFsp is already installed by `provision.ps1`.

### Host side (virt-manager)

1. Shut down the VM
2. In virt-manager, open VM hardware details
3. **Memory** > Enable shared memory (required for virtiofs)
4. **Add Hardware** > **Filesystem**
   - Driver: `virtiofs`
   - Source path: `/var/home/barrett/storage/code/repos/coulomb/vms/windows-10`
   - Target path: `share`
5. Boot the VM

### Guest side (Windows)

1. Mount the virtio-win ISO, browse to `viofs\w10\amd64`, right-click the `.inf` file and Install
2. Open **Services** (`services.msc`), find **VirtIO-FS Service**, set startup to **Automatic** and click **Start**
3. The shared directory should appear as a new drive letter (e.g. `Z:`)

## Snapshot

```sh
# Take clean snapshot after provisioning
virsh -c qemu:///system snapshot-create-as win10 provisioned-clean
```

```sh
# Revert
virsh -c qemu:///system snapshot-revert win10 provisioned-clean
```

## Useful Commands

```sh
# Check disk image size on host
du -h ~/storage/code/vms/win10.qcow2

# Watch disk growth during provisioning
watch -n 5 du -h ~/storage/code/vms/win10.qcow2
```

## GPU Passthrough (optional)

For Fusion 360 and other GPU-heavy apps, you may want to pass through a GPU.

1. Isolate the GPU with `vfio-pci` kernel module (add to kernel args)
2. Add the GPU as a PCI host device in virt-manager
3. This is a more involved setup. See the Arch Wiki article on PCI passthrough

TODO: Dynamic GPU passthrough. Pass smaller GPU over only when VM needed?
