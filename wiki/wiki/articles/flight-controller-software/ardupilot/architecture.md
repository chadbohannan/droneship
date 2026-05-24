# ArduPilot Architecture

ArduPilot's architecture is a single-threaded cooperative scheduler running on top of a hardware abstraction layer (AP_HAL). Vehicle-specific code (ArduCopter, ArduPlane, ArduRover) builds on a common library ecosystem — the same EKF, motor control, filtering, and MAVLink code runs on every vehicle type.

## Overview

The central design principle is predictable timing: the main loop runs at a fixed rate (400 Hz for copters) and tasks must complete within their allocated time slot. If a task overruns, the scheduler logs an overrun and the next task is delayed. No preemption occurs at the application level — all tasks are cooperative.

## Scheduler

`AP_Scheduler` drives the main loop. Tasks are registered in a `SCHED_TASK` table with:
- Function pointer to execute
- Desired rate (Hz)
- Maximum allowed execution time (µs)

The scheduler calls each task at its configured rate and tracks actual execution time. Tasks that exceed their budget are flagged in the `PM` (performance monitor) log message. `SCHED_LOOP_RATE` (default 400 Hz for copters) sets the fundamental loop period.

The loop is synchronised to IMU data arrival — the scheduler waits for the next IMU sample before starting the next cycle. This ensures attitude estimation is driven by fresh sensor data rather than running at an unconstrained pace.

## Control Cascade

ArduCopter implements a nested control loop cascade:

```
Position setpoint
  → Position controller (2–10 Hz)
  → Velocity controller (50 Hz)
  → Attitude controller (400 Hz)
     → Angle controller (outer, P only)
     → Rate controller (inner, PID+FF)
  → Motor mixing (400 Hz)
  → Motor output
```

Each layer outputs a setpoint for the next. The innermost rate controller runs at the full 400 Hz loop rate. See [PID Tuning](pid-tuning.md) for rate controller parameters.

## Library Structure

ArduPilot organises shared functionality into libraries under `libraries/`:

| Library | Purpose |
|---------|---------|
| `AP_AHRS` | Attitude and heading reference system — wraps EKF3 |
| `AP_NavEKF3` | Extended Kalman Filter navigation |
| `AP_InertialSensor` | IMU driver management, calibration, filtering |
| `AP_Compass` | Magnetometer management |
| `AP_GPS` | GPS protocol parsing, blending, health |
| `AP_Baro` | Barometric altimeter |
| `AP_MotorsMatrix` | Motor mixing matrix for multirotors |
| `AP_Mission` | Waypoint storage and execution |
| `AP_Fence` | Geofence enforcement |
| `AP_HAL` | Hardware abstraction |
| `AP_Scheduler` | Cooperative task scheduler |
| `GCS_MAVLink` | MAVLink protocol implementation |
| `AC_PID` | PID controller |
| `AP_Scripting` | Lua scripting engine |

Vehicle-specific code lives in `ArduCopter/`, `ArduPlane/`, `ArduRover/`, etc. and calls into these libraries.

## Vehicle Class Hierarchy

All vehicle implementations inherit from `AP_Vehicle`, which provides the scheduler, serial port management, HAL callbacks, and parameter system. Flight modes in ArduCopter are classes inheriting from `Mode`, each implementing `init()`, `run()`, and `exit()` methods. The active mode's `run()` is called every scheduler cycle.

## Threading Model

ArduPilot uses a small number of threads:

- **Main thread**: Runs the scheduler and all application tasks at 400 Hz
- **Timer thread** (priority 181): Handles 1 kHz time-sensitive operations
- **IO thread**: Handles SD card, EEPROM, and FRAM writes (isolated to prevent blocking the main loop)
- **UART thread**: Receives and buffers incoming serial data

Application code runs exclusively on the main thread — no locking is needed for shared state between tasks. Sensor drivers use the timer thread for DMA completion handling.

## State Estimation Flow

```
IMU (400 Hz) ──→ AP_InertialSensor ──→ AP_NavEKF3 ──→ AP_AHRS
GPS (5-10 Hz) ─→ AP_GPS ────────────→ AP_NavEKF3
Baro (10 Hz) ──→ AP_Baro ───────────→ AP_NavEKF3
Compass (10 Hz) → AP_Compass ────────→ AP_NavEKF3
                                             ↓
                                      Position, velocity, attitude
                                      available to all modules
                                      via AP_AHRS interface
```

## Parameter System

Parameters are registered at compile time with `AP_Param::setup_sketch_defaults()`. Each library declares its parameters as class members. The parameter system handles serialisation to/from EEPROM and MAVLink PARAM_VALUE messages. See [Parameter System](parameters.md).

## Related Concepts

- [AP_HAL](ap-hal.md)
- [Build System](build-system.md)
- [SITL Simulation](sitl.md)
- [EKF and Navigation](ekf-navigation.md)
- [PID Tuning](pid-tuning.md)
- [Lua Scripting](lua-scripting.md)

## Sources

- [Learning ArduPilot: Introduction — ArduPilot dev docs](https://ardupilot.org/dev/docs/learning-ardupilot-introduction.html) — 2026-05-22
- [Multirotor Control Systems — ArduPilot DeepWiki](https://deepwiki.com/ArduPilot/ardupilot/3.1.2-multirotor-control-systems) — 2026-05-22
- [Core Architecture — ArduPilot DeepWiki](https://deepwiki.com/ArduPilot/ardupilot/2-core-architecture) — 2026-05-22
- [Threading — ArduPilot dev docs](https://ardupilot.org/dev/docs/learning-ardupilot-threading.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
