# ArduPilot

ArduPilot is an open-source autopilot software suite supporting multirotors, fixed-wing aircraft, VTOL platforms, rovers, boats, and submarines — one of the two dominant autopilot ecosystems in the hobby and professional drone world alongside Betaflight/iNav.

## Overview

Where Betaflight and iNav are optimized for manual and semi-autonomous FPV flight, ArduPilot is a full autopilot stack: it can fly complete autonomous missions, hold position, follow terrain, execute 3D waypoint navigation, return to launch, and enforce geofences without pilot input. It runs on a wide range of flight controller hardware and communicates externally via [MAVLink](ardupilot/mavlink.md).

ArduPilot is published under GNU GPL v3, governed by the ArduPilot Foundation. Stable release as of late 2025: **Copter/Plane/Rover 4.6.3**.

## Firmware Variants

ArduPilot is a single codebase compiled into per-vehicle firmware targets. All variants share the parameter system, MAVLink interface, EKF3 navigation, and filtering infrastructure.

| Firmware | Vehicle |
|----------|---------|
| ArduCopter | Multirotors, traditional helicopters |
| ArduPlane | Fixed-wing, VTOL, quadplanes |
| ArduRover | Ground rovers, boats, USVs |
| ArduSub | Underwater ROVs |
| AntennaTracker | Pan/tilt antenna pointing systems |

## Comparison with Other Firmware

| Capability | ArduPilot | Betaflight | iNav |
|------------|-----------|------------|------|
| Autonomous waypoint missions | Yes | No | Limited |
| Terrain following | Yes | No | Partial |
| Geofencing | Yes | Basic | Yes |
| EKF state estimation | EKF3 | Basic | EKF2 |
| Low-latency acro tuning | Limited | Excellent | Good |
| MAVLink | Native | No | Partial |
| Lua scripting | Yes | Yes | Yes |
| SITL simulation | Extensive | Basic | Basic |
| Companion computer integration | First-class | Minimal | Limited |

ArduPilot's strength is autonomous operation, sensor fusion, and programmability. For pure FPV freestyle or racing, Betaflight remains the better choice. iNav is a practical middle ground for long-range FPV with GPS modes.

## Hardware

ArduPilot runs on hardware with significantly more resources than FPV-class flight controllers — redundant IMUs, dedicated barometers, magnetometers, CAN bus, and often a co-processor for IO are standard.

- **Pixhawk series** — Cube Orange, Pixhawk 6C/6X; the reference platform
- **Matek, Holybro, mRo** — popular mid-tier options
- **Linux targets** — Raspberry Pi + Navio2, BeagleBone, Qualcomm Snapdragon for payloads requiring compute

See [Supported Hardware](ardupilot/hardware.md) for selection guidance, minimum specs, and board comparisons.

## History

| Year | Milestone |
|------|-----------|
| 2007 | Jordi Muñoz develops early RC stabilization code; Chris Anderson founds DIY Drones |
| 2010 | Project formalised on Arduino hardware |
| 2011–12 | Andrew Tridgell adds SITL, automated testing, PyMAVLink, MAVProxy; Pat Hickey writes AP_HAL |
| 2012 | Randy Mackay becomes lead ArduCopter maintainer |
| 2013 | 3DRobotics ships Pixhawk as purpose-built ArduPilot hardware |
| 2016 | ArduPilot Foundation formed as independent governance body |
| 2025 | Copter/Plane/Rover 4.6.3 stable release |

## Article Map

The ArduPilot section of this wiki is organised into the following articles. Start with **First Flight** if you are setting up a new build; use the map below to navigate to specific topics.

### Setup and First Flight
| Article | Covers |
|---------|--------|
| [First Flight Setup](ardupilot/first-flight.md) | Calibration sequence, motor test, hover procedure, tuning progression |
| [Arming and Pre-Flight Checks](ardupilot/arming-preflight.md) | ARMING_CHECK bitmask, all pre-arm messages and fixes, arming methods |
| [Parameters](ardupilot/parameters.md) | Naming hierarchy, GCS access, param files, storage |
| [Ground Control Stations](ardupilot/gcs.md) | Mission Planner, QGC, MAVProxy comparison |

### Flight and Navigation
| Article | Covers |
|---------|--------|
| [Flight Modes](ardupilot/flight-modes.md) | All ArduCopter modes, required sensors, transitions |
| [EKF and Navigation](ardupilot/ekf-navigation.md) | EKF3, sensor fusion, GPS glitch handling |
| [GPS and GNSS](ardupilot/gps-gnss.md) | Protocols, dual GPS, RTK, GPS-for-yaw |
| [Optical Flow and Non-GPS Nav](ardupilot/optical-flow.md) | PMW3901, T265, UWB, indoor positioning |
| [Failsafes](ardupilot/failsafes.md) | Radio, battery, GPS, GCS, EKF failsafe actions |
| [Geofencing](ardupilot/geofence.md) | Circular, altitude, polygon zones, breach actions |
| [Mission Planning](ardupilot/mission-planning.md) | Waypoints, DO_ commands, surveys, terrain following |

### Tuning and Diagnostics
| Article | Covers |
|---------|--------|
| [PID Tuning](ardupilot/pid-tuning.md) | Rate controller, ATC_RAT_* params, AutoTune, input shaping |
| [Motor Mixing and Output](ardupilot/motor-mixing.md) | Mixing matrix, FRAME_CLASS/TYPE, thrust expo, voltage comp |
| [Vibration, Filtering, and Tuning](vibration-filtering-and-tuning.md) | Noise bands, notch/RPM filters, spectral analysis |
| [Logging and Analysis](ardupilot/logging.md) | LOG_BITMASK, message types, log review workflow |
| [Power Monitoring](ardupilot/power-monitoring.md) | Sensor calibration, capacity tracking, failsafe thresholds |

### Sensors and Peripherals
| Article | Covers |
|---------|--------|
| [Sensors](ardupilot/sensors.md) | IMU, baro, compass, airspeed, rangefinder |
| [CAN Bus and DroneCAN](ardupilot/can-dronecan.md) | Wiring, node IDs, CAN GPS/ESC devices |
| [RC Systems and RCMAP](ardupilot/rc-systems.md) | Protocols, channel mapping, auxiliary functions |
| [Telemetry Radios](ardupilot/telemetry-radios.md) | SiK, WiFi, LTE, ELRS MAVLink passthrough |

### Connectivity and Programming
| Article | Covers |
|---------|--------|
| [MAVLink Protocol](ardupilot/mavlink.md) | Message framing, v1/v2, common messages, routing |
| [Companion Computers](ardupilot/companion-computers.md) | Wiring, MAVProxy routing, Guided mode offboard control |
| [Lua Scripting](ardupilot/lua-scripting.md) | SCR_ENABLE, API surface, worked examples |
| [DroneKit](../programming/dronekit.md) | Python MAVLink library for companion computers |
| [MAVSDK](../programming/mavsdk.md) | Modern multi-language MAVLink SDK |
| [ROS / ROS2 Integration](../programming/ros-integration.md) | MAVROS, ardupilot_ros, sensor topics |

### Software Internals
| Article | Covers |
|---------|--------|
| [Architecture](ardupilot/architecture.md) | Scheduler, library structure, vehicle firmware layout |
| [AP_HAL](ardupilot/ap-hal.md) | Hardware abstraction, board configs, porting |
| [Build System](ardupilot/build-system.md) | Waf build, board targets, custom builds |
| [Custom Firmware](ardupilot/custom-firmware.md) | Feature flags, custom libraries, upstream contribution |
| [SITL Simulation](ardupilot/sitl.md) | sim_vehicle.py, physics backends, automated testing |

## Sources

- [ArduPilot — Wikipedia](https://en.wikipedia.org/wiki/ArduPilot) — 2026-05-21
- [ArduPilot Official Site](https://ardupilot.org/) — 2026-05-21
- [ArduPilot GitHub](https://github.com/ArduPilot/ardupilot) — 2026-05-21

<!-- linted: 2026-05-23 -->
