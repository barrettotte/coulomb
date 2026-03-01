// KWin script: place Brave windows on correct monitors based on saved session.
//
// Expects `var rules = [...]` to be prepended by session-restore.sh before
// this file is loaded into KWin.
//
// Spotify/Discord/Daedalus placement is handled by KWin window rules
// (kwinrulesrc), not by this script.

// Build screen-name -> screen object lookup
var screenObj = {};
for (var i = 0; i < workspace.screens.length; i++) {
  screenObj[workspace.screens[i].name] = workspace.screens[i];
}

var assignedRules = [];
for (var i = 0; i < rules.length; i++) {
  assignedRules.push(false);
}

// Strip " - Brave" suffix from caption to get the active tab title
function activeTabTitle(caption) {
  var suffix = " - Brave";
  if (caption.length > suffix.length &&
      caption.substring(caption.length - suffix.length) === suffix) {
    return caption.substring(0, caption.length - suffix.length);
  }
  return caption;
}

function placeBrave(win) {
  var title = activeTabTitle(win.caption);

  // Match by tab title membership
  for (var i = 0; i < rules.length; i++) {
    if (assignedRules[i]) {
      continue;
    }
    var titles = rules[i].tab_titles;

    if (titles && titles.length > 0) {
      for (var j = 0; j < titles.length; j++) {
        if (titles[j] === title) {
          console.info("COULOMB_RESTORE: MATCH tab_titles rule[" + i + "] screen=" + rules[i].screen + " title=" + title);
          applyRule(win, rules[i]);
          assignedRules[i] = true;
          return true;
        }
      }
    }
  }

  // Fallback: caption substring match
  for (var i = 0; i < rules.length; i++) {
    if (assignedRules[i]) {
      continue;
    }
    if (win.caption.indexOf(rules[i].caption) !== -1 ||
        rules[i].caption.indexOf(win.caption) !== -1) {
      console.info("COULOMB_RESTORE: MATCH caption rule[" + i + "] screen=" + rules[i].screen + " caption=" + win.caption);
      applyRule(win, rules[i]);
      assignedRules[i] = true;
      return true;
    }
  }

  // Last resort: assign in saved order
  for (var i = 0; i < rules.length; i++) {
    if (assignedRules[i]) {
      continue;
    }
    console.info("COULOMB_RESTORE: MATCH order rule[" + i + "] screen=" + rules[i].screen + " caption=" + win.caption);
    applyRule(win, rules[i]);
    assignedRules[i] = true;
    return true;
  }

  console.info("COULOMB_RESTORE: NO MATCH for caption=" + win.caption + " (" + rules.length + " rules, all assigned)");
  return false;
}

function applyRule(win, rule) {
  var screen = screenObj[rule.screen];

  if (!screen) {
    console.info("COULOMB_RESTORE: screen not found: " + rule.screen);
    return;
  }
  workspace.sendClientToScreen(win, screen);

  if (rule.maximized) {
    win.setMaximize(true, true);
  } else {
    win.setMaximize(false, false);
    var geo = win.frameGeometry;
    geo.x = rule.x;
    geo.y = rule.y;
    geo.width = rule.width;
    geo.height = rule.height;
    win.frameGeometry = geo;
  }
}

function handleWindow(win, source) {
  var rc = String(win.resourceClass).toLowerCase();
  if (win.skipTaskbar || win.specialWindow) {
    return;
  }
  if (rc === "brave-browser") {
    console.info("COULOMB_RESTORE: " + source + " brave caption=" + win.caption);
    placeBrave(win);
  }
}

// Place any Brave windows that already exist
var existing = workspace.windowList();
for (var i = 0; i < existing.length; i++) {
  handleWindow(existing[i], "existing");
}

// Listen for new Brave windows
workspace.windowAdded.connect(function (win) {
  handleWindow(win, "added");
  win.captionChanged.connect(function () {
    var rc = String(win.resourceClass).toLowerCase();
    if (rc === "brave-browser") {
      console.info("COULOMB_RESTORE: captionChanged caption=" + win.caption);
      placeBrave(win);
    }
  });
});
