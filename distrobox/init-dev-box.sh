#!/bin/bash

# Initialize dev-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "dev-box"

# initialize keyring
echo "Initializing Arch Keyring..."
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy --noconfirm archlinux-keyring

echo "Installing packages..."

# shell / CLI tools
sudo pacman -Syu --noconfirm --needed \
    zsh \
    ripgrep \
    fd \
    curl \
    wget \
    jq \
    htop \
    tree \
    strace \
    wl-clipboard

# git
sudo pacman -S --noconfirm --needed \
    git \
    git-lfs \
    git-crypt \
    github-cli

# media
sudo pacman -S --noconfirm --needed \
    feh \
    ffmpeg \
    imagemagick

# build
sudo pacman -S --noconfirm --needed \
    base-devel \
    cmake

# languages / runtimes
sudo pacman -S --noconfirm --needed \
    python \
    go \
    npm \
    lua \
    luajit \
    ruby \
    jdk-openjdk \
    dotnet-sdk

# GUI deps
sudo pacman -S --noconfirm --needed \
    qt6-base \
    tk

# databases
sudo pacman -S --noconfirm --needed \
    postgresql-libs \
    sqlite

# web dev
sudo pacman -S --noconfirm --needed \
    hugo

# infra / cloud
sudo pacman -S --noconfirm --needed \
    docker \
    docker-compose \
    ollama \
    terraform \
    aws-cli-v2 \
    kubectl \
    helm

# CUDA - use injected driver, but install toolkit
sudo pacman -Syu --noconfirm cuda --assume-installed opencl-nvidia

# rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# uv - python package manager
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# VS Code (AUR)
if ! pacman -Qi visual-studio-code-bin &>/dev/null; then
    echo "Installing VS Code from AUR..."
    git clone https://aur.archlinux.org/visual-studio-code-bin.git /tmp/vscode-aur
    (cd /tmp/vscode-aur && makepkg -si --noconfirm)
    rm -rf /tmp/vscode-aur
fi

# export VS Code to host
distrobox-export --app code
distrobox-export --bin /usr/bin/code --export-path "$HOST_HOME/.local/bin"

# VS Code settings symlink
mkdir -p "$HOME/.config/Code/User"
ln -snf "$DOTFILES/vscode/settings.json" "$HOME/.config/Code/User/settings.json"

# VS Code extensions
echo "Installing VS Code extensions..."
xargs -L 1 /usr/bin/code --install-extension < "$DOTFILES/vscode/extensions.txt"

setup_zsh

# setup Go env
mkdir -p "$HOME/go/bin"
mkdir -p "$HOME/go/pkg"
mkdir -p "$HOME/go/src"

setup_symlinks
init_end
