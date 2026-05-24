# MAVSDK

MAVSDK is the modern multi-language SDK for MAVLink-based autopilots including ArduPilot. It uses a gRPC server architecture with auto-generated language bindings, providing an async-first API for C++, Python, Swift, Java, Go, and Rust.

## Overview

MAVSDK's C++ core (`mavsdk_server`) handles the actual MAVLink connection and provides a plugin API. Language-specific clients communicate with the server via gRPC. In Python, `mavsdk_server` is embedded in the package and launched automatically.

MAVSDK is the recommended successor to [DroneKit-Python](dronekit.md) for new projects — it is actively maintained, supports Python 3.7+, and uses asyncio throughout.

## Installation

```bash
pip install mavsdk
```

For C++, clone the repository and build with CMake. Pre-built binaries are available on GitHub Releases.

## Connecting

```python
import asyncio
from mavsdk import System

async def run():
    drone = System()
    await drone.connect(system_address="udp://:14540")
    # Or:
    # await drone.connect("serial:///dev/ttyUSB0:57600")
    # await drone.connect("tcp://192.168.1.100:5760")

    print("Waiting for drone to connect...")
    async for state in drone.core.connection_state():
        if state.is_connected:
            print("Connected!")
            break

asyncio.run(run())
```

When `system_address` is empty, MAVSDK launches an embedded server. When provided, it connects to an existing `mavsdk_server` process.

## Plugin Architecture

MAVSDK organises functionality into plugins:

| Plugin | Purpose |
|--------|---------|
| `action` | Arm, disarm, takeoff, land, RTL, goto |
| `telemetry` | Position, attitude, battery, flight mode streams |
| `offboard` | Real-time velocity/position setpoints |
| `mission` | Mission upload, download, execute |
| `param` | Read/write parameters |
| `camera` | Camera control and capture |
| `gimbal` | Gimbal control |
| `info` | Vehicle version and identification |

## Basic Flight

```python
async def fly():
    drone = System()
    await drone.connect(system_address="udp://:14540")

    # Arm
    await drone.action.arm()

    # Takeoff to 10 m
    await drone.action.takeoff()
    await asyncio.sleep(10)

    # Goto position
    await drone.action.goto_location(
        latitude_deg=-35.3632,
        longitude_deg=149.1652,
        absolute_altitude_m=580.0,   # MSL altitude
        yaw_deg=float('nan'))        # nan = maintain current yaw

    await asyncio.sleep(15)

    # Land
    await drone.action.land()
```

## Telemetry Streams

All telemetry is async generator-based:

```python
async def print_position(drone):
    async for position in drone.telemetry.position():
        print(f"Lat: {position.latitude_deg}, "
              f"Alt: {position.relative_altitude_m} m")

async def print_battery(drone):
    async for battery in drone.telemetry.battery():
        print(f"Battery: {battery.remaining_percent:.0%}")

# Run multiple streams concurrently
await asyncio.gather(
    print_position(drone),
    print_battery(drone),
)
```

Other telemetry streams: `attitude_euler()`, `velocity_ned()`, `gps_info()`, `flight_mode()`, `armed()`, `in_air()`.

## Offboard Control

Offboard mode enables real-time position or velocity setpoints sent by the companion computer. The autopilot must receive setpoints at ≥ 2 Hz or it exits offboard mode.

```python
from mavsdk.offboard import VelocityNedYaw, PositionNedYaw

await drone.offboard.set_velocity_ned(VelocityNedYaw(1.0, 0.0, 0.0, 0.0))
await drone.offboard.start()

# Fly north at 1 m/s for 5 seconds
for _ in range(50):
    await drone.offboard.set_velocity_ned(VelocityNedYaw(1.0, 0.0, 0.0, 0.0))
    await asyncio.sleep(0.1)

await drone.offboard.stop()
```

Position setpoint (local NED frame, relative to home):
```python
await drone.offboard.set_position_ned(PositionNedYaw(10.0, 0.0, -5.0, 0.0))
```

## Mission Upload

```python
from mavsdk.mission import MissionItem, MissionPlan

mission_items = [
    MissionItem(
        latitude_deg=-35.3632,
        longitude_deg=149.1652,
        relative_altitude_m=10,
        speed_m_s=5,
        is_fly_through=True,
        gimbal_pitch_deg=float('nan'),
        gimbal_yaw_deg=float('nan'),
        camera_action=MissionItem.CameraAction.NONE,
        loiter_time_s=float('nan'),
        camera_photo_interval_s=float('nan'),
        acceptance_radius_m=float('nan'),
        yaw_deg=float('nan'),
        camera_photo_distance_m=float('nan'),
    )
]

mission_plan = MissionPlan(mission_items)
await drone.mission.upload_mission(mission_plan)
await drone.action.arm()
await drone.mission.start_mission()
```

## Parameter Access

```python
value = await drone.param.get_param_float("ATC_RAT_RLL_P")
await drone.param.set_param_float("ATC_RAT_RLL_P", 0.15)
```

## Related Concepts

- [MAVLink Protocol](../flight-controller-software/ardupilot/mavlink.md)
- [Companion Computers](../flight-controller-software/ardupilot/companion-computers.md)
- [DroneKit](dronekit.md)
- [PyMAVLink](pymavlink.md)
- [SITL Simulation](../flight-controller-software/ardupilot/sitl.md)

## Sources

- [MAVSDK Python Quickstart](https://mavsdk.mavlink.io/develop/en/python/quickstart.html) — 2026-05-22
- [MAVSDK GitHub](https://github.com/mavlink/MAVSDK) — 2026-05-22
- [MAVSDK Offboard Guide](https://mavsdk.mavlink.io/main/en/cpp/guide/offboard.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
