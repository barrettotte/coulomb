#!/bin/bash

# Initialize gamedev-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "gamedev-box"

echo "Installing packages..."
install_apt_base

sudo apt-get install -y pkg-config

# graphics / Vulkan
sudo apt-get install -y \
    vulkan-tools \
    libvulkan-dev \
    vulkan-validationlayers-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libegl1-mesa-dev

# windowing / input
sudo apt-get install -y \
    libx11-dev \
    libxrandr-dev \
    libxi-dev \
    libxinerama-dev \
    libxcursor-dev \
    libwayland-dev

# audio
sudo apt-get install -y \
    libasound2-dev \
    libpulse-dev

# Unreal Engine deps
sudo apt-get install -y \
    mono-complete \
    clang \
    lld \
    libsdl2-dev

# Godot deps
sudo apt-get install -y \
    scons \
    libfreetype-dev \
    libpng-dev \
    zlib1g-dev \
    libmbedtls-dev

# languages
sudo apt-get install -y \
    dotnet-sdk-8.0 \
    default-jdk

# Godot
echo "Installing Godot..."
mkdir -p "$HOME/.local/bin"
GODOT_VERSION=$(curl -s https://api.github.com/repos/godotengine/godot/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/-stable//')
curl -L "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip
unzip -o /tmp/godot.zip -d /tmp/godot
mv /tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64 "$HOME/.local/bin/godot"
chmod +x "$HOME/.local/bin/godot"
rm -rf /tmp/godot /tmp/godot.zip

pin_nvidia_gpu

setup_zsh
setup_symlinks
init_end

echo ""
echo "NOTE: Unreal Engine must be built from source on Linux."
echo "  1. Link your GitHub account at https://www.unrealengine.com/en-US/ue-on-github"
echo "  2. Clone: git clone https://github.com/EpicGames/UnrealEngine.git"
echo "  3. Run: ./Setup.sh && ./GenerateProjectFiles.sh && make"
echo ""
echo "NOTE: Unity Hub must be installed manually."
echo "  1. Download from https://unity.com/download"
echo "  2. chmod +x UnityHub.AppImage && ./UnityHub.AppImage"
