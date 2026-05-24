# emlidtool

Pre-installed Navio2 CLI for system diagnostics, ArduPilot vehicle configuration, and RCIO co-processor firmware management.

## Overview

`emlidtool` is a command-line utility included in the Emlid Raspbian image. It is the recommended way to configure which ArduPilot vehicle binary runs at boot, run hardware self-tests, and update the RCIO co-processor firmware. All subcommands require root; run with `sudo`.

The four subcommands are `info`, `test`, `ardupilot`, and `rcio`. Each is described below.

```
sudo emlidtool <subcommand> [options]
```

## info

Displays hardware and software identification for the current Navio2 / Raspberry Pi system.

```bash
sudo emlidtool info
```

Example output:
```
Vendor:  Emlid Limited
Product: Navio 2
Issue:   Emlid 2020-02-17 a1b2c3d
Kernel:  4.19.97-emlid-v7+
```

Use `info` to record the exact image version and kernel before filing a bug report or when updating firmware.

## test

Runs functional diagnostics on Navio2 hardware sensors. Without arguments it tests all supported devices; pass a sensor name to test a single one.

```bash
sudo emlidtool test          # test all sensors
sudo emlidtool test imu      # test IMUs only
sudo emlidtool test gps      # test GNSS receiver
sudo emlidtool test baro     # test barometer
sudo emlidtool test adc      # test ADC channels
```

The test subcommand verifies:
- Both IMUs (MPU-9250 via SPI0, LSM9DS1 via SPI1/AUX) — checks device ID registers
- MS5611 barometer — attempts a pressure/temperature conversion cycle
- u-blox GNSS receiver — checks SPI communication and parses a UBX message
- ADC channels — reads each RCIO ADC channel for a non-zero response
- RCIO co-processor — checks the `/sys/kernel/rcio/status/alive` register

A PASS on all sensors confirms the Raspberry Pi → Navio2 HAT interface is working before investing time in software configuration. Run `emlidtool test` first on any new build or after a physical impact.

## ardupilot

Configures which ArduPilot vehicle binary runs at boot and manages the systemd service. This is the standard way to select between ArduCopter, ArduPlane, ArduRover, and ArduSub without manually editing configuration files.

```bash
sudo emlidtool ardupilot configure        # full TUI
sudo emlidtool ardupilot configure --no-tui   # non-interactive for scripting
sudo emlidtool ardupilot help             # print configuration guide
```

### TUI workflow

When run without `--no-tui`, `ardupilot configure` presents a terminal user interface (TUI) — a full-screen interactive menu in the SSH session — with the following decisions:

1. **RCIO firmware check:** Before showing any options, the tool checks the RCIO co-processor firmware version. If outdated, it prompts to update now. Decline only if you need to diagnose the RCIO separately; an outdated RCIO can cause erratic PWM or RC input behavior.

2. **Vehicle type:** Select from ArduCopter, ArduPlane, ArduRover, ArduSub, and available version variants of each.

3. **Boot behavior:** Whether ArduPilot should start automatically on every boot (enables the systemd service) or remain manually started.

4. **Immediate action:** Whether to start the service now, stop it, or leave it unchanged.

After confirming, the tool writes the selection to the vehicle-specific configuration file (e.g., `/etc/default/arducopter`) and reloads systemd.

### Configuration files written

The tool creates or updates `/etc/default/arducopter` (or the equivalent for the selected vehicle). This file is where you subsequently add GCS IP addresses, telemetry port assignments, and other startup flags:

```bash
# /etc/default/arducopter — edited after emlidtool configure
TELEM1="-A udp:192.168.1.100:14550"
TELEM2="-C /dev/ttyUSB0"
ARDUPILOT_OPTS="$TELEM1 $TELEM2"
```

See [Navio2 ArduPilot Configuration](ardupilot-configuration.md) for the full flag reference.

### Non-interactive use

`--no-tui` reads vehicle selection from environment variables or prompts on stdin, enabling automated provisioning:

```bash
echo "1" | sudo emlidtool ardupilot configure --no-tui   # select option 1 (copter)
```

## rcio

Manages the RCIO co-processor firmware. The co-processor runs independent firmware; new Emlid image releases often bundle updated RCIO firmware for bug fixes and compatibility with newer ArduPilot HAL changes.

```bash
sudo emlidtool rcio check              # check current vs. available version
sudo emlidtool rcio update             # flash bundled firmware
sudo emlidtool rcio update -f          # force update even if versions match
sudo emlidtool rcio update -p /path/to/firmware.bin   # use specific file
sudo emlidtool rcio update -q -y       # non-interactive (suppress + auto-confirm)
```

| Flag | Meaning |
|------|---------|
| `check` | Report firmware version and whether update is available |
| `update` | Flash latest bundled RCIO firmware |
| `-f` | Force flash regardless of version comparison |
| `-p path` | Use a specific firmware binary |
| `-q` | Suppress progress output |
| `-y` | Skip confirmation prompt |

### Update procedure internals

1. Stops ArduPilot if running (to release SPI bus).
2. Issues a bootloader entry command to the co-processor via SPI.
3. Transfers the firmware binary page-by-page over SPI.
4. Verifies the programmed firmware checksum.
5. Resets the co-processor into application mode.

The update takes about 30 seconds. Power loss during flashing leaves the co-processor in bootloader mode — re-run `emlidtool rcio update` to recover.

### Known RCIO firmware issues

**Update loop:** After `apt upgrade` of Emlid packages, some users find `ardupilot configure` repeatedly prompts for an RCIO update even after it reports success. The firmware version register stays at `0x0`. This indicates the flash verification passed but the version was not written correctly. Fix: run `sudo emlidtool rcio update -f` to force a reflash, then power-cycle the board (full shutdown, not just reboot).

**"Board does not support RCIO":** This error appears when the Emlid kernel modules are not loaded or the Navio2 is not correctly seated. Verify:
```bash
lsmod | grep rcio        # should show rcio_spi and rcio_core
cat /sys/kernel/rcio/status/alive   # should return 1
```
If `lsmod` shows nothing, the kernel modules failed to load. Check `dmesg | grep rcio` for SPI initialization errors and confirm the Navio2 extension header is fully engaged.

**ArduPilot service must be stopped first:** If ArduPilot is running and holding the SPI bus when `rcio update` is called, the flash will time out. `emlidtool` usually handles this automatically, but if it fails, stop manually:
```bash
sudo systemctl stop ardupilot
sudo emlidtool rcio update
sudo systemctl start ardupilot
```

## RCIO Connectivity Quick Check

Read the co-processor health register directly:

```bash
cat /sys/kernel/rcio/status/alive
# 1 = co-processor online
# 0 = not responding — check physical seating and kernel modules
```

## Workflow: New Board Setup

A clean first-boot sequence using emlidtool:

```bash
# 1. Confirm hardware is recognized
sudo emlidtool info

# 2. Run sensor self-test
sudo emlidtool test

# 3. Update RCIO firmware to latest
sudo emlidtool rcio update

# 4. Select vehicle type and enable autostart
sudo emlidtool ardupilot configure

# 5. Add GCS IP to config file
sudo nano /etc/default/arducopter
# → add: ARDUPILOT_OPTS="-A udp:192.168.1.100:14550"

# 6. Restart and verify
sudo systemctl restart ardupilot
sudo journalctl -u ardupilot -f
```

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Emlid Raspbian OS](raspbian-emlid.md)
- [Navio2 ArduPilot Configuration](ardupilot-configuration.md)
- [RCIO Co-Processor](rcio.md)
- [Navio2 Power System](power-system.md)
- [Navio2 Hardware Setup](hardware-setup.md)

## Sources

- [Emlidtool — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/emlidtool/) — 2026-05-22
- [Installation and running — Emlid Navio2 docs](https://docs.emlid.com/navio2/ardupilot/installation-and-running/) — 2026-05-22
- [rcio-dkms releases — GitHub (emlid/rcio-dkms)](https://github.com/emlid/rcio-dkms/releases) — 2026-05-22

<!-- linted: 2026-05-23 -->
