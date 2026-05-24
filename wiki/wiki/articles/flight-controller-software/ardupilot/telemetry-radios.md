# Telemetry Radios — ArduPilot

Telemetry radios carry MAVLink between the vehicle and the ground station. They are the primary link for real-time HUD data, parameter editing in the field, mission upload, and log download over the air.

## Overview

ArduPilot accepts MAVLink on any serial port. A telemetry radio sits on one of those serial ports (TELEM1 or TELEM2) on the vehicle and its paired module connects to the GCS laptop or tablet. Configure the flight controller port with `SERIALx_PROTOCOL = 2` (MAVLink 2) and `SERIALx_BAUD` matching the radio.

## SiK Radios

The most widely used option. SiK firmware is open-source and runs on RFD900 and Holybro/3DR 915 MHz / 433 MHz modules.

### Configuration

```
SERIAL1_PROTOCOL = 2     (MAVLink 2)
SERIAL1_BAUD     = 57    (57600 baud)
```

SiK radios auto-pair: power both on together, and they connect within a few seconds.

### AT Commands

Configure via Mission Planner (Setup → Optional Hardware → SiK Radio) or directly via AT commands in a serial terminal (connect to one radio at 57600, type `+++` to enter command mode):

| Command | Description |
|---------|-------------|
| `ATI5` | Show all parameters |
| `ATS2=64` | Set AIR_SPEED to 64 kbps |
| `ATS3=25` | Set NET_ID (change to avoid interference) |
| `ATS4=20` | Set TX_POWER (20 dBm) |
| `ATS5=1` | Enable ECC (error correcting code, halves data rate) |
| `AT&W` | Write parameters to EEPROM |
| `ATZ` | Reboot radio |

Both radios in a pair must have matching `NET_ID` and `AIR_SPEED`. Default settings provide > 300 m range out of the box. Directional antennas on the ground station extend range to several kilometres.

### RFD900 Variants

RFD900 (900 MHz) and RFD868 (868 MHz) use the same SiK firmware but offer higher transmit power (1 W vs 100 mW) and more robust link budgets for long-range applications. The RFD900 draws up to 800 mA at full transmit power — use an external 5 V BEC rather than the TELEM port's 500 mA supply.

## WiFi Telemetry

### ESP8266 / ESP32

Low-cost WiFi modules connect to the flight controller serial port at 921600 baud and create a WiFi access point or client. The GCS connects via UDP to the module's IP address. Range is limited to ~100 m; useful for bench work and indoor tests.

DroneBridge for ESP32 extends range to ~1 km using custom antenna configuration and adds Bluetooth LE support.

```
SERIALx_PROTOCOL = 2
SERIALx_BAUD     = 921
```

## LTE / Cellular

For beyond-visual-line-of-sight (BVLOS) operations, cellular LTE modems provide unlimited range (constrained by coverage). Examples: Skydroid, Herelink, UAVCast 4G module. These typically run a VPN or peer-to-peer link to relay MAVLink between vehicle and GCS.

Latency is higher than RF radios (typically 50–200 ms round-trip) and depends on cellular network quality.

## ELRS and CRSF as MAVLink Passthrough

ExpressLRS and TBS Crossfire RC systems support bidirectional MAVLink over the same RF link as RC control. No separate telemetry radio is needed.

```
SERIALx_PROTOCOL = 2      (MAVLink 2)
SERIALx_BAUD     = 460    (460800 for ELRS; 416000 for CRSF)
RSSI_TYPE        = 5       (CRSF link quality)
```

Enable MAVLink forwarding in the transmitter module. The GCS connects to the transmitter's USB port. This is increasingly the preferred approach for FPV/long-range builds that already use ELRS.

See [RC Systems and RCMAP](rc-systems.md) for RC protocol setup.

## Frequency and Power Regulations

| Frequency | Region | Common use |
|-----------|--------|-----------|
| 915 MHz | Americas | SiK, RFD900, ELRS |
| 868 MHz | Europe | SiK EU version |
| 433 MHz | Worldwide | SiK, lower bandwidth |
| 2.4 GHz | Worldwide | WiFi, ELRS 2.4G |
| 5.8 GHz | Worldwide | WiFi, video |

Always check local regulations for permissible power levels. The FCC Part 97 amateur radio license allows higher power in the US with an appropriate callsign; most commercial operations use unlicensed ISM band power limits.

## GCS Failsafe Integration

The GCS failsafe monitors telemetry heartbeats — not the radio link quality directly. A radio failure that drops MAVLink heartbeats for `FS_GCS_TIMEOUT` seconds (default 5 s) triggers the GCS failsafe. See [Failsafes](failsafes.md).

## Related Concepts

- [MAVLink Protocol](mavlink.md)
- [Ground Control Stations](gcs.md)
- [RC Systems and RCMAP](rc-systems.md)
- [Failsafes](failsafes.md)

## Sources

- [SiK Telemetry Radio — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-sik-telemetry-radio.html) — 2026-05-22
- [SiK Radio Advanced Configuration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-3dr-radio-advanced-configuration-and-technical-information.html) — 2026-05-22
- [ESP32 WiFi Telemetry — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-esp32-telemetry.html) — 2026-05-22
- [Crossfire and ELRS — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-tbs-rc.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
