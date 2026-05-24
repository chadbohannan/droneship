# Companion Computers — ArduPilot

A companion computer is a single-board computer mounted on the vehicle that connects to the flight controller via MAVLink, enabling capabilities beyond the autopilot's onboard compute: computer vision, precision landing, obstacle avoidance, offboard control via DroneKit or MAVSDK, and ROS-based autonomous systems.

## Overview

The companion computer receives the full MAVLink telemetry stream from the flight controller (GPS, attitude, battery, RC) and can issue commands back — primarily by placing the vehicle in Guided mode and sending position, velocity, or attitude targets. The flight controller remains the safety layer: if the companion computer stops sending commands, the vehicle holds position and eventually triggers the GCS failsafe.

## Wiring

Connect the flight controller's **TELEM2** port to the companion computer's UART RX/TX pins. Cross-connect TX↔RX. Share a common ground.

| Flight Controller Pin | Companion Computer |
|----------------------|-------------------|
| TELEM2 TX | UART RX |
| TELEM2 RX | UART TX |
| GND | GND |

Avoid 5V from the TELEM port to power the companion computer — use a dedicated BEC. At 921600 baud, hardware flow control (CTS/RTS) improves reliability on longer traces; PCB-to-PCB connections at this rate typically work without it.

On Raspberry Pi, enable UART via `sudo raspi-config` → Interfacing Options → Serial → disable login shell → enable hardware serial. The port appears as `/dev/serial0`.

## Serial Port Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `SERIAL2_PROTOCOL` | 2 | MAVLink 2 on TELEM2 |
| `SERIAL2_BAUD` | 921 | 921600 baud |
| `BRD_SER2_RTSCTS` | 2 | Enable hardware flow control (optional) |

After parameter changes, reboot the flight controller.

## MAVProxy as Router

MAVProxy running on the companion computer acts as a MAVLink router: it consumes the serial link to the flight controller and forwards MAVLink to multiple network endpoints (GCS on the ground, other processes on the companion).

```bash
# Basic router — serial FC to UDP GCS
mavproxy.py --master=/dev/serial0 --baudrate=921600 \
  --out=192.168.1.10:14550

# Run as background daemon with multiple outputs
mavproxy.py --daemon --non-interactive \
  --master=/dev/serial0 --baudrate=921600 \
  --out=udp:groundstation:14550 \
  --out=127.0.0.1:14551
```

Lighter-weight alternatives when MAVProxy's resource use is a concern: `mavlink-routerd` or `mavp2p`.

## Offboard Control (Guided Mode)

The companion computer commands the vehicle by switching it to Guided mode and sending target messages. The vehicle must receive updated targets at least every `GUID_TIMEOUT` seconds (default 3 s) or it will hold level hover.

Key MAVLink messages for offboard control:

| Message | Use |
|---------|-----|
| `SET_POSITION_TARGET_LOCAL_NED` | Fly to NED position or velocity |
| `SET_POSITION_TARGET_GLOBAL_INT` | Fly to WGS84 lat/lon/altitude |
| `SET_ATTITUDE_TARGET` | Set roll/pitch/yaw with thrust |
| `COMMAND_LONG (MAV_CMD_DO_SET_MODE)` | Switch flight mode |

Position targets require GPS. `GUIDED_NOGPS` mode allows attitude-only offboard control for GPS-denied environments.

## Recommended Hardware

| Board | Use Case | Notes |
|-------|---------|-------|
| Raspberry Pi 4 | General purpose, vision, MAVProxy | 3–7 W; good library support |
| NVIDIA Jetson Nano | Real-time ML/CV inference | 5–10 W; 128-core GPU; ~3× Pi cost |
| NVIDIA Jetson Xavier NX | Advanced CV, SLAM | 10–20 W; highest compute |
| Orange Pi Zero 2 | Lightweight routing | Low power; limited ML capability |
| Intel NUC | Maximum compute | 200+ g; weight penalty for most builds |

Integrated solutions (PixC4-Jetson, PixC4-Pi) combine the flight controller and companion computer on a single board with direct PCB-level MAVLink, eliminating wiring complexity.

## Common Use Cases

**Precision landing**: Camera detects landing pad, sends position corrections to flight controller in Guided mode. Raspberry Pi with downward camera is a common setup.

**Obstacle avoidance**: Depth camera (Intel RealSense D435) feeds a proximity grid to ArduPilot via MAVLink proximity messages. BendyRuler or Dijkstra path planners steer around obstacles.

**Vision-based positioning**: Intel T265 or ZED stereo camera provides visual odometry, fused by EKF3 via ExternalNav source (`EK3_SRC1_POSXY=6`). Enables accurate indoor flight without GPS. See [Optical Flow and Non-GPS Navigation](optical-flow.md).

**Mission scripting**: DroneKit-Python or MAVSDK runs on companion, commands complex multi-point missions not expressible as simple waypoints.

**ROS integration**: MAVROS on ROS/ROS2 bridges ArduPilot telemetry to the ROS topic graph. Computer vision nodes publish position setpoints which MAVROS relays to the flight controller. See [ROS and ROS2 Integration](../../programming/ros-integration.md).

## MAVLink Routing

The flight controller forwards all MAVLink messages (including GPS, attitude, RC) to every port running MAVLink protocol. Messages are routed by system ID and component ID: broadcast messages (target=0) reach all connected systems; addressed messages reach only the target. ArduPilot will not forward a command to a system it hasn't yet received a heartbeat from — GCS must receive at least one packet before sending targeted commands.

## Related Concepts

- [MAVLink Protocol](mavlink.md)
- [EKF and Navigation](ekf-navigation.md)
- [Optical Flow and Non-GPS Navigation](optical-flow.md)
- [Failsafes](failsafes.md)
- [DroneKit](../../programming/dronekit.md)
- [MAVSDK](../../programming/mavsdk.md)
- [ROS and ROS2 Integration](../../programming/ros-integration.md)
- [Ground Control Stations](gcs.md)

## Sources

- [Companion Computers — ArduPilot dev docs](https://ardupilot.org/dev/docs/companion-computers.html) — 2026-05-22
- [Communicating with Raspberry Pi via MAVLink — ArduPilot dev docs](https://ardupilot.org/dev/docs/raspberry-pi-via-mavlink.html) — 2026-05-22
- [Copter Commands in Guided Mode — ArduPilot dev docs](https://ardupilot.org/dev/docs/copter-commands-in-guided-mode.html) — 2026-05-22
- [MAVLink Routing in ArduPilot — ArduPilot dev docs](https://ardupilot.org/dev/docs/mavlink-routing-in-ardupilot.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
