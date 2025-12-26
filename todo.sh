#!/bin/bash

# Stuff that I need to add to Ansible and check. But, this is the order of operations needed.

set -e

COULOMB="$HOME/storage/code/repos/coulomb"
DOTFILES="$COULOMB/dotfiles"

# =============================================================================
# Directory structure
# =============================================================================

# Directories for mounted drives
mkdir -p "$HOME/storage/mass"
mkdir -p "$HOME/storage/code"
mkdir -p "$HOME/storage/misc"

mkdir -p "$HOME/storage/code/repos"
ln -snf "$HOME/storage/code/repos" "$HOME/repos"

# make sure we actually have access to the mounted drives
sudo chown -R barrett:barrett "$HOME/storage"

# =============================================================================
# Mounted drives
# =============================================================================

# Add each drive to /etc/fstab
# UUID=xxx   /home/barrett/storage/mass   ext4    defaults,nofail       0 2
# UUID=xxx   /home/barrett/storage/code   ext4    defaults,nofail       0 2
# UUID=xxx   /home/barrett/storage/misc   ext4    defaults,nofail       0 2
systemctl daemon-reload

# =============================================================================
# Setup Zsh
# =============================================================================

# set default shell to zsh
chsh -s /usr/bin/zsh

# ohmyzsh
touch "$HOME/.zshrc"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# ohmyzsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

ln -snf "$DOTFILES/.zshrc" "$HOME/.zshrc"

# =============================================================================
# Fonts
# =============================================================================

curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/JetBrainsMono.zip
unzip /tmp/JetBrainsMono.zip -d /tmp/JetBrainsMono
cp -r /tmp/JetBrainsMono "$HOME/.local/share/fonts/"

# refresh font cache
fc-cache -fv

# =============================================================================
# Distrobox
# =============================================================================

# needed for podman CDI (Container Device Interface)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

mkdir -p "$HOME/storage/code/distrobox"
mkdir -p "$HOME/storage/code/podman"
mkdir -p "$HOME/.config/containers"
mkdir -p "$HOME/.config/distrobox"

# make sure distrobox export bin directory has correct permissions
mkdir -p "$HOME/.local/bin"
sudo chown -R barrett:barrett "$HOME/.local/bin"

# store container data on other drive
distrobox stop --all
podman stop -a

ln -snf "$DOTFILES/podman/storage.conf" "$HOME/.config/containers/storage.conf"
ln -snf "$DOTFILES/distrobox/distrobox.conf" "$HOME/.config/distrobox/distrobox.conf"

# =============================================================================
# Dotfiles
# =============================================================================

# setup git user
ln -snf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"

# KDE Plasma config
ln -snf "$DOTFILES/kde/kdeglobals" "$HOME/.config/kdeglobals"
ln -snf "$DOTFILES/kde/kwinrc" "$HOME/.config/kwinrc"

# Konsole
ln -snf "$DOTFILES/konsole/default-zsh.profile" "$HOME/.local/share/konsole/default-zsh.profile"
ln -snf "$DOTFILES/konsole/konsolerc" "$HOME/.config/konsolerc"

# Power management
ln -snf "$DOTFILES/powerdevilrc" "$HOME/.config/powerdevilrc"

# tmux
ln -snf "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"

# fix Steam defaulting to wrong GPU
ln -snf "$DOTFILES/flatpak/overrides/com.valvesoftware.Steam" "$HOME/.local/share/flatpak/overrides/com.valvesoftware.Steam"

# =============================================================================
# TODO: Virtualization
# =============================================================================

# =============================================================================
# Final
# =============================================================================

distrobox assemble create --file distrobox/distrobox.ini

