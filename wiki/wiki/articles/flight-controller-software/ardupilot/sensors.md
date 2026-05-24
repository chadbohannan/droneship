# Sensors — ArduPilot

ArduPilot supports redundant sensor instances for IMUs, compasses, and barometers. The EKF3 runs multiple lanes using different IMU instances and selects the best-performing one. Understanding sensor parameters, calibration, and health reporting is essential for reliable autonomous flight.

## IMU (Accelerometer and Gyroscope)

ArduPilot uses 1–3 IMU instances depending on the flight controller hardware. All instances run simultaneously; EKF3 uses them for parallel lane estimation.

### Parameters

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `INS_USE` | 1 | — | Enable IMU 1 |
| `INS_USE2` | 1 | — | Enable IMU 2 |
| `INS_USE3` | 0 | — | Enable IMU 3 (if present) |
| `INS_ACCEL_FILTER` | 20 | Hz | Low-pass filter on accelerometer data |
| `INS_GYRO_FILTER` | 20 | Hz | Low-pass filter on gyro data |
| `INS_LOG_BAT_MASK` | 0 | bitmask | Enable IMU batch sampler for FFT (set to 1 for vibration analysis) |

`INS_GYRO_FILTER` is the primary knob for noise vs. phase-lag tradeoff. Reduce to 10–15 Hz for noisy builds (more filtering, more lag) or increase to 40+ Hz for clean builds with notch filters configured. Note that `ATC_RAT_*_FLTD` should be set to `INS_GYRO_FILTER / 2`. See [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md).

### Temperature Calibration

Some high-quality flight controllers support IMU temperature calibration, which corrects for bias drift as the board warms up from cold. Enabled via `INS_TCAL_ENABLE`. The board must be cooled to below ambient, then warmed to operating temperature during calibration. Run only once; the calibration table is stored in flash.

### Accelerometer Calibration

Run from GCS (Setup → Mandatory Hardware → Accel Calibration). Place the vehicle on each of 6 faces (flat, right side, left side, nose down, nose up, back). Calibration stores offsets and scale factors in `INS_ACCOFFS_*` and `INS_ACCSCAL_*` parameters.

## Compass (Magnetometer)

Most ArduPilot builds use an external compass mounted away from motor current interference. Internal compasses (on the flight controller PCB) are near power wiring and have poor performance above ~20 A total system current.

### Parameters

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `COMPASS_USE` | 1 | — | Enable compass 1 |
| `COMPASS_USE2` | 1 | — | Enable compass 2 |
| `COMPASS_EXTERN` | varies | — | Set 1 for external compass (auto-detected on most hardware) |
| `COMPASS_ORIENT` | 0 | enum | Orientation relative to vehicle (0=normal; see ROTATION_* enums for rotated mounts) |
| `COMPASS_AUTODEC` | 1 | — | 1 = automatically compute magnetic declination from GPS position |
| `COMPASS_DEC` | 0 | rad | Manual declination when `COMPASS_AUTODEC = 0`; find value at ngdc.noaa.gov |

### Calibration

Run compass calibration (Setup → Mandatory Hardware → Compass) before first flight and after any changes to motor wiring or frame. ArduPilot offers onboard calibration (rotate vehicle through all orientations) and Mission Planner's large vehicle calibration (tumble vehicle). Modern versions auto-detect compass orientation during calibration.

Signs of compass problems: `COMPASS OFFSETS TOO HIGH` pre-arm message (offsets > 500); `COMPASSES INCONSISTENT` (internal and external disagree > 45°); EKF yaw drift in hover.

Fixes: mount external compass 10+ cm from motor ESC wires; disable internal compass (`COMPASS_USE2 = 0`); re-route high-current wiring away from compass location.

## Barometer

The barometer measures atmospheric pressure to estimate altitude. ArduPilot supports primary and secondary barometers on most modern flight controllers.

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `GND_ABS_PRESS` | auto | Pa | Ground level reference pressure (set at boot from barometer) |
| `GND_TEMP` | 0 | °C | Ground temperature reference (0 = use sensor value) |
| `BARO_PROBE_EXT` | 0 | bitmask | Bitmask for external I2C barometer types to probe |
| `BARO_EXT_BUS` | -1 | — | I2C bus for external barometer (−1 = probe all buses) |

Barometers are sensitive to airflow. Always cover the barometer opening with foam or a protective cover; direct prop wash causes altitude oscillations. Flying indoors can cause calibration errors if pressure differs significantly from the ground pressure at startup.

## Rangefinder

Rangefinders provide height above ground for landing, terrain following, and (with optical flow) indoor altitude hold. ArduPilot supports lidar, sonar, and radar sensors over I2C, serial, analog, and DroneCAN.

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `RNGFND_TYPE` | 0 | enum | Sensor type (0=disabled, 1=analog, 2=MaxSonar I2C, 7=LightWare serial, etc.) |
| `RNGFND_MAX_CM` | 700 | cm | Maximum valid range — **must be set accurately**; ArduPilot falls back to baro above this |
| `RNGFND_MIN_CM` | 20 | cm | Minimum valid range; readings below this are ignored |
| `RNGFND_ORIENT` | 25 | enum | Mounting orientation (25 = downward-facing) |
| `RNGFND_LANDING` | 0 | — | 1 = use rangefinder for landing altitude (Copter) |

Set `RNGFND_MAX_CM` to the actual tested maximum range, not the datasheet maximum. ArduPilot switches to barometer when the rangefinder exceeds its max range — setting this too high prevents proper fallback.

Multiple rangefinders (up to 10 instances) are configured with `RNGFND2_*`, `RNGFND3_*`, etc. Different orientations support obstacle detection (forward, sideways) in addition to altitude.

## Airspeed Sensor

Used on fixed-wing and VTOL vehicles for accurate speed measurement. Not used by ArduCopter. Pitot tube + differential pressure sensor (DLVR, MS4515, SDP33). Configured via `ARSPD_TYPE` and `ARSPD_PIN`. EKF3 fuses airspeed measurements for improved state estimation in planes.

## Sensor Redundancy and Health

EKF3 runs one lane per enabled IMU instance. Each lane can independently select which compass, GPS, or barometer instance to use (`EK3_AFFINITY` bitmask). If a sensor fails a health check or produces high innovations, that lane is penalised and the system switches to a better lane.

The `SENSORS` health flags in `SYS_STATUS` (visible in Mission Planner's Flight Data status window) show which sensors are present, enabled, and healthy in real time.

## Related Concepts

- [EKF and Navigation](ekf-navigation.md)
- [GPS and GNSS](gps-gnss.md)
- [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)
- [CAN Bus and DroneCAN](can-dronecan.md)
- [Hardware](hardware.md)
- [Optical Flow and Non-GPS Navigation](optical-flow.md)

## Sources

- [Advanced Compass Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-compass-setup-advanced.html) — 2026-05-22
- [Rangefinder Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-rangefinder-setup.html) — 2026-05-22
- [IMU Temperature Calibration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-imutempcal.html) — 2026-05-22
- [IMU Batch Sampler — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-imu-batchsampling.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
