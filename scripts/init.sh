#!/bin/bash

# Bazzite system setup. Runs Ansible playbooks for host config and Flatpaks, then creates and initializes distroboxes.
# Usage: bash init.sh [--fresh] [--help]

set -e

usage() {
    echo "Usage: bash init.sh [--fresh] [--help]"
    echo "  --fresh  Destroy all existing distroboxes before recreating them"
    echo "  --help   Show this help message"
    exit 0
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ANSIBLE_DIR="$REPO_DIR/ansible"
VENV_DIR="$HOME/.cache/ansible-bootstrap-venv"

FRESH=false
for arg in "$@"; do
    case "$arg" in
        --fresh) FRESH=true ;;
        --help|-h) usage ;;
    esac
done

ANSIBLE_EXTRA_VARS="target_user=$USER ansible_python_interpreter=$(which python3)"
ANSIBLE_BASE_CMD=(ansible-playbook -i "$ANSIBLE_DIR/inventory.ini" -vv --extra-vars "$ANSIBLE_EXTRA_VARS" --ask-become-pass)

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
"${ANSIBLE_BASE_CMD[@]}" "$ANSIBLE_DIR/playbooks/host-setup.yml"

echo ""
echo "========================================"
echo "Running flatpaks playbook..."
echo "========================================"
"${ANSIBLE_BASE_CMD[@]}" "$ANSIBLE_DIR/playbooks/flatpaks.yml"

# =============================================================================
# Distrobox setup
# =============================================================================

DISTROBOX_INI="$REPO_DIR/distrobox/distrobox.ini"
BOX_NAMES=$(grep '^\[' "$DISTROBOX_INI" | tr -d '[]')

if [ "$FRESH" = true ]; then
    echo ""
    echo "========================================"
    echo "Wiping out existing distroboxes..."
    echo "========================================"
    "${ANSIBLE_BASE_CMD[@]}" "$ANSIBLE_DIR/playbooks/distrobox-nuke.yml"
fi

echo ""
echo "========================================"
echo "Setting up distroboxes..."
echo "========================================"

FAILED_BOXES=()

for box in $BOX_NAMES; do
    echo "Creating $box..."
    tmp_ini="/tmp/distrobox-${box}.ini"
    awk "/^\[${box}\]/{found=1} found && /^\[/ && !/^\[${box}\]/{exit} found" "$DISTROBOX_INI" > "$tmp_ini"
    distrobox assemble create --file "$tmp_ini"
    rm -f "$tmp_ini"

    echo "Initializing $box... (watch logs: podman logs -f $box)"
    distrobox enter "$box" -- true

    # verify the container is actually running
    if distrobox enter "$box" -- echo "ok" &>/dev/null; then
        echo "$box initialized successfully."
    else
        echo "ERROR: $box failed to initialize. Removing container."
        distrobox rm -f "$box" 2>/dev/null || true
        FAILED_BOXES+=("$box")
    fi
done

# =============================================================================
# Summary
# =============================================================================

echo ""
echo "========================================"
echo "Setup complete!"
echo "========================================"
echo ""
if [ ${#FAILED_BOXES[@]} -gt 0 ]; then
    echo "WARNING: The following distroboxes failed to initialize and were removed:"
    for box in "${FAILED_BOXES[@]}"; do
        echo "  - $box"
    done
    echo ""
fi
echo "You may need to log out and back in for group changes to take effect."
