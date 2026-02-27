#!/bin/bash

# Common functions for distrobox init scripts
# Usage: source "$(dirname "$0")/common.sh"

export DEBIAN_FRONTEND=noninteractive

# Ensure DEBIAN_FRONTEND is preserved through sudo and preconfigure keyboard
if command -v debconf-set-selections &>/dev/null; then
    echo 'Defaults env_keep += "DEBIAN_FRONTEND"' | sudo tee /etc/sudoers.d/keep-debian-frontend >/dev/null
    echo "keyboard-configuration keyboard-configuration/layoutcode string us" | sudo debconf-set-selections
    echo "keyboard-configuration keyboard-configuration/xkb-keymap select us" | sudo debconf-set-selections
fi

HOST_HOME="/home/$USER"
DOTFILES="$HOST_HOME/repos/coulomb/dotfiles"
MARKER_FILE="$HOME/.distrobox-initialized"

# Initialize box - set variables, check marker, print header
# Usage: init_start "box-name"
init_start() {
    BOX_NAME="$1"

    if [ -f "$MARKER_FILE" ]; then
        echo "$BOX_NAME already initialized. Skipping init script."
        exit 0
    fi

    echo "Initializing $BOX_NAME..."
    echo "Host home: $HOST_HOME"
    echo "Dotfiles: $DOTFILES"
}

# Install oh-my-zsh with plugins and set zsh as default shell
setup_zsh() {
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
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
}

# Touch marker file and print completion message
init_end() {
    touch "$MARKER_FILE"
    echo "$BOX_NAME initialization completed."
    echo "restart container or run 'zsh' to start."
}
