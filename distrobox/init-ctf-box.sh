#!/bin/bash

# Initialize ctf-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "ctf-box"

echo "Installing packages..."
install_apt_base

# recon / scanning
sudo apt-get install -y \
    nmap \
    nikto \
    gobuster \
    dirb \
    enum4linux

# exploitation
sudo apt-get install -y \
    metasploit-framework \
    sqlmap \
    hydra \
    burpsuite

# reverse engineering / binary analysis
sudo apt-get install -y \
    ghidra \
    radare2 \
    gdb \
    binwalk \
    ltrace \
    strace \
    hexyl \
    checksec \
    nasm

# password cracking
sudo apt-get install -y \
    john \
    hashcat \
    hashid

# networking
sudo apt-get install -y \
    wireshark \
    tcpdump \
    netcat-traditional \
    socat \
    openvpn \
    tshark \
    whois

# forensics / steganography
sudo apt-get install -y \
    foremost \
    exiftool \
    steghide \
    imagemagick \
    ffmpeg \
    pngcheck \
    pngtools

# languages (base packages cover python3/build-essential)
sudo apt-get install -y \
    golang \
    php \
    nodejs \
    ruby

# wordlists
sudo apt-get install -y \
    seclists

# crypto
sudo apt-get install -y \
    python3-sympy

# hardware
sudo apt-get install -y \
    sigrok-cli \
    pulseview

# ctf extras
sudo apt-get install -y \
    jq \
    sqlite3 \
    tmux

# rust
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# uv - python package manager
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
export PATH="$HOME/.local/bin:$PATH"

# Claude Code
curl -fsSL https://claude.ai/install.sh | bash

# miniconda
echo "Installing Miniconda..."
mkdir -p "$HOME/.miniconda3"
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -u -p "$HOME/.miniconda3"
rm -f /tmp/miniconda.sh
"$HOME/.miniconda3/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
"$HOME/.miniconda3/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
"$HOME/.miniconda3/bin/conda" create -y -n sage -c conda-forge sage python=3.12

# pip installs
echo "Installing pip packages..."
pip3 install --break-system-packages \
    pwntools \
    angr \
    uncompyle6 \
    ROPgadget \
    ropper \
    pycryptodome \
    sherlock-project \
    volatility3

# ruby gems
echo "Installing ruby gems..."
gem install zsteg

# pwndbg (GDB plugin for binary exploitation)
echo "Installing pwndbg..."
git clone https://github.com/pwndbg/pwndbg.git "$HOME/.pwndbg"
pushd "$HOME/.pwndbg"
./setup.sh
popd

setup_zsh
setup_symlinks
init_end

echo ""
echo "NOTE: IDA Free must be installed manually."
echo "  1. Download from https://hex-rays.com/ida-free/"
echo "  2. Run: chmod +x idafree*.run && ./idafree*.run"
