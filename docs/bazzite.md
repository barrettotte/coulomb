# Bazzite

Prerequisites to complete before running `bash init.sh`.

Using image `bazzite-nvidia-open:stable` (open kernel module).

Why the open module:

- **Better long-session stability with NVIDIA on KWin Wayland.** The proprietary driver had
  cross-GPU dmabuf import failures that caused screen freezes after hours of use even with
  a single GPU. nvidia-open avoids those.
- **All current cards in the system are Turing+** (RTX 3090 Ti / GA102 Ampere), supported by
  the open module. If a Pascal or older NVIDIA card is ever added, the open driver won't bind
  to it; the fallback is rebasing to proprietary `bazzite-nvidia`, but that loses the
  long-session stability above.

**Hard-learned constraint: do NOT pair two NVIDIA GPUs for VFIO passthrough on this stack.**
Both `bazzite-nvidia` (proprietary) and `bazzite-nvidia-open` were tested with a second
NVIDIA card in 2026-05 (GTX 1070 Pascal + 3090 Ti, then RTX 3050 6GB Ampere + 3090 Ti).
Both froze the host on VM start with `drm_WARN_ON(!list_empty(&fb->filp_head))` +
`NVRM: Attempting to remove device with non-zero usage count!` - KWin Wayland holds
framebuffers on the secondary NVIDIA card that the nvidia driver can't release on hot-unbind.
Driver variant doesn't matter; it's a KWin/nvidia-multi-GPU integration issue. See
`vms/windows-10/setup.md` Hardware History for the full incident notes. Use a non-NVIDIA
secondary (AMD, Intel) if you want dynamic GPU passthrough on this host.

## Switch image variants

Current → open (required for the dynamic-passthrough workflow with multiple Turing+ NVIDIA GPUs):

```sh
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-nvidia-open:stable
sudo systemctl reboot
```

Fallback → proprietary (only needed if a Pascal or older NVIDIA card is plugged in and must
have a host driver - accept that dynamic GPU passthrough won't work reliably until that card
is removed):

```sh
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-nvidia:stable
sudo systemctl reboot
```

To roll back to the previous deployment if something is wrong:

```sh
rpm-ostree rollback
sudo systemctl reboot
```

After confirming the new variant is stable, the old deployment can be pinned-cleaned automatically
by rpm-ostree (no manual cleanup required).

## Drive Mounts

```sh
lsblk -f

sudo mkdir -p /var/mnt/code
sudo sh -c 'echo "UUID=<UUID-1> /var/mnt/code ext4 defaults,nofail 0 2" >> /etc/fstab'

sudo mkdir -p /var/mnt/mass
sudo sh -c 'echo "UUID=<UUID-2> /var/mnt/mass ext4 defaults,nofail 0 2" >> /etc/fstab'

sudo mkdir -p /var/mnt/misc
sudo sh -c 'echo "UUID=<UUID-3> /var/mnt/misc ext4 defaults,nofail 0 2" >> /etc/fstab'

# Recursive bind mount (so things like Daedalus don't throw a fit over symlinks)
mkdir -p "$HOME/storage"
sudo sh -c 'echo "/var/mnt /var/home/barrett/storage none rbind,nofail 0 0" >> /etc/fstab'

sudo systemctl daemon-reload
sudo mount -a

ln -s ~/storage/code/repos ~/repos
```

## Homebrew

```sh
# Note: I think this might already come bundled with Bazzite
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## SSH Keys

```sh
ssh-keygen -t ed25519 -C "<email>"
ssh-add ~/.ssh/id_ed25519
```

## Setup

```sh
git clone https://github.com/barrettotte/coulomb.git && cd coulomb
bash init.sh
```
