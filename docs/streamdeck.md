# Stream Deck Layout

Elgato Stream Deck MK.2 (5x3) button layout using OpenDeck.
All buttons use the "Run Command" action from the starter pack plugin.

It was kind of just too cumbersome to use dotfiles for this and its not hard to spend like 10 minutes
setting this up.

Icons are found in `../assets/streamdeck-icons`.

## Row 0

| Button | Label | Command |
|--------|-------|---------|
| 0,0 | Daedalus | `flatpak-spawn --host flatpak run com.github.barrettotte.daedalus` |
| 0,1 | Claude Terminal | `kde-ptyxis -e /var/home/barrett/storage/code/repos/coulomb/scripts/claude-terminal.sh` |
| 0,2 | dev-box terminal | `flatpak-spawn --host kde-ptyxis -e distrobox enter dev-box` |
| 0,3 | Win10 VM | `flatpak-spawn --host flatpak run org.virt_manager.virt-manager --connect qemu:///system --show-domain-console win10` |
| 0,4 | - | |

## Row 1

| Button | Label | Command |
|--------|-------|---------|
| 1,0 | Obsidian | `flatpak-spawn --host flatpak run md.obsidian.Obsidian` |
| 1,1 | VS Code | `flatpak-spawn --host distrobox enter dev-box -- code` |
| 1,2 | Zed | `flatpak-spawn --host /home/barrett/.local/zed.app/bin/zed --new` |
| 1,3 | - | |
| 1,4 | - | |

## Row 2

| Button | Label | Command |
|--------|-------|---------|
| 2,0 | Discord | `flatpak-spawn --host flatpak run com.discordapp.Discord` |
| 2,1 | Spotify | `flatpak-spawn --host flatpak run com.spotify.Client` |
| 2,2 | Brave | `flatpak-spawn --host flatpak run com.brave.Browser about:blank` |
| 2,3 | Fishtank | `flatpak-spawn --host flatpak run com.brave.Browser https://www.fishtank.live/` |
| 2,4 | Mic Mute | `flatpak-spawn --host qdbus org.kde.kglobalaccel /component/kmix invokeShortcut mic_mute` |
