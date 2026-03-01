// KWin script: enumerate all normal windows and log their positions/screens
// as structured JSON lines to journalctl (via console.info).
//
// NOTE: console.info() is suppressed in KDE 6 / KWin Wayland.
// Only console.info/warn/error produce journal output under kwin_wayland.
//
// Loaded temporarily by session-save.sh; output is parsed from journalctl SYSLOG_IDENTIFIER=kwin_wayland.

(function () {
  var SENTINEL = "COULOMB_SESSION_END";
  var PREFIX = "COULOMB_SESSION:";
  var MAXIMIZED_TOLERANCE = 20; // px threshold for detecting maximized windows

  // Build a lookup of screen name -> geometry from workspace.screens
  var screenGeo = {};
  for (var i = 0; i < workspace.screens.length; i++) {
    var scr = workspace.screens[i];
    screenGeo[scr.name] = scr.geometry;
  }

  // Determine which output name a window belongs to by checking which screen
  // area contains the window's center point.
  function screenForWindow(win) {
    var cx = win.frameGeometry.x + Math.floor(win.frameGeometry.width / 2);
    var cy = win.frameGeometry.y + Math.floor(win.frameGeometry.height / 2);

    for (var name in screenGeo) {
      var g = screenGeo[name];
      if (cx >= g.x && cx < g.x + g.width && cy >= g.y && cy < g.y + g.height) {
        return name;
      }
    }
    return "unknown";
  }

  var windows = workspace.windowList();

  for (var i = 0; i < windows.length; i++) {
    var win = windows[i];

    // Skip non-normal windows (docks, panels, desktop, etc.)
    if (win.skipTaskbar || win.specialWindow) {
      continue;
    }

    // Skip minimized windows to avoid stale data
    if (win.minimized) {
      continue;
    }

    var data = {
      resourceClass: String(win.resourceClass),
      caption: String(win.caption),
      screen: screenForWindow(win),
      maximized: (win.frameGeometry.width >= screenGeo[screenForWindow(win)].width - MAXIMIZED_TOLERANCE),
      x: win.frameGeometry.x,
      y: win.frameGeometry.y,
      width: win.frameGeometry.width,
      height: win.frameGeometry.height,
    };

    console.info(PREFIX + JSON.stringify(data));
  }

  console.info(SENTINEL);

})();
