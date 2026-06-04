#!/bin/bash

# Initialize ctf-box: per-user setup only.
# Image-level packages live in ctf-box.Containerfile.

set -ex

source "$(dirname "$0")/common.sh"
init_start "ctf-box"

# shell - oh-my-zsh ships in the image at /opt/ohmyzsh
setup_zsh_from_image

# per-user CLI without a clean system-install path
curl -fsSL https://claude.ai/install.sh | bash

setup_symlinks
init_end

echo ""
echo "NOTE: IDA Free must be installed manually."
echo "  1. Download from https://hex-rays.com/ida-free/"
echo "  2. Run: chmod +x idafree*.run && ./idafree*.run"
