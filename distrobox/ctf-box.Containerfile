FROM docker.io/kalilinux/kali-rolling:latest

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

# kali-menu: provides .desktop files used by distrobox-export
RUN apt-get install -y kali-menu

# recon / scanning
RUN apt-get install -y \
        nmap \
        nikto \
        gobuster \
        dirb \
        enum4linux

# exploitation
RUN apt-get install -y \
        metasploit-framework \
        sqlmap \
        hydra \
        burpsuite

# reverse engineering / binary analysis
RUN apt-get install -y \
        ghidra \
        radare2 \
        gdb \
        binwalk \
        ltrace \
        strace \
        checksec \
        nasm

# password cracking
RUN apt-get install -y \
        john \
        hashcat \
        hashid

# networking
RUN apt-get install -y \
        wireshark \
        tcpdump \
        netcat-traditional \
        socat \
        openvpn \
        tshark \
        whois

# forensics / steganography
RUN apt-get install -y \
        foremost \
        exiftool \
        steghide \
        imagemagick \
        ffmpeg \
        pngcheck \
        pngtools

# languages (base layer already has python3 + build-essential)
RUN apt-get install -y \
        golang \
        php \
        nodejs \
        ruby

# wordlists
RUN apt-get install -y seclists

# crypto
RUN apt-get install -y python3-sympy

# hardware
RUN apt-get install -y \
        sigrok-cli \
        pulseview

# ctf extras
RUN apt-get install -y \
        jq \
        sqlite3 \
        tmux

# Ghidra: force X11 backend (Wayland blank-UI workaround) + KDE category fixes
RUN sed -i 's|^Exec=ghidra|Exec=env GDK_BACKEND=x11 _JAVA_AWT_WM_NONREPARENTING=1 ghidra|' /usr/share/applications/kali-ghidra.desktop && \
    sed -i 's/^Categories=.*/Categories=Development;Debugger;/' /usr/share/applications/kali-ghidra.desktop && \
    sed -i 's/^Categories=.*/Categories=Development;Network;Security;/' /usr/share/applications/kali-burpsuite.desktop && \
    sed -i 's/^Categories=.*/Categories=Network;Monitor;/' /usr/share/applications/org.wireshark.Wireshark.desktop && \
    sed -i 's|^Exec=.*|Exec=wireshark %f|' /usr/share/applications/org.wireshark.Wireshark.desktop

# rustup: shared toolchain in /opt/rustup. CARGO_HOME stays at per-user default (~/.cargo)
# at runtime so `cargo install` writes to the user's home. Symlink shims to /usr/local/bin
# so `cargo`/`rustc`/etc. resolve without PATH changes.
ENV RUSTUP_HOME=/opt/rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        CARGO_HOME=/opt/cargo sh -s -- -y --default-toolchain stable --no-modify-path && \
    chmod -R a+rX /opt/rustup /opt/cargo && \
    for t in cargo cargo-clippy cargo-fmt cargo-miri clippy-driver rust-analyzer rust-gdb rust-gdbgui rust-lldb rustc rustdoc rustfmt rustup; do \
        [ -e "/opt/cargo/bin/$t" ] && ln -sf "/opt/cargo/bin/$t" "/usr/local/bin/$t" ; \
    done

# uv: python package manager (official tarball, system-wide at /usr/local/bin)
RUN curl -L https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-unknown-linux-gnu.tar.gz -o /tmp/uv.tar.gz && \
    tar -xzf /tmp/uv.tar.gz -C /tmp && \
    install -m 755 /tmp/uv-x86_64-unknown-linux-gnu/uv  /usr/local/bin/uv && \
    install -m 755 /tmp/uv-x86_64-unknown-linux-gnu/uvx /usr/local/bin/uvx && \
    rm -rf /tmp/uv.tar.gz /tmp/uv-x86_64-unknown-linux-gnu

# miniconda + sage env at /opt/miniconda3, read-only after install.
# To customize the env, clone it per-user: `conda create -n sage-mine --clone sage`.
RUN curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/miniconda3 && \
    rm -f /tmp/miniconda.sh && \
    /opt/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    /opt/miniconda3/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    /opt/miniconda3/bin/conda create -y -n sage -c conda-forge sage python=3.12 && \
    /opt/miniconda3/bin/conda clean -afy && \
    chmod -R a+rX /opt/miniconda3

# Make conda available in login shells without setting PATH everywhere
RUN printf '%s\n' \
    '# coulomb: source miniconda for interactive shells' \
    'if [ -f /opt/miniconda3/etc/profile.d/conda.sh ]; then' \
    '    . /opt/miniconda3/etc/profile.d/conda.sh' \
    'fi' \
    > /etc/profile.d/coulomb-miniconda.sh

# CTF Python tooling - system-wide (Kali enforces PEP 668).
RUN pip3 install --break-system-packages --ignore-installed --no-cache-dir \
        pwntools \
        angr \
        uncompyle6 \
        ROPgadget \
        ropper \
        pycryptodome \
        sherlock-project \
        volatility3

# ruby gems system-wide
RUN gem install zsteg

# pwndbg: install to /opt, wire it into the system-wide gdbinit so it loads
# for any user without per-user .gdbinit edits.
RUN git clone --depth=1 https://github.com/pwndbg/pwndbg.git /opt/pwndbg && \
    cd /opt/pwndbg && \
    ./setup.sh && \
    mkdir -p /etc/gdb && \
    echo 'source /opt/pwndbg/gdbinit.py' > /etc/gdb/gdbinit

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

LABEL org.coulomb.box=ctf-box
