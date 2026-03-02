# Distrobox Manual Setup

Post-install steps that can't be automated in init scripts.
Run these after `distrobox assemble create` or running the base `init.sh` script.

## ctf-box

**Wireshark Live Capture**

Wireshark runs in ctf-box but can't capture locally from a rootless container.
Capture on the host with `tcpdump` and pipe live into Wireshark:

```sh
sudo tcpdump -i enp7s0 -U -w - | wireshark -k -i -
```

Or capture to a file and open it later:

```sh
sudo tcpdump -i enp7s0 -w ~/capture.pcap
wireshark ~/capture.pcap
```

**IDA Free**
- Download from https://hex-rays.com/ida-free/
- `chmod +x idafree*.run && ./idafree*.run`

## embed-box

**Xilinx Vivado**
- Download the installer from https://www.xilinx.com/support/download.html
- `chmod +x Xilinx_Unified_*_Lin64.bin && ./Xilinx_Unified_*_Lin64.bin`
- All dependencies are already installed in the container.

## gamedev-box

**Unreal Engine** (Must be built from source on Linux)
- Link your GitHub account at https://www.unrealengine.com/en-US/ue-on-github
- `git clone https://github.com/EpicGames/UnrealEngine.git`
- `./Setup.sh && ./GenerateProjectFiles.sh && make`
