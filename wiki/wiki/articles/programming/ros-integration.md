# ROS and ROS2 Integration — ArduPilot

The Robot Operating System (ROS) provides a distributed publish-subscribe middleware that connects perception, planning, and control algorithms. ArduPilot integrates with ROS via MAVROS (ROS1) or `ardupilot_ros` (ROS2 native), enabling computer vision pipelines, SLAM-based navigation, and complex autonomous behaviour on companion computers.

## Overview

ArduPilot does not run ROS itself — it runs on the flight controller, communicating via MAVLink. A companion computer running ROS bridges the two systems: ROS nodes publish position setpoints that MAVROS relays to ArduPilot, and ArduPilot publishes telemetry back as ROS topics. The flight controller remains the safety-critical layer; ArduPilot enforces failsafes regardless of what ROS commands.

## Coordinate Frames

ArduPilot uses **NED** (North-East-Down). ROS uses **ENU** (East-North-Up). MAVROS converts automatically — publish and subscribe in ENU from ROS; MAVROS handles translation. Do not perform manual frame conversion when using MAVROS.

| Frame | X | Y | Z |
|-------|---|---|---|
| NED (ArduPilot) | North | East | Down |
| ENU (ROS) | East | North | Up |

MAVROS also applies a 90° yaw rotation for local position frames.

## MAVROS (ROS1)

MAVROS (`ros-<distro>-mavros`) bridges ArduPilot MAVLink to ROS topics, services, and actions.

### Installation

```bash
sudo apt install ros-noetic-mavros ros-noetic-mavros-extras
ros_install_geographiclib_datasets.sh   # required datasets
```

### Connecting

```bash
roslaunch mavros apm.launch \
  fcu_url:=/dev/ttyUSB0:57600 \
  gcs_url:=udp://@192.168.1.10:14550
```

Or via TCP for SITL:
```bash
roslaunch mavros apm.launch fcu_url:=tcp://127.0.0.1:5762
```

### Key Topics

| Topic | Type | Direction | Description |
|-------|------|-----------|-------------|
| `/mavros/state` | `mavros_msgs/State` | Sub | Connection status, armed, flight mode |
| `/mavros/local_position/pose` | `geometry_msgs/PoseStamped` | Sub | Current position (ENU, relative to home) |
| `/mavros/global_position/global` | `sensor_msgs/NavSatFix` | Sub | GPS position |
| `/mavros/imu/data` | `sensor_msgs/Imu` | Sub | IMU data |
| `/mavros/battery` | `sensor_msgs/BatteryState` | Sub | Battery state |
| `/mavros/setpoint_position/local` | `geometry_msgs/PoseStamped` | Pub | Position setpoint (ENU) |
| `/mavros/setpoint_velocity/cmd_vel` | `geometry_msgs/TwistStamped` | Pub | Velocity setpoint (body frame) |
| `/mavros/setpoint_raw/local` | `mavros_msgs/PositionTarget` | Pub | Combined position/velocity/acceleration |
| `/mavros/vision_pose/pose` | `geometry_msgs/PoseStamped` | Pub | External position estimate (VIO) |
| `/mavros/rc/override` | `mavros_msgs/OverrideRCIn` | Pub | Override RC channels |

### Arming and Mode via Services

```python
import rospy
from mavros_msgs.srv import CommandBool, SetMode

rospy.wait_for_service('/mavros/cmd/arming')
arm_service = rospy.ServiceProxy('/mavros/cmd/arming', CommandBool)
arm_service(True)

mode_service = rospy.ServiceProxy('/mavros/set_mode', SetMode)
mode_service(custom_mode='GUIDED')
```

### Offboard Control Pattern

```python
import rospy
from geometry_msgs.msg import PoseStamped

pub = rospy.Publisher('/mavros/setpoint_position/local',
                      PoseStamped, queue_size=10)
rate = rospy.Rate(20)  # 20 Hz — must be > 2 Hz to maintain GUIDED

# Must publish before switching to GUIDED mode
target = PoseStamped()
target.pose.position.x = 5.0   # East (ENU)
target.pose.position.y = 0.0   # North
target.pose.position.z = 3.0   # Up

for _ in range(100):            # pre-publish setpoints
    pub.publish(target)
    rate.sleep()

mode_service(custom_mode='GUIDED')
arm_service(True)
```

## Vision Pose (Visual Odometry Input)

Feed external position estimates (VIO, SLAM, VICON) to ArduPilot's EKF via MAVROS:

```python
from geometry_msgs.msg import PoseStamped

pose_pub = rospy.Publisher('/mavros/vision_pose/pose',
                           PoseStamped, queue_size=10)

# Your VIO system publishes to this topic
# MAVROS forwards as VISION_POSITION_ESTIMATE MAVLink message
# ArduPilot fuses via EK3_SRC1_POSXY = 6 (ExternalNav)
```

ArduPilot EKF3 configuration for visual odometry:
```
EK3_SRC1_POSXY = 6    (ExternalNav)
EK3_SRC1_VELXY = 6
EK3_SRC1_POSZ  = 6
EK3_SRC1_YAW   = 6
```

## ROS2 and ardupilot_ros

ArduPilot 4.5+ supports a native DDS interface (Micro-XRCE-DDS) compatible with ROS2. The `ardupilot_ros` package provides integration without MAVROS.

```bash
# Install ardupilot_ros (ROS2 Humble)
sudo apt install ros-humble-ardupilot-ros
```

Key ROS2 topics mirror MAVROS but use the ROS2 naming convention. The direct DDS connection eliminates the MAVLink-to-ROS serialisation overhead — suitable for high-rate sensor fusion.

For ROS2 without DDS: MAVROS2 (`ros-humble-mavros`) provides the same interface as ROS1 MAVROS.

## Common Pipelines

**Precision landing via ArUco**: Camera node detects marker → computes 3D pose → publishes to `/mavros/vision_pose/pose` → ArduPilot EKF3 uses ExternalNav → vehicle positions to land on marker.

**Obstacle avoidance**: Depth camera → point cloud → `OctoMap` or custom node → proximity grid published as `sensor_msgs/LaserScan` → MAVROS proximity plugin → ArduPilot's BendyRuler or Dijkstra path planner.

**SLAM-based indoor navigation**: ORB-SLAM3 or RTAB-Map publishes odometry → MAVROS `/vision_pose/pose` → ArduPilot EKF3 indoor position hold.

## Related Concepts

- [Companion Computers](../flight-controller-software/ardupilot/companion-computers.md)
- [MAVLink Protocol](../flight-controller-software/ardupilot/mavlink.md)
- [Optical Flow and Non-GPS Navigation](../flight-controller-software/ardupilot/optical-flow.md)
- [EKF and Navigation](../flight-controller-software/ardupilot/ekf-navigation.md)
- [MAVSDK](mavsdk.md)

## Sources

- [ROS with ArduPilot — ArduPilot dev docs](https://ardupilot.org/dev/docs/ros.html) — 2026-05-22
- [ROS VIO Tracking Camera — ArduPilot dev docs](https://ardupilot.org/dev/docs/ros-vio-tracking-camera.html) — 2026-05-22
- [MAVROS Documentation — ROS wiki](https://docs.ros.org/en/iron/p/mavros/) — 2026-05-22

<!-- linted: 2026-05-23 -->
