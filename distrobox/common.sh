#!/bin/bash

# Common functions for distrobox init scripts
# Usage: source "$(dirname "$0")/common.sh"

# Debian/Ubuntu-specific setup (skipped on Arch, Kali inherits from Debian)
if command -v apt-get &>/dev/null; then
    export DEBIAN_FRONTEND=noninteractive

    if command -v debconf-set-selections &>/dev/null; then
        echo 'Defaults env_keep += "DEBIAN_FRONTEND"' | sudo tee /etc/sudoers.d/keep-debian-frontend >/dev/null
        echo "keyboard-configuration keyboard-configuration/layoutcode string us" | sudo debconf-set-selections
        echo "keyboard-configuration keyboard-configuration/xkb-keymap select us" | sudo debconf-set-selections
    fi
fi

HOST_HOME="/home/$USER"
DOTFILES="$HOST_HOME/repos/coulomb/dotfiles"
MARKER_FILE="$HOME/.distrobox-initialized"

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

# Install base packages common to all Debian/Ubuntu-based boxes.
install_apt_base() {
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        cmake \
        git \
        curl \
        wget \
        unzip \
        python3 \
        python3-pip \
        python3-venv \
        zsh
}

# Install oh-my-zsh with plugins and set zsh as default shell
setup_zsh() {
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing ohmyzsh plugins and changing default shell to Zsh..."
        rm -rf "$HOME/.oh-my-zsh"

        RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
        sudo chsh -s /usr/bin/zsh $USER
    fi
}

# Symlink common dotfiles and repos
setup_symlinks() {
    ln -snf "$HOST_HOME/storage/code/repos" "$HOME/repos"
    ln -snf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
    ln -snf "$DOTFILES/.zshrc" "$HOME/.zshrc"
    ln -snf "$HOST_HOME/.ssh" "$HOME/.ssh"
}

# Pin OpenGL / Vulkan / DRI offload inside the container to the NVIDIA RTX
# 3090 Ti (PCI 0000:0d:00.0). The host has a secondary AMD Radeon RX 7600
# (PCI 0000:07:00.0) that gets passed through to the Win10 VM via vfio-pci.
# Container apps inherit /dev/dri/* from the host, so without this pin a
# GUI app inside a distrobox can pick up the AMD card and crash hard when
# the libvirt hooks unbind amdgpu on VM start (Electron renderers die,
# OpenGL contexts disappear). distrobox-enter goes through `su -` so
# /etc/profile.d/*.sh is sourced for the launched command.
pin_nvidia_gpu() {
    sudo tee /etc/profile.d/nvidia-pin.sh > /dev/null <<'EOF'
export DRI_PRIME=pci-0000_0d_00_0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __NV_PRIME_RENDER_OFFLOAD=1
export MESA_VK_DEVICE_SELECT=10de:2203
EOF
    sudo chmod 0644 /etc/profile.d/nvidia-pin.sh
}

# Write marker file and print completion message
init_end() {
    touch "$MARKER_FILE"
    echo "$BOX_NAME initialization completed."
    echo "restart container or run 'zsh' to start."
}
