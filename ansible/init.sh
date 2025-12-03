#!/bin/bash

set -e

VENV_DIR="$HOME/.cache/ansible-bootstrap-venv"

ANSIBLE_EXTRA_VARS="target_user=$USER ansible_python_interpreter=$(which python)"
ANSIBLE_BASE_CMD=(ansible-playbook -i inventory.ini -vv --extra-vars "$ANSIBLE_EXTRA_VARS" --ask-become-pass)

echo "Starting Fedora Kinoite bootstrap..."

# make sure python is installed (normally included in Fedora Kinoite)
if ! command -v python3 &> /dev/null; then
    echo "Python3 could not be found. Cannot continue setup."
    exit 1
fi

# make sure secureboot is disabled (for NVIDIA drivers)
if [ "$(mokutil --sb-state)" = "SecureBoot enabled" ]; then
    echo "SecureBoot is enabled. This needs to be disabled in BIOS to continue."
    exit 2
fi

# create and/or enter virtual env
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating python virtual environment for Ansible..."
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    echo "Installing Ansible core..."
    pip install ansible requests
else
    echo "Using existing python virtual environment."
    source "$VENV_DIR/bin/activate"
fi

echo "Installing Ansible collections..."
ansible-galaxy collection install ansible.posix community.general

# run base setup - os upgrade, drivers, kargs, etc
echo "Running base setup..."
"${ANSIBLE_BASE_CMD[@]}" playbooks/base.yml || true

# check if playbook succeeded
if [ $? -ne 0 ]; then
    echo "Base setup playbook failed."
    exit 3
fi

BOOTED_DEPLOYMENT=$(rpm-ostree status --json | jq '.deployments[] | select(.booted == true) | .id')
STAGED_DEPLOYMENT=$(rpm-ostree status --json | jq '.deployments[] | select(.staged == true) | .id')

if [[ "$BOOTED_DEPLOYMENT" != "$STAGED_DEPLOYMENT" && -n "$STAGED_DEPLOYMENT" ]]; then
    echo
    echo "========================================================"
    echo "A system update has been staged."
    echo "Staged deployment: $STAGED_DEPLOYMENT"
    echo "Booted deployment: $BOOTED_DEPLOYMENT"
    echo "========================================================"

    while true; do
        read -p "Do you want to reboot now? [y/N]: " yn
        case $yn in
            [Yy]* )
                echo "Rebooting system...Run this script again after reboot."
                systemctl reboot
                break;;
            [Nn]* )
                echo "Reboot skipped. Changes will not apply until reboot."
                exit 0;;
            * ) echo "Answer [Y]es or [N]o";;
        esac
    done
else
    echo "No pending reboots detected."
    echo "Base system is up to date."
    echo "Booted deployment: $BOOTED_DEPLOYMENT"

    read -p "Proceed to user environment setup (main.yml)? [y/N]" main_yn
    if [[ $main_yn =~ ^[Yy]$ ]]; then
        echo "Setting up user environment..."
        "${ANSIBLE_BASE_CMD[@]}" playbooks/user-env.yml

        if [ $? -ne 0 ]; then
            echo "User environment setup playbook failed."
            exit 4
        fi
    else
        echo "User environment setup skipped."
    fi
fi
