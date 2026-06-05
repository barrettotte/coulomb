FROM docker.io/library/archlinux:latest

# keyring + full sync
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Syu --noconfirm

# distrobox-init runtime deps
RUN pacman -S --noconfirm --needed \
        base-devel \
        sudo \
        shadow \
        inetutils \
        less \
        wget \
        curl \
        diffutils \
        findutils \
        gnupg \
        pinentry \
        xdg-utils \
        xorg-xauth \
        xorg-xkbcomp \
        ncurses

# shell / CLI
RUN pacman -S --noconfirm --needed \
        zsh \
        ripgrep \
        fd \
        jq \
        htop \
        tree \
        strace \
        wl-clipboard

# git
RUN pacman -S --noconfirm --needed \
        git \
        git-lfs \
        git-crypt \
        github-cli

# media
RUN pacman -S --noconfirm --needed \
        feh \
        ffmpeg \
        imagemagick

# build
RUN pacman -S --noconfirm --needed cmake

# languages / runtimes
RUN pacman -S --noconfirm --needed \
        python \
        python-pip \
        go \
        npm \
        lua \
        luajit \
        ruby \
        jdk-openjdk \
        dotnet-sdk \
        rustup \
        uv

# GUI deps
RUN pacman -S --noconfirm --needed qt6-base tk

# databases
RUN pacman -S --noconfirm --needed postgresql-libs sqlite

# web dev
RUN pacman -S --noconfirm --needed hugo

# infra / cloud
RUN pacman -S --noconfirm --needed \
        docker \
        docker-compose \
        ollama \
        aws-cli-v2 \
        kubectl \
        helm

# CUDA toolkit only - distrobox nvidia=true injects the driver at runtime
RUN pacman -Syu --noconfirm cuda --assume-installed opencl-nvidia

# rustup: shared toolchain in /opt/rustup. Arch's rustup package already installs
# proxy shims at /usr/bin/{cargo,rustc,...}; they resolve the toolchain via
# RUSTUP_HOME. CARGO_HOME stays at the per-user default so `cargo install` writes
# to ~/.cargo, not a root-owned shared dir.
ENV RUSTUP_HOME=/opt/rustup
RUN rustup default stable && \
    chmod -R a+rX /opt/rustup

# VS Code
RUN pacman -S --noconfirm --needed \
        gtk3 \
        libxss \
        alsa-lib \
        libnotify \
        libsecret \
        nss \
        libxkbfile && \
    curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" -o /tmp/vscode.tar.gz && \
    mkdir -p /opt/vscode && \
    tar -xzf /tmp/vscode.tar.gz -C /opt/vscode --strip-components=1 && \
    ln -sf /opt/vscode/bin/code /usr/bin/code && \
    rm -f /tmp/vscode.tar.gz

# VS Code .desktop entry
RUN cat > /usr/share/applications/code.desktop <<'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/bin/code --unity-launch %F
Icon=/opt/vscode/resources/app/resources/linux/code.png
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/bin/code --new-window %F
Icon=/opt/vscode/resources/app/resources/linux/code.png
EOF

# oh-my-zsh source - copied into $HOME on first login
RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh /opt/ohmyzsh && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
        /opt/ohmyzsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
        /opt/ohmyzsh/custom/plugins/zsh-syntax-highlighting

# pacman cache cleanup
RUN pacman -Scc --noconfirm

LABEL org.coulomb.box=dev-box
