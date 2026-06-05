FROM docker.io/library/ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# pre-seed keyboard-configuration
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl gnupg debconf-utils && \
    echo "keyboard-configuration keyboard-configuration/layoutcode string us" | debconf-set-selections && \
    echo "keyboard-configuration keyboard-configuration/xkb-keymap select us" | debconf-set-selections

# distrobox-init runtime deps
RUN apt-get install -y \
        sudo \
        passwd \
        hostname \
        less \
        wget \
        gnupg \
        pinentry-curses \
        xdg-utils \
        xauth \
        x11-utils \
        ncurses-base \
        procps \
        locales

# base build / CLI
RUN apt-get install -y \
        build-essential \
        cmake \
        git \
        unzip \
        python3 \
        python3-pip \
        python3-venv \
        zsh

# SDR frameworks
RUN apt-get install -y \
        gnuradio \
        gr-osmosdr \
        gqrx-sdr

# RTL-SDR driver / tools
RUN apt-get install -y \
        rtl-sdr \
        librtlsdr-dev

# SoapySDR abstraction
RUN apt-get install -y \
        soapysdr-tools \
        soapysdr-module-rtlsdr

# decoders
RUN apt-get install -y \
        multimon-ng \
        rtl-433 \
        direwolf \
        fldigi \
        wsjtx

# signal analysis
RUN apt-get install -y \
        inspectrum \
        tshark

# satellite tracking
RUN apt-get install -y gpredict

# audio processing / routing
RUN apt-get install -y \
        sox \
        pulseaudio \
        pavucontrol

# SDR++ build deps
RUN apt-get install -y \
        libfftw3-dev \
        libglfw3-dev \
        libvolk2-dev \
        libzstd-dev \
        libairspy-dev \
        libairspyhf-dev \
        libhackrf-dev \
        librtaudio-dev \
        libsoapysdr-dev

# SDR++ build from source, installed system-wide to /usr
RUN git clone --depth=1 https://github.com/AlexandreRouma/SDRPlusPlus.git /tmp/sdrpp && \
    mkdir -p /tmp/sdrpp/build && \
    cd /tmp/sdrpp/build && \
    cmake .. \
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
        -DOPT_BUILD_M17_DECODER=OFF && \
    make -j"$(nproc)" && \
    make install && \
    cd / && \
    rm -rf /tmp/sdrpp

# SDR++ .desktop category fix (HamRadio alone goes to lost+found in KDE)
RUN sed -i 's/Categories=HamRadio/Categories=Network;HamRadio;/' /usr/share/applications/sdrpp.desktop

# PyBOMBS - GNU Radio out-of-tree module manager (deprecated upstream but kept for parity)
RUN pip3 install --no-cache-dir PyBOMBS

# sudoers tweak: lets the user opt in to non-interactive apt by exporting
# DEBIAN_FRONTEND=noninteractive in their shell before `sudo apt-get install ...`
RUN echo 'Defaults env_keep += "DEBIAN_FRONTEND"' > /etc/sudoers.d/keep-debian-frontend && \
    chmod 0440 /etc/sudoers.d/keep-debian-frontend

# oh-my-zsh source - copied into $HOME on first login
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh /opt/ohmyzsh && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        /opt/ohmyzsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        /opt/ohmyzsh/custom/plugins/zsh-syntax-highlighting

# apt cache cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

LABEL org.coulomb.box=radio-box
