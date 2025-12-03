#!/bin/bash

# For each distrobox: Remove the distrobox, delete the custom home directory, and remove the podman container.
# This was made while testing automation and should probably not be used otherwise.
#
# sample listing:
#
# $ distrobox ls
# ID           | NAME                 | STATUS             | IMAGE
# ef397e304ade | test-box             | Up 7 minutes       | registry.fedoraproject.org/fedora:41

set -e

DISTROBOX_CUSTOM_HOMES="$HOME/storage/code/distrobox/homes"

echo "Nuking all distroboxes..."

distrobox ls | awk -F '|' 'NR>1 {print $2}' | xargs | while read -r box; do
    for container in $box; do
        printf '%.s=' $(seq 1 80)
        echo -e "\nNuking: $container..."

        echo "Removing distrobox $container..."
        distrobox rm -f "$container"

        # podman container probably removed already, but just in case
        echo "Removing podman container $container..."
        podman rm -f "$box" 2>/dev/null || echo "(Podman container already removed)"

        TARGET_DIR="$DISTROBOX_CUSTOM_HOMES/$container"
        if [ -d "$TARGET_DIR" ]; then
            echo "Deleting container's home directory $TARGET_DIR..."
            rm -rf "$TARGET_DIR"
        else
            echo "WARNING: container home directory $TARGET_DIR not found. Skipping."
        fi

        printf '%.s=' $(seq 1 80) && echo
    done
done

echo "Nuke completed."

