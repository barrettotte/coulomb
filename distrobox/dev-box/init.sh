#!/bin/bash

set -ex

source "$(dirname "$0")/../common.sh"
init_start "dev-box"
setup_zsh_from_image

curl -fsSL https://claude.ai/install.sh | bash

# VS Code user config + extensions
mkdir -p "$HOME/.config/Code/User"
ln -snf "$DOTFILES/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
xargs -L 1 /usr/bin/code --install-extension < "$DOTFILES/vscode/extensions.txt"

# go workspace dirs
mkdir -p "$HOME/go/bin" "$HOME/go/pkg" "$HOME/go/src"

setup_symlinks

init_end
