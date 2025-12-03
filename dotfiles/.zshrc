# zsh config
export ZSH="$HOME/.oh-my-zsh"

DISABLE_UNTRACKED_FILES_DIRTY="true"
ZSH_THEME="fishy"
# https://github.com/ohmyzsh/ohmyzsh/wiki/themes

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# Go config
export GOPATH="$HOME/go"
if [ -d "$HOME/go/bin" ]; then
    export PATH="$PATH:$HOME/go/bin"
fi

# host-only config
if [ -z "$CONTAINER_ID" ]; then
    # nop
fi

# prefix for distrobox container prompt
function distrobox_prompt() {
    if [[ -n "$CONTAINER_ID" ]]; then
        echo "%{$fg_bold[cyan]%]%}[$CONTAINER_ID]%{$reset_color%} "
    fi
}

# override prompt when in distrobox
setopt PROMPT_SUBST
if [[ "$PROMPT" != *'$(distrobox_prompt)'* ]]; then
    PROMPT='$(distrobox_prompt)'"$PROMPT"
fi

# add distrobox exported bins
export PATH="$HOME/.local/bin:$PATH"
