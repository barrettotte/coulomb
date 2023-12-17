# zsh
export ZSH="$HOME/.oh-my-zsh"
export ZSH_THEME="fishy"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

# path
export PATH=$PATH:~/.local/bin

# go
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$(go env GOPATH)/bin

# rust
export RUST_BACKTRACE=full

# sdkman
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# conda (contents within this block are managed by 'conda init')
__conda_setup="$('/home/barrett/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/barrett/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/barrett/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/barrett/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# aliases
alias ll="ls -al"
