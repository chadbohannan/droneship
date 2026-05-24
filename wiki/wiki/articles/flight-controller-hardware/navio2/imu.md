# Navio2 Dual IMU (MPU9250 + LSM9DS1)

Two independent 9-DOF Inertial Measurement Units (IMUs) — accelerometer, gyroscope, and magnetometer — providing redundant attitude sensing for ArduPilot.

## Overview

An Inertial Measurement Unit (IMU) is a sensor package that measures the forces and rotation rates acting on a body. A 9-DOF (nine degrees of freedom) IMU combines a three-axis accelerometer (linear acceleration), a three-axis gyroscope (angular rate), and a three-axis magnetometer (magnetic field direction). Together these let a flight controller compute attitude — roll, pitch, and yaw — in real time, independent of GPS.

Navio2 carries two IMU chips: an InvenSense MPU-9250 and an STMicroelectronics LSM9DS1. Each integrates all three sensor types, providing complete attitude-rate and magnetic-heading data. Having two independent IMUs allows ArduPilot to detect a degraded or failed sensor by comparing their outputs and automatically promote the healthy unit to primary. This is particularly valuable because single-IMU failures are often subtle — they manifest as drift rather than total loss.

Navio2 was the first Raspberry Pi HAT to use the secondary (AUX) SPI controller in addition to the primary SPI controller. Distributing the two IMUs across separate SPI buses means each chip's transactions do not impose timing jitter on the other, reducing cross-sensor noise.

## Sensor Specifications

| Parameter | MPU-9250 | LSM9DS1 |
|-----------|----------|---------|
| Gyroscope range | ±250/500/1000/2000 °/s | ±245/500/2000 °/s |
| Accelerometer range | ±2/4/8/16 g | ±2/4/8/16 g |
| Magnetometer range | ±4800 µT | ±400/800/1200/1600 µT |
| Output data rate (gyro/accel) | Up to 8 kHz (gyro), 4 kHz (accel) | Up to 952 Hz |
| Interface | SPI (primary SPI0) | SPI (AUX SPI1) |
| Temperature sensor | Yes | Yes |

**Production note:** TDK InvenSense discontinued the MPU-9250 in 2022. Navio2 boards sold after this date are new-old-stock (NOS) units that drew from the pre-discontinuation inventory. The ICM-42688-P is InvenSense's current replacement, but no Emlid hardware revision uses it; the MPU-9250 specification above remains accurate for all Navio2 boards in distribution.

## SPI Bus Architecture

Raspberry Pi exposes two SPI controllers: SPI0 (the standard master) and SPI1 (the auxiliary controller, previously unused by HATs). Navio2's kernel driver activates SPI1 for the LSM9DS1, while the MPU-9250 communicates over SPI0. Both sensors can therefore be polled in the same loop without one blocking the other.

The MS5611 barometer was deliberately left as the sole device on I2C to prevent SPI bus noise from corrupting its high-resolution ADC conversion. This three-bus architecture (SPI0, SPI1, I2C) is a design principle that distinguishes Navio2 from earlier single-bus autopilot HATs.

## ArduPilot IMU Parameters

ArduPilot numbers IMUs from 1. On Navio2, IMU 1 is the MPU-9250 and IMU 2 is the LSM9DS1.

| Parameter | Function | Typical Value |
|-----------|----------|---------------|
| INS_USE | Enable IMU 1 (MPU-9250) | 1 |
| INS_USE2 | Enable IMU 2 (LSM9DS1) | 1 |
| INS_GYRO_FILTER | Low-pass filter cutoff (Hz) | 20 |
| INS_ACCEL_FILTER | Accelerometer LPF cutoff (Hz) | 20 |
| INS_ACC_BODYFIX | Body-frame accelerometer correction | 1 |

When both IMUs are enabled, ArduPilot averages their outputs during normal flight. If one IMU diverges beyond a threshold, it is flagged and the other becomes sole input to the EKF.

## Magnetometer (Compass) Details

The MPU-9250 contains an AK8963 magnetometer sub-chip connected via an auxiliary I2C bus internal to the MPU-9250 package. ArduPilot **disables the AK8963 by default** on Navio2 because the LSM9DS1's magnetometer shows lower initial offsets and better consistency. The LSM9DS1 magnetometer is set as the primary onboard compass (Compass #1).

Enabling the AK8963 as a secondary compass is possible through Mission Planner's Compass settings tab. In practice, an external compass module (mounted in a GPS puck away from motor noise) outperforms either onboard magnetometer and should be prioritized when available.

## AHRS — Attitude and Heading Reference System

Emlid provides a Mahony AHRS example in the emlid/Navio2 library that demonstrates fusing all nine IMU axes (accel + gyro + mag) into roll, pitch, and yaw estimates. The Mahony filter is a complementary filter: the gyroscope provides fast-response attitude rate integration, while the accelerometer and magnetometer correct slow drift via proportional-integral feedback.

The example streams orientation quaternions over a network socket to a Python 3D visualizer that can run on any PC or Mac on the same network:

```bash
# On Raspberry Pi (pass PC/Mac IP and port)
cd Navio2/C++/Examples/AHRS
make
sudo ./AHRS -i mpu 192.168.1.100 7000   # -i lsm for LSM9DS1

# On PC/Mac — run before starting AHRS
cd Navio2/Utilities/3DIMU
python 3Dimu.py
```

This is a development and validation tool, not ArduPilot's attitude estimator. ArduPilot uses its own EKF (Extended Kalman Filter) for flight, which is more robust than the Mahony filter for dynamic maneuvers.

## Calibration

**Accelerometer calibration** must be performed with the aircraft level and in six orientations (level, nose up/down, left/right side up, inverted). In Mission Planner, use Initial Setup → Mandatory Hardware → Accel Calibration. Perform this calibration for each IMU independently if prompted.

**Compass/magnetometer calibration** uses the onboard magnetometer in each IMU as a backup compass. An external compass (typically inside the GPS module) should be set as compass priority 1 due to its distance from motor interference. Use the compass calibration wizard and enable compass mot (COMPASS_MOTCT) if significant yaw deviation occurs at high throttle.

**Gyro calibration** happens automatically at startup; the aircraft must remain stationary for the first 3–5 seconds after boot.

## Vibration and IMU Performance

IMU performance degrades significantly when vibration aliases into the accelerometer passband. The MPU-9250's internal digital low-pass filter (configured via INS_GYRO_FILTER) is the first line of defense. ArduPilot's harmonic notch filter targets motor RPM harmonics above the LPF cutoff. Review VIBE log messages after every configuration change; VibeX/Y/Z above 30 m/s² requires better mechanical isolation.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 AHRS](ahrs.md)
- [Navio2 Barometer (MS5611)](barometer.md)
- [Vibration, Filtering, and Tuning](../../flight-controller-software/vibration-filtering-and-tuning.md)
- [EKF & Navigation](../../flight-controller-software/ardupilot/ekf-navigation.md)
- [Sensors](../../flight-controller-software/ardupilot/sensors.md)

## Sources

- [9DOF IMU — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/imu-mpu9250_lsm9ds1/) — 2026-05-22
- [NAVIO2 Overview — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-navio2-overview.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
