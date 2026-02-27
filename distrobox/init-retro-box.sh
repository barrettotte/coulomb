#!/bin/bash

# Initialize retro-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "retro-box"

echo "Installing packages..."
install_apt_base

# multi-system emulators
sudo apt-get install -y \
    mame \
    dosbox

# home computer emulators
sudo apt-get install -y \
    vice \
    stella

# cross assemblers / compilers
sudo apt-get install -y \
    cc65 \
    nasm

# z88dk (Z80 cross compiler)
echo "Installing z88dk..."
sudo apt-get install -y \
    pkg-config \
    libxml2-dev \
    libgmp-dev \
    libboost-all-dev \
    texinfo \
    ragel \
    re2c \
    dos2unix
rm -rf /tmp/z88dk
git clone --recursive https://github.com/z88dk/z88dk.git /tmp/z88dk
pushd /tmp/z88dk
chmod 777 build.sh
./build.sh -i "$HOME/.local/z88dk"
popd
rm -rf /tmp/z88dk

setup_zsh
setup_symlinks
init_end

echo ""
echo "NOTE: z88dk installed to ~/.local/z88dk"
echo "  Add to PATH: export PATH=\$HOME/.local/z88dk/bin:\$PATH"
echo "  Set env: export ZCCCFG=\$HOME/.local/z88dk/lib/config"
