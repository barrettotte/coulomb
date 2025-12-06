# Coulomb

Dotfiles and installation scripts for my Fedora Kinoite system.

This leverages distrobox heavily to keep the main system clean.

## Directory Summary

- [ansible/](ansible/) - playbooks to setup base system and user environment
- [distrobox/](distrobox/) - distroboxes for various purposes
- [docs/](docs/) - misc markdown notes
- [dotfiles/](dotfiles/) - nvim config, `.zshrc`, etc.
- [scripts/](scripts/) - misc scripts that may or may not be useful

## Setup

```sh
git clone https://github.com/barrettotte/coulomb.git && cd coulomb

bash ansible/init.sh
# Note: This script will need to be run multiple times for reboots due to rpm-ostree changes.
# But, it still handles idempotent updates properly.

# If user environment playbook skipped earlier, run manually
source $HOME/.cache/ansible-bootstrap-venv/bin/activate
ansible-playbook -i ansible/inventory.ini -vv ansible/playbooks/user-env.yml --ask-become-pass
```

## Distroboxes

| Name        | Image                        | Summary                             |
| ----------- | ---------------------------- | ----------------------------------- |
| `ctf-box`   | `kalilinux/kali-rolling`     | TODO: CTF environment               |
| `dev-box`   | `archlinux/archlinux:latest` | General development                 |
| `embed-box` | `ubuntu:22.04`               | TODO: FPGA and embedded development |
| `radio-box` | `ubuntu:22.04`               | TODO: SDR, GNU Radio                |

All distroboxes are defined in `distrobox/distrobox.ini`

## Known Issues

### Multi-GPU "Fun"

I have a GTX 1030 and an RTX 3090 Ti, but my BIOS has the 1030 with a higher PCI bus number.
This causes the boot process to not show logs during boot even after trying with various kernel args.
This also causes other issues where sometimes the 1030 is used instead of the 3090 (Steam).
I hope to continually tweak to fix this or maybe even figure out a better workaround.

Also, there's some kind of weird race condition where sometimes rebooting causes three dots to be displayed
on a monitor connected to the 1030. The system kind of gets stuck, but hard powering off fixes this most times.

## TODO:

- neovim
  - LSP (nvim-lspconfig), autocomplete (nvim-cmp or blink.cmp), linting
  - which-key.nvim
  - move blocks of code (already builtin? I'm dumb)
- add Konsole profiles and/or shortcuts for opening dev-box
- mouse and keyboard LEDs don't turn off on shutdown
- ctf-box
- embed-box
- radio-box

## References

- https://docs.fedoraproject.org/en-US/fedora-kinoite/
  - https://docs.fedoraproject.org/en-US/fedora-kinoite/troubleshooting/#_using_nvidia_drivers
- https://wiki.archlinux.org/title/Plymouth
- https://github.com/nvim-lua/kickstart.nvim
- https://www.nerdfonts.com
- [How to Customize Tmux (20XX Edition) | Zero Plugins](https://www.youtube.com/watch?v=XivdyrFCV4M)
