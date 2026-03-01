#!/usr/bin/env bash

# Restore window session: launch apps, load a generated KWin script to place
# Brave windows on the correct monitors based on saved session.json.
#
# Spotify/Discord placement is handled by KWin window rules (kwinrulesrc),
# not by this script.
#
# Brave windows are matched by checking if the active tab title (caption)
# appears in the saved tab_titles list for each window. Falls back to saved
# order if no tab title match is found.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SESSION_FILE="$HOME/.config/coulomb/session.json"
KWIN_RESTORE_JS="$SCRIPT_DIR/kwin-session-restore.js"
DBUS_SERVICE="org.kde.KWin"
DBUS_PATH="/Scripting"
KWIN_SCRIPT_NAME="coulomb-session-restore"
CLEANUP_DELAY=90

if [[ ! -f "$SESSION_FILE" ]]; then
  echo "ERROR: no session file found at $SESSION_FILE" >&2
  exit 1
fi


# Extract Brave window placement rules from session.json
brave_rules=$(jq -c '[.windows[] | select(.resourceClass == "brave-browser")]' "$SESSION_FILE")
brave_count=$(echo "$brave_rules" | jq 'length')

if [[ "$brave_count" -eq 0 ]]; then
  echo "WARN: no Brave windows in session file, skipping Brave placement"
fi

# Build temporary KWin script: prepend rules JSON to the static JS
tmp_kwin=$(mktemp "${TMPDIR:-/tmp}/coulomb-restore-XXXXXX.js")
{
  echo "var rules = $brave_rules;"
  cat "$KWIN_RESTORE_JS"
} > "$tmp_kwin"

# Load the KWin placement script BEFORE launching apps so the windowAdded
# listener is ready to catch windows as they appear

# Unload any previous instance (stale from earlier run or missed cleanup)
qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" unloadScript "$KWIN_SCRIPT_NAME" &>/dev/null || true

echo "Loading KWin placement script..."
script_id=$(qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" loadScript "$tmp_kwin" "$KWIN_SCRIPT_NAME")
if [[ -z "$script_id" ]]; then
  echo "ERROR: failed to load KWin restore script" >&2
  rm -f "$tmp_kwin"
  exit 1
fi

qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" start &>/dev/null

# Launch applications (skip any that are already running)

launch_if_needed() {
  local name="$1" pattern="$2" flatpak_id="$3"
  if pgrep -f "$pattern" >/dev/null 2>&1; then
    echo "$name already running, skipping launch"
  else
    echo "Launching $name..."
    flatpak run "$flatpak_id" &>/dev/null & disown
  fi
}

launch_if_needed "Brave"    "brave"            "com.brave.Browser"
launch_if_needed "Spotify"  "/spotify/spotify"  "com.spotify.Client"
launch_if_needed "Discord"  "/Discord"          "com.discordapp.Discord"
launch_if_needed "Daedalus" "daedalus"          "com.github.barrettotte.daedalus"

echo "Session restore active. Cleanup in ${CLEANUP_DELAY}s."
echo "done"


# Background cleanup: unload script and remove temp file after timeout
(
  sleep "$CLEANUP_DELAY"
  qdbus-qt6 "$DBUS_SERVICE" "$DBUS_PATH" unloadScript "$KWIN_SCRIPT_NAME" &>/dev/null || true
  rm -f "$tmp_kwin"
) &
disown
exit 0
