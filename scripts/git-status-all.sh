#!/bin/bash

# Checks git status of all repos in a directory (default: current directory)
# Usage: ./git-status-all.sh [target_directory]

dir="${1:-.}"

for repo in "$dir"/*/; do
    [ -d "$repo/.git" ] || continue

    status=$(git -C "$repo" status --porcelain)
    if [ -n "$status" ]; then
        echo -e "\033[1;33m$(basename "$repo")\033[0m"
        git -C "$repo" status --short
        echo
    fi
done
