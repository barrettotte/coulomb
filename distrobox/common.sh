#!/bin/bash

# Common functions for distrobox init scripts.
# Usage: source "$(dirname "$0")/common.sh"

HOST_HOME="/home/$USER"
DOTFILES="$HOST_HOME/repos/coulomb/dotfiles"
MARKER_FILE="$HOME/.distrobox-initialized"

# Pin steady-state rendering to the NVIDIA RTX 3090 Ti (PCI 0000:0d:00.0).
# The AMD card is the VFIO passthrough target, so containerised GUI apps must
# steer to NVIDIA. Idempotent: rewritten on every init_hook so a dotfile edit
# propagates on next container restart.
# Caveat: doesn't help Chromium/Electron apps, which probe every
# /dev/dri/renderDN regardless and crash when AMD's render node disappears.
sudo tee /etc/profile.d/coulomb-gpu-pin.sh > /dev/null <<'EOF'
export DRI_PRIME=pci-0000_0d_00_0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export MESA_VK_DEVICE_SELECT=10de:2203
EOF
sudo chmod 644 /etc/profile.d/coulomb-gpu-pin.sh

# Initialize box - check marker, fix permissions, print header.
# Usage: init_start "box-name"
init_start() {
    BOX_NAME="$1"

    if [ -f "$MARKER_FILE" ]; then
        echo "$BOX_NAME already initialized. Skipping init script."
        echo "To re-run init, delete $MARKER_FILE and recreate the container."
        exit 0
    fi

    # fix ownership of dirs distrobox setup created as root
    sudo chown -R "$(id -u):$(id -g)" "$HOME"

    # suppress distro login messages
    touch "$HOME/.hushlogin"

    echo "Initializing $BOX_NAME..."
    echo "Host home: $HOST_HOME"
    echo "Dotfiles: $DOTFILES"
}

# Copy image-shipped /opt/ohmyzsh into $HOME and switch login shell to zsh.
setup_zsh_from_image() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Linking ohmyzsh from /opt and changing default shell to Zsh..."
        cp -r /opt/ohmyzsh "$HOME/.oh-my-zsh"
        rm -rf "$HOME/.oh-my-zsh/cache" # force fresh compinit on first zsh
        sudo chsh -s /usr/bin/zsh "$USER"
    fi
}

# Symlink common dotfiles and repos
setup_symlinks() {
    ln -snf "$HOST_HOME/storage/code/repos" "$HOME/repos"
    ln -snf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
    ln -snf "$DOTFILES/.zshrc" "$HOME/.zshrc"
    ln -snf "$HOST_HOME/.ssh" "$HOME/.ssh"
}

# Write marker file and print completion message
init_end() {
    touch "$MARKER_FILE"
    echo "$BOX_NAME initialization completed."
    echo "restart container or run 'zsh' to start."
}
