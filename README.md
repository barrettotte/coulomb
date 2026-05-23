# Coulomb

My system config and dotfiles. Currently using Bazzite.

This leverages distrobox heavily to keep the main system clean.

## Directory Summary

- [ansible/](ansible/) - playbooks to setup host and user environment
- [distrobox/](distrobox/) - distroboxes for various purposes
- [docs/](docs/) - misc markdown notes
- [dotfiles/](dotfiles/) - nvim config, `.zshrc`, etc.
- [scripts/](scripts/) - session save/restore and misc scripts
- [vms/](vms/) - VM provisioning

## Setup

Setup prerequisites (see [docs/bazzite.md](docs/bazzite.md)):

```sh
# last step of prerequisites
git clone https://github.com/barrettotte/coulomb.git && cd coulomb
bash scripts/init.sh
```

This runs two playbooks then creates/initializes distroboxes:
1. `host-setup.yml` - brew packages, zsh, dotfiles, fonts, services
2. `flatpaks.yml` - all Flatpak applications
3. Distrobox create + init from `distrobox/distrobox.ini` (could be a playbook, but more chatty ran standalone)

## Updating

Update host packages (brew, flatpaks) and all distroboxes:

```sh
bash scripts/update.sh
```

## Distroboxes

| Name          | Image                        | Summary                             |
| ------------- | ---------------------------- | ----------------------------------- |
| `ctf-box`     | `kalilinux/kali-rolling`     | CTF and security tools              |
| `dev-box`     | `archlinux/archlinux:latest` | General development                 |
| `embed-box`   | `ubuntu:22.04`               | FPGA and embedded development       |
| `gamedev-box` | `ubuntu:22.04`               | Game development (Godot, Unreal)    |
| `radio-box`   | `ubuntu:22.04`               | SDR and GNU Radio                   |

All distroboxes are defined in `distrobox/distrobox.ini`.
Some boxes require manual post-install steps.
See [docs/distrobox-manual-setup.md](docs/distrobox-manual-setup.md).

## References

- https://github.com/nvim-lua/kickstart.nvim
- https://www.nerdfonts.com
- [How to Customize Tmux (20XX Edition) | Zero Plugins](https://www.youtube.com/watch?v=XivdyrFCV4M)
- https://docs.bazzite.gg/
- https://docs.fedoraproject.org/en-US/fedora-kinoite/
