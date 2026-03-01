#!/usr/bin/env python3

"""
Merge KWin window data with Brave SNSS tab data.

For each Brave window from KWin, find the SNSS window whose tab titles
contain the active caption, then attach tab_titles and tab_hash.

Usage: merge_brave_tabs.py <kwin_windows_json> <snss_tabs_json>
"""

import json
import sys

BRAVE_SUFFIX = " - Brave"

kwin = json.loads(sys.argv[1])
snss = json.loads(sys.argv[2])

for win in kwin:
    if win.get("resourceClass") != "brave-browser":
        continue

    caption = win.get("caption", "")

    # Strip ' - Brave' suffix to get the active tab title
    active_title = caption[: -len(BRAVE_SUFFIX)] if caption.endswith(BRAVE_SUFFIX) else caption

    # Find the SNSS window that contains this active tab title
    best = None
    for sw in snss:
        for tab in sw["tabs"]:
            if tab["title"] == active_title:
                best = sw
                break
        if best:
            break

    if best:
        win["tab_titles"] = best["tab_titles"]
        win["tab_hash"] = best["tab_hash"]

json.dump(kwin, sys.stdout)
