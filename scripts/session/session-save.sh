#!/usr/bin/env bash

# Save current window-to-monitor mappings by loading a temporary KWin script,
# parsing its console.info output from journalctl, and writing session.json.
#
# For Brave windows, also parses SNSS session files to capture all tab titles
# per window so restore can match by tab hash instead of just active caption.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KWIN_SCRIPT="$SCRIPT_DIR/kwin-session-save.js"
SESSION_DIR="$HOME/.config/coulomb"
SESSION_FILE="$SESSION_DIR/session.json"
SENTINEL="COULOMB_SESSION_END"
PREFIX="COULOMB_SESSION:"
DBUS_SERVICE="org.kde.KWin"
DBUS_PATH="/Scripting"
TIMEOUT=5

mkdir -p "$SESSION_DIR"

# Record timestamp just before loading the script so we only read new log lines
timestamp=$(date '+%Y-%m-%d %H:%M:%S')

# Load the KWin script via DBus
script_id=$(qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" loadScript "$KWIN_SCRIPT" "coulomb-session-save")
if [[ -z "$script_id" ]]; then
  echo "ERROR: failed to load KWin script" >&2
  exit 1
fi

qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" start &>/dev/null

# Poll journalctl for the sentinel line indicating the script finished
elapsed=0
found=false
while (( elapsed < TIMEOUT )); do
  if journalctl SYSLOG_IDENTIFIER=kwin_wayland --since "$timestamp" --no-pager -o cat 2>/dev/null | grep -q "$SENTINEL"; then
    found=true
    break
  fi
  sleep 0.5
  elapsed=$((elapsed + 1))
done

# Unload the script
qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" unloadScript "coulomb-session-save" &>/dev/null || true

if ! $found; then
  echo "ERROR: timed out waiting for KWin script output" >&2
  exit 1
fi

# Parse COULOMB_SESSION: lines into a JSON array
kwin_windows=$(
  journalctl SYSLOG_IDENTIFIER=kwin_wayland --since "$timestamp" --no-pager -o cat 2>/dev/null \
    | grep "${PREFIX}" \
    | sed "s/.*${PREFIX}//" \
    | jq -s '.'
)

# Parse Brave SNSS session files for tab-level data
brave_tabs=$("$SCRIPT_DIR/brave_session.py" 2>/dev/null || echo '[]')

# Merge: for each Brave window from KWin, find the SNSS window whose tab titles
# contain the active caption, then attach tab_titles and tab_hash.
merged=$("$SCRIPT_DIR/merge_brave_tabs.py" "$kwin_windows" "$brave_tabs")

# Build final session file
saved_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
jq -n --arg saved_at "$saved_at" --argjson windows "$merged" \
  '{ saved_at: $saved_at, windows: $windows }' > "$SESSION_FILE"

count=$(echo "$merged" | jq 'length')
echo "Saved $count windows to $SESSION_FILE"
