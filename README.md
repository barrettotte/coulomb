# Coulomb

My system config and dotfiles. Currently using Bazzite.

This leverages distrobox heavily to keep the main system clean.

## Directory Summary

- [ansible/](ansible/) - playbooks to setup host and user environment
- [distrobox/](distrobox/) - distroboxes for various purposes
- [docs/](docs/) - misc markdown notes
- [dotfiles/](dotfiles/) - nvim config, `.zshrc`, etc.
- [services/](services/) - custom services
- [scripts/](scripts/) - misc scripts that may or may not be useful
- [vms/](vms/) - VM provisioning

## Setup

Setup prerequisites (see [docs/bazzite.md](docs/bazzite.md)):

```sh
# last step of prerequisites
git clone https://github.com/barrettotte/coulomb.git && cd coulomb
bash init.sh
```

This runs two playbooks then creates/initializes distroboxes:
1. `host-setup.yml` - brew packages, zsh, dotfiles, fonts, services
2. `flatpaks.yml` - all Flatpak applications
3. Distrobox create + init from `distrobox/distrobox.ini` (could be a playbook, but more chatty ran standalone)

## Distroboxes

| Name          | Image                        | Summary                             |
| ------------- | ---------------------------- | ----------------------------------- |
| `ctf-box`     | `kalilinux/kali-rolling`     | CTF and security tools              |
| `dev-box`     | `archlinux/archlinux:latest` | General development                 |
| `embed-box`   | `ubuntu:22.04`               | FPGA and embedded development       |
| `gamedev-box` | `ubuntu:22.04`               | Game development (Godot, Unreal)    |
| `mobile-box`  | `ubuntu:22.04`               | Android and mobile development      |
| `radio-box`   | `ubuntu:22.04`               | SDR and GNU Radio                   |
| `retro-box`   | `ubuntu:22.04`               | Vintage computing and retro dev     |

All distroboxes are defined in `distrobox/distrobox.ini`

## Known Issues

### Multi-GPU "Fun"

I have a GTX 1030 and an RTX 3090 Ti, but my BIOS has the 1030 with a higher PCI bus number.
This causes the boot process to not show logs during boot even after trying with various kernel args.
This also causes other issues where sometimes the 1030 is used instead of the 3090 (Steam).
I hope to continually tweak to fix this or maybe even figure out a better workaround.

Also, there's some kind of weird race condition where sometimes rebooting causes three dots to be displayed
on a monitor connected to the 1030. The system kind of gets stuck, but hard powering off fixes this most times.
The race condition behavior might have been an issue only on Fedora Kinoite 43 <2026, hasn't happened on Bazzite so far.

For Bazzite, I need to use `bazzite-nvidia` instead of `bazzite-nvidia-open` so I can have Pascal architecture support for the GTX 1030.

## TO DO

- `discord-rpc-bridge` systemd install
- `daedalus` flatpak install

## References

- https://github.com/nvim-lua/kickstart.nvim
- https://www.nerdfonts.com
- [How to Customize Tmux (20XX Edition) | Zero Plugins](https://www.youtube.com/watch?v=XivdyrFCV4M)
- https://docs.bazzite.gg/
- https://docs.fedoraproject.org/en-US/fedora-kinoite/
