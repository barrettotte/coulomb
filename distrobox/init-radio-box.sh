#!/bin/bash

# Initialize radio-box distrobox

set -ex

source "$(dirname "$0")/common.sh"
init_start "radio-box"

echo "Installing packages..."
install_apt_base

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

# SDR++ (build from source)
echo "Installing SDR++..."
sudo apt-get install -y \
    libfftw3-dev \
    libglfw3-dev \
    libvolk2-dev \
    libzstd-dev \
    libairspy-dev \
    libairspyhf-dev \
    libhackrf-dev \
    librtaudio-dev \
    libsoapysdr-dev
rm -rf /tmp/sdrplusplus
git clone https://github.com/AlexandreRouma/SDRPlusPlus.git /tmp/sdrplusplus
mkdir -p /tmp/sdrplusplus/build
(cd /tmp/sdrplusplus/build && cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr \
    -DOPT_BUILD_RTL_SDR_SOURCE=ON \
    -DOPT_BUILD_SOAPY_SOURCE=ON \
    -DOPT_BUILD_AIRSPY_SOURCE=ON \
    -DOPT_BUILD_AIRSPYHF_SOURCE=ON \
    -DOPT_BUILD_HACKRF_SOURCE=ON \
    -DOPT_BUILD_AUDIO_SINK=ON \
    -DOPT_BUILD_NETWORK_SINK=ON \
    -DOPT_BUILD_AUDIO_SOURCE=OFF \
    -DOPT_BUILD_PLUTOSDR_SOURCE=OFF \
    -DOPT_BUILD_FOBOSSDR_SOURCE=OFF \
    -DOPT_BUILD_HERMES_SOURCE=OFF \
    -DOPT_BUILD_M17_DECODER=OFF \
    && make -j"$(nproc)" \
    && sudo make install)
rm -rf /tmp/sdrplusplus

# pip installs
echo "Installing pip packages..."
pip3 install \
    PyBOMBS

# SDR++ config
mkdir -p "$HOST_HOME/storage/misc/radio/recordings"
mkdir -p "$HOME/.config/sdrpp"
cat > "$HOME/.config/sdrpp/recorder_config.json" <<EOF
{
    "Recorder": {
        "ignoreSilence": false,
        "mode": 1,
        "recPath": "$HOST_HOME/storage/misc/radio/recordings"
    }
}
EOF

# fix SDR++ categories (HamRadio alone goes to lost+found in KDE)
sudo sed -i 's/Categories=HamRadio/Categories=Network;HamRadio;/' /usr/share/applications/sdrpp.desktop

setup_zsh
setup_symlinks
init_end
