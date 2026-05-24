# EKF and Navigation — ArduPilot

ArduPilot's Extended Kalman Filter (EKF3) is the core navigation engine: it fuses data from all available sensors into a unified estimate of position, velocity, attitude, and environmental state. Every GPS-reliant flight mode depends on EKF3 producing a healthy, trusted navigation solution.

## Overview

EKF3 maintains a state vector of approximately 22 quantities: 3D position, 3D velocity, attitude (roll/pitch/yaw), gyro and accelerometer biases, wind velocity, and magnetic field parameters. It continuously integrates IMU measurements and corrects them using slower, noisier sensors like GPS and barometer. When a sensor measurement deviates significantly from the EKF's prediction, it is rejected — innovation checking prevents a single bad sensor from corrupting the entire navigation solution.

Multiple EKF cores (lanes) run in parallel, one per enabled IMU. The system continuously evaluates lane quality and switches to the best-performing lane if the current primary degrades.

## Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `EK3_ENABLE` | 1 | Enable EKF3 (reboot required) |
| `AHRS_EKF_TYPE` | 3 | Select EKF3 as flight control estimator (2=EKF2, 3=EKF3) |
| `EK2_ENABLE` | 0 | Disable EKF2 when using EKF3 to save RAM |
| `EK3_IMU_MASK` | 3 | Bitmask of IMUs to run as lanes (default: both IMUs) |
| `EK3_PRIMARY` | 0 | Which lane to prefer as primary (0=auto) |

## Source Selection

EKF3 supports multiple sensor source sets — primary (SRC1) and secondary (SRC2) — enabling in-flight transitions between GPS and non-GPS navigation. Sources are selected per measurement type:

| Parameter | Value | Source |
|-----------|-------|--------|
| `EK3_SRC1_POSXY` | 0=None, 3=GPS, 6=ExternalNav | Horizontal position |
| `EK3_SRC1_VELXY` | 0=None, 3=GPS, 5=OpticalFlow, 6=ExternalNav | Horizontal velocity |
| `EK3_SRC1_POSZ` | 1=Baro, 2=RangeFinder, 3=GPS, 6=ExternalNav | Vertical position |
| `EK3_SRC1_VELZ` | 0=None, 3=GPS, 6=ExternalNav | Vertical velocity |
| `EK3_SRC1_YAW` | 1=Compass, 2=GPS, 3=GPS+Compass fallback, 6=ExternalNav, 8=GSF | Yaw/heading |

Default (GPS + compass): `POSXY=3, VELXY=3, POSZ=1, VELZ=0, YAW=1`

Secondary source set (`EK3_SRC2_*`) can be configured for optical flow or visual odometry, then activated via an RC switch (`RCx_OPTION = 90`).

## Sensor Noise Parameters

These control how much EKF3 trusts each sensor. Lower values mean more trust; higher values mean the sensor is treated as noisy and given less weight.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `EK3_POSNE_NOISE` | 0.5 m | Assumed GPS horizontal position noise |
| `EK3_VELNE_NOISE` | 0.1 m/s | Assumed GPS horizontal velocity noise |
| `EK3_ALT_M_NSE` | 1.0 m | Altitude noise (barometer vs accelerometer balance) |
| `EK3_YAW_M_NSE` | 0.5 rad | Compass yaw noise (lower = trust compass more) |

## GPS Glitch Handling

When GPS position or velocity innovations spike, EKF3 rejects the GPS measurement and coasts on IMU integration alone. This provides short-term protection (5–10 s typically) before position drift becomes significant. ArduPilot's glitch detection flags a GPS glitch event in the log (`ERR` message, subsystem 6) when this occurs.

In GPS-requiring modes (Loiter, PosHold, RTL), a sustained GPS glitch can trigger the EKF failsafe. See [Failsafes](failsafes.md).

## Compass-less Operation

Set `EK3_SRC1_YAW = 8` to use the Gaussian Sum Filter (GSF) for heading estimation from GPS-derived velocity. This requires a high-quality GPS receiver (u-blox M8 or better) and at least 3 m/s of translational speed before the yaw estimate converges. Compass-less operation eliminates the most common source of EKF yaw failures (magnetic interference) but requires the vehicle to move briefly before yaw is trusted.

Set `COMPASS_ENABLE = 0` to fully disable compass-related pre-arm checks when operating compass-less.

## EKF Lanes and Innovation Checking

Each EKF lane runs against the same sensor inputs but uses a different IMU instance. Innovations — the difference between a sensor measurement and the EKF's prediction — are squared and normalised. Values below 1.0 indicate the measurement is accepted; above 1.0 indicates rejection.

Lane switching is controlled by `EK3_ERR_THRESH`: when a non-primary lane accumulates significantly lower error than the primary, the system switches. `EK3_AFFINITY` controls which sensor types (GPS, baro, compass, airspeed) can each lane independently select.

## Log Messages

### XKF1 — State Estimates

| Field | Description |
|-------|-------------|
| `C` | Core (lane) number |
| `Roll`, `Pitch`, `Yaw` | Attitude estimates (°) |
| `VN`, `VE`, `VD` | Velocity north, east, down (m/s) |
| `PN`, `PE`, `PD` | Position north, east, down (m) |
| `GX/GY/GZ` | Gyro biases (rad/s) |

### XKF4 — Innovation Ratios

| Field | Description |
|-------|-------------|
| `SV` | Velocity innovation ratio — > 1.0 = GPS velocity rejected |
| `SP` | Position innovation ratio — > 1.0 = GPS position rejected |
| `SH` | Heading innovation ratio — > 1.0 = compass rejected |
| `SM` | Magnetic innovation ratio |
| `FS` | Filter saturation flags |

Normal in-flight values are below 0.3. Values approaching 1.0 indicate sensor quality degradation. Cross-reference with `ERR` messages and mode changes.

### XKF5 — Auxiliary

`HAGL` (height above ground), `RI` (rangefinder innovation), `Herr` (heading error), `ePos` (position error estimate).

## Diagnosing EKF Problems

1. **Check XKF4 innovations** — which ratio spiked? `SV/SP` → GPS problem; `SH/SM` → compass problem.
2. **GPS quality** — plot `GPS.HDOP` and `GPS.NSats`. HDOP > 2.0 or < 6 satellites degrades EKF.
3. **Compass interference** — `SM` spikes often correlate with high-throttle motor current. Route motor wires away from compass; use external compass.
4. **Vibration** — VIBE > 30 m/s² corrupts accelerometer integration. See [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md).
5. **Lane switches** — unexpected lane changes appear in logs and can indicate an IMU or sensor failing on a specific core.

For deeper diagnosis, replay the flight log through the EKF inside [SITL](sitl.md) using the `Replay` tool. Replay re-runs the estimator against the original IMU, GPS, baro, and mag samples, so changes to `EK3_*` noise terms, source masks, and affinity bits can be evaluated against the actual failure without re-flying. Capture replay-eligible logs by setting `LOG_REPLAY = 1` and `LOG_DISARMED = 1` ahead of time — see [Log Replay](sitl.md#log-replay). SITL also exposes `SIM_GPS_GLITCH_*` and `SIM_MAG_FAIL` for synthesising the failure modes above in a controlled environment before they appear in real flight.

## Non-GPS Navigation

Configure `EK3_SRC2_*` for optical flow or visual odometry and switch sources in flight with an RC switch. Typical indoor non-GPS setup:

```
EK3_SRC1_VELXY = 5    (OpticalFlow)
EK3_SRC1_POSXY = 0    (no GPS position)
EK3_SRC1_POSZ  = 1    (barometer)
EK3_SRC1_YAW   = 1    (compass)
```

See [Optical Flow and Non-GPS Navigation](optical-flow.md) for sensor setup.

## Related Concepts

- [Sensors](sensors.md)
- [GPS and GNSS](gps-gnss.md)
- [Optical Flow and Non-GPS Navigation](optical-flow.md)
- [Failsafes](failsafes.md)
- [Flight Modes](flight-modes.md)
- [Logging and Analysis](logging.md)
- [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)

## Sources

- [EKF — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-apm-navigation-extended-kalman-filter-overview.html) — 2026-05-22
- [EKF Source Selection — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-ekf-sources.html) — 2026-05-22
- [EKF3 Affinity and Lane Switching — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-ek3-affinity-lane-switching.html) — 2026-05-22
- [Compass-less Operation — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-compassless.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
