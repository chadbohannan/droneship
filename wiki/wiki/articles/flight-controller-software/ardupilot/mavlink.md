# MAVLink Protocol — ArduPilot

MAVLink (Micro Air Vehicle Link) is the binary telemetry and command protocol connecting ArduPilot to ground stations, companion computers, and other MAVLink-capable systems. Every GCS interaction, parameter change, mission upload, and offboard command travels as a MAVLink message.

## Overview

MAVLink is a lightweight, header-only library with implementations in C, C++, Python, and other languages. Messages are compact binary frames with a CRC. The protocol is connectionless — systems identify each other by system ID and component ID carried in every frame. ArduPilot acts as system ID 1, component ID 1 by default. Ground stations typically use system ID 255.

## Protocol Versions

### MAVLink v1

```
┌──────┬────┬─────┬────────┬──────────┬──────────┬─────────────────┬──────┐
│ 0xFE │ LEN│ SEQ │ SYSID  │ COMPID   │ MSGID(8) │ PAYLOAD (0-255) │ CRC  │
└──────┴────┴─────┴────────┴──────────┴──────────┴─────────────────┴──────┘
  1B     1B   1B    1B        1B          1B          variable         2B
```

- Start byte: `0xFE`
- 8-bit message ID (max 256 message types)
- 6-byte header + 2-byte CRC = 8 bytes overhead

### MAVLink v2

```
┌──────┬────┬─────┬─────┬────────┬──────────┬──────────┬─────────────────┬────────────┬──────┐
│ 0xFD │ LEN│INCOMPAT│COMPAT│ SEQ │ SYSID  │ COMPID   │ MSGID (24-bit) │ PAYLOAD    │ CRC  │
└──────┴────┴─────┴─────┴────────┴──────────┴──────────┴─────────────────┴────────────┴──────┘
  1B     1B   1B    1B    1B   1B     1B          3B          variable       +13B sig    2B
```

- Start byte: `0xFD`
- 24-bit message ID (16 million+ message types)
- Incompatibility and compatibility flags for safe protocol evolution
- Optional 13-byte message signature for authentication
- 10-byte header (4 bytes more than v1, but vastly more capable)

Use MAVLink v2 for all new builds. Set `SERIAL*_PROTOCOL = 2`. MAVLink v1 is still required for some older radios.

## Common Messages

| Message | ID | Direction | Description |
|---------|-----|-----------|-------------|
| `HEARTBEAT` | 0 | Both | System presence; 1 Hz minimum; contains vehicle type and mode |
| `ATTITUDE` | 30 | FC→GCS | Roll, pitch, yaw and rates |
| `GLOBAL_POSITION_INT` | 33 | FC→GCS | Fused GPS position (lat/lon/alt in 1e7 degrees and mm) |
| `BATTERY_STATUS` | 147 | FC→GCS | Voltage per cell, current, remaining capacity |
| `RC_CHANNELS` | 65 | FC→GCS | Raw RC input values |
| `STATUSTEXT` | 253 | FC→GCS | Human-readable status message with severity |
| `COMMAND_LONG` | 76 | GCS→FC | Execute a command (param1–param7) |
| `PARAM_REQUEST_READ` | 20 | GCS→FC | Request one parameter by name or index |
| `PARAM_VALUE` | 22 | FC→GCS | Parameter value response |
| `PARAM_SET` | 23 | GCS→FC | Set a parameter |
| `MISSION_ITEM_INT` | 73 | GCS→FC | Mission waypoint (coordinates in 1e7 degrees) |
| `REQUEST_DATA_STREAM` | 66 | GCS→FC | Request message group at rate (Hz) |

### HEARTBEAT Fields

`type` (vehicle class), `autopilot` (firmware type), `base_mode` (arm status + mode flags), `custom_mode` (ArduPilot flight mode number), `system_status` (boot/active/standby/emergency/poweroff).

### COMMAND_LONG

The universal command envelope. `command` is a `MAV_CMD_*` enum (e.g., `MAV_CMD_DO_SET_MODE = 176`, `MAV_CMD_COMPONENT_ARM_DISARM = 400`). `param1`–`param7` carry command-specific arguments.

## System and Component IDs

| System | SYSID | COMPID |
|--------|-------|--------|
| ArduPilot | 1 (`SYSID_THISMAV`) | 1 (MAV_COMP_ID_AUTOPILOT1) |
| Ground station | 255 | 1 |
| Companion computer | 1 (shared) | varies |
| Camera, gimbal | 1 (shared) | varies |

`SYSID_THISMAV` must be unique across all vehicles on the same RF link in multi-drone operations.

A message with target system/component = 0 is broadcast to all. ArduPilot routes messages to all known channels unless a specific target is identified.

## Message Signing (v2)

MAVLink v2 signing uses a 32-byte pre-shared key and appends a 13-byte signature (link ID + 6-byte timestamp + 6-byte HMAC-SHA256 truncated). Signing provides authentication and replay protection but not encryption — payloads remain plaintext.

Configure signing via the `SETUP_SIGNING` message from a trusted GCS connection. Once enabled, unsigned messages are rejected.

## Telemetry Rates

### SR* Parameters (Legacy)

`SR0_*` through `SR3_*` set default streaming rates (Hz) for message groups on each serial port:

| Parameter | Message group |
|-----------|--------------|
| `SRx_EXTRA1` | Attitude (ATT), AHRS |
| `SRx_EXTRA2` | VFR HUD |
| `SRx_EXTRA3` | Vibration, battery, home |
| `SRx_POSITION` | Position, velocity |
| `SRx_RC_CHAN` | RC channels |
| `SRx_RAW_SENS` | Raw IMU |

### SET_MESSAGE_INTERVAL (Modern)

More precise. Send `COMMAND_LONG` with `command = MAV_CMD_SET_MESSAGE_INTERVAL (511)`, `param1 = message ID`, `param2 = interval in microseconds` (e.g., 100000 = 10 Hz). GCS software typically configures this automatically on connect.

## Serial Port Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `SERIAL0_PROTOCOL` | 2 | USB (always MAVLink) |
| `SERIAL1_PROTOCOL` | 2 | Telem1: MAVLink 2 |
| `SERIAL1_BAUD` | 57 | 57600 baud for SiK radios |
| `SERIAL2_PROTOCOL` | 2 | Telem2: MAVLink 2 |
| `SERIAL2_BAUD` | 921 | 921600 for companion computer |

Reboot after changing `SERIAL*_PROTOCOL`.

## MAVLink Inspector (Mission Planner)

Press **Ctrl+F** → Advanced Tools → MAVLink Inspector. Displays live message rates, field values, and per-message statistics. Use it to verify streams are arriving and to inspect raw telemetry values for debugging.

## Related Concepts

- [Ground Control Stations](gcs.md)
- [Companion Computers](companion-computers.md)
- [Telemetry Radios](telemetry-radios.md)
- [Parameters](parameters.md)
- [DroneKit](../../programming/dronekit.md)
- [MAVSDK](../../programming/mavsdk.md)
- [PyMAVLink](../../programming/pymavlink.md)

## Sources

- [MAVLink Basics — ArduPilot dev docs](https://ardupilot.org/dev/docs/mavlink-basics.html) — 2026-05-22
- [MAVLink Routing in ArduPilot — ArduPilot dev docs](https://ardupilot.org/dev/docs/mavlink-routing-in-ardupilot.html) — 2026-05-22
- [MAVLink v2 — mavlink.io](https://mavlink.io/en/guide/mavlink_2.html) — 2026-05-22
- [Requesting Data from the Autopilot — ArduPilot dev docs](https://ardupilot.org/dev/docs/mavlink-requesting-data.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
