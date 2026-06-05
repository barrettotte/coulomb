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
        zsh \
        pkg-config

# graphics / Vulkan
RUN apt-get install -y \
        vulkan-tools \
        libvulkan-dev \
        vulkan-validationlayers-dev \
        libgl1-mesa-dev \
        libglu1-mesa-dev \
        libegl1-mesa-dev

# windowing / input
RUN apt-get install -y \
        libx11-dev \
        libxrandr-dev \
        libxi-dev \
        libxinerama-dev \
        libxcursor-dev \
        libwayland-dev

# audio
RUN apt-get install -y \
        libasound2-dev \
        libpulse-dev

# Unreal Engine deps
RUN apt-get install -y \
        mono-complete \
        clang \
        lld \
        libsdl2-dev

# Godot deps (for source builds)
RUN apt-get install -y \
        scons \
        libfreetype-dev \
        libpng-dev \
        zlib1g-dev \
        libmbedtls-dev

# .NET + JDK
RUN apt-get install -y \
        dotnet-sdk-8.0 \
        default-jdk

# Godot binary, system-wide at /usr/local/bin/godot
RUN GODOT_VERSION=$(curl -s https://api.github.com/repos/godotengine/godot/releases/latest \
        | grep -oP '"tag_name":\s*"\K[^"]+' | sed 's/-stable//') && \
    curl -L "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -o /tmp/godot.zip && \
    unzip -o /tmp/godot.zip -d /tmp/godot && \
    install -m 755 /tmp/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot && \
    rm -rf /tmp/godot /tmp/godot.zip

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

LABEL org.coulomb.box=gamedev-box
