#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$HOME/.cache/ansible-bootstrap-venv"

ANSIBLE_EXTRA_VARS="target_user=$USER ansible_python_interpreter=$(which python3)"
ANSIBLE_BASE_CMD=(ansible-playbook -i "$SCRIPT_DIR/inventory.ini" -vv --extra-vars "$ANSIBLE_EXTRA_VARS" --ask-become-pass)

echo "Starting Bazzite setup..."

# =============================================================================
# Check Prerequisites
# =============================================================================

if ! command -v python3 &> /dev/null; then
    echo "ERROR: python3 not found."
    exit 1
fi

if ! command -v brew &> /dev/null; then
    echo "ERROR: Homebrew not found. Install it first - see bazzite.md"
    exit 1
fi

# =============================================================================
# Python venv + Ansible
# =============================================================================

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment for Ansible..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install ansible requests
else
    echo "Using existing Python virtual environment."
    source "$VENV_DIR/bin/activate"
fi

echo "Installing Ansible collections..."
ansible-galaxy collection install ansible.posix community.general

# =============================================================================
# Run playbooks
# =============================================================================

echo ""
echo "========================================"
echo "Running host-setup playbook..."
echo "========================================"
"${ANSIBLE_BASE_CMD[@]}" "$SCRIPT_DIR/playbooks/host-setup.yml"

echo ""
echo "========================================"
echo "Running flatpaks playbook..."
echo "========================================"
"${ANSIBLE_BASE_CMD[@]}" "$SCRIPT_DIR/playbooks/flatpaks.yml"

echo ""
echo "========================================"
echo "Running distrobox playbook..."
echo "========================================"
"${ANSIBLE_BASE_CMD[@]}" "$SCRIPT_DIR/playbooks/distrobox.yml"

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
echo "You may need to log out and back in for group changes to take effect."
echo "Run 'newgrp libvirt' to apply libvirt group in the current session."
