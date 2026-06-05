#!/bin/bash

set -ex

source "$(dirname "$0")/../common.sh"
init_start "ctf-box"
setup_zsh_from_image

curl -fsSL https://claude.ai/install.sh | bash

setup_symlinks
init_end

echo ""
echo "NOTE: IDA Free must be installed manually."
echo "  1. Download from https://hex-rays.com/ida-free/"
echo "  2. Run: chmod +x idafree*.run && ./idafree*.run"
