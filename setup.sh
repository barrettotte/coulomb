#!/bin/bash

# Setup my Ubuntu 22.04 dev box

set -e

SEPARATOR="\n$(printf '=%.0s' {1..64})"
COULOMB="$HOME/coding/repos/coulomb"
SECONDS=0

trap 'echo "Error occurred on line $LINENO. Last command: $BASH_COMMAND"; exit 1' ERR

# use apt-get install and echo name to console
# $1 package name
# $2 (optional) version command
echoed_apt_install() {
  if [ $# -eq 0 ]; then
    echo 'No arguments given echoed_apt_install' && exit 1
  fi
  sudo apt-get -y install $1 > /dev/null

  if [ -n "$2" ]; then
    local v=$(eval "$2")
    echo "$v"
  else
    echo "$1"
  fi
}

# install from snap and echo name to console
# $1 app name
# $2 (optional) extra install flags
echoed_snap_install() {
  if [ $# -eq 0 ]; then
    echo 'No arguments given for echoed_snap_install' && exit 2
  fi
  sudo snap install $1 $2 &> /dev/null
  echo "$1 $(snap info $1 | tail -n 1 | awk '{print $2}')"
}

# echo python package version
# $1 package name
py_pkg_version() {
  local v=$(pip show $1 2> /dev/null | grep 'Version')
  if [ -n "$v" ]; then
    echo "$1 $v"
  else
    echo "python package $1 not found or installed." && exit 3
  fi
}

###########################
#   Start                 #
###########################

echo 'Setting up Ubuntu 22.04 dev VM...'
echo 'This will take a while. Please stand by...'

echo "Updating dependencies..."
sudo apt-get update > /dev/null
sudo apt-get -y upgrade > /dev/null

###########################
#   General/Misc          #
###########################

printf "$SEPARATOR\nInstalling general/misc dependencies...\n\n"

sudo apt-get -y install unzip curl > /dev/null
sudo apt-get -y install ca-certificates software-properties-common lsb-release > /dev/null
sudo apt-get -y install libfuse2 libssl-dev libffi-dev > /dev/null

echoed_apt_install diffutils
echoed_apt_install nfs-common
echoed_apt_install smbclient
echoed_apt_install openvpn '(openvpn --version | head -n 1)'
echoed_apt_install ffmpeg 'ffmpeg -version | head -n 1'
echoed_apt_install imagemagick
echoed_apt_install neofetch 'neofetch --version'
echoed_apt_install wine-stable 'wine --version'

# user
echo "Configuring user $USER..."

# desktop env
echo "Configuring desktop environment (GNOME)..."

# disable idle screen off
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout '0'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.session idle-delay 0

# dark theme
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# show hidden files
gsettings set org.gtk.Settings.FileChooser show-hidden true

# favorite apps
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'firefox_firefox.desktop', 'code.desktop', 'intellij-idea-community_intellij-idea-community.desktop', 'org.kicad.kicad.desktop', 'spotify_spotify.desktop']"

###########################
#   Development           #
###########################

printf "$SEPARATOR\nInstalling development dependencies...\n\n"

echoed_apt_install git 'git --version'
echoed_apt_install git-lfs
echoed_apt_install vim
echoed_apt_install build-essential
echoed_apt_install tmux 'tmux -V'
echoed_apt_install jq 'jq --version'
echoed_apt_install cmake 'cmake --version | head -n 1'
echoed_apt_install qemu-system 'qemu-system-x86_64 --version | head -n 1'
echoed_apt_install gcc-aarch64-linux-gnu

# zsh
if ! [ -x "$(command -v zsh)" ]; then
  echo -n 'Installing zsh...'
  echoed_apt_install zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended > /dev/null

  # plugins
  git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" > /dev/null
  git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" > /dev/null
fi
zsh --version

# vscode
if ! [ -x "$(command -v code)" ]; then
  echo -n 'Installing vscode...'
  curl -s https://vscode.download.prss.microsoft.com/dbazure/download/stable/0ee08df0cf4527e40edc9aa28f4b5bd38bbff2b2/code_1.85.1-1702462158_amd64.deb -o /tmp/vscode.deb
  sudo apt-get -y install /tmp/vscode.deb > /dev/null
fi
echo "vscode $(code --version | head -n 1)"

# docker
if ! [ -x "$(command -v docker)" ]; then
  echo -n 'Installing docker...'

  sudo install -m 0755 -d /etc/apt/keyrings > /dev/null
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes > /dev/null
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update > /dev/null
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
fi
docker --version

# kubernetes
if ! [ -x "$(command -v minikube)" ]; then
  echo -n 'Installing minikube...'
  curl -sL https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /tmp/minikube
  sudo install /tmp/minikube /usr/local/bin/minikube
fi
minikube version | head -n 1

# node
if ! [ -x "$(command -v nvm)" ]; then
  echo -n 'Installing nvm...'
  curl -s https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh -o /tmp/nvm-install
  chmod +x /tmp/nvm-install && /tmp/nvm-install > /dev/null
  export NVM_DIR="$HOME/.nvm"
  source "$HOME/.nvm/nvm.sh" > /dev/null
fi

nvm install node > /dev/null
echo "nvm $(nvm --version)"
echo "node $(node --version)"
echo "npm $(npm --version)"

# global node packages
echo 'Installing global node packages...'
npm i -g @vscode/vsce --quiet > /dev/null
echo "@vscode/vsce $(vsce --version)"

# python and conda
sudo apt-get -y install python3 python2 python3-pip python3.11-venv > /dev/null

if ! [ -x "$(command -v conda)" ]; then
  echo -n 'Installing miniconda...'
  curl -s https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh
  chmod +x /tmp/miniconda.sh && /tmp/miniconda.sh -b -u > /dev/null
  source "$HOME/miniconda3/bin/activate" > /dev/null
  conda init bash > /dev/null
fi

conda --version
echo "pip $(pip3 --version | awk '{print $2}')"
python3 --version
python2 --version

# global python packages
echo 'Installing global python packages...'

# jupyter notebooks
if ! [ -x "$(command -v jupyter)" ]; then
  echo -n 'Installing jupyter...'
  conda install -c conda-forge jupyterlab -y > /dev/null
fi
py_pkg_version jupyterlab

# sdkman
if ! [ -x "$(command -v sdk)" ]; then
  echo -n 'Installing sdkman...'
  curl -s https://get.sdkman.io -o /tmp/sdkman
  chmod +x /tmp/sdkman && /tmp/sdkman > /dev/null
  source "$HOME/.sdkman/bin/sdkman-init.sh" > /dev/null
fi
echo "sdkman $(sdk version | sed -n 3p | awk '{print $2}')"

# JVM languages
sdk install java 11.0.21-ms > /dev/null && java --version | head -n 1
sdk install gradle > /dev/null && gradle --version > /dev/null && gradle --version | sed -n 3p
sdk install maven > /dev/null && mvn --version | head -n 1
sdk install groovy > /dev/null && groovy --version
sdk install kotlin > /dev/null && kotlin -version
sdk install scala > /dev/null && scala --version

# dotnet
if ! [ -x "$(command -v dotnet)" ]; then
  echo 'Installing dotnet...'

  declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
  curl -sL https://packages.microsoft.com/config/ubuntu/$repo_version/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb
  sudo dpkg -i /tmp/packages-microsoft-prod.deb > /dev/null
  sudo apt-get update > /dev/null

  echoed_apt_install dotnet-sdk-8.0
  echoed_apt_install aspnetcore-runtime-8.0
fi
echo 'dotnet SDKs'
dotnet --list-sdks

echo 'dotnet runtimes'
dotnet --list-runtimes

# go
if ! [ -x "$(command -v go)" ]; then
  echo -n 'Installing go...'
  curl -s -L https://go.dev/dl/go1.21.5.linux-amd64.tar.gz -o /tmp/go.tar.gz
  sudo tar -C /usr/local -xzvf /tmp/go.tar.gz > /dev/null
fi
/usr/local/go/bin/go version

# hugo
if ! [ -x "$(command -v hugo)" ]; then
  echo -n 'Installing hugo...'
  curl -sL https://github.com/gohugoio/hugo/releases/download/v0.121.1/hugo_extended_0.121.1_linux-amd64.deb -o /tmp/hugo.deb
  sudo dpkg -i /tmp/hugo.deb
fi
hugo version

# rust
if ! [ -x "$(command -v rustc)" ]; then
  echo -n 'Installing rust...'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y > /dev/null
  source "$HOME/.cargo/env" > /dev/null
  rustup toolchain install stable > /dev/null
fi
rustc -V

# github cli
if ! [ -x "$(command -v gh)" ]; then
  echo -n 'Installing github cli...'
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt-get update > /dev/null \
    && sudo apt-get install gh -y > /dev/null
fi
gh --version | head -n 1

# latex
if ! [ -x "$(command -v tex)" ]; then
  echo -n 'Installing latex...'
  sudo apt-get -y install texlive-latex-base > /dev/null
  sudo apt-get -y install texlive-fonts-recommended texlive-fonts-extra texlive-latex-extra > /dev/null
fi
tex -v | head -n 1

# pandoc
if ! [ -x "$(command -v pandoc)" ]; then
  echo -n 'Installing pandoc...'
  curl -sL https://github.com/jgm/pandoc/releases/download/3.1.11/pandoc-3.1.11-1-amd64.deb -o /tmp/pandoc.deb
  sudo dpkg -i /tmp/pandoc.deb > /dev/null
fi
pandoc -v | head -n 1

# misc languages
echoed_apt_install nasm 'nasm -v'
echoed_apt_install sqlite3 'echo "SQLite $(sqlite3 -version)"'
echoed_apt_install ruby-full 'ruby --version'
sudo apt-get -y install php8.1 --no-install-recommends > /dev/null && (php -v | head -n 1)
sudo apt-get -y install r-base r-base-dev > /dev/null && (R --version | head -n 1)

# snap apps
echoed_snap_install octave
echoed_snap_install intellij-idea-community --classic
echoed_snap_install android-studio --classic

###########################
#   CTF                   #
###########################

printf "$SEPARATOR\nInstalling CTF dependencies...\n\n"

sudo DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark > /dev/null && (wireshark -v | head -n 1)
echoed_apt_install ltrace
echoed_apt_install hexedit
echoed_apt_install hexyl
echoed_apt_install gobuster
echoed_apt_install john
echoed_apt_install nmap 'nmap --version | head -n 1'
echoed_apt_install hashcat
echoed_apt_install checksec
echoed_apt_install steghide
echoed_apt_install exiftool
echoed_apt_install pngcheck
echoed_apt_install pngtools
echoed_apt_install zbar-tools
echoed_apt_install z3
echoed_apt_install foremost
echoed_apt_install aircrack-ng
sudo gem install zsteg

# ctf python packages
echo 'Installing CTF python packages...'

if ! conda info --envs | grep -q ctf-base; then
  echo 'creating ctf-base conda env...'
  conda create --name ctf-base -y > /dev/null
fi

eval "$(conda shell.bash hook)"
conda activate ctf-base

conda install -c conda-forge pwntools -y > /dev/null && py_pkg_version pwntools
pip3 install angr > /dev/null && py_pkg_version angr
pip3 install uncompyle6 > /dev/null && py_pkg_version uncompyle6
pip3 install ROPgadget > /dev/null && py_pkg_version ROPgadget

conda activate base

# metasploit
if ! [ -x "$(command -v msfconsole)" ]; then
  echo -n 'Installing metasploit...'
  curl -sL https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb -o /tmp/msfinstall
  chmod 755 /tmp/msfinstall && /tmp/msfinstall > /dev/null
fi
echo 'metasploit'

# ngrok
if ! [ -x "$(command -v ngrok)" ]; then
  echo -n 'Installing ngrok...'
  curl -sL https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -o /tmp/ngrok.tgz
  sudo tar xvzf /tmp/ngrok.tgz -C /usr/local/bin > /dev/null
fi
ngrok -v

# seclists
SECLISTS=/usr/share/wordlists
SECLISTS_VERSION='2023.2'
if ! [ -d "$SECLISTS" ]; then
  echo -n "Adding seclists to $SECLISTS..."
  curl -sL "https://github.com/danielmiessler/SecLists/archive/refs/tags/$SECLISTS_VERSION.zip" -o /tmp/seclists.zip
  sudo mkdir -p "$SECLISTS" && sudo unzip -o /tmp/seclists.zip -d "$SECLISTS" > /dev/null
fi
echo "seclists $SECLISTS_VERSION"

# dirb wordlists
DIRB_WORDLISTS=/usr/share/wordlists/dirb
if ! [ -d "$DIRB_WORDLISTS" ]; then
  echo -n "Adding dirb wordlists to $DIRB_WORDLISTS..."
  git clone --quiet https://github.com/v0re/dirb.git /tmp/dirb > /dev/null
  sudo cp -rf /tmp/dirb/wordlists /usr/share/wordlists/dirb
fi
echo "dirb wordlists ($DIRB_WORDLISTS)"

# pycdc
if ! [ -x "$(command -v /opt/pycdc/pycdc)" ]; then
  echo -n 'Installing pycdc...'
  sudo git clone --quiet https://github.com/zrax/pycdc.git /opt/pycdc > /dev/null
  pushd ./ > /dev/null && cd /opt/pycdc
  sudo cmake . > /dev/null
  sudo make > /dev/null
  popd
fi
echo 'pycdc'

# pwndbg
PWNDBG_VERSION='2023.07.17'
if ! [ -x "$(command -v pwndbg)" ]; then
  echo -n 'Installing pwndbg...'
  curl -sL "https://github.com/pwndbg/pwndbg/releases/download/$PWNDBG_VERSION-pkgs/pwndbg_${PWNDBG_VERSION}_amd64.deb" -o /tmp/pwndbg.deb
  sudo dpkg -i /tmp/pwndbg.deb > /dev/null
fi
echo "pwndbg $PWNDBG_VERSION"

# stegseek
if ! [ -x "$(command -v stegseek)" ]; then
  echo -n 'Installing stegseek...'
  curl -sL https://github.com/RickdeJager/stegseek/releases/download/v0.6/stegseek_0.6-1.deb -o /tmp/stegseek.deb
  sudo apt-get -y install libjpeg62 > /dev/null
  sudo dpkg -i /tmp/stegseek.deb > /dev/null
fi
echo 'stegseek 0.6.1'

# hydra
HYDRA_VERSION='9.5'
if ! [ -x "$(command -v hydra)" ]; then
  echo -n 'Installing hydra...'
  curl -sL "https://github.com/vanhauser-thc/thc-hydra/archive/refs/tags/v$HYDRA_VERSION.zip" -o /tmp/hydra.zip
  unzip -o /tmp/hydra.zip -d /tmp > /dev/null
  pushd ./ > /dev/null && cd "/tmp/thc-hydra-$HYDRA_VERSION"
  sudo ./configure > /dev/null
  sudo make > /dev/null
  sudo make install > /dev/null
  popd
fi
echo -n 'hydra ' && hydra version | head -n 1 | awk '{print $2}'

# binwalk
BINWALK_VERSION='2.3.4'
if ! [ -x "$(command -v binwalk)" ]; then
  echo -n 'Installing binwalk...'
  curl -sL "https://github.com/ReFirmLabs/binwalk/archive/refs/tags/v$BINWALK_VERSION.zip" -o /tmp/binwalk.zip
  sudo unzip -o /tmp/binwalk.zip -d /opt > /dev/null
  pushd ./ > /dev/null && cd "/opt/binwalk-$BINWALK_VERSION"
  sudo python3 setup.py install > /dev/null
  popd
fi
binwalk -h | sed -n 2p

# sqlmap
if ! [ -x "$(command -v sqlmap)" ]; then
  echo -n 'Installing sqlmap...'
  sudo git clone --quiet --depth 1 https://github.com/sqlmapproject/sqlmap.git /opt/sqlmap > /dev/null
  sudo ln -sf /opt/sqlmap/sqlmap.py /usr/local/bin/sqlmap
fi
echo "sqlmap $(sqlmap --version)"

# burp suite
BURP_VERSION='2023.11.1.3'
if ! [ -e "/opt/burp/burp-$BURP_VERSION.jar" ]; then
  echo -n 'Installing burp suite...'
  sudo mkdir -p /opt/burp
  sudo curl -sL "https://portswigger-cdn.net/burp/releases/download?product=community&version=$BURP_VERSION&type=Jar" -o "/opt/burp/burp-$BURP_VERSION.jar"
fi
echo "burp suite $BURP_VERSION"

# ghidra
GHIDRA_VERSION='10.4'
if ! [ -x "$(command -v ghidra)" ]; then
  echo -n 'Installing ghidra...'
  curl -sL "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_20230928.zip" -o /tmp/ghidra.zip
  sudo unzip -o /tmp/ghidra.zip -d /opt > /dev/null
  sudo ln -sf "/opt/ghidra_${GHIDRA_VERSION}_PUBLIC/ghidraRun" /usr/local/bin/ghidra
fi
echo "ghidra $GHIDRA_VERSION"

# IDA
if ! [ -x "$(command -v ida64)" ]; then
  echo -n 'Installing IDA (free)...'
  curl -sL https://out7.hex-rays.com/files/idafree83_linux.run -o /tmp/ida.run
  chmod +x /tmp/ida.run
  sudo /tmp/ida.run --unattendedmodeui none --mode unattended --prefix /opt/ida
  sudo ln -sf /opt/ida/ida64 /usr/local/bin/ida64
fi
echo 'IDA (free) 8.3'

###########################
#   Hardware              #
###########################

printf "$SEPARATOR\nInstalling hardware dependencies...\n\n"

echoed_apt_install verilog 'iverilog -V | sed -n 1p'
echoed_apt_install ghdl 'ghdl --version | head -n 1'
echoed_apt_install openscad 'openscad --version'
echoed_snap_install logisim-evolution
echoed_snap_install freecad

# gtkwave
if ! [ -x "$(command -v gtkwave)" ]; then
  echo -n 'Installing gtkwave...'
  sudo apt-get -y install gtkwave > /dev/null
  sudo apt-get -y install libcanberra-gtk-module libcanberra-gtk3-module > /dev/null
fi
gtkwave --version | head -n 1

# kicad
if ! [ -x "$(command -v kicad-cli)" ]; then
  echo -n 'Installing kicad...'
  sudo add-apt-repository --yes ppa:kicad/kicad-7.0-releases > /dev/null
  sudo apt-get update > /dev/null
  sudo apt-get -y install --install-recommends kicad > /dev/null
fi
echo "kicad $(kicad-cli version)"

# arduino
if ! [ -x "$(command -v arduino)" ]; then
  echo -n 'Installing arduino...'
  sudo mkdir -p /opt/arduino
  sudo curl -sL https://downloads.arduino.cc/arduino-ide/nightly/arduino-ide_nightly-20231217_Linux_64bit.AppImage -o /opt/arduino/arduino.AppImage
  sudo chmod +x /opt/arduino/arduino.AppImage
  sudo ln -sf /opt/arduino/arduino.AppImage /usr/local/bin/arduino
fi
echo 'arduino'

# platformio
if ! [ -d "$HOME/.platformio/penv/bin" ]; then
  echo -n 'Installing platformio...'
  curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py -o /tmp/get-platformio.py
  python3 /tmp/get-platformio.py > /dev/null
fi
$HOME/.platformio/penv/bin/pio --version

###########################
#   Misc Applications     #
###########################

printf "$SEPARATOR\nInstalling misc applications...\n\n"

echoed_snap_install drawio
echoed_snap_install gimp
echoed_snap_install audacity
echoed_snap_install libreoffice
echoed_snap_install vlc
echoed_snap_install spotify
echoed_snap_install blender --classic

###########################
#   Finish                #
###########################

printf "$SEPARATOR\nFinishing up...\n\n"

# general cleanup
echo 'Cleaning...'
sudo apt-get autoremove -y > /dev/null
sudo apt-get autoclean > /dev/null

# clone coulomb repo for additional setup files
if ! [ -d "$COULOMB" ]; then
  echo "Cloning coulomb repo to $COULOMB..."
  mkdir -p "$HOME/coding/repos"
  git clone --quiet --depth 1 https://github.com/barrettotte/coulomb.git "$COULOMB" > /dev/null
fi

# set git config
git config --global user.name "Barrett Otte"
git config --global user.email "barrettotte@gmail.com"
git config --global pull.rebase false
gh config set git_protocol ssh -h github.com

# set dotfiles
echo 'Setting dotfiles...'
DOTFILES="$COULOMB/dotfiles/"
ln -sf "$DOTFILES/.zshrc" "$HOME/.zshrc"
ln -sf "$DOTFILES/.tmux.conf" "$HOME/.tmux.conf"
ln -sf "$DOTFILES/.config/gtk-3.0/bookmarks" "$HOME/.config/gtk-3.0/bookmarks"

# set shell
if [ "$SHELL" != "/usr/bin/zsh" ]; then
  echo "Changing default shell to zsh for user $USER..."
  sudo chsh -s $(which zsh) $USER
  echo 'Logout and login to finish setting shell.'
fi

# general system info
echo '' && neofetch
df -h

END_SECS=$SECONDS
printf '\nScript executed in: %d minute(s)\n' "$((END_SECS/60 - 1440  * (END_SECS/86400)))"
printf 'Setup completed. It is highly recommended to reboot now!\n'
