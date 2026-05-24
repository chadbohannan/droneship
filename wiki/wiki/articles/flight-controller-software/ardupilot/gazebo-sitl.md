# Gazebo SITL

Connecting ArduPilot SITL to Gazebo for physics-realistic simulation with sensor models, complex environments, and ROS integration.

## Overview

ArduPilot's built-in SITL physics model is adequate for software and parameter testing, but it uses a simplified rigid-body dynamics model without environmental effects. Gazebo is a full robotics simulator with physics engines (ODE, Bullet, DART), realistic sensor noise models, wind simulation, camera rendering, and support for complex 3D worlds. Connecting ArduPilot SITL to Gazebo moves the physics responsibility from ArduPilot's internal model to Gazebo, giving more realistic sensor outputs and environmental interactions.

The connection uses the `ardupilot_gazebo` plugin, which runs inside Gazebo and communicates with ArduPilot's SITL over UDP. ArduPilot sends motor PWM values to the plugin; the plugin simulates the resulting forces and returns sensor data (IMU, GPS, barometer, etc.) back to ArduPilot at each timestep. From ArduPilot's perspective, it behaves identically to any other SITL backend — MAVLink, parameters, logs, and GCS tools all work normally.

## When to Use Gazebo SITL

Use Gazebo SITL when you need:

- **Sensor noise models** — IMU and GPS outputs with realistic noise that stresses EKF tuning
- **Camera simulation** — visual odometry, optical flow, or computer vision testing with rendered imagery
- **Complex environments** — obstacle avoidance testing in 3D worlds with buildings, terrain, and objects
- **Multi-vehicle simulation** — multiple vehicles in a shared physics world with collision
- **ROS integration** — Gazebo is the standard simulation backend for ROS/ROS2, making it the right choice for mavros and ROS2-based companion code testing

For pure parameter tuning, Lua scripting, mission validation, or failsafe testing, the built-in SITL backend is faster and simpler.

## Installation

### Gazebo

ArduPilot Gazebo SITL requires **Gazebo Garden** (Gazebo 7.x, the new versioning) or **Gazebo Classic** (Gazebo 11). Gazebo Garden is recommended for new projects.

```bash
# Gazebo Garden (Ubuntu 22.04)
sudo apt install ros-humble-ros-gz
# or standalone:
sudo apt install gz-garden
```

For Gazebo Classic (Gazebo 11):

```bash
sudo apt install gazebo11 libgazebo11-dev
```

### ardupilot_gazebo Plugin

The official ArduPilot Gazebo plugin is maintained at `https://github.com/ArduPilot/ardupilot_gazebo`.

```bash
git clone https://github.com/ArduPilot/ardupilot_gazebo
cd ardupilot_gazebo
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo
make -j4
sudo make install
```

Set the Gazebo plugin and model paths so Gazebo can locate the plugin:

```bash
# Add to ~/.bashrc
export GZ_SIM_SYSTEM_PLUGIN_PATH=$HOME/ardupilot_gazebo/build:${GZ_SIM_SYSTEM_PLUGIN_PATH}
export GZ_SIM_RESOURCE_PATH=$HOME/ardupilot_gazebo/models:$HOME/ardupilot_gazebo/worlds:${GZ_SIM_RESOURCE_PATH}
```

For Gazebo Classic, use `GAZEBO_PLUGIN_PATH` and `GAZEBO_MODEL_PATH` instead.

## Launching Gazebo SITL

The setup requires two terminal sessions: one for Gazebo, one for ArduPilot SITL.

### Terminal 1 — Launch Gazebo

```bash
# Gazebo Garden with a copter world
gz sim -v4 -r iris_runway.sdf
```

For Gazebo Classic:

```bash
gazebo --verbose worlds/iris_arducopter_runway.world
```

The world file loads the vehicle model with the `ardupilot_gazebo` plugin attached. The plugin listens on UDP ports (default: `9002` for motor inputs, `9003` for sensor outputs) and waits for ArduPilot.

### Terminal 2 — Launch ArduPilot SITL

```bash
cd ardupilot
sim_vehicle.py -v ArduCopter -f gazebo-iris --console --map
```

The `-f gazebo-iris` frame tells SITL to use Gazebo as its backend. ArduPilot connects to Gazebo's plugin UDP ports and begins the simulation loop. The `--console` and `--map` flags work as normal.

### Combined launch (optional)

```bash
# Single script approach
sim_vehicle.py -v ArduCopter -f gazebo-iris \
  --add-param-file=ardupilot_gazebo/config/gazebo-iris.parm \
  --console --map
```

## Available Worlds and Models

The `ardupilot_gazebo` repository ships several world files:

| World file | Description |
|-----------|-------------|
| `iris_runway.sdf` | Iris quadcopter on a flat runway |
| `iris_with_lidar.sdf` | Iris with 2D lidar sensor attached |
| `iris_with_ardupilot_runway.sdf` | Iris with GPS, IMU, and barometer plugins wired |
| `underwater.sdf` | ArduSub vehicle in a pool environment |

To test a plane:

```bash
gz sim -r zephyr_runway.sdf
sim_vehicle.py -v ArduPlane -f gazebo-zephyr --console --map
```

## Sensor Models

The `ardupilot_gazebo` plugin wires Gazebo sensor models to ArduPilot's SITL sensor interface:

| Sensor | Gazebo plugin | ArduPilot input |
|--------|--------------|-----------------|
| IMU | `ImuSensor` | Accelerometer + gyro |
| GPS | `NavSatSensor` | GPS lat/lon/alt + velocity |
| Barometer | `AirPressureSensor` | Altitude (converted from pressure) |
| Magnetometer | `MagnetometerSensor` | Compass heading |
| Camera | `CameraSensor` | Raw image (for companion scripts) |
| Rangefinder | `RaySensor` (lidar) | Downward-looking range |

Sensor noise parameters are configurable in the SDF model file under each sensor's `<noise>` element, allowing you to test EKF robustness under different noise conditions.

## ROS Integration

Gazebo Garden integrates directly with ROS2 via the `ros_gz_bridge`. This lets you inspect sensor topics from ROS2 tools while ArduPilot SITL runs the flight stack:

```bash
# Bridge Gazebo IMU topic to ROS2
ros2 run ros_gz_bridge parameter_bridge \
  /imu@sensor_msgs/msg/Imu@gz.msgs.IMU

# View topic
ros2 topic echo /imu
```

For mavros integration, run SITL with Gazebo as the backend, then connect mavros to ArduPilot's MAVLink output:

```bash
ros2 launch mavros apm.launch fcu_url:=udp://:14550@
```

The combination of Gazebo physics, ArduPilot flight control, and mavros gives a complete ROS2 development environment without real hardware.

## Tuning the Simulation Loop

Gazebo and ArduPilot must run at compatible speeds. By default, SITL runs as fast as the CPU allows and Gazebo runs at real time. This mismatch can cause instability.

```bash
# Match real-time factor: set in the world SDF
<physics type="ode">
  <real_time_factor>1.0</real_time_factor>
  <real_time_update_rate>400</real_time_update_rate>
</physics>
```

ArduPilot's physics timestep in Gazebo mode is 2.5 ms (400 Hz). Set `real_time_update_rate` to 400 and `real_time_factor` to 1.0 for stable operation.

If the simulation runs too slowly on your hardware, reduce `real_time_update_rate` to 250 and adjust the speedup:

```bash
sim_vehicle.py -v ArduCopter -f gazebo-iris --speedup=1
```

## Differences from Built-in SITL

| Aspect | Built-in SITL | Gazebo SITL |
|--------|--------------|-------------|
| Setup complexity | None | Plugin build + world file |
| Physics fidelity | Simplified rigid body | Full ODE/Bullet physics |
| Sensor noise | Minimal | Configurable Gaussian noise |
| Camera simulation | No | Yes |
| Multi-vehicle | Via SITL_FEATURE | Yes, native |
| ROS2 integration | Via mavros only | Native topic bridge |
| CPU requirement | Low | High (GPU helpful) |
| SITL launch time | Fast | Slower (Gazebo startup) |

## Related Concepts

- [SITL — Software in the Loop](sitl.md)
- [ROS and ROS2 Integration](../../programming/ros-integration.md)
- [Navio2 SITL](../../flight-controller-hardware/navio2/navio2-sitl.md)
- [MAVProxy](mavproxy.md)

## Sources

- [SITL with Gazebo — ArduPilot developer docs](https://ardupilot.org/dev/docs/sitl-with-gazebo.html) — 2026-05-22
- [ardupilot_gazebo — GitHub](https://github.com/ArduPilot/ardupilot_gazebo) — 2026-05-22
- [Gazebo Garden — Getting Started](https://gazebosim.org/docs/garden/getstarted) — 2026-05-22
- [Using SITL for ArduPilot Testing — ArduPilot developer docs](https://ardupilot.org/dev/docs/using-sitl-for-ardupilot-testing.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
