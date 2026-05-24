# DroneKit-Python

DroneKit-Python is a Python library for communicating with ArduPilot vehicles via MAVLink. It wraps PyMAVLink to provide a high-level `Vehicle` object with telemetry attributes and methods for arming, mode changes, goto commands, and mission upload.

## Overview

DroneKit abstracts MAVLink message handling into a Vehicle object. You connect, read attributes, and send commands without parsing MAVLink frames directly. It works with real hardware over serial or UDP, with [SITL](../flight-controller-software/ardupilot/sitl.md) over TCP/UDP, and on companion computers connected to the flight controller.

> **Maintenance status**: DroneKit-Python's last release was v2.9.1 (April 2017). Python 3.10+ is not fully supported. For new projects, [MAVSDK](mavsdk.md) is the recommended alternative.

## Installation

```bash
pip install dronekit
```

Python 3.7–3.9 recommended. Python 3.10+ may have compatibility issues.

## Connecting

```python
from dronekit import connect, VehicleMode

# Serial (companion computer)
vehicle = connect('/dev/ttyAMA0', baud=921600, wait_ready=True)

# UDP (SITL or telemetry radio GCS)
vehicle = connect('udp:127.0.0.1:14550', wait_ready=True)

# TCP (SITL)
vehicle = connect('tcp:127.0.0.1:5760', wait_ready=True)
```

`wait_ready=True` blocks until all vehicle attributes are populated.

## Reading Telemetry

Position and velocity are reported in NED (North-East-Down) coordinates — a local Cartesian frame where X points north, Y points east, and Z points down from the home position.

```python
print(vehicle.location.global_frame)      # lat, lon, alt (absolute)
print(vehicle.location.local_frame)       # NED relative to home
print(vehicle.attitude)                   # roll, pitch, yaw (radians)
print(vehicle.velocity)                   # NED velocity (m/s)
print(vehicle.battery)                    # voltage, current, level
print(vehicle.mode)                       # VehicleMode("GUIDED") etc.
print(vehicle.armed)                      # True/False
print(vehicle.gps_0)                      # GPS fix type, satellites
print(vehicle.airspeed)                   # m/s
print(vehicle.groundspeed)               # m/s
print(vehicle.heading)                    # 0–360°
```

## Arming and Mode Control

```python
# Arm
vehicle.mode = VehicleMode("GUIDED")
vehicle.armed = True

# Wait until armed
while not vehicle.armed:
    time.sleep(1)

# Takeoff to 10 m
vehicle.simple_takeoff(10)

# Wait until altitude reached
while True:
    if vehicle.location.global_relative_frame.alt >= 9.5:
        break
    time.sleep(1)
```

## Goto (Guided Mode)

```python
from dronekit import LocationGlobalRelative

target = LocationGlobalRelative(-35.363261, 149.165230, 10)  # lat, lon, alt(m)
vehicle.simple_goto(target)

# With speed override
vehicle.simple_goto(target, groundspeed=5)
```

`simple_goto` sets a position target in Guided mode. The vehicle navigates there autonomously.

## Velocity Commands

```python
import dronekit

def send_ned_velocity(vx, vy, vz, duration):
    """Send NED velocity command (m/s). vz positive = down."""
    msg = vehicle.message_factory.set_position_target_local_ned_encode(
        0,                          # time_boot_ms
        0, 0,                       # target system, component
        mavutil.mavlink.MAV_FRAME_LOCAL_NED,
        0b0000111111000111,         # type_mask: velocity only
        0, 0, 0,                    # position (ignored)
        vx, vy, vz,                 # velocity
        0, 0, 0,                    # acceleration (ignored)
        0, 0)                       # yaw, yaw_rate (ignored)
    for _ in range(0, duration):
        vehicle.send_mavlink(msg)
        time.sleep(1)
```

## Mission Upload

```python
from dronekit import Command
from pymavlink import mavutil

cmds = vehicle.commands
cmds.download()
cmds.wait_ready()
cmds.clear()

# Takeoff
cmds.add(Command(0, 0, 0, mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT,
    mavutil.mavlink.MAV_CMD_NAV_TAKEOFF, 0, 0, 0, 0, 0, 0, 0, 0, 10))

# Waypoint
cmds.add(Command(0, 0, 0, mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT,
    mavutil.mavlink.MAV_CMD_NAV_WAYPOINT, 0, 0, 0, 0, 0, 0,
    -35.361354, 149.165218, 20))

# RTL
cmds.add(Command(0, 0, 0, mavutil.mavlink.MAV_FRAME_GLOBAL_RELATIVE_ALT,
    mavutil.mavlink.MAV_CMD_NAV_RETURN_TO_LAUNCH, 0, 0, 0, 0, 0, 0, 0, 0, 0))

cmds.upload()
vehicle.mode = VehicleMode("AUTO")
```

## Closing

```python
vehicle.close()
```

## Limitations

- Python 3.10+ incompatible (dependency issues)
- No asyncio support — blocking API design
- Unmaintained since 2017; use [MAVSDK](mavsdk.md) for new projects
- Mission upload requires re-downloading commands before adding new ones after `clear()`

## Related Concepts

- [MAVLink Protocol](../flight-controller-software/ardupilot/mavlink.md)
- [Companion Computers](../flight-controller-software/ardupilot/companion-computers.md)
- [MAVSDK](mavsdk.md)
- [PyMAVLink](pymavlink.md)
- [SITL Simulation](../flight-controller-software/ardupilot/sitl.md)

## Sources

- [DroneKit-Python Quick Start](https://dronekit-python.readthedocs.io/en/latest/guide/quick_start.html) — 2026-05-22
- [DroneKit-Python Guided Mode](https://dronekit-python.readthedocs.io/en/latest/guide/copter/guided_mode.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
