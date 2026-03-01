# zsh config
export ZSH="$HOME/.oh-my-zsh"

DISABLE_UNTRACKED_FILES_DIRTY="true"
ZSH_THEME="fishy"
# https://github.com/ohmyzsh/ohmyzsh/wiki/themes

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
source $ZSH/oh-my-zsh.sh

# Find brew-installed tools first
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Source system profile scripts (sets up flatpak, etc.)
emulate sh -c 'source /etc/profile'

# Go config
export GOPATH="$HOME/go"
if [ -d "$HOME/go/bin" ]; then
    export PATH="$PATH:$HOME/go/bin"
fi

# host-only config
if [ -z "$CONTAINER_ID" ]; then
    # nop
fi

if [[ "$CONTAINER_ID" == "dev-box" ]]; then
    export PATH=$PATH:/opt/cuda/bin
    export DOCKER_HOST=unix:///run/host/run/user/$(id -u)/podman/podman.sock

    # Suppress distrobox's prompt injection
    export PROMPT_COMMAND=""
    export DISTROBOX_ENTER_PROMPT_FIX=0

    PROMPT='📦%{$fg_bold[cyan]%}dev-box%{$reset_color%} %~ > '
fi

# aliases
alias clanker="claude"

# add distrobox exported bins
export PATH="$HOME/.local/bin:$PATH"
