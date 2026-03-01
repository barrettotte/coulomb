#!/usr/bin/env python3

"""
Parse Brave's SNSS session files to extract window->tab mappings.

Reads the most recent Session_* file from the Brave Flatpak profile,
parses the binary SNSS v3 format, and outputs a JSON array of windows
with their tab titles and a hash for stable identification.

Output format:
  [
    {
      "window_id": 123,
      "tabs": [{"url": "...", "title": "..."}],
      "tab_titles": ["Title A", "Title B"],
      "tab_hash": "a1b2c3d4e5f67890"
    }
  ]
"""

import hashlib
import json
import struct
import sys
from pathlib import Path

BRAVE_SESSIONS_DIR = (
    Path.home()
    / ".var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser/Default/Sessions"
)

# SNSS command IDs we care about
CMD_SET_TAB_WINDOW = 0
CMD_TAB_CLOSED = 3
CMD_WINDOW_CLOSED = 4
CMD_UPDATE_TAB_NAVIGATION = 6


def align4(n):
    return (n + 3) & ~3


def find_session_file():
    """Return the most recent Session_* file by mtime."""
    if not BRAVE_SESSIONS_DIR.exists():
        return None

    files = sorted(BRAVE_SESSIONS_DIR.glob("Session_*"), key=lambda f: f.stat().st_mtime, reverse=True)
    return files[0] if files else None


def parse_snss(filepath):
    """Parse an SNSS v3 file and return window->tab mapping."""
    data = filepath.read_bytes()

    if data[:4] != b"SNSS":
        raise ValueError(f"not an SNSS file: {data[:4]}")

    offset = 8  # skip magic + version

    # State tracking
    windows = {}  # window_id -> set of tab_ids
    tabs = {}  # tab_id -> {url, title, nav_index}

    while offset + 2 <= len(data):
        size = struct.unpack_from("<H", data, offset)[0]
        entry_start = offset + 2

        if size == 0 or entry_start + size > len(data):
            break

        cmd_id = data[entry_start]
        payload = data[entry_start + 1 : entry_start + size]
        offset = entry_start + size

        try:
            if cmd_id == CMD_SET_TAB_WINDOW and len(payload) >= 8:
                # v3 format: raw [window_id:int32] [tab_id:int32]
                win_id = struct.unpack_from("<i", payload, 0)[0]
                tab_id = struct.unpack_from("<i", payload, 4)[0]
                windows.setdefault(win_id, set()).add(tab_id)

            elif cmd_id == CMD_UPDATE_TAB_NAVIGATION and len(payload) >= 12:
                # v3 format: [pickle_size:uint32] [tab_id:int32] [nav_index:int32] [url:string] [title:string16] ...

                pos = 4  # skip pickle size prefix

                tab_id = struct.unpack_from("<i", payload, pos)[0]
                pos += 4

                nav_idx = struct.unpack_from("<i", payload, pos)[0]
                pos += 4

                url_len = struct.unpack_from("<i", payload, pos)[0]
                pos += 4

                url = payload[pos : pos + url_len].decode("utf-8", errors="replace")
                pos += align4(url_len)

                title_chars = struct.unpack_from("<i", payload, pos)[0]
                pos += 4

                title_bytes = title_chars * 2
                title = payload[pos : pos + title_bytes].decode("utf-16-le", errors="replace")

                # Keep the most recent navigation entry per tab
                if tab_id not in tabs or nav_idx > tabs[tab_id]["nav_index"]:
                    tabs[tab_id] = {
                        "url": url,
                        "title": title,
                        "nav_index": nav_idx
                    }

            elif cmd_id == CMD_TAB_CLOSED and len(payload) >= 4:
                closed_id = struct.unpack_from("<i", payload, 0)[0]

                for w in windows.values():
                    w.discard(closed_id)

                tabs.pop(closed_id, None)

            elif cmd_id == CMD_WINDOW_CLOSED and len(payload) >= 4:
                closed_id = struct.unpack_from("<i", payload, 0)[0]
                windows.pop(closed_id, None)

        except (struct.error, IndexError):
            continue

    # Build output
    result = []
    for win_id, tab_ids in windows.items():
        win_tabs = []

        for tid in sorted(tab_ids):
            if tid in tabs:
                win_tabs.append({"url": tabs[tid]["url"], "title": tabs[tid]["title"]})

        if not win_tabs:
            continue

        sorted_titles = sorted(t["title"] for t in win_tabs if t["title"])
        tab_hash = hashlib.sha256("\n".join(sorted_titles).encode()).hexdigest()[:16]

        result.append({
            "window_id": win_id,
            "tabs": win_tabs,
            "tab_titles": sorted_titles,
            "tab_hash": tab_hash,
        })

    return result


def main():
    filepath = find_session_file()

    if filepath is None:
        print("[]")
        return

    try:
        windows = parse_snss(filepath)
        json.dump(windows, sys.stdout, indent=2)
        print()

    except Exception as e:
        print(f"error parsing {filepath}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
