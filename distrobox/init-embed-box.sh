#!/bin/bash

# Initialize embed-box: per-user setup only.
# Image-level packages live in embed-box.Containerfile.

set -ex

source "$(dirname "$0")/common.sh"
init_start "embed-box"

# shell - oh-my-zsh ships in the image at /opt/ohmyzsh
setup_zsh_from_image

setup_symlinks
init_end

echo ""
echo "NOTE: Xilinx Vivado must be installed manually."
echo "  1. Download the installer from https://www.xilinx.com/support/download.html"
echo "  2. Run: chmod +x Xilinx_Unified_*_Lin64.bin && ./Xilinx_Unified_*_Lin64.bin"
echo "  3. All dependencies are already installed in this container."
