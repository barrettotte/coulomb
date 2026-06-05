#!/bin/bash

set -ex

source "$(dirname "$0")/../common.sh"
init_start "embed-box"
setup_zsh_from_image
setup_symlinks
init_end

echo ""
echo "NOTE: Xilinx Vivado must be installed manually."
echo "  1. Download the installer from https://www.xilinx.com/support/download.html"
echo "  2. Run: chmod +x Xilinx_Unified_*_Lin64.bin && ./Xilinx_Unified_*_Lin64.bin"
echo "  3. All dependencies are already installed in this container."
