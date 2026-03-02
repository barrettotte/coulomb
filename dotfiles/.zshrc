# zsh config
export ZSH="$HOME/.oh-my-zsh"

DISABLE_UNTRACKED_FILES_DIRTY="true"
ZSH_THEME="fishy"
# https://github.com/ohmyzsh/ohmyzsh/wiki/themes

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
export ZSH_COMPDUMP=$ZSH/cache/.zcompdump-$HOST
source $ZSH/oh-my-zsh.sh

# Find brew-installed tools first (host only)
if [ -z "$CONTAINER_ID" ] && [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Source system profile scripts (sets up flatpak, etc.)
emulate sh -c 'source /etc/profile' 2>/dev/null

# Go config
export GOPATH="$HOME/go"
if [ -d "$HOME/go/bin" ]; then
    export PATH="$PATH:$HOME/go/bin"
fi

if [ -n "$CONTAINER_ID" ]; then
    export DOCKER_HOST=unix:///run/host/run/user/$(id -u)/podman/podman.sock
    export SSH_AUTH_SOCK=/run/host/run/user/$(id -u)/ssh-agent.socket

    # Suppress distrobox's prompt injection
    export PROMPT_COMMAND=""
    export DISTROBOX_ENTER_PROMPT_FIX=0

    PROMPT='📦%{$fg_bold[cyan]%}'"$CONTAINER_ID"'%{$reset_color%} %~ > '
fi

if [[ "$CONTAINER_ID" == "ctf-box" ]]; then
    export PATH="$PATH:$HOME/.local/share/gem/ruby/3.3.0/bin"
fi

if [[ "$CONTAINER_ID" == "dev-box" ]]; then
    export PATH=$PATH:/opt/cuda/bin
fi

# aliases
alias clanker="claude"

# add distrobox exported bins
export PATH="$HOME/.local/bin:$PATH"
