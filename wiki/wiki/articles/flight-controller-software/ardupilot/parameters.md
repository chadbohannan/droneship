# Parameter System — ArduPilot

ArduPilot's parameter system stores all configuration values in non-volatile memory (EEPROM or FRAM) on the flight controller. Every tunable behaviour — from PID gains to failsafe thresholds to sensor calibration offsets — is a named parameter accessible via GCS or MAVLink.

## Overview

Parameters are identified by a name of up to 16 characters. Names follow a hierarchical prefix convention that groups related parameters: `ATC_RAT_RLL_P` belongs to the attitude controller rate roll proportional gain; `BATT_FS_LOW_ACT` is the battery failsafe low-voltage action. The prefix structure makes browsing and searching manageable across the 500–1000+ parameters in a typical build.

## Naming Convention

| Prefix | Subsystem |
|--------|-----------|
| `ATC_` | Attitude controller |
| `EK3_` | EKF3 navigation |
| `BATT_` | Battery monitor (BATT2_ for second battery) |
| `GPS_` | GPS configuration |
| `INS_` | Inertial navigation system |
| `MOT_` | Motor output |
| `RC_`, `RCMAP_` | RC input and channel mapping |
| `SERIAL_`, `SERIALx_` | Serial port configuration |
| `FS_` | Failsafe thresholds and actions |
| `FENCE_` | Geofence |
| `SCR_` | Lua scripting |
| `ARMING_` | Pre-arm checks |
| `WPNAV_` | Waypoint navigation |
| `SYSID_` | System and GCS identity |

Multi-instance subsystems append a number: `BATT2_MONITOR`, `COMPASS2_USE`, `GPS_TYPE2`.

## Parameter Types

| Type | Size | ArduPilot Class |
|------|------|-----------------|
| Integer (8-bit) | 1 byte | `AP_Int8` |
| Integer (16-bit) | 2 bytes | `AP_Int16` |
| Integer (32-bit) | 4 bytes | `AP_Int32` |
| Float | 4 bytes | `AP_Float` |
| 3D Vector | 12 bytes | `AP_Vector3f` |

Parameters are stored as signed integers or IEEE 754 floats. Bitmask parameters use integers; the meaning of each bit is documented in the parameter description.

## Storage

Parameters are written to EEPROM or FRAM on the flight controller. Typical storage sizes:

| Hardware | Storage | Technology |
|----------|---------|------------|
| Pixhawk (original) | 16 KB | FRAM |
| Cube Orange | 16 KB | FRAM |
| F4/F7 boards | 4–8 KB | EEPROM |

The `StorageManager` library divides storage into areas: parameters, fence points, waypoints, rally points. Parameter storage fills first; if it overflows the allocated area, new parameters are silently dropped — this is rare on modern H7 boards with generous storage.

In [SITL](sitl.md), parameters are stored in `eeprom.bin` in the working directory.

## Reading and Writing Parameters

### Mission Planner

**CONFIG → Full Parameter List** displays every parameter. Search by name or description. Modified-but-unsaved parameters are highlighted. Click **Write Parameters** to commit to the vehicle; **Refresh Params** re-reads from the vehicle.

**Save to File / Load from File** export and import `.param` files for backup, sharing, or comparison.

### MAVProxy

```bash
param show ATC_RAT_RLL_P        # Display one parameter
param set ATC_RAT_RLL_P 0.15    # Set a parameter
param show *                    # List all parameters
param show ATC_*                # List all attitude controller parameters
param download                  # Download parameter metadata
param help ATC_RAT_RLL_P        # Show description and range
```

Load parameters at MAVProxy startup:
```bash
mavproxy.py --master=/dev/ttyUSB0 --cmd="param load defaults.parm"
```

### Parameter File Format

```
# Comments begin with #
ATC_RAT_RLL_P   0.135
ATC_RAT_PIT_P   0.135
MOT_THST_EXPO   0.65
BATT_FS_LOW_ACT 2
```

## MAVLink Protocol

Parameters are read and written via MAVLink:

- **`PARAM_REQUEST_LIST`** — GCS requests all parameters; autopilot streams back `PARAM_VALUE` messages for each
- **`PARAM_REQUEST_READ`** — Request a single parameter by name or index
- **`PARAM_VALUE`** — Response containing name (16 chars), value (float), type, total count, and index
- **`PARAM_SET`** — Set a parameter; autopilot responds with `PARAM_VALUE` confirming the new value

Parameter names are more stable than indices — use names in automation scripts, not index numbers.

## Important Special Parameters

| Parameter | Use |
|-----------|-----|
| `FORMAT_VERSION` | Set to 0 and reboot to reset all parameters to firmware defaults |
| `SYSID_THISMAV` | Vehicle MAVLink system ID (default 1; change for multi-drone setups) |
| `SYSID_MYGCS` | GCS system ID (default 252 for Mission Planner) |
| `BRD_SERIAL_NUM` | Board serial number (informational) |

## Resetting Parameters

Three methods:

1. **Mission Planner**: CONFIG → Full Parameter List → Reset to Default (reboots automatically).
2. **FORMAT_VERSION**: Set `FORMAT_VERSION = 0`, reboot. All parameters reset to firmware defaults.
3. **Firmware swap**: Flash different firmware then reflash original (time-consuming; not recommended).

After reset, accelerometer and compass calibration flags are cleared — recalibrate or use Mission Planner's Force Calibration option to restore calibration without re-running the full procedure.

Always **save parameters to file before resetting** if you need to restore them.

## Scripting Access

Lua scripts access parameters via named objects:

```lua
local my_param = param:get("ATC_RAT_RLL_P")
param:set("ATC_RAT_RLL_P", 0.15)
```

The `param:get()` call caches the memory address after the first lookup, avoiding repeated name-based searches. See [Lua Scripting](lua-scripting.md).

## Related Concepts

- [Ground Control Stations](gcs.md)
- [MAVLink Protocol](mavlink.md)
- [PID Tuning](pid-tuning.md)
- [Lua Scripting](lua-scripting.md)
- [First Flight Setup](first-flight.md)

## Sources

- [Parameter Reset — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-parameter-reset.html) — 2026-05-22
- [Getting and Setting Parameters — ArduPilot dev docs](https://ardupilot.org/dev/docs/mavlink-get-set-params.html) — 2026-05-22
- [Storage and EEPROM Management — ArduPilot dev docs](https://ardupilot.org/dev/docs/learning-ardupilot-storage-and-eeprom-management.html) — 2026-05-22
- [MAVProxy Cheatsheet — MAVProxy docs](https://ardupilot.org/mavproxy/docs/getting_started/cheatsheet.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
