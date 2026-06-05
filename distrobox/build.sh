#!/bin/bash
# Build coulomb distrobox images.
# Usage:
#   ./build.sh              # build all converted boxes
#   ./build.sh dev-box      # build a single box

set -euo pipefail
cd "$(dirname "$0")"

BOXES=(dev-box embed-box ctf-box gamedev-box radio-box)

build_one() {
    local box="$1"
    local containerfile="${box}/Containerfile"
    if [ ! -f "$containerfile" ]; then
        echo "No Containerfile for $box (expected $containerfile)" >&2
        return 1
    fi
    echo "==> Building localhost/coulomb-${box}:latest"
    podman build -t "localhost/coulomb-${box}:latest" -f "$containerfile" .
}

if [ $# -eq 0 ]; then
    for box in "${BOXES[@]}"; do
        build_one "$box"
    done
else
    build_one "$1"
fi
