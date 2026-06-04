#!/bin/bash

# Initialize radio-box: per-user setup only.
# Image-level packages and SDR++ build live in radio-box.Containerfile.

set -ex

source "$(dirname "$0")/common.sh"
init_start "radio-box"

# shell - oh-my-zsh ships in the image at /opt/ohmyzsh
setup_zsh_from_image

# SDR++ recorder config: writes recordings to the host so they survive recreate
mkdir -p "$HOST_HOME/storage/misc/radio/recordings"
mkdir -p "$HOME/.config/sdrpp"
cat > "$HOME/.config/sdrpp/recorder_config.json" <<EOF
{
    "Recorder": {
        "ignoreSilence": false,
        "mode": 1,
        "recPath": "$HOST_HOME/storage/misc/radio/recordings"
    }
}
EOF

setup_symlinks
init_end
