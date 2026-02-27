# Bazzite

Notes of differences when setting up on Bazzite instead of Kinoite

```sh
# Nvidia fixes

rpm-ostree kargs --append=nvidia-drm.modeset=1 --append=nvidia-drm.fbdev=1

# need this for Pascal architecture support (GTX 1030)
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bazzite-nvidia:stable
```

```sh
lsblk -f

sudo mkdir -p /var/mnt/code
sudo sh -c 'echo "UUID=75c7d7e0-385b-41eb-af2e-989e448546d8 /var/mnt/code ext4 defaults,nofail 0 2" >> /etc/fstab'

sudo mkdir -p /var/mnt/mass
sudo sh -c 'echo "UUID=e2ba426d-139e-4d8e-9026-8e7508f6011b /var/mnt/mass ext4 defaults,nofail 0 2" >> /etc/fstab'

sudo mkdir -p /var/mnt/misc
sudo sh -c 'echo "UUID=8697a5dd-bf0c-48bd-821a-53341bf49b2b /var/mnt/misc ext4 defaults,nofail 0 2" >> /etc/fstab'

# add recursive bind mount (so things like Daedalus don't throw a fit over symlinks)
mkdir -p "$HOME/storage"
sudo sh -c 'echo "/var/mnt /var/home/barrett/storage none rbind,nofail 0 0" >> /etc/fstab'


sudo systemctl daemon-reload
sudo mount -a

ln -s ~/storage/code/repos ~/repos
```

```sh
# brew installed:
htop
claude
fastfetch
zsh
```

```sh
ssh-keygen -t ed25519 -C "barrettotte@gmail.com"
ssh-add ~/.ssh/id_ed25519
```

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
echo $(brew --prefix)/bin/zsh | sudo tee -a /etc/shells
sudo usermod --shell $(brew --prefix)/bin/zsh $USER

DOTFILES="$HOME/storage/code/repos/coulomb/dotfiles"
ln -snf "$DOTFILES/.zshrc" "$HOME/.zshrc"

echo 'export XDG_DATA_DIRS="/home/barrett/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/share/kde-settings/kde-profile/default/share:/usr/local/share:/usr/share"' >> ~/.zprofile

```


## To Do

```sh
# Virtualization
- qemu-kvm
- libvirt
- virt-install
- virt-manager
- edk2-ovmf # UEFI support for Windows 10/11 VMs
- bridge-utils
- vagrant
- vagrant-libvirt
- vagrant-sshfs

# Containerization
- distrobox
- toolbox
- podman

# Misc Tools
- curl
- git
- zsh
- tmux


# fix Steam defaulting to wrong GPU?
ln -snf "$DOTFILES/flatpak/overrides/com.valvesoftware.Steam" "$HOME/.local/share/flatpak/overrides/com.valvesoftware.Steam"


```
