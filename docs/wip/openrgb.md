# OpenRGB

WIP, I didn't quite get this figured out yet...only discovers my motherboard so far, but this is for the future.

Ideally this should be included in the ansible init playbooks

```sh
lsmod | grep i2c_dev                                                                   
# make sure its running
```

```sh
flatpak install flathub org.openrgb.OpenRGB

# modified from https://openrgb.org/releases/release_0.9/openrgb-udev-install.sh for visibility
curl -o /tmp/60-openrgb.rules https://openrgb.org/releases/release_0.9/60-openrgb.rules
sudo mv /tmp/60-openrgb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

# all devices kind of makes me cringe...but it seems popular enough I guess
flatpak override --user --device=all --device=usb org.openrgb.OpenRGB
```

```sh
lsusb

# 1b1c:1bc4 Corsair CORSAIR K70 RGB PRO Mechanical Gaming Keyboard
# 046d:c090 Logitech, Inc. G703 LIGHTSPEED Wireless Gaming Mouse w/ HERO
# Note: These are not included in 60-openrgb.rules - probably why this isn't working...

# repo: https://gitlab.com/CalcProgrammer1/OpenRGB/-/tree/master
# 1.0 as of 2025-12-03 might release soonish that includes these devices - https://openrgb.org/devices.html
```
