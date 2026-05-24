# Navio2 Emlid Raspbian OS

Emlid's customized Raspberry Pi OS image with Navio2 kernel drivers, ArduPilot, and ROS pre-installed.

## Overview

Emlid distributes a modified Raspbian image for Navio2 that includes the kernel extensions and pre-built software stack needed to fly ArduPilot without manual compilation. The standard Raspberry Pi OS kernel lacks the AUX SPI driver, the co-processor interface driver, and the sysfs mappings that Navio2 requires. Emlid's image ships custom `raspberrypi-kernel` and `raspberrypi-kernel-headers` packages that activate these interfaces and expose hardware through standard Linux abstractions (`/dev`, `/sys`).

The image supports Raspberry Pi 2B, 3B, 3B+, and 4B from a single SD card image. It ships without a desktop GUI — the Raspberry Pi's CPU and RAM are better allocated to ArduPilot and ROS than to a graphical environment.

## What the Image Includes

| Component | Version / Notes |
|-----------|-----------------|
| Base OS | Raspbian Bullseye (Debian 11) |
| Kernel | Custom Emlid build with Navio2 HAT drivers |
| ArduPilot binaries | ArduCopter, ArduPlane, ArduRover, ArduSub (pre-built) |
| ROS | ROS 1 Noetic (pre-installed) |
| MAVROS | Pre-installed, configured for ArduPilot UDP bridge |
| Python libraries | emlid/Navio2 sensor drivers |

## Kernel Drivers

Navio2 requires kernel modules not present in stock Raspbian:

| Driver | Purpose |
|--------|---------|
| `spi-bcm2835aux` | AUX SPI1 controller for LSM9DS1 IMU |
| `rcio` | Co-processor interface: PWM output + RC input sysfs |
| `navio2-leds` | RGB status LED control |
| Navio2 HAT EEPROM | Board identification at boot |

These modules load automatically at boot via `/etc/modules-load.d/`. The co-processor driver creates `/sys/kernel/rcio/` where ArduPilot and user code read RC input channels and write PWM output commands.

## Flashing and First Boot

1. Download the latest `.img.xz` from the Emlid docs site.
2. Flash to a 8 GB+ micro-SD card (Class 10 / UHS-I recommended):
   ```bash
   xzcat emlid-raspbian-*.img.xz | sudo dd of=/dev/sdX bs=4M status=progress
   ```
3. Mount the `/boot` partition and create `wpa_supplicant.conf` for WiFi pre-configuration:
   ```
   country=US
   ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
   update_config=1
   network={
       ssid="YourSSID"
       psk="YourPassword"
   }
   ```
4. Insert the card, power on, and SSH in:
   ```bash
   ssh pi@navio.local    # Zeroconf hostname; password: raspberry
   ```
   If Zeroconf does not resolve, find the IP address with nmap:
   ```bash
   nmap -sn 192.168.1.*   # look for hostname "navio" in the results
   ```
   Alternatively use the Fing app on a smartphone or Zenmap on a desktop.
5. Change the default password immediately: `passwd`

## WiFi Configuration

Pre-configure WiFi by editing `wpa_supplicant.conf` on the SD card's `/boot` partition before inserting it:

```
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="YourSSID"
    psk="YourPassword"
}
```

On a Linux host, generate the hashed passphrase to avoid storing plaintext:

```bash
sudo bash -c "wpa_passphrase 'YourSSID' 'YourPassword' >> /boot/wpa_supplicant.conf"
```

Disable WiFi power management to prevent GCS connection drops during flight:

```bash
sudo iw dev wlan0 set power_save off
```

Add this command to `/etc/rc.local` (before `exit 0`) so it persists across reboots.

## Expanding the Root Filesystem

The Emlid Raspbian Buster image auto-expands on first boot. On older Bullseye or Buster images that do not auto-expand, expand manually:

```bash
sudo raspi-config --expand-rootfs
sudo reboot
```

This fills the SD card with the root partition; without it, only ~3 GB of space is available regardless of card size.

## Managing ArduPilot

The `ardupilot.service` systemd unit reads vehicle type and options from a vehicle-specific file (e.g., `/etc/default/arducopter`). The recommended way to set the vehicle type is via [emlidtool](emlidtool.md) `ardupilot configure`, which also checks RCIO firmware before applying the change. See [Navio2 ArduPilot Configuration](ardupilot-configuration.md) for the full flag and parameter reference.

Check ArduPilot logs:

```bash
sudo journalctl -u ardupilot --since "10 minutes ago"
```

ArduPilot data flash logs are written to `/var/APM/logs/` (ArduCopter) or the equivalent vehicle path.

## Updating ArduPilot

Emlid provides updated ArduPilot packages through their APT repository. To update:

```bash
sudo apt update
sudo apt install -y emlid-copter   # or emlid-plane, emlid-rover
```

To install a specific ArduPilot version or a custom build, replace the binary in `/usr/bin/` and restart the service.

## Building Custom Packages

Cross-compile ArduPilot on an x86 host (faster than native RPi compilation) and transfer the binary:

```bash
# On x86 host with ArduPilot cloned
./waf configure --board=navio2
./waf copter
scp build/navio2/bin/arducopter pi@navio.local:/usr/bin/arducopter
ssh pi@navio.local "sudo systemctl restart ardupilot"
```

## Docker on the Image

The Emlid Raspbian image supports Docker for containerized development. Running ROS nodes in Docker containers isolates dependencies and simplifies version management when working with multiple ROS packages. Performance overhead is minimal for IO-bound robotics workloads.

## Known Issues and Compatibility

- Raspberry Pi 5 is **not supported** as of the current Emlid image (the GPIO architecture changed).
- WiFi power management must be disabled to prevent connection drops during GCS use:
  ```bash
  sudo iw dev wlan0 set power_save off
  ```
  Add this to `/etc/rc.local` to persist across reboots.
- The Emlid image does not include a GUI; connecting an HDMI monitor shows a console only.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 ArduPilot Configuration](ardupilot-configuration.md)
- [Navio2 ROS and MAVROS](../../programming/navio2-ros.md)
- [Navio2 Dual IMU](imu.md)

## Sources

- [Introduction — Emlid Navio2 docs](https://docs.emlid.com/navio2/) — 2026-05-22
- [Raspberry Pi configuration — Emlid Navio2 docs](https://docs.emlid.com/navio2/configuring-raspberry-pi/) — 2026-05-22

<!-- linted: 2026-05-23 -->
