#!/bin/bash

# Initialize gamedev-box: per-user setup only.
# Image-level packages live in gamedev-box.Containerfile.

set -ex

source "$(dirname "$0")/common.sh"
init_start "gamedev-box"

# shell - oh-my-zsh ships in the image at /opt/ohmyzsh
setup_zsh_from_image

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
