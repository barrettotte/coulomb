#!/usr/bin/env bash
# KDE shutdown hook - save window session before logout/shutdown.
# Symlinked to ~/.config/plasma-workspace/shutdown/

exec /var/home/barrett/storage/code/repos/coulomb/scripts/session/session-save.sh
