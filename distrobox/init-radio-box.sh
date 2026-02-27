#!/bin/bash

# Initialize radio-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "radio-box"

# update and install packages
echo "Installing packages..."
sudo apt-get update

# general
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    zsh

# SDR frameworks
sudo apt-get install -y \
    gnuradio \
    gr-osmosdr \
    gqrx-sdr

# RTL-SDR driver / tools
sudo apt-get install -y \
    rtl-sdr \
    librtlsdr-dev

# SoapySDR abstraction layer
sudo apt-get install -y \
    soapysdr-tools \
    soapysdr-module-rtlsdr

# decoders
sudo apt-get install -y \
    multimon-ng \
    rtl-433 \
    direwolf \
    fldigi \
    wsjtx

# signal analysis
sudo apt-get install -y \
    inspectrum \
    tshark

# satellite tracking
sudo apt-get install -y \
    gpredict

# audio processing / routing
sudo apt-get install -y \
    sox \
    pulseaudio \
    pavucontrol

# pip installs
echo "Installing pip packages..."
pip3 install \
    PyBOMBS

setup_zsh
setup_symlinks
init_end
