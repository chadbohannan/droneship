# Drone Wiki Index

## Airframes
- [Airframes](wiki/articles/airframes/airframes.md) — Frame classes, materials, construction types, and size conventions
- [Rotor Configurations](wiki/articles/airframes/rotor-configurations.md) — Motor count, quadcopter geometry layouts, spin direction, and tradeoffs

## Propulsion
- [Brushless Motors](wiki/articles/propulsion/motors.md) — KV rating, stator sizing, frame-to-motor matching, construction details, selection workflow
- [Propellers](wiki/articles/propulsion/propellers.md) — Notation, diameter/pitch/blade count tradeoffs, materials, mounting, selection by use case
- [Propulsion System Design](wiki/articles/propulsion/propulsion-system-design.md) — Thrust-to-weight calculation, system matching workflow, reference configurations
- [ESC — Electronic Speed Controller](wiki/articles/propulsion/esc.md) — Protocols, firmware, bidirectional DSHOT, calibration

## Flight Controller Software

- [Vibration, Filtering, and Tuning](wiki/articles/flight-controller-software/vibration-filtering-and-tuning.md) — Noise bands, filter types (LPF, notch, RPM), spectral analysis, firmware params

### ArduPilot
- [ArduPilot](wiki/articles/flight-controller-software/ardupilot.md) — Overview, history, firmware variants, comparison table, and **full article map**

  **Setup** · [First Flight](wiki/articles/flight-controller-software/ardupilot/first-flight.md) · [Arming & Pre-Flight](wiki/articles/flight-controller-software/ardupilot/arming-preflight.md) · [Parameters](wiki/articles/flight-controller-software/ardupilot/parameters.md) · [GCS](wiki/articles/flight-controller-software/ardupilot/gcs.md)

  **Flight** · [Flight Modes](wiki/articles/flight-controller-software/ardupilot/flight-modes.md) · [EKF & Navigation](wiki/articles/flight-controller-software/ardupilot/ekf-navigation.md) · [GPS/GNSS](wiki/articles/flight-controller-software/ardupilot/gps-gnss.md) · [Optical Flow](wiki/articles/flight-controller-software/ardupilot/optical-flow.md) · [Failsafes](wiki/articles/flight-controller-software/ardupilot/failsafes.md) · [Geofence](wiki/articles/flight-controller-software/ardupilot/geofence.md) · [Missions](wiki/articles/flight-controller-software/ardupilot/mission-planning.md)

  **Tuning** · [PID Tuning](wiki/articles/flight-controller-software/ardupilot/pid-tuning.md) · [Motor Mixing](wiki/articles/flight-controller-software/ardupilot/motor-mixing.md) · [Logging](wiki/articles/flight-controller-software/ardupilot/logging.md) · [Power Monitor](wiki/articles/flight-controller-software/ardupilot/power-monitoring.md)

  **Sensors** · [Sensors](wiki/articles/flight-controller-software/ardupilot/sensors.md) · [CAN/DroneCAN](wiki/articles/flight-controller-software/ardupilot/can-dronecan.md) · [RC Systems](wiki/articles/flight-controller-software/ardupilot/rc-systems.md) · [Telemetry Radios](wiki/articles/flight-controller-software/ardupilot/telemetry-radios.md)

  **Connectivity** · [MAVLink](wiki/articles/flight-controller-software/ardupilot/mavlink.md) · [MAVProxy](wiki/articles/flight-controller-software/ardupilot/mavproxy.md) · [Companion Computers](wiki/articles/flight-controller-software/ardupilot/companion-computers.md) · [Lua Scripting](wiki/articles/flight-controller-software/ardupilot/lua-scripting.md)

  **Internals** · [Architecture](wiki/articles/flight-controller-software/ardupilot/architecture.md) · [AP_HAL](wiki/articles/flight-controller-software/ardupilot/ap-hal.md) · [Hardware](wiki/articles/flight-controller-software/ardupilot/hardware.md) · [Build System](wiki/articles/flight-controller-software/ardupilot/build-system.md) · [Custom Firmware](wiki/articles/flight-controller-software/ardupilot/custom-firmware.md) · [SITL](wiki/articles/flight-controller-software/ardupilot/sitl.md) · [Gazebo SITL](wiki/articles/flight-controller-software/ardupilot/gazebo-sitl.md)

## Flight Controller Hardware

### Navio2
- [Navio2](wiki/articles/flight-controller-hardware/navio2/navio2.md) — Emlid autopilot HAT for Raspberry Pi running ArduPilot on Linux
- [Navio2 Hardware Setup](wiki/articles/flight-controller-hardware/navio2/hardware-setup.md) — Assembly, wiring, servo rail pinout, connector reference
- [Navio2 Dual IMU (MPU9250 + LSM9DS1)](wiki/articles/flight-controller-hardware/navio2/imu.md) — Redundant 9-DOF IMU pair on dual SPI buses
- [Navio2 AHRS](wiki/articles/flight-controller-hardware/navio2/ahrs.md) — Mahony complementary filter fusing IMU + magnetometer into roll/pitch/yaw
- [Navio2 GNSS Receiver](wiki/articles/flight-controller-hardware/navio2/gnss.md) — Multi-constellation u-blox receiver (GPS/GLONASS/BeiDou/Galileo)
- [Navio2 Barometer (MS5611)](wiki/articles/flight-controller-hardware/navio2/barometer.md) — High-resolution pressure sensor, UV sensitivity, I2C isolation
- [Navio2 ADC](wiki/articles/flight-controller-hardware/navio2/adc.md) — 6-channel ADC: board/servo rail voltage, power module V/I, two general-purpose inputs
- [Navio2 RGB LED](wiki/articles/flight-controller-hardware/navio2/led.md) — sysfs-controlled RGB LED; ArduPilot status patterns and user API
- [Navio2 PWM Output](wiki/articles/flight-controller-hardware/navio2/pwm-output.md) — 14-channel 5 V servo rail driven by onboard co-processor
- [Navio2 RC Input (PPM/SBUS)](wiki/articles/flight-controller-hardware/navio2/rc-input.md) — Co-processor RC decoding for PPM and SBUS receivers
- [Navio2 Power System](wiki/articles/flight-controller-hardware/navio2/power-system.md) — Triple-redundant power, power module specs, servo rail BEC requirement
- [Navio2 ArduPilot Configuration](wiki/articles/flight-controller-hardware/navio2/ardupilot-configuration.md) — Systemd service, UDP GCS, Navio2-specific parameters, relay/GPIO mapping
- [Navio2 Emlid Raspbian OS](wiki/articles/flight-controller-hardware/navio2/raspbian-emlid.md) — Custom Linux image with ArduPilot, ROS, and Navio2 kernel drivers
- [emlidtool](wiki/articles/flight-controller-hardware/navio2/emlidtool.md) — CLI for system diagnostics, vehicle selection, and RCIO firmware management
- [Navio2 RCIO Co-Processor](wiki/articles/flight-controller-hardware/navio2/rcio.md) — Kernel modules, sysfs map, ADC channels, PWM watchdog, firmware update, troubleshooting
- [Navio2 SITL](wiki/articles/flight-controller-hardware/navio2/navio2-sitl.md) — x86 and native RPi SITL, GCS connection, parameter parity, Gazebo integration

## GNSS
- [RTK GPS](wiki/articles/gnss/rtk-gps.md) — Centimetre-level positioning: Fix/Float/Single statuses, base/rover setup, ArduPilot integration
- [PPK — Post-Processed Kinematic](wiki/articles/gnss/ppk.md) — Post-flight log processing for UAV mapping; hot-shoe sync, RTKLIB workflow
- [Emlid Reach M+ and M2](wiki/articles/gnss/reach-m.md) — UAV GNSS rover modules: specs, connectors, antenna placement, radio wiring

## Radio Systems
*(empty)*

## FPV Systems
*(empty)*

## Power Systems
- [Battery](wiki/articles/power-systems/battery.md) — LiPo/Li-Ion chemistry, C-rating, cell config, charging, failure modes

## Programming
- [DroneKit-Python](wiki/articles/programming/dronekit.md) — Python MAVLink library: telemetry, Guided mode commands, mission upload
- [MAVSDK](wiki/articles/programming/mavsdk.md) — Modern multi-language MAVLink SDK: plugins, async patterns, offboard control
- [PyMAVLink](wiki/articles/programming/pymavlink.md) — Low-level MAVLink parser/generator underlying DroneKit and MAVProxy
- [ROS and ROS2 Integration](wiki/articles/programming/ros-integration.md) — MAVROS, ardupilot_ros, sensor topics, setpoint control, CV pipelines
- [Navio2 ROS and MAVROS](wiki/articles/programming/navio2-ros.md) — Running ROS with MAVROS on Navio2's Raspberry Pi
- [Navio2 Python and C++ Programming](wiki/articles/programming/navio2-python.md) — Direct sensor access via Emlid's open-source libraries

## Maintenance
*(empty)*

## Regulations
*(empty)*

## Glossary
- [Glossary](wiki/articles/glossary/glossary.md) — Definitions of abbreviations and technical terms: GNSS/RTK, flight controllers, propulsion, protocols, and more
