# coulomb

My WIP dev env

## VM

Eventually I want this to be a standalone setup and not just on a VM.
Maybe I'll get a nice Thinkpad or something.

- Ubuntu 22.04, minimal install, install 3rd drivers
- 256GB disk
- 16GB RAM
- 1 processor, 8 cores per processor

## Setup Script

```sh
wget -O - https://raw.githubusercontent.com/barrettotte/coulomb/master/setup.sh | bash
```

This script will later use `git clone` to download additional config files like dotfiles from this repo.

## Post-Setup Script

- setup github cli `gh auth login`
- sign into vscode for env sync
- add new access token to Github

## To Do

- firefox bookmarks - ctf and general stuff
- additional desktop env config
- more useful aliases
- vim config
- FPGA tools
- CUDA?
- python script to clone all user's repos to `~/coding/repos`
- complete [Linux From Scratch](https://www.linuxfromscratch.org/)
