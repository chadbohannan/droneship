# Ground Control Stations — ArduPilot

A ground control station (GCS) is the software interface between operator and autopilot. It connects via MAVLink over USB, serial radio, or network; provides real-time telemetry; enables parameter configuration; and manages mission upload and log download.

## Overview

ArduPilot supports several GCS applications, each suited to different workflows. Mission Planner is the most feature-complete for Windows users and the primary documentation reference. QGroundControl offers cross-platform and mobile support. MAVProxy is a minimal CLI tool used for development, automation, and routing.

Connection is established via a serial port (USB, UART, or radio) or network socket. The autopilot streams MAVLink telemetry at configured rates and accepts commands in return.

## Mission Planner

Mission Planner (Windows, macOS) is the reference GCS for ArduPilot. It provides six primary screens:

| Screen | Purpose |
|--------|---------|
| **Flight Data (DATA)** | Real-time HUD, map, arming, mode control |
| **Flight Plan (PLAN)** | Waypoint mission design and upload |
| **Initial Setup (SETUP)** | Calibrations, mandatory hardware configuration |
| **Config/Tuning (CONFIG)** | Full parameter list, PID tuning, advanced config |
| **Simulation** | SITL integration |

### Key Workflows

**Parameters**: CONFIG → Full Parameter List. Search by name or description. Save/load `.param` files. Write changes to vehicle with the Write Parameters button.

**Log download**: Flight Data → DataFlash Logs → Download DataFlash Log Via MAVLink. Logs save to `MissionPlanner/logs/COPTER/`.

**MAVLink Inspector**: Ctrl+F → Advanced Tools → MAVLink Inspector. Shows real-time message rates and field values — useful for verifying telemetry stream health.

**Mission upload**: PLAN → design waypoints → Write. Read downloads the current mission from the vehicle.

**Motor test**: Setup → Optional Hardware → Motor Test. Tests individual motors by letter with props off.

## QGroundControl

Cross-platform (Windows, macOS, Linux, Android, iOS). Preferred for field operations and mobile use. Feature gaps versus Mission Planner on ArduPilot:

- No polygon fence support
- No rally points
- No terrain following
- Less granular parameter access

Best for: ready-to-fly users, tablet/phone field control, PX4 crossover builds.

## MAVProxy

Command-line GCS and routing daemon. Python-based. Runs on Linux/macOS/Windows; ships with ArduPilot's SITL.

### Connection and Routing

```bash
# Connect to vehicle via USB
mavproxy.py --master=/dev/ttyUSB0 --baud=57600

# Route to GCS on network + companion computer
mavproxy.py --master=/dev/ttyAMA0 --baudrate=921600 \
  --out=192.168.1.10:14550 --out=127.0.0.1:14551
```

### Key Commands

| Command | Action |
|---------|--------|
| `arm throttle` | Arm motors |
| `disarm` | Disarm |
| `mode loiter` | Change flight mode |
| `param show ATC_RAT_RLL_P` | Display parameter |
| `param set ATC_RAT_RLL_P 0.15` | Set parameter |
| `param show *` | List all parameters |
| `wp list` | Show mission waypoints |
| `wp load mission.txt` | Upload mission from file |
| `log download` | Download latest log |
| `rc 3 1500` | Override RC channel 3 to 1500 µs |
| `graph ATT.Roll ATT.DesRoll` | Plot fields |

MAVProxy is the router of choice for companion computer setups — it forwards MAVLink between the flight controller serial port and multiple network endpoints simultaneously. See [Companion Computers](companion-computers.md).

## Other Options

| GCS | Platform | Notes |
|-----|---------|-------|
| APM Planner 2 | macOS, Linux | Reduced features; best Mac native option |
| Tower (DroidPlanner) | Android | Follow-me, map-based control |
| MAV Pilot | iOS | Mobile monitoring |

## Telemetry Link Setup

### Serial Port Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| `SERIAL1_PROTOCOL` | 2 | MAVLink 2 on Telem1 |
| `SERIAL1_BAUD` | 57 | 57600 baud for SiK radios |
| `SERIAL2_PROTOCOL` | 2 | MAVLink 2 on Telem2 |
| `BRD_SER1_RTSCTS` | 2 | Hardware flow control on Telem1 |

USB (Serial0) always runs MAVLink at 115200 baud. Telem1 defaults to 57600 for radio telemetry. Telem2 is commonly used for companion computer or second GCS.

### Network Connection (ArduPilot 4.5+)

```
NET_ENABLE   = 1
NET_IPADDR0  = 192
NET_IPADDR1  = 168
NET_IPADDR2  = 144
NET_IPADDR3  = 14
NET_P1_TYPE  = 2    (UDP server)
NET_P1_PORT  = 14550
```

### Stream Rates (SR* Parameters)

`SR0_*` through `SR3_*` control telemetry data rates (Hz) per serial port. Setting `SRx_EXTRA1 = 10` streams attitude data at 10 Hz on port x.

Modern GCS software uses `SET_MESSAGE_INTERVAL` (MAV_CMD 511) for per-message rate control, which is more precise than the legacy `REQUEST_DATA_STREAM` groups. Most GCS auto-configure these on connect.

## Related Concepts

- [MAVLink Protocol](mavlink.md)
- [Telemetry Radios](telemetry-radios.md)
- [Mission Planning](mission-planning.md)
- [Logging and Analysis](logging.md)
- [Parameters](parameters.md)
- [Companion Computers](companion-computers.md)

## Sources

- [Choosing a Ground Station — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-choosing-a-ground-station.html) — 2026-05-22
- [Mission Planner Features — Mission Planner docs](https://ardupilot.org/planner/docs/mission-planner-features.html) — 2026-05-22
- [MAVProxy Cheatsheet — MAVProxy docs](https://ardupilot.org/mavproxy/docs/getting_started/cheatsheet.html) — 2026-05-22
- [Telemetry Port Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-telemetry-port-setup.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
