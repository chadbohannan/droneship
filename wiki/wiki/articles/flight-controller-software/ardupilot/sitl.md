# SITL — Software in the Loop Simulation — ArduPilot

ArduPilot's SITL (Software in the Loop) simulator runs the actual firmware on a PC against a simulated physics model. No hardware is required. SITL is the primary tool for safe development, mission validation, script testing, and automated regression testing.

## Overview

SITL compiles ArduPilot for the `sitl` board target and links it against a flight dynamics model (FDM). The resulting binary runs like real firmware — it processes [MAVLink](mavlink.md), runs the [EKF](ekf-navigation.md), executes [Lua scripts](lua-scripting.md), and respects all [parameters](parameters.md) — but motors output to the physics simulator rather than real ESCs. [Ground control stations](gcs.md) and [MAVProxy](mavproxy.md) connect exactly as they would to a real vehicle.

Because the same source tree builds both the SITL binary and real firmware via the [build system](build-system.md)'s board abstraction (see [AP_HAL](ap-hal.md)), behavior validated in SITL — flight modes, failsafe sequences, mission logic, Lua handlers — transfers directly to flight hardware. The simulator is the first stop for every ArduPilot pull request: every change is regression-tested in SITL by CI before it can merge.

## Installation

SITL runs on Linux natively and on Windows/macOS via WSL2 or Docker. The minimal setup:

```bash
# Clone ArduPilot
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot
cd ardupilot

# Install dependencies (Ubuntu/Debian)
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile

# Build and launch (first launch builds automatically)
Tools/autotest/sim_vehicle.py -v ArduCopter --console --map
```

The first launch takes 2–5 minutes to build; subsequent launches with `--no-rebuild` start in seconds.

## sim_vehicle.py

`sim_vehicle.py` is the SITL launcher. It builds the firmware, starts the physics backend, launches MAVProxy, and opens optional display windows.

### Key Flags

| Flag | Description |
|------|-------------|
| `-v ArduCopter` | Vehicle type (ArduCopter, ArduPlane, ArduRover, ArduSub, Blimp, AntennaTracker) |
| `-f quad` | Frame type (quad, hexa, octo, heli, plane, tailsitter, gazebo-iris, etc.) |
| `-L KSFO` | Start location (named entry from `Tools/autotest/locations.txt`, or `lat,lon,alt,hdg`) |
| `--console` | Open MAVProxy console window |
| `--map` | Open interactive map display |
| `--no-rebuild` | Skip rebuild (saves time if code unchanged) |
| `-w` | Wipe parameters to defaults |
| `--speedup 2` | Run simulation at 2× real time (1–10 typical; higher values may destabilise the EKF) |
| `-I 1` | Instance number — offsets all UDP ports by 10 per instance for multi-vehicle |
| `-D` | Run under gdb for source-level debugging |
| `--valgrind` | Run under valgrind for memory diagnostics |
| `-A "--serial0=udpclient:..."` | Pass extra ArduPilot arguments |

### Connecting Mission Planner

```bash
# SITL outputs MAVLink on UDP 14550 by default
# Mission Planner: connect to UDP port 14550
sim_vehicle.py -v ArduCopter --console --map \
  -A "--serial0=udpclient:192.168.1.10:14550"
```

MAVProxy auto-connects when started. Mission Planner connects to `127.0.0.1:14550` (UDP). Additional GCS clients can attach via MAVProxy's `output add <ip>:<port>` command, which fans the MAVLink stream to multiple endpoints without losing the primary connection.

## Physics Backends

SITL ships with a built-in physics model (default) plus adapters for external simulators:

| Backend | Use Case | Setup |
|---------|---------|-------|
| Built-in | Development, testing, scripting | Default — no setup needed |
| [Gazebo](gazebo-sitl.md) | [ROS](../../programming/ros-integration.md) integration, sensor noise, multi-vehicle | Requires separate Gazebo install |
| JSBSim | High-fidelity fixed-wing aerodynamics | Requires JSBSim install |
| RealFlight | High-fidelity RC sim with graphics | Requires RealFlight + Windows |
| X-Plane | Fixed-wing with photorealistic visuals | Requires X-Plane |
| AirSim / Unreal | Photorealistic rendering + camera/lidar simulation | Requires Unreal Engine |
| Webots | Robotics simulation | Requires Webots |
| FlightAxis | Commercial high-fidelity FDM | Requires RealFlight 9+ |

For most ArduCopter development work, the built-in backend is sufficient. Move to Gazebo when you need realistic sensor noise, camera rendering, or environmental obstacles; see [Gazebo SITL](gazebo-sitl.md) for the bridge plugin and world setup.

## MAVProxy in SITL

[MAVProxy](mavproxy.md) starts automatically and provides three windows: command prompt, console (status), and map. Key SITL commands in MAVProxy:

```bash
arm throttle        # arm
mode guided         # switch to Guided
mode auto           # start mission
wp list             # view mission
graph ATT.Roll      # live plot
param set ATC_RAT_RLL_P 0.2
log download        # download last log
```

## Failure Injection

SITL exposes a family of `SIM_*` parameters that inject faults at runtime, letting you exercise failsafe and EKF-recovery paths without leaving the desk. Set them live from MAVProxy with `param set`.

| Parameter | Effect | Typical use |
|-----------|--------|-------------|
| `SIM_GPS_DISABLE` | `1` = stop GPS updates | Verify GPS failsafe, EKF dead-reckoning |
| `SIM_GPS_GLITCH_X/Y/Z` | Inject position glitch (m) | EKF innovation gating, glitch protection |
| `SIM_RC_FAIL` | `1` = no-pulses, `2` = low-throttle | RC failsafe, RTL trigger |
| `SIM_BARO_DISABLE` | `1` = freeze barometer | Alt-source fallback, baro-GPS blending |
| `SIM_MAG_FAIL` | `1` = compass dropout | Compass redundancy, yaw recovery |
| `SIM_BATT_VOLTAGE` | Force battery voltage (V) | Battery failsafe, low-voltage RTL |
| `SIM_WIND_SPD` / `SIM_WIND_DIR` | Steady wind (m/s, deg) | Position-hold and waypoint tracking under wind |
| `SIM_WIND_TURB` | Turbulence intensity (m/s) | Stress-test attitude controller |
| `SIM_ENGINE_FAIL` | Bitmask of motors to disable | Motor-out tests on multirotors |
| `SIM_VIB_FREQ_X/Y/Z` | IMU vibration frequency (Hz) | Vibration filtering, EKF accel innovation |
| `SIM_SPEEDUP` | Simulation rate multiplier | Runtime equivalent of `--speedup` |

Full list lives in `libraries/SITL/SIM_Aircraft.cpp`. Combine with autotest scripts to lock failure scenarios into regression tests.

## Log Replay

Reproduce a real flight in simulation from a dataflash log (see [Logging and Analysis](logging.md) for log capture):

```bash
# Build replay tool
./waf configure --board=sitl --debug && ./waf replay

# Run replay
build/sitl/tool/Replay logs/00000001.BIN
```

The replay re-runs the EKF against the original sensor data. Use it to test filter parameter changes or diagnose EKF failures without repeating the flight.

Enable `LOG_REPLAY = 1` and `LOG_DISARMED = 1` on the vehicle to capture data suitable for replay. Logs without these flags lack the raw IMU/GPS records the replay tool needs.

## Automated Testing

ArduPilot's test infrastructure has three distinct layers. All three run in CI on every pull request; all must pass before a PR can merge.

### Layer 1 — SITL Autotest (Integration Tests)

The primary layer. Tests spawn a full simulated vehicle and execute scripted flight scenarios via MAVLink. Each test method arms, flies, injects faults or commands, and asserts expected vehicle state.

```bash
# Run the entire ArduCopter test suite (builds first)
Tools/autotest/autotest.py build.Copter test.Copter

# Run one specific named test
Tools/autotest/autotest.py build.Copter test.Copter.RTLYaw

# Equivalent shorthand used in CI
Tools/autotest/autotest.py ArduCopter
```

Vehicle test suites are in `Tools/autotest/`:

| File | Vehicle |
|------|---------|
| `arducopter.py` | Multirotor (ArduCopter) |
| `arduplane.py` | Fixed-wing (ArduPlane) |
| `rover.py` | Rover |
| `ardusub.py` | ArduSub |
| `helicopter.py` | Traditional helicopter |

Each suite is a Python class (`AutoTestCopter`, etc.) inheriting from `vehicle_test_suite.TestSuite`. Tests are plain methods — they use `self.takeoff()`, `self.change_mode()`, `self.set_parameters()`, `self.assert_receive_message()`, etc. Because the test harness speaks [pymavlink](../../programming/pymavlink.md) directly, a test method is also a working example of MAVLink-based automation. See [pymavlink](../../programming/pymavlink.md) for the underlying API.

```python
# Minimal custom test structure
class MyTest(AutoTestCopter):
    def TestHover(self):
        self.takeoff(10)
        self.hover(10)
        self.do_RTL()

    def tests(self):
        return [self.TestHover]
```

### Layer 2 — C++ Unit Tests (GTest)

Fast, isolated tests of library functions with no simulator. Tests live in `libraries/<lib>/tests/` and use GoogleTest via `#include <AP_gtest.h>`.

```bash
# Build unit tests (compiles for both linux and sitl targets)
./waf configure --board=sitl
./waf tests

# Run all unit tests
Tools/autotest/autotest.py run.unit_tests

# Run a single test binary directly
build/sitl/tests/test_math
```

Example test (`libraries/AP_Math/tests/test_math.cpp`):

```cpp
#include <AP_gtest.h>

TEST(MathTest, IsZero) {
    EXPECT_TRUE(is_zero(0.0f));
    EXPECT_FALSE(is_zero(1.0f));
}

AP_GTEST_MAIN()
```

Unit tests build for two targets — `linux` (native) and `sitl` — and run binaries from `build/<target>/tests/`. CI runs both. Add unit tests for any new utility function or library that has deterministic, hardware-independent behaviour.

### Layer 3 — Python Tests (pytest)

Tests for Python tooling. Two locations:

```bash
# Autotest framework unit tests
pytest Tools/autotest/unittest/

# Project-level Python tests (run by CI on every PR)
pytest tests/
```

`tests/` contains tests following standard pytest discovery conventions (`test_*.py` or `*_test.py`). Files must not execute code at global scope — use `if __name__ == "__main__":` guards, since pytest imports files during discovery.

`Tools/autotest/unittest/` tests the autotest framework itself — parameter annotation utilities, log parsers, and similar tooling.

## Multi-Vehicle Simulation

Each SITL instance owns a block of UDP ports. Launch additional vehicles with `-I N` to offset ports by `10 × N`:

```bash
# Terminal 1 — instance 0 (default ports: 14550, 5760)
sim_vehicle.py -v ArduCopter -I 0 --sysid 1

# Terminal 2 — instance 1 (ports: 14560, 5770)
sim_vehicle.py -v ArduCopter -I 1 --sysid 2 \
  -L KSFO --add-param-file=swarm.parm
```

Set distinct `SYSID_THISMAV` values so the GCS can address each vehicle individually. For shared-world physics and inter-vehicle collision, use the Gazebo backend.

## Simulation on Hardware (SoH)

ArduPilot's "Simulation on Hardware" mode runs the SITL physics model on a real flight controller instead of on a PC. The firmware still believes it is flying — motors, servos, and peripherals stay disarmed at the HAL level — but the board-specific code paths (sensor drivers, DMA timing, RTOS scheduling) execute on the target silicon. This catches issues that pure-PC SITL cannot: driver races, peripheral bus contention, and timing-sensitive scheduler bugs.

SoH is distinct from traditional Hardware-in-the-Loop, where a separate PC runs the physics and streams sensor data into real firmware over a serial link. Modern ArduPilot favours SoH; classic HITL is deprecated.

## Related Concepts

- [Build System](build-system.md)
- [AP_HAL](ap-hal.md)
- [Architecture](architecture.md)
- [Ground Control Stations](gcs.md)
- [MAVProxy](mavproxy.md)
- [MAVLink](mavlink.md)
- [Lua Scripting](lua-scripting.md)
- [Parameters](parameters.md)
- [EKF and Navigation](ekf-navigation.md)
- [Logging and Analysis](logging.md)
- [Gazebo SITL](gazebo-sitl.md)
- [Navio2 SITL](../../flight-controller-hardware/navio2/navio2-sitl.md)
- [pymavlink](../../programming/pymavlink.md)
- [ROS and ROS2 Integration](../../programming/ros-integration.md)

## Sources

- [Using SITL for ArduPilot Testing — ArduPilot dev docs](https://ardupilot.org/dev/docs/using-sitl-for-ardupilot-testing.html) — 2026-05-22
- [SITL with Gazebo — ArduPilot dev docs](https://ardupilot.org/dev/docs/sitl-with-gazebo.html) — 2026-05-22
- [Autotest Framework — ArduPilot dev docs](https://ardupilot.org/dev/docs/the-ardupilot-autotest-framework.html) — 2026-05-22
- [Testing with Replay — ArduPilot dev docs](https://ardupilot.org/dev/docs/testing-with-replay.html) — 2026-05-22
- [SITL Parameters reference — ArduPilot dev docs](https://ardupilot.org/dev/docs/sitl-with-airsim.html) — 2026-05-23
- [Simulation on Hardware — ArduPilot dev docs](https://ardupilot.org/dev/docs/simulation-2.html) — 2026-05-23
- [AGENTS.md — ArduPilot GitHub](https://github.com/ArduPilot/ardupilot/blob/master/AGENTS.md) — 2026-05-23
- [autotest.py — ArduPilot GitHub](https://github.com/ArduPilot/ardupilot/blob/master/Tools/autotest/autotest.py) — 2026-05-23

<!-- linted: 2026-05-23 -->
