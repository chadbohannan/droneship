# Navio2

Autopilot HAT for Raspberry Pi that runs ArduPilot on Linux, enabling full ROS integration and Python/C++ development without a separate companion computer.

## Overview

Navio2 is a flight controller add-on board (HAT — Hardware Attached on Top) produced by Emlid that plugs directly onto a Raspberry Pi's 40-pin GPIO header. Unlike microcontroller-based flight controllers (Pixhawk, CUAV, Matek), Navio2 delegates the ArduPilot flight stack to a full Linux environment. This architectural choice means ROS, Python scripts, computer vision pipelines, and arbitrary user code all run on the same processor as the flight controller — no serial link to a companion computer is needed.

The board integrates two independent 9-DOF IMUs, a u-blox NEO-M8N multi-constellation GNSS receiver, an MS5611 high-resolution barometer, a 14-channel PWM servo co-processor, PPM/SBUS RC input decoding, a triple-redundant power supply with battery current/voltage monitoring, and an RGB status LED. Emlid distributes a customized Raspbian image with ArduPilot, MAVROS, and Navio2 kernel drivers pre-installed.

## Hardware Summary

| Feature | Details |
|---------|---------|
| Form factor | Raspberry Pi HAT (40-pin GPIO) |
| Compatible RPi | 2B, 3B, 3B+, 4B |
| IMUs | MPU-9250 (SPI0) + LSM9DS1 (SPI1/AUX) |
| GNSS | u-blox NEO-M8N (GPS/GLONASS/BeiDou/Galileo/SBAS) |
| Barometer | MS5611 (I2C1, sole occupant) |
| PWM outputs | 14 channels, 5 V, co-processor generated |
| RC input | PPM or SBUS, co-processor decoded |
| Power inputs | Power module + servo rail BEC (Battery Eliminator Circuit) + RPi USB (ideal diode arbitration) |
| Power module | 6S LiPo max, 60 A current sensing, 5.3 V / 2.25 A output |
| Status LED | RGB, sysfs-controlled |
| Antenna | MCX coax for external GNSS patch antenna |

## How It Differs from Pixhawk

| Aspect | Navio2 | Pixhawk / Matek |
|--------|--------|-----------------|
| CPU | Raspberry Pi (ARM Cortex-A, Linux) | STM32 (ARM Cortex-M, bare-metal / ChibiOS) |
| Companion computer | Not needed — same CPU | Separate board via UART/USB |
| Programming | Python, C++, ROS on Linux | Lua scripting, parameter files, MAVLink |
| ArduPilot update | `apt upgrade`, binary swap | .apj firmware upload via GCS |
| Real-time guarantees | Linux + SCHED_FIFO (~100 µs jitter) | Hard real-time (~1 µs jitter) |
| DSHOT ESC support | No (analog PWM only) | Yes (on supported boards) |
| Power consumption | Higher (RPi idle ~500 mA) | Lower (STM32 ~100 mA) |
| Weight | ~120 g (RPi 3B + Navio2) | ~40–60 g (FC only) |

Navio2 excels for research and education where programmability matters more than weight and power efficiency. Pixhawk-family boards are better for production vehicles where hard real-time guarantees, DSHOT support, and weight savings are priorities.

## Software Architecture

```
Raspberry Pi running Emlid Raspbian
├── Emlid kernel (SPI1/AUX, co-processor rcio driver)
├── ArduPilot (systemd service)
│   ├── Reads: /sys/kernel/rcio/ (RC input)
│   ├── Writes: /sys/kernel/rcio/ (PWM output)
│   ├── Reads: SPI0 (MPU-9250), SPI1 (LSM9DS1), I2C1 (MS5611), SPI (GPS)
│   └── MAVLink UDP → GCS / MAVROS
└── ROS (optional, runs alongside ArduPilot)
    └── MAVROS node ↔ ArduPilot via UDP:14650
```

## Getting Started

1. Flash the Emlid Raspbian image to a micro-SD card.
2. Configure WiFi in `/boot/wpa_supplicant.conf`.
3. Assemble Navio2 on Raspberry Pi with spacers and extension header — see [Hardware Setup](hardware-setup.md).
4. Wire ESCs, RC receiver, GPS antenna, and power module — see [Hardware Setup](hardware-setup.md) and [Power System](power-system.md).
5. SSH in and run `sudo emlidtool ardupilot configure` to select vehicle type — see [ArduPilot Configuration](ardupilot-configuration.md).
6. Connect Mission Planner via UDP and complete calibration.

## Article Map

**Hardware**
- [Hardware Setup](hardware-setup.md) — assembly, wiring, connectors, vibration isolation
- [Dual IMU (MPU9250 + LSM9DS1)](imu.md) — 9-DOF redundancy, SPI bus architecture, calibration
- [GNSS Receiver](gnss.md) — u-blox NEO-M8N, multi-constellation, antenna placement
- [Barometer (MS5611)](barometer.md) — I2C isolation, UV sensitivity, ground effect
- [PWM Output](pwm-output.md) — 14-channel servo rail, co-processor, sysfs interface
- [RC Input (PPM/SBUS)](rc-input.md) — co-processor decoding, failsafe, sysfs readback
- [Power System](power-system.md) — triple redundancy, ideal diodes, battery monitoring

**Software**
- [ArduPilot Configuration](ardupilot-configuration.md) — systemd service, serial flags, Navio2 parameters, relay/GPIO mapping
- [Emlid Raspbian OS](raspbian-emlid.md) — custom image, kernel drivers, first boot, WiFi
- [emlidtool](emlidtool.md) — CLI for diagnostics, vehicle selection, RCIO firmware management
- [RCIO Co-Processor](rcio.md) — kernel modules, full sysfs map, ADC channels, firmware update, troubleshooting
- [Navio2 SITL](navio2-sitl.md) — x86 and native RPi SITL, GCS connection, parameter parity, Gazebo
- [Navio2 ROS and MAVROS](../../programming/navio2-ros.md) — MAVROS topics, GUIDED mode, ROS 2 path
- [Navio2 Python/C++ Programming](../../programming/navio2-python.md) — emlid/Navio2 library, sensor examples, real-time scheduling

## Related Concepts

- [ArduPilot](../../flight-controller-software/ardupilot.md)
- [Companion Computers](../../flight-controller-software/ardupilot/companion-computers.md)
- [ROS and ROS2 Integration](../../programming/ros-integration.md)
- [Vibration, Filtering, and Tuning](../../flight-controller-software/vibration-filtering-and-tuning.md)

## Sources

- [NAVIO2 Overview — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-navio2-overview.html) — 2026-05-22
- [Introduction — Emlid Navio2 docs](https://docs.emlid.com/navio2/) — 2026-05-22

<!-- linted: 2026-05-23 -->
