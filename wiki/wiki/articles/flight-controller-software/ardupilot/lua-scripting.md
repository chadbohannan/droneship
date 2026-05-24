# Lua Scripting — ArduPilot

ArduPilot's onboard Lua scripting engine enables custom vehicle behaviour without recompiling firmware. Scripts run on the flight controller itself, with direct access to sensors, parameters, RC channels, servo outputs, and GCS messaging.

## Overview

Lua scripts are stored on the SD card and loaded automatically at boot. They run cooperatively in ArduPilot's scheduler — each script function reschedules itself at a specified interval and must not block. The API is generated from binding declarations and is type-safe; calling a non-existent method or passing the wrong type raises a Lua error rather than crashing the firmware.

## Setup

1. Set `SCR_ENABLE = 1` and reboot. Additional `SCR_*` parameters appear after reboot.
2. Create the directory `/APM/scripts/` on the SD card (or let ArduPilot create it on first boot).
3. Place `.lua` files in that directory. They load automatically on the next boot.
4. Upload scripts via Mission Planner: CONFIG → MAVFTP, or by removing the SD card.

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `SCR_ENABLE` | 0 | — | 1 = enable Lua scripting; reboot required |
| `SCR_HEAP_SIZE` | 43000 | bytes | Heap allocation; increase to 150 000–300 000 for complex scripts |
| `SCR_VM_I_COUNT` | 10000 | instructions | Per-call instruction limit; prevents runaway scripts from blocking the scheduler |

If `SCR_HEAP_SIZE` is too low, scripts fail with out-of-memory errors and may prevent EKF or terrain following from initialising. Increase to 150000–300000 for complex applets.

## Script Structure

```lua
-- Schedule a function to run at 10 Hz
local function update()
  -- Do work here
  return update, 100   -- reschedule in 100 ms
end

return update, 1000    -- first call after 1000 ms (1 s)
```

The final `return` at script level schedules the entry function. Each function's final `return` reschedules itself. Omit the `return` to stop execution.

## API Reference

### Vehicle and Arming

```lua
vehicle:arm()                -- arm motors
vehicle:disarm()             -- disarm
vehicle:set_mode(6)          -- set flight mode (6 = Loiter)
arming:is_armed()            -- returns bool
```

### AHRS (Attitude and Position)

```lua
ahrs:get_roll()              -- roll angle (radians)
ahrs:get_pitch()             -- pitch angle (radians)
ahrs:get_yaw()               -- yaw angle (radians)
ahrs:get_position()          -- Location object (lat, lng, alt)
ahrs:get_home()              -- home Location
ahrs:get_hagl()              -- height above ground (m)
ahrs:get_gyro()              -- Vector3f gyro rates (rad/s)
ahrs:wind_estimate()         -- Vector3f wind estimate (m/s)
```

### Battery

```lua
battery:voltage(0)           -- voltage of battery instance 0
battery:current_amps(0)      -- current draw (A)
battery:capacity_remaining_pct(0)  -- remaining %
```

### GCS Messaging

```lua
gcs:send_text(6, "Hello!")   -- severity 6=INFO, 4=WARNING, 3=ERROR
```

### RC Input and Output

```lua
rc:get_pwm(7)                -- PWM value of channel 7 (µs); false if unavailable
rc:set_output_pwm_chan_timeout(8, 1500, 5000)  -- set channel 8 to 1500 µs for 5 s
```

### Parameters

```lua
local p = param:get("ATC_RAT_RLL_P")   -- read parameter (float)
param:set("ATC_RAT_RLL_P", 0.15)       -- set parameter
```

Parameter objects cache the memory address after first lookup — create them at script load time and reuse.

### Scheduling

```lua
local function callback()
  gcs:send_text(6, "tick")
  return callback, 1000   -- reschedule every 1 s
end
```

## Worked Examples

**Payload trigger on landing:**
```lua
local function check_landing()
  if not arming:is_armed() then
    rc:set_output_pwm_chan_timeout(9, 2000, 3000)  -- trigger relay for 3 s
  end
  return check_landing, 500
end
return check_landing, 1000
```

**Low battery warning:**
```lua
local function check_battery()
  if battery:capacity_remaining_pct(0) < 20 then
    gcs:send_text(4, "Battery below 20%!")
  end
  return check_battery, 5000
end
return check_battery, 5000
```

## Limitations

- **No blocking calls** — scripts use cooperative multitasking; `socket.sleep()` or long loops prevent other tasks from running.
- **~1 kB stack** per script — avoid deep recursion or large local arrays.
- **No file I/O** — scripts cannot read from or write to the SD card directly.
- **Safety**: scripts can arm, change modes, and override RC — test thoroughly in SITL before flying. See [SITL Simulation](sitl.md).

## Useful Applets

ArduPilot ships several ready-to-use Lua applets in the scripts library:

| Script | Function |
|--------|---------|
| `quiktune.lua` | Automated PID tuning without twitching — see [PID Tuning](pid-tuning.md) |
| `landing-with-guard.lua` | Checks rangefinder before landing in Auto |
| `copter-auto-arm.lua` | Arms automatically when throttle raised |

Auxiliary RC switch option `RCx_OPTION = 300–307` assigns RC channels as scripting inputs.

## Related Concepts

- [Parameters](parameters.md)
- [SITL Simulation](sitl.md)
- [PID Tuning](pid-tuning.md)
- [Mission Planning](mission-planning.md)
- [Companion Computers](companion-computers.md)
- [Architecture](architecture.md)

## Sources

- [Lua Scripts — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-lua-scripts.html) — 2026-05-22
- [Script Setup and Use Examples — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-scripting-step-by-step.html) — 2026-05-22
- [Lua Scripting System — ArduPilot DeepWiki](https://deepwiki.com/ArduPilot/ardupilot/7.1-lua-scripting-system) — 2026-05-22

<!-- linted: 2026-05-23 -->
