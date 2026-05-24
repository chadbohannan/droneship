# Optical Flow and Non-GPS Navigation — ArduPilot

Optical flow sensors measure relative ground velocity by tracking surface texture across successive camera frames — the drone equivalent of a mouse sensor. Combined with a rangefinder for altitude, they enable position hold indoors or in GPS-denied environments without any satellite navigation.

## Overview

ArduPilot's EKF3 can fuse optical flow data in place of GPS for horizontal velocity estimation. The sensor provides relative velocity only — it cannot determine absolute position. Drift accumulates over time, so optical flow is best for short hover sessions or when combined with other absolute position references (beacons, visual odometry, GPS transitions).

## Supported Sensors

| Sensor | FLOW_TYPE | Interface | Notes |
|--------|-----------|-----------|-------|
| PMW3901 (CXOF) | 4 | SPI/UART | Common; used in Bitcraze Flow Deck, Holybro |
| PX4FLOW | 1 | I2C | High-resolution; includes gyro; bulky |
| ARK Flow | 6 | DroneCAN | Integrated Broadcom lidar; open source |
| MAVLink optical flow | 5 | MAVLink | Companion computer or external processor |
| SITL | 10 | Internal | Simulation only |

ADNS3080 (mouse sensor) is archived and not recommended for new builds.

## Mounting Requirements

- Mount sensor pointing **straight down**.
- Align X-axis forward (USB port toward rear on most modules) or correct with `FLOW_ORIENT_YAW`.
- Minimum operating altitude: ~10 cm (depends on sensor field of view).
- Maximum effective altitude: ~3 m — accuracy degrades above this as the field of view covers more area than the sensor can accurately track.
- Surface requirements: textured (concrete, grass, carpet). Polished floors, water, and repeating patterns cause tracking loss.
- Adequate lighting required. Most sensors fail in darkness.

## Required Companion: Rangefinder

A rangefinder is **required** for autonomous position-hold modes (Loiter via optical flow). It provides altitude for EKF3 and also limits the vehicle from climbing above the sensor's effective range.

Configure rangefinder with `RNGFND_TYPE` (sensor type), `RNGFND_MAX_CM` (max range), `RNGFND_MIN_CM` (minimum range), and `RNGFND_ORIENT = 25` (downward-facing).

FlowHold mode does not require a rangefinder, though altitude accuracy will be barometer-only.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FLOW_TYPE` | 0 | Sensor type (0=disabled, 1=PX4Flow, 4=CXOF, 6=DroneCAN) |
| `FLOW_FXSCALER` | 0 | X-axis scale correction (0.1% per unit) — calibrate by flying figure-eights |
| `FLOW_FYSCALER` | 0 | Y-axis scale correction |
| `FLOW_ORIENT_YAW` | 0 | Yaw correction for non-standard mounting (centidegrees) |

After enabling `FLOW_TYPE`, reboot. Verify the sensor is reporting in Mission Planner's optical flow widget before configuring EKF3.

## EKF3 Source Configuration

Configure EKF3 to use optical flow as the primary horizontal velocity source:

```
EK3_SRC1_VELXY = 5    (OpticalFlow)
EK3_SRC1_POSXY = 0    (no absolute position source)
EK3_SRC1_POSZ  = 1    (barometer)
EK3_SRC1_VELZ  = 0    (no vertical velocity)
EK3_SRC1_YAW   = 1    (compass)
```

Disable GPS arming check if flying without GPS: reduce `ARMING_CHECK` bitmask to exclude bit 3 (GPS lock).

## FlowHold Mode

FlowHold uses optical flow for position damping without requiring GPS or a rangefinder. Altitude is barometer-only. It damps lateral drift when sticks are centred but does not hold absolute position — the vehicle will still drift slowly.

Key FlowHold parameters:

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `FHLD_BRAKE_RATE` | 8.0 | °/s² | Deceleration rate (lean angle reduction rate) when sticks released |
| `FHLD_FILT_HZ` | 5.0 | Hz | Low-pass filter cutoff on flow sensor data; lower values smooth noise but add lag |
| `FHLD_QUAL_MIN` | 10 | — | Minimum quality score (0–255) below which flow data is rejected |

## GPS/Non-GPS Source Switching

ArduPilot supports in-flight switching between GPS (SRC1) and optical flow (SRC2) via an RC switch (`RCx_OPTION = 90`). Configure SRC2 for optical flow and SRC1 for GPS. Switch to SRC2 when flying indoors, back to SRC1 outdoors.

Log messages `EV` (events 85–87) record source transitions.

## Visual Odometry

Intel RealSense T265, ZED stereo camera, and ModalAI VOXL 2 provide 6DoF visual odometry, including position (not just velocity). This is superior to optical flow for extended indoor flights because absolute position is maintained.

Visual odometry data is fed to ArduPilot via a companion computer and the ExternalNav MAVLink interface:

```
EK3_SRC1_POSXY = 6    (ExternalNav)
EK3_SRC1_VELXY = 6    (ExternalNav)
EK3_SRC1_POSZ  = 6    (ExternalNav)
EK3_SRC1_YAW   = 6    (ExternalNav)
```

The ROS `vision_to_mavros` package or MAVROS's `vision_pose` topic feeds the visual odometry to ArduPilot. See [Companion Computers](companion-computers.md) and [ROS and ROS2 Integration](../../programming/ros-integration.md).

## UWB Beacon Positioning

Ultra-wideband (UWB) beacons placed at known positions in a room provide absolute position estimates with ~10 cm accuracy. ArduPilot receives beacon measurements via MAVLink and fuses them via EKF3's beacon source. Community implementations use modules such as MDEK1001 anchors with a companion computer bridge.

## Performance Expectations

| Condition | Expected behaviour |
|-----------|-------------------|
| Good lighting, textured surface, <3 m altitude | Stable hover, <0.5 m/s drift |
| Dim lighting or smooth surface | Increased drift, possible tracking loss |
| >3 m altitude | Degraded accuracy; position not guaranteed |
| Combined with rangefinder + good surface | Loiter-like hold for 30–60 s before drift becomes significant |

## Related Concepts

- [EKF and Navigation](ekf-navigation.md)
- [Sensors](sensors.md)
- [Companion Computers](companion-computers.md)
- [GPS and GNSS](gps-gnss.md)
- [Flight Modes](flight-modes.md)

## Sources

- [Optical Flow Sensor Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-optical-flow-sensor-setup.html) — 2026-05-22
- [FlowHold Mode — ArduPilot Copter docs](https://ardupilot.org/copter/docs/flowhold-mode.html) — 2026-05-22
- [Non-GPS Navigation — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-non-gps-navigation-landing-page.html) — 2026-05-22
- [EKF Source Selection — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-ekf-sources.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
