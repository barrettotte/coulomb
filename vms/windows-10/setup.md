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
4. Create a disk (100GB+ recommended, qcow2 format)
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
2. Browse to the virtio-win CDROM → `viostor\w10\amd64`
3. The VirtIO disk will appear, proceed with install

### After Windows install

1. Mount the virtio-win ISO inside Windows
2. Run `virtio-win-gt-x64.msi` to install all VirtIO guest drivers (network, display, etc.)
3. Install SPICE guest tools for clipboard sharing and dynamic resolution

## Provision

```powershell
# Transfer provisioning script to VM and run the following in elevated PowerShell

Set-ExecutionPolicy Bypass -Scope Process -Force
.\provision.ps1
```

## Snapshot

```sh
# Take clean snapshot after provisioning
virsh snapshot-create-as win10 provisioned-clean
```

```sh
# Revert
virsh snapshot-revert win10 provisioned-clean
```

## GPU Passthrough (optional)

For Fusion 360 and other GPU-heavy apps, you may want to pass through a GPU.

1. Isolate the GPU with `vfio-pci` kernel module (add to kernel args)
2. Add the GPU as a PCI host device in virt-manager
3. This is a more involved setup — see the Arch Wiki article on PCI passthrough
