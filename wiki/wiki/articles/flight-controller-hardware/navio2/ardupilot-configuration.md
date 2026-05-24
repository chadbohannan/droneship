# Navio2 ArduPilot Configuration

Running and configuring ArduPilot on Navio2 from the Emlid Raspbian image.

## Overview

On Navio2, ArduPilot runs as a standard Linux userspace process managed by systemd, rather than as bare-metal firmware on a microcontroller. Emlid's Raspbian image ships pre-built binaries for ArduCopter, ArduPlane, ArduRover, and ArduSub. The active vehicle type and startup flags are configured in a vehicle-specific file such as `/etc/default/arducopter`. ArduPilot communicates with ground control stations (Mission Planner, QGroundControl, MAVProxy) over UDP through the Raspberry Pi's WiFi or Ethernet interface, eliminating the need for a dedicated telemetry radio on bench setups.

## Installing the Image

Download the latest Emlid Raspbian image from [docs.emlid.com/navio2](https://docs.emlid.com/navio2/) and flash it to a micro-SD card using Balena Etcher or `dd`. Boot the Raspberry Pi; Navio2 hardware is recognized automatically by the Emlid kernel drivers included in the image.

On first boot, configure WiFi by editing `/boot/wpa_supplicant.conf` before inserting the SD card, or connect via Ethernet. Access the Pi via SSH:

```bash
ssh pi@navio.local   # Zeroconf hostname; default password: raspberry
```

## Vehicle Selection

The recommended method is `sudo emlidtool ardupilot configure` (see [emlidtool](emlidtool.md)), which presents a TUI for vehicle type, boot behavior, and performs an RCIO firmware check automatically. For manual or scripted configuration, edit the vehicle-specific file directly:

```bash
# /etc/default/arducopter  (or arduplane, ardurover, ardusub)
TELEM1="-A udp:192.168.1.100:14550"
ARDUPILOT_OPTS="$TELEM1"
```

`emlidtool ardupilot configure` creates the vehicle-specific file (`/etc/default/arducopter` etc.) and enables the correct systemd service. Add GCS and telemetry options to that file after configuration.

Systemd service management:

```bash
sudo systemctl start ardupilot     # start now
sudo systemctl stop ardupilot      # stop
sudo systemctl enable ardupilot    # start on boot
sudo systemctl status ardupilot    # check status
sudo journalctl -u ardupilot -f    # follow logs
```

## Serial Port Flag Mapping

ArduPilot's command-line flags map to MAVLink serial instances:

| Flag | MAVLink Serial | Default baud | Typical use |
|------|---------------|--------------|-------------|
| -A | Serial 0 | 115200 | Console / primary GCS |
| -C | Serial 1 | 57600 | Telemetry radio |
| -D | Serial 2 | 57600 | Secondary telemetry |
| -B | Serial 3 | 38400 | GPS 1 |
| -E | Serial 4 | 38400 | GPS 2 / external device |

To stream MAVLink to a GCS at 192.168.1.100 on port 14550 via UDP:

```bash
ARDUPILOT_OPTS="-A udp:192.168.1.100:14550"
```

To add a telemetry radio on `/dev/ttyUSB0` in addition to the UDP GCS:

```bash
TELEM1="-A udp:192.168.1.100:14550"
TELEM2="-C /dev/ttyUSB0"
ARDUPILOT_OPTS="$TELEM1 $TELEM2"
```

After editing, reload and restart:

```bash
sudo systemctl daemon-reload && sudo systemctl restart ardupilot
```

## Navio2-Specific Parameters

These parameters differ from typical Pixhawk defaults and must be set correctly on Navio2:

| Parameter | Value | Reason |
|-----------|-------|--------|
| AHRS_ORIENTATION | 0 | Board mounted upright, arrow forward |
| INS_USE | 1 | Enable IMU 1 (MPU-9250) |
| INS_USE2 | 1 | Enable IMU 2 (LSM9DS1) |
| BATT_MONITOR | 4 | Voltage + current from power module |
| BATT_VOLT_PIN | 2 | Navio2 ADC channel for voltage |
| BATT_CURR_PIN | 3 | Navio2 ADC channel for current |
| GPS_TYPE | 2 | u-blox auto-configure |
| COMPASS_USE | 1 | Enable compass |
| COMPASS_EXTERNAL | 0 | Onboard compass (or 1 if using external GPS compass) |

## Initial Calibration Sequence

Perform these in order before first flight:

1. **Frame type:** Set FRAME_CLASS and FRAME_TYPE to match the airframe.
2. **Accelerometer calibration:** Initial Setup → Accel Calibration. Level + 5 orientations.
3. **Compass calibration:** Initial Setup → Compass. Rotate aircraft through all orientations.
4. **RC calibration:** Initial Setup → Radio Calibration. Move all sticks to extremes.
5. **ESC calibration:** Follow ArduPilot ESC calibration procedure for the ESC firmware in use.
6. **Battery monitor calibration:** Measure battery voltage with multimeter; adjust BATT_VOLT_MULT.

## Aux Channel Warning

**Auxiliary function switches on RC input channels 5–8 are not supported on Navio2.** Assigning AUX functions (flight mode switches, arming switches, etc.) to these channels causes erroneous PWM signals on the motor output channels. Map auxiliary functions only to channels 9 and above, or use the dedicated `RCx_OPTION` parameters on those higher channels.

## Relay and GPIO Output

The Navio2 servo rail pins double as GPIO outputs for triggering cameras, lights, or relay modules. ArduPilot's relay system maps a relay index to a GPIO pin number.

The relay pin numbering on Navio2:

| Servo rail pin | ArduPilot relay pin | GPIO sysfs number |
|---------------|--------------------|--------------------|
| 1–14 | 0–13 | 500–513 |
| IO17 | 14 | 514 |
| IO18 | 15 | 515 |
| LED R/G/B | 16–18 | 516–518 |

Set `RELAY_PIN` in Mission Planner's Full Parameter List to the desired relay pin index. Do not assign a relay pin to a channel also in use for PWM motor/servo output.

## Compass Configuration

Navio2 carries two magnetometers: the AK8963 embedded in the MPU-9250, and the magnetometer inside the LSM9DS1. ArduPilot disables the AK8963 by default and uses the LSM9DS1 magnetometer as the onboard compass (Compass #1). The AK8963 can be enabled as Compass #2 through Mission Planner's Compass page.

For best results, use an external compass (e.g., inside a Here3 or M8N GPS module) as Compass #1. External compasses are farther from motor and ESC current noise than the onboard chips. Set `COMPASS_EXTERN` and compass priority accordingly.

Onboard compass calibration in Mission Planner:
1. Initial Setup → Compass → Start.
2. Rotate the aircraft around all six axes until the progress bar completes.
3. Verify offset magnitudes (COMPASS_OFS_X/Y/Z) are below ±150. Larger offsets indicate magnetic interference at the mounting location.

## Connecting to a GCS

ArduPilot on Navio2 streams MAVLink over UDP (default port 14550). Set the TELEM1 flag to your GCS IP before starting ArduPilot.

### Mission Planner (Windows)

Download from [firmware.ardupilot.org](http://firmware.ardupilot.org/Tools/MissionPlanner/). Set connection type to UDP and port 14550 — it will auto-detect the incoming MAVLink stream.

### QGroundControl (cross-platform)

Download from [qgroundcontrol.com](https://docs.qgroundcontrol.com/en/getting_started/download_and_install.html). Add a UDP connection on port 14550 in Application Settings → Comm Links.

### APM Planner (Linux/Mac)

Download from [firmware.ardupilot.org](http://firmware.ardupilot.org/Tools/APMPlanner/). On Linux, add the user to the `dialout` group: `sudo adduser $USER dialout`. APM Planner listens on UDP 14550 automatically.

### MAVProxy (console)

MAVProxy is the preferred tool for scripting and forwarding:

```bash
mavproxy.py --master 127.0.0.1:14550 --out 192.168.1.100:14500
```

Replace `192.168.1.100` with the GCS IP. Add multiple `--out` flags to forward to several clients simultaneously. MAVProxy can also inject RTCM corrections to the GPS port via `--inject-rtcm`.

## Building ArduPilot from Source

To build a custom ArduPilot binary for Navio2:

```bash
# Cross-compile on an x86 Linux host
./waf configure --board=navio2
./waf copter
# Binary at: build/navio2/bin/arducopter
```

Copy the binary to the Raspberry Pi and place it in `/usr/bin/arducopter`, then restart the service.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Emlid Raspbian OS](raspbian-emlid.md)
- [ArduPilot](../../flight-controller-software/ardupilot.md)
- [Parameters](../../flight-controller-software/ardupilot/parameters.md)
- [GCS](../../flight-controller-software/ardupilot/gcs.md)
- [First Flight](../../flight-controller-software/ardupilot/first-flight.md)
- [Navio2 Power System](power-system.md)

## Sources

- [Installation and running — Emlid Navio2 docs](https://docs.emlid.com/navio2/ardupilot/installation-and-running/) — 2026-05-22
- [Building for NAVIO2 on RPi3 — ArduPilot Dev docs](https://ardupilot.org/dev/docs/building-for-navio2-on-rpi3.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
