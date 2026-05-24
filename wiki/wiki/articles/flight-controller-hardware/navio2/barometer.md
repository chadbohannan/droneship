# Navio2 Barometer (MS5611)

High-resolution pressure sensor providing altitude estimation to within 10 cm resolution.

## Overview

Navio2 uses a Measurement Specialties MS5611-01BA03 barometric pressure sensor connected over I2C. The MS5611 is the only sensor on its I2C bus — other sensors were deliberately moved to SPI to eliminate bus transaction noise during the MS5611's analog-to-digital conversion phase. Noise injected during conversion shifts the reported pressure and produces false altitude jumps; the isolated I2C bus eliminates this failure mode.

The sensor resolves pressure differences equivalent to approximately 10 cm of altitude change under calm, thermally stable conditions. In practice, GPS/barometer fusion in ArduPilot's EKF provides the altitude estimate used for flight, with the barometer contributing most heavily during hover and slow flight where GPS vertical accuracy degrades.

## Specifications

| Parameter | Value |
|-----------|-------|
| Chip | MS5611-01BA03 |
| Pressure range | 10–1200 mbar |
| Resolution (RMS) | 0.012 mbar (≈ 10 cm altitude) |
| Temperature range | −40 to +85 °C |
| Interface | I2C1 (exclusive bus) |
| Supply voltage | 3.3 V (via Navio2 regulator) |
| Conversion time | 0.5–8.22 ms (OSR-dependent) |

## Development Example

Run the included barometer example to verify sensor operation:

```bash
cd C++/Examples/Barometer
make
./Barometer
```

Or in Python:

```bash
cd Python
python Barometer.py
```

Expected output (temperature is elevated due to heat from the Raspberry Pi SoC):

```
Temperature(C): 34.3509172821 Pressure(millibar): 1030.4646104
Temperature(C): 34.2971904755 Pressure(millibar): 1030.4639519
Temperature(C): 34.2795449066 Pressure(millibar): 1030.4555444
Temperature(C): 34.3018652344 Pressure(millibar): 1030.4692192
```

## I2C Bus Isolation

The Raspberry Pi exposes two I2C buses (I2C0 and I2C1). Navio2 places the MS5611 on I2C1 as the sole occupant. The IMU chips (MPU-9250 and LSM9DS1) and the GPS are connected via SPI. This single-occupant arrangement ensures no other device issues I2C START conditions during the MS5611's 8 ms conversion window, which would otherwise inject noise through capacitive coupling on the shared bus lines.

## UV Light Sensitivity

The MS5611 uses a steel-cap integrated circuit package that provides minimal UV shielding. Direct sunlight on the sensor causes thermal gradients and photoelectric effects in the reference circuitry, producing sudden apparent altitude jumps of 5–20 m. Mitigation options:

- Cover the sensor with a small piece of acoustic foam or microphone fabric that blocks light but allows pressure equalization.
- Mount the Navio2 / Raspberry Pi inside a partially enclosed frame that shadows the board.
- Use a 3D-printed enclosure with a small vent hole for pressure access.

Do not seal the sensor completely — the barometer requires atmospheric pressure access to function.

## ArduPilot Configuration

ArduPilot auto-detects the MS5611 on Navio2 with no parameter changes required. Relevant parameters for altitude behavior:

| Parameter | Function | Default |
|-----------|----------|---------|
| BARO_PRIMARY | Primary barometer index | 0 (first found) |
| EK3_ALT_SOURCE | EKF altitude source | 0 (baro) |
| EK3_BARO_DELAY | Barometer measurement delay (ms) | 0 |
| RNGFND_TYPE | Rangefinder type (if adding sonar/lidar) | 0 (none) |

For indoor flight without GPS, set EK3_ALT_SOURCE to 0 (barometer only) and ensure the sensor is shielded from air conditioning drafts, which cause pressure transients that appear as altitude changes.

## Raspberry Pi Heat Conduction

The MS5611 is physically close to the Raspberry Pi's SoC, which generates substantial heat under load. The board conducts heat through the standoffs and PCB to the Navio2, causing the barometer to report ambient temperatures 5–15 °C above actual room temperature. This does not affect pressure accuracy significantly (the MS5611 applies on-chip temperature compensation), but temperature readouts from the barometer should not be used as an environmental reference. The effect is most pronounced on Raspberry Pi 4, which runs hotter than earlier models.

## Ground Effect and Prop Wash

At low altitude (below approximately 1 m), rotor downwash creates a local pressure increase under the aircraft. This causes the barometer to read falsely low, making the autopilot descend slightly on final approach. The effect is most pronounced on large-diameter propellers. Configure the landing approach to use rangefinder data below a set altitude if precision landing is required.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Dual IMU](imu.md)
- [EKF & Navigation](../../flight-controller-software/ardupilot/ekf-navigation.md)
- [Sensors](../../flight-controller-software/ardupilot/sensors.md)

## Sources

- [Barometer — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/barometer/) — 2026-05-22
- [NAVIO2 Overview — ArduPilot](https://ardupilot.org/copter/docs/common-navio2-overview.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
