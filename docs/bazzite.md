# Bazzite

Prerequisites to complete before running `bash init.sh`.

Using image `bazzite-nvidia:stable`

## Drive Mounts

```sh
lsblk -f

sudo mkdir -p /var/mnt/code
sudo sh -c 'echo "UUID=<UUID-1> /var/mnt/code ext4 defaults,nofail 0 2" >> /etc/fstab'

sudo mkdir -p /var/mnt/mass
sudo sh -c 'echo "UUID=<UUID-2> /var/mnt/mass ext4 defaults,nofail 0 2" >> /etc/fstab'

sudo mkdir -p /var/mnt/misc
sudo sh -c 'echo "UUID=<UUID-3> /var/mnt/misc ext4 defaults,nofail 0 2" >> /etc/fstab'

# Recursive bind mount (so things like Daedalus don't throw a fit over symlinks)
mkdir -p "$HOME/storage"
sudo sh -c 'echo "/var/mnt /var/home/barrett/storage none rbind,nofail 0 0" >> /etc/fstab'

sudo systemctl daemon-reload
sudo mount -a

ln -s ~/storage/code/repos ~/repos
```

## Homebrew

```sh
# Note: I think this might already come bundled with Bazzite
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## SSH Keys

```sh
ssh-keygen -t ed25519 -C "<email>"
ssh-add ~/.ssh/id_ed25519
```

## Setup

```sh
git clone https://github.com/barrettotte/coulomb.git && cd coulomb
bash init.sh
```
