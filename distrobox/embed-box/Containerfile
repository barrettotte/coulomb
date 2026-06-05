FROM docker.io/library/ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

# pre-seed keyboard-configuration so xorg/locales installs don't block
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

# debug
RUN apt-get install -y gdb

# ARM cross toolchain
RUN apt-get install -y \
        gcc-arm-none-eabi \
        gdb-multiarch \
        binutils-arm-none-eabi \
        libnewlib-arm-none-eabi

# AVR cross toolchain
RUN apt-get install -y \
        gcc-avr \
        avr-libc \
        avrdude

# RISC-V cross toolchain
RUN apt-get install -y \
        gcc-riscv64-unknown-elf \
        binutils-riscv64-unknown-elf

# debug / flash / serial
RUN apt-get install -y \
        openocd \
        stlink-tools \
        dfu-util \
        flashrom \
        minicom \
        picocom

# USB / FTDI / bus
RUN apt-get install -y \
        libusb-1.0-0-dev \
        libftdi-dev \
        usbutils \
        i2c-tools

# logic analyzer
RUN apt-get install -y \
        sigrok-cli \
        pulseview

# simulation
RUN apt-get install -y \
        ngspice \
        gtkwave \
        iverilog \
        verilator \
        ghdl

# open-source FPGA toolchain (Lattice iCE40)
RUN apt-get install -y \
        yosys \
        nextpnr-ice40 \
        fpga-icestorm

# Vivado / Quartus deps
RUN apt-get install -y \
        libtinfo5 \
        libncurses5 \
        libncursesw5 \
        xorg \
        libx11-dev \
        libxext-dev \
        libxrender-dev \
        libxtst-dev \
        default-jre \
        libglib2.0-0

# arduino-cli
RUN curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
        | BINDIR=/usr/local/bin sh

# pip packages installed system-wide
RUN pip3 install --no-cache-dir \
        platformio \
        esptool

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

LABEL org.coulomb.box=embed-box
