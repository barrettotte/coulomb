#!/bin/bash

# Update host packages (brew, flatpaks) and all distroboxes.
# Usage: bash update.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ANSIBLE_DIR="$REPO_DIR/ansible"
VENV_DIR="$HOME/.cache/ansible-bootstrap-venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "ERROR: Ansible venv not found. Run init.sh first."
    exit 1
fi

source "$VENV_DIR/bin/activate"

ANSIBLE_EXTRA_VARS="target_user=$USER ansible_python_interpreter=$(which python3)"

echo "Starting system update..."
ansible-playbook \
    -i "$ANSIBLE_DIR/inventory.ini" \
    -vv \
    --extra-vars "$ANSIBLE_EXTRA_VARS" \
    --ask-become-pass \
    "$ANSIBLE_DIR/playbooks/update.yml"

echo ""
echo "Update complete!"
