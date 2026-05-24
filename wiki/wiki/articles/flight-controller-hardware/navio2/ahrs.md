# Navio2 AHRS

Attitude and Heading Reference System implementation using the Mahony complementary filter, fusing IMU and magnetometer data into a quaternion attitude estimate.

## Overview

An Attitude and Heading Reference System (AHRS) produces roll, pitch, and yaw angles by fusing inertial sensor data over time. A gyroscope integrates angular rate for short-term accuracy; an accelerometer and magnetometer correct gyro drift over the long term. The Navio2 repository includes a C++ AHRS implementation of the Mahony complementary filter algorithm, originally authored by Robert Mahony and implemented by Sebastian Madgwick, adapted by Emlid for the Navio2's dual IMU.

This implementation is intended for custom applications — for example, attitude visualisation, robotics, or gimbal control — that run alongside or independently of ArduPilot. ArduPilot has its own AHRS/EKF pipeline and does not use this code.

## Algorithm: Mahony Complementary Filter

The Mahony filter maintains a quaternion `(q0, q1, q2, q3)` representing the orientation of the sensor frame relative to the earth frame. At each timestep `dt`:

1. Read accelerometer `(ax, ay, az)`, gyroscope `(gx, gy, gz)`, and magnetometer `(mx, my, mz)` from the IMU.
2. Normalise accelerometer and magnetometer vectors.
3. Estimate the gravity and magnetic field direction from the current quaternion.
4. Compute the cross-product error between estimated and measured field directions.
5. Apply proportional (`Kp`) and integral (`Ki`) feedback to correct the gyro rates.
6. Integrate corrected gyro rates to update the quaternion.

If the magnetometer reading is zero (invalid), the algorithm falls back to `updateIMU()`, which uses only accelerometer feedback and loses yaw observability.

Key tuning constants:

| Constant | Default | Units | Effect |
|----------|---------|-------|--------|
| `twoKp` | 2.0 | dimensionless | Proportional gain — higher values converge faster but amplify noise |
| `twoKi` | 0.0 | dimensionless | Integral gain — non-zero corrects steady-state gyro bias at the cost of slower response |

## Supported Sensors

Both IMUs on Navio2 are supported. Select at runtime with the `-i` flag (see [Navio2 Dual IMU](imu.md) for hardware details):

| Flag | Sensor |
|------|--------|
| `-i mpu` | MPU9250 (primary IMU) |
| `-i lsm` | LSM9DS1 (secondary IMU) |

## Building and Running

```bash
cd Navio2/C++/Examples
make
sudo chrt -f 99 ./AHRS -i mpu
```

`chrt -f 99` sets FIFO real-time scheduling at priority 99. Without it, the Linux scheduler can preempt the update loop for tens of milliseconds, causing `dt` spikes that accumulate as quaternion drift — most visibly as yaw wander. The [Emlid Raspbian](raspbian-emlid.md) image includes the PREEMPT_RT kernel patch, which makes real-time priority scheduling effective.

Output is printed to the console as roll, pitch, and yaw in degrees. Optionally pass an IP address and port to stream quaternion data over UDP for 3D visualisation:

```bash
sudo chrt -f 99 ./AHRS -i mpu 192.168.1.100 7000
```

Emlid provides a 3D visualizer that renders the attitude as an animated block on a PC or Mac. Run the visualizer before starting the AHRS process:

```bash
# On PC/Mac — run first, listens on port 7000
cd Navio2/Utilities/3DIMU
python 3Dimu.py
```

Visualizer dependencies:

- **Mac:** `sudo pip install PyOpenGL PyOpenGL_accelerate pyserial`
- **Windows:** install [Python 2.7](https://www.python.org/downloads/), [PyOpenGL 3.0.2](https://pypi.python.org/pypi/PyOpenGL/3.0.2), [pyserial 2.7](https://pypi.python.org/pypi/pyserial/2.7),. Disable Windows Firewall for the connection to succeed.

## Gyro Offset Calibration

Call `setGyroOffset()` before the main loop to measure and store the gyroscope bias while the sensor is stationary. The bias is subtracted from each gyro reading during the update. Keep the board still for approximately one second during calibration.

```cpp
AHRS ahrs(std::move(imu));
ahrs.setGyroOffset();   // board must be stationary
while (true) {
    ahrs.update(dt);
    float roll, pitch, yaw;
    ahrs.getEuler(&roll, &pitch, &yaw);
    printf("Roll: %.1f  Pitch: %.1f  Yaw: %.1f\n", roll, pitch, yaw);
}
```

## Output: Euler Angles and Quaternion

`getEuler()` converts the internal quaternion to ZYX Euler angles (yaw-pitch-roll convention) in degrees. Direct quaternion component access:

| Method | Returns |
|--------|---------|
| `getW()` | Scalar component q0 |
| `getX()` | Vector component q1 |
| `getY()` | Vector component q2 |
| `getZ()` | Vector component q3 |

Use quaternions directly when feeding attitude data to a gimbal controller or 3D renderer to avoid gimbal-lock singularities at ±90° pitch.

## Limitations

- No Python implementation is provided in the Navio2 repository — AHRS is C++ only.
- Yaw accuracy depends entirely on magnetometer quality. Compass interference from motors and power wiring degrades heading. Hard- and soft-iron calibration offsets must be applied to the magnetometer readings before use in a demanding application.
- The Mahony filter has no sensor noise model. For state estimation in an autonomous vehicle, prefer ArduPilot's EKF3, which fuses GPS, barometer, optical flow, and lidar in addition to IMU.

## Related Concepts

- [Navio2 Dual IMU (MPU9250 + LSM9DS1)](imu.md)
- [Navio2 Python and C++ Programming](../../programming/navio2-python.md)
- [EKF & Navigation](../../flight-controller-software/ardupilot/ekf-navigation.md)
- [Vibration, Filtering, and Tuning](../../flight-controller-software/vibration-filtering-and-tuning.md)

## Sources

- Navio2 repository: `C++/Examples/AHRS.cpp`, `C++/Examples/AHRS.hpp` — 2026-05-22
- Mahony AHRS algorithm: S. O. Madgwick, x-io.co.uk/open-source-imu-and-ahrs-algorithms/

<!-- linted: 2026-05-23 -->
