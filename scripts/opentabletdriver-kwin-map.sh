#!/bin/bash

# Maps OpenTabletDriver virtual devices to the tablet display (DP-2)
# in KWin. OTD creates two devices: Virtual Tablet and Virtual Artist Tablet.
# Without this, KWin maps them to the full virtual desktop, causing misalignment.

DISPLAY_OUTPUT="DP-2"

sysnames=$(qdbus org.kde.KWin /org/kde/KWin/InputDevice \
    org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDeviceManager devicesSysNames 2>/dev/null)

for ev in $sysnames; do
    name=$(cat "/sys/class/input/$ev/device/name" 2>/dev/null)
    if [[ "$name" == *"OpenTabletDriver"* ]]; then
        qdbus org.kde.KWin "/org/kde/KWin/InputDevice/$ev" \
            org.freedesktop.DBus.Properties.Set org.kde.KWin.InputDevice outputName "$DISPLAY_OUTPUT"
    fi
done
