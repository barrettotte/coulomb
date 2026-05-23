#!/usr/bin/env bash
# Install libvirt hook scripts for win10 GPU passthrough.
# Run as root: sudo bash install.sh

set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
DST_DIR="/etc/libvirt/hooks"

install -m 0755 -d "$DST_DIR" "$DST_DIR/qemu.d/win10/prepare/begin" "$DST_DIR/qemu.d/win10/release/end"

install -m 0755 "$SRC_DIR/qemu" "$DST_DIR/qemu"
install -m 0755 "$SRC_DIR/qemu.d/win10/prepare/begin/10-gpu-attach.sh" "$DST_DIR/qemu.d/win10/prepare/begin/10-gpu-attach.sh"
install -m 0755 "$SRC_DIR/qemu.d/win10/release/end/10-gpu-return.sh" "$DST_DIR/qemu.d/win10/release/end/10-gpu-return.sh"

systemctl restart virtqemud.service
echo "installed; virtqemud restarted"
