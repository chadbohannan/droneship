# MAVProxy

ArduPilot's developer-oriented command-line ground station and MAVLink router, used in [SITL](sitl.md), companion computer workflows, and any scenario requiring headless or scripted autopilot access.

## Overview

MAVProxy is a Python-based GCS and MAVLink multiplexer maintained by the ArduPilot project. Unlike Mission Planner or QGroundControl, it runs entirely in the terminal with no GUI requirement, making it the right tool for SSH sessions, Raspberry Pi companion computers, automated testing, and SITL. MAVProxy opens a single connection to the autopilot (the *master*) and simultaneously forwards MAVLink traffic to any number of *output* endpoints — a GUI GCS, a companion script, a logger, and a second observer can all receive the same stream at once.

MAVProxy ships as a dependency of ArduPilot's SITL and launches automatically when you run `sim_vehicle.py`. On Navio2, it is the standard bridge between the ArduPilot process (which streams to `127.0.0.1:14550`) and a remote GCS on the ground network.

## Installation

```bash
# Linux/macOS (Python 3)
pip3 install MAVProxy

# Verify
mavproxy.py --version
```

On Debian/Ubuntu you can also install via apt:

```bash
sudo apt install python3-mavproxy
```

Windows users should follow the [MAVProxy Windows installation guide](https://ardupilot.org/mavproxy/docs/getting_started/download_and_installation.html#windows); the recommended method is WSL2.

## Connecting to a Vehicle

Specify the master connection with `--master`. MAVProxy accepts serial ports, UDP sockets, and TCP sockets interchangeably.

```bash
# USB serial (typical for bench testing)
mavproxy.py --master=/dev/ttyUSB0 --baud=57600

# UART (companion computer on Navio2)
mavproxy.py --master=/dev/ttyAMA0 --baud=921600

# UDP (ArduPilot streaming over network)
mavproxy.py --master=udp:127.0.0.1:14550

# TCP (useful for SITL or network-only setups)
mavproxy.py --master=tcp:192.168.1.5:5760
```

On Navio2, ArduPilot is configured to stream MAVLink to `udp:127.0.0.1:14550` by default via the `-A` flag in `/etc/default/arducopter`. MAVProxy connects to that port as master, then routes to the GCS on the ground network:

```bash
mavproxy.py --master=127.0.0.1:14550 --out=192.168.1.2:14500
```

Where `192.168.1.2` is the GCS laptop, not the Raspberry Pi.

## MAVLink Routing

MAVProxy's core value is routing: one master, multiple outputs. Every `--out` target receives a full copy of the MAVLink stream and can also inject commands upstream.

```bash
# Route to GCS + companion script simultaneously
mavproxy.py --master=/dev/ttyAMA0 \
  --out=192.168.1.10:14550 \
  --out=127.0.0.1:14551

# SITL → Mission Planner on Windows + logging script
mavproxy.py --master=tcp:127.0.0.1:5760 \
  --out=udpout:192.168.1.5:14550 \
  --out=udpout:127.0.0.1:14560 \
  --streamrate=10
```

Supported connection string prefixes:

| Prefix | Example | Description |
|--------|---------|-------------|
| (bare) | `192.168.1.2:14550` | UDP out to host:port |
| `udpin:` | `udpin:0.0.0.0:14550` | Listen for incoming UDP |
| `udpout:` | `udpout:192.168.1.2:14550` | Send UDP to host:port |
| `tcp:` | `tcp:127.0.0.1:5760` | TCP client |
| `tcpin:` | `tcpin:0.0.0.0:5760` | TCP server |
| `/dev/ttyX` | `/dev/ttyUSB0` | Serial port |

## Interactive Console

When started interactively, MAVProxy presents a command prompt with optional console and map windows:

```bash
mavproxy.py --master=/dev/ttyUSB0 --console --map
```

`--console` opens a status panel showing attitude, GPS fix, battery, and mode. `--map` opens a live map window tracking vehicle position.

### Useful Commands

| Command | Effect |
|---------|--------|
| `arm throttle` | Arm motors (bypasses pre-arm checks) |
| `disarm` | Disarm |
| `mode loiter` | Switch to Loiter mode |
| `mode guided` | Switch to Guided mode |
| `param show ATC_RAT_RLL_P` | Display a parameter value |
| `param set ATC_RAT_RLL_P 0.15` | Write a parameter |
| `param save params.parm` | Save all params to file |
| `param load params.parm` | Upload params from file |
| `wp list` | Display current mission |
| `wp load mission.txt` | Upload mission from file |
| `wp save mission.txt` | Download mission to file |
| `rc 3 1500` | Override RC channel 3 to 1500 µs |
| `rc all 0` | Release all RC overrides |
| `log list` | List onboard logs |
| `log download` | Download latest log |
| `graph ATT.Roll ATT.DesRoll` | Live plot from telemetry |
| `link list` | Show active link statistics |
| `status` | Dump all received MAVLink message values |
| `exit` | Quit MAVProxy |

## Module System

MAVProxy loads optional modules that add capabilities without changing the core tool. Modules are loaded at startup with `--load-module` or at runtime with `module load`.

```bash
# Load at startup
mavproxy.py --master=... --load-module=joystick --load-module=battery

# Load interactively
module load parrot
module list
```

Key built-in modules:

| Module | Purpose |
|--------|---------|
| `console` | Status window (loaded by `--console`) |
| `map` | Live map (loaded by `--map`) |
| `graph` | Real-time telemetry plots |
| `joystick` | Joystick/gamepad input |
| `battery` | Battery warnings |
| `relay` | Relay output control |
| `log` | Log download management |
| `wp` | Waypoint / mission management |
| `fence` | Geofence management |
| `rally` | Rally point management |
| `param` | Parameter management |
| `rc` | RC override |
| `calibration` | Accelerometer and compass calibration |
| `signing` | MAVLink 2 packet signing |

## Scripting with MAVProxy

MAVProxy can run Python scripts that interact with the MAVLink stream. Use `--script` or the `script` command interactively:

```bash
mavproxy.py --master=... --script=my_mission.py
```

Scripts access the `mpstate` API to send commands and read telemetry. For production companion computer scripts, [DroneKit](../../programming/dronekit.md) or [MAVSDK](../../programming/mavsdk.md) provide higher-level abstractions; MAVProxy scripts are better suited for one-off automation tasks.

## SITL Integration

MAVProxy is the default GCS launched by `sim_vehicle.py`. SITL opens a TCP server on `127.0.0.1:5760`; MAVProxy connects as master and re-exposes traffic over UDP 14550 and 14551 for GCS tools.

```bash
# sim_vehicle.py starts MAVProxy automatically
sim_vehicle.py -v ArduCopter --console --map

# Connect Mission Planner to UDP 14550 on the same machine
# Or forward to a remote GCS:
sim_vehicle.py -v ArduCopter \
  --out=192.168.1.5:14550
```

Inside the SITL MAVProxy prompt, all the usual commands work. The `graph` module is especially useful here — `graph ATT.Roll ATT.DesRoll` shows real-time roll tracking during a tuning session.

## Headless / Daemon Mode

For companion computers, run MAVProxy as a background routing daemon:

```bash
mavproxy.py --master=/dev/ttyAMA0 --baud=921600 \
  --out=192.168.1.10:14550 \
  --daemon --state-basedir=/var/mavproxy &
```

`--daemon` suppresses the interactive prompt. `--state-basedir` sets where MAVProxy saves its state files (parameters cache, mission cache). Wrap in a systemd unit for automatic start:

```ini
[Unit]
Description=MAVProxy router
After=network.target

[Service]
ExecStart=/usr/local/bin/mavproxy.py \
  --master=/dev/ttyAMA0 --baud=921600 \
  --out=192.168.1.10:14550 --daemon \
  --state-basedir=/var/mavproxy
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Related Concepts

- [SITL — Software in the Loop](sitl.md)
- [MAVLink](mavlink.md)
- [Ground Control Stations](gcs.md)
- [Companion Computers](companion-computers.md)
- [DroneKit](../../programming/dronekit.md)
- [pymavlink](../../programming/pymavlink.md)

## Sources

- [MAVProxy Documentation](https://ardupilot.org/mavproxy/) — 2026-05-22
- [Download and Installation — MAVProxy docs](https://ardupilot.org/mavproxy/docs/getting_started/download_and_installation.html) — 2026-05-22
- [MAVProxy Cheatsheet — MAVProxy docs](https://ardupilot.org/mavproxy/docs/getting_started/cheatsheet.html) — 2026-05-22
- [Installation and Running ArduPilot — Emlid Navio2 docs](https://docs.emlid.com/navio2/ardupilot/installation-and-running/) — 2026-05-22

<!-- linted: 2026-05-23 -->
