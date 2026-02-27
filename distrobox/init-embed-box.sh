#!/bin/bash

# Initialize embed-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "embed-box"

# update and install packages
echo "Installing packages..."
sudo apt-get update

# general
sudo apt-get install -y \
    build-essential \
    cmake \
    gdb \
    git \
    curl \
    wget \
    unzip \
    python3 \
    python3-pip \
    python3-venv \
    zsh

# ARM cross toolchain
sudo apt-get install -y \
    gcc-arm-none-eabi \
    gdb-multiarch \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi

# AVR cross toolchain
sudo apt-get install -y \
    gcc-avr \
    avr-libc \
    avrdude

# RISC-V cross toolchain
sudo apt-get install -y \
    gcc-riscv64-unknown-elf \
    binutils-riscv64-unknown-elf

# debug / flash / serial
sudo apt-get install -y \
    openocd \
    stlink-tools \
    dfu-util \
    flashrom \
    minicom \
    picocom

# USB / FTDI / bus tools
sudo apt-get install -y \
    libusb-1.0-0-dev \
    libftdi-dev \
    usbutils \
    i2c-tools

# logic analyzer
sudo apt-get install -y \
    sigrok-cli \
    pulseview

# simulation
sudo apt-get install -y \
    ngspice \
    gtkwave \
    iverilog \
    verilator \
    ghdl

# open-source FPGA toolchain (Lattice iCE40)
sudo apt-get install -y \
    yosys \
    nextpnr-ice40 \
    fpga-icestorm

# Vivado / Quartus deps
sudo apt-get install -y \
    libtinfo5 \
    libncurses5 \
    libncursesw5 \
    locales \
    xorg \
    libx11-dev \
    libxext-dev \
    libxrender-dev \
    libxtst-dev \
    default-jre \
    libglib2.0-0

# logisim-evolution
echo "Installing Logisim Evolution..."
mkdir -p "$HOME/.local/bin"
LOGISIM_VERSION=$(curl -s https://api.github.com/repos/logisim-evolution/logisim-evolution/releases/latest | grep -oP '"tag_name":\s*"v?\K[^"]+')
curl -L "https://github.com/logisim-evolution/logisim-evolution/releases/download/v${LOGISIM_VERSION}/logisim-evolution-${LOGISIM_VERSION}-all.jar" -o "$HOME/.local/bin/logisim-evolution.jar"

# arduino-cli
echo "Installing arduino-cli..."
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | BINDIR="$HOME/.local/bin" sh

# pip installs
echo "Installing pip packages..."
pip3 install \
    platformio \
    esptool

setup_zsh
setup_symlinks
init_end

echo ""
echo "NOTE: Xilinx Vivado must be installed manually."
echo "  1. Download the installer from https://www.xilinx.com/support/download.html"
echo "  2. Run: chmod +x Xilinx_Unified_*_Lin64.bin && ./Xilinx_Unified_*_Lin64.bin"
echo "  3. All dependencies are already installed in this container."
