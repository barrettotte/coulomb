#!/bin/bash

# Initialize dev-box distrobox

set -ex

BOX_NAME="dev-box"
HOST_HOME="/home/$USER"
DOTFILES="$HOST_HOME/repos/coulomb/dotfiles"
MARKER_FILE="$HOME/.distrobox-initialized"

# exit if already initialized
if [ -f "$MARKER_FILE" ]; then
    echo "$BOX_NAME already initialized. Skipping init script."
    exit 0
fi

echo "Initializing $BOX_NAME..."
echo "Host home: $HOST_HOME"
echo "Dotfiles: $DOTFILES"

# initialize keyring
echo "Initializing Arch Keyring..."
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy --noconfirm archlinux-keyring

# update and install packages
echo "Installing packages..."
sudo pacman -Syu --noconfirm --needed \
    neovim \
    vim \
    zsh \
    git \
    feh \
    ffmpeg \
    ripgrep \
    wl-clipboard \
    fd \
    curl \
    jq \
    base-devel \
    npm \
    python \
    go

# uv - python package manager
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh

# compile/install Microsoft proprietary VS Code (for marketplace/debuggers)
if ! command -v code &> /dev/null; then
    echo "Installing VS Code..."
    rm -rf /tmp/vscode

    git clone https://aur.archlinux.org/visual-studio-code-bin.git /tmp/vscode
    pushd . && cd /tmp/vscode
    makepkg -si --noconfirm
    popd && rm -rf /tmp/vscode
fi

# add vscode extensions (generated via code --list-extensions > extensions.txt)
echo "Installing VS Code extensions..."
cat "$DOTFILES/vscode/extensions.txt" | xargs -L 1 code --install-extension || true

# setup nerd font (for vscode, nvim will use host's nerd font)
if [ ! -d "$HOME/.local/share/fonts/JetBrainsMono" ]; then
    echo "Installing JetBrainsMono Nerd Font..."
    rm -f /tmp/JetBrainsMono.zip

    curl -L https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip -o /tmp/JetBrainsMono.zip
    mkdir -p "$HOME/.local/share/fonts"
    unzip /tmp/JetBrainsMono.zip -d "$HOME/.local/share/fonts/JetBrainsMono"

    fc-cache -fv
    rm -f "/tmp/JetBrainsMono.zip"
fi

# set default shell to zsh and setup plugins
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    echo "Installing ohmyzsh plugins and changing default shell to Zsh..."
    rm -rf "$HOME/.oh-my-zsh"
    
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    sudo chsh -s /usr/bin/zsh $USER
fi

# setup Go env
mkdir -p "$HOME/go/bin"
mkdir -p "$HOME/go/pkg"
mkdir -p "$HOME/go/src"

# symlinks
ln -snf "$HOST_HOME/storage/code/repos" "$HOME/repos"

mkdir -p "$HOME/.config/Code/User"
ln -snf "$DOTFILES/vscode/settings.json" "$HOME/.config/Code/User/settings.json"

ln -snf "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
ln -snf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -snf "$DOTFILES/nvim" "$HOME/.config/nvim"

touch "$MARKER_FILE"
echo "$BOX_NAME initialization completed."
echo "restart container or run 'zsh' to start."
