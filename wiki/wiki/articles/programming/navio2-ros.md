# Navio2 ROS and MAVROS

Running ROS with MAVROS on Navio2 for sensor access, mission control, and computer-vision pipelines — on the same Raspberry Pi as ArduPilot.

## Overview

Because Navio2 runs ArduPilot on a full Linux system, ROS runs on the same Raspberry Pi without a separate companion computer. Emlid's Raspbian image pre-installs ROS 1 Noetic and the MAVROS node. MAVROS (MAVLink + ROS) bridges ArduPilot's MAVLink telemetry stream to ROS topics and services, giving robotics algorithms direct access to attitude, position, velocity, battery state, and RC data. Navio2's hardware drivers additionally expose raw sensor data as kernel sysfs nodes that can be read independently of ArduPilot.

The on-board ROS setup is the key architectural advantage of Navio2 over a traditional microcontroller flight controller paired with a companion computer: the single-board form factor reduces wiring complexity and eliminates the MAVLink serial link between flight controller and companion computer.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Raspberry Pi                              │
│                                                             │
│  ┌──────────────┐   UDP/14650    ┌───────────────────────┐  │
│  │  ArduPilot   │◄──────────────►│  MAVROS node          │  │
│  │  (systemd)   │                │  (roslaunch)          │  │
│  └──────────────┘                └──────────┬────────────┘  │
│         │                                   │               │
│   sysfs/dev                          ROS topics             │
│   (IMU, baro,                    /mavros/imu/data           │
│    GPS, PWM,                     /mavros/global_position/   │
│    RC input)                     /mavros/state              │
│                                  /mavros/setpoint_raw/      │
└─────────────────────────────────────────────────────────────┘
```

## Launching MAVROS

Emlid's image provides a MAVROS launch configuration pre-wired for Navio2:

```bash
# Connect MAVROS to ArduPilot's UDP telemetry port
roslaunch mavros apm.launch fcu_url:=udp://:14650@ gcs_url:=udp://@192.168.1.100:14550
```

- `fcu_url:=udp://:14650@` — MAVROS listens on port 14650 for ArduPilot
- `gcs_url` — optional; MAVROS proxies GCS traffic if present

Ensure ArduPilot's `/etc/default/arducopter` (or the active vehicle file) exports to port 14650:

```bash
ARDUPILOT_OPTS="-A udp:127.0.0.1:14650"
```

## Key MAVROS Topics

| Topic | Type | Description |
|-------|------|-------------|
| `/mavros/imu/data` | sensor_msgs/Imu | Fused IMU data from ArduPilot EKF |
| `/mavros/imu/data_raw` | sensor_msgs/Imu | Raw IMU (unfiltered) |
| `/mavros/global_position/global` | sensor_msgs/NavSatFix | GPS latitude/longitude/altitude |
| `/mavros/global_position/local` | geometry_msgs/PoseStamped | Position in local NED (North-East-Down) frame |
| `/mavros/local_position/velocity_local` | geometry_msgs/TwistStamped | Body velocity |
| `/mavros/state` | mavros_msgs/State | Armed, mode, connected |
| `/mavros/battery` | sensor_msgs/BatteryState | Voltage, current, remaining |
| `/mavros/rc/in` | mavros_msgs/RCIn | Raw RC input values |
| `/mavros/setpoint_raw/local` | mavros_msgs/PositionTarget | Offboard position/velocity commands |
| `/mavros/setpoint_attitude/attitude` | geometry_msgs/PoseStamped | Offboard attitude commands |

## Offboard / GUIDED Mode Control

To command the vehicle from ROS, switch ArduPilot to GUIDED mode and publish setpoints:

```python
import rospy
from mavros_msgs.srv import SetMode, CommandBool
from mavros_msgs.msg import PositionTarget

rospy.init_node('my_controller')

# Arm and set GUIDED mode
set_mode = rospy.ServiceProxy('/mavros/set_mode', SetMode)
arm = rospy.ServiceProxy('/mavros/cmd/arming', CommandBool)

set_mode(custom_mode='GUIDED')
arm(True)

# Publish position setpoint
pub = rospy.Publisher('/mavros/setpoint_raw/local', PositionTarget, queue_size=1)
msg = PositionTarget()
msg.coordinate_frame = PositionTarget.FRAME_LOCAL_NED
msg.type_mask = (PositionTarget.IGNORE_VX | PositionTarget.IGNORE_VY | PositionTarget.IGNORE_VZ |
                 PositionTarget.IGNORE_AFX | PositionTarget.IGNORE_AFY | PositionTarget.IGNORE_AFZ |
                 PositionTarget.IGNORE_YAW_RATE)  # position + yaw only
msg.position.x = 0.0
msg.position.y = 0.0
msg.position.z = -5.0   # 5 m altitude in NED (negative = up)
pub.publish(msg)
```

ArduPilot in GUIDED mode follows setpoints as long as they continue to arrive. Setpoint publication must occur at ≥ 2 Hz to prevent the autopilot from dropping out of GUIDED.

## Raw Sensor Access Without ArduPilot

Navio2 sensors (IMU, barometer, GNSS) are accessed directly over SPI and I2C — not through a sysfs tree. The Emlid Navio2 C++ and Python library wraps the SPI device files (`/dev/spidev0.1` for MPU-9250, `/dev/spidev1.0` for LSM9DS1, `/dev/i2c-1` for MS5611) with typed accessor classes. Custom ROS nodes link against or reimplement these interfaces for sensor logging or building a custom attitude estimator.

RC input channels and ADC (analog-to-digital converter) readings — managed by the RCIO co-processor — are readable from sysfs at `/sys/kernel/rcio/rcin/ch0` through `ch15` and `/sys/kernel/rcio/adc/ch0` through `ch5`, independently of ArduPilot (see [RCIO Co-Processor](../flight-controller-hardware/navio2/rcio.md)).

See [Navio2 Python/C++ Programming](navio2-python.md) for working sensor access examples.

## ROS 2 Migration

ArduPilot 4.5 introduced DDS (Data Distribution Service) support via the `AP_DDS` library, enabling direct ROS 2 topic communication without MAVROS. On Navio2, this requires:
- A ROS 2 installation (Humble or later) — not included in the Emlid Raspbian image by default
- ArduPilot built with `--enable-dds`
- Micro-XRCE-DDS agent running on the Raspberry Pi

The MAVROS (ROS 1) path remains functional and is the simpler option for most Navio2 projects.

## Related Concepts

- [Navio2](../flight-controller-hardware/navio2/navio2.md)
- [Navio2 ArduPilot Configuration](../flight-controller-hardware/navio2/ardupilot-configuration.md)
- [Navio2 Emlid Raspbian OS](../flight-controller-hardware/navio2/raspbian-emlid.md)
- [ROS and ROS2 Integration](ros-integration.md)
- [Companion Computers](../flight-controller-software/ardupilot/companion-computers.md)
- [MAVLink](../flight-controller-software/ardupilot/mavlink.md)
- [Navio2 Python/C++ Programming](navio2-python.md)

## Sources

- [ROS — Emlid Navio2 docs](https://docs.emlid.com/navio2/ros/) — 2026-05-22
- [Navio2 — robots.ros.org](https://robots.ros.org/navio2/) — 2026-05-22

<!-- linted: 2026-05-23 -->
