# Arming and Pre-Flight Checks — ArduPilot

ArduPilot will not arm unless a configurable set of safety checks pass. Understanding exactly what each check tests, how to resolve failures, and how arming itself works prevents frustrating bench sessions and, more importantly, prevents flying an unsafe vehicle.

## Overview

Arming enables motor output. Before it does, ArduPilot evaluates every enabled check in the `ARMING_CHECK` bitmask. Failures appear in red on the GCS HUD and are re-broadcast as MAVLink STATUS_TEXT messages approximately every 30 seconds while disarmed. When multiple checks fail, resolve them one at a time — each arm attempt reveals the next blocking failure.

The default `ARMING_CHECK = 1` enables all checks. Disabling checks to work around failures is appropriate only on the bench with props off; never fly with safety checks disabled.

## Arming Methods

| Method | How | Parameter / Option |
|--------|-----|--------------------|
| Stick (rudder) | Throttle down + yaw right for 5 s | `ARMING_RUDDER`: 0=disabled, 1=arm only, 2=arm/disarm |
| RC switch | Assign arm function to an aux channel | `RCx_OPTION = 153` (arm), `154` (arm/disarm), `160` (arm/disarm with interlock) |
| GCS | MAVLink `DO_ARM` command | Mission Planner, QGC, MAVProxy |
| Lua script | `vehicle:arm()` API call | Requires `SCR_ENABLE = 1` |

Hold yaw-right for more than 15 seconds after arming — this triggers AutoTrim, which adjusts RC trims based on stick input. Avoid doing this accidentally.

### Modes That Permit Arming

Arming is permitted in: **Stabilize, Acro, AltHold, Loiter, PosHold**.

Arming is blocked in: Auto (unless `AUTO_OPTIONS` bit 0 is set), AutoTune, Brake, Circle, Flip, Land, RTL, SmartRTL, Guided (unless `GUID_OPTIONS` bit is set).

### Hardware Safety Switch

Boards with a physical safety switch (most Pixhawk-family hardware) require it to be pressed until the LED goes solid before arming. To disable the safety switch requirement: set `BRD_SAFETY_DEFLT = 0` and reboot. This is common on builds where the switch is inaccessible, but removes a physical interlock — set it deliberately.

## Disarming

| Method | Trigger |
|--------|---------|
| Stick | Throttle minimum + yaw left for 2 s |
| Auto-disarm | Throttle at minimum for 15 s (configurable: `DISARM_DELAY`) |
| RC switch | `RCx_OPTION = 81` (disarm) or `154` (arm/disarm toggle) |
| GCS | MAVLink `DO_ARM` with arm=0 |
| Emergency stop | `RCx_OPTION = 31` — immediately kills all motors regardless of flight state |

## ARMING_CHECK Bitmask

Each bit enables one category of pre-arm checks. Set `ARMING_CHECK` to the sum of desired bits, or `1` for all.

| Bit | Value | Category |
|-----|-------|----------|
| 0 | 1 | All checks (default) |
| 1 | 2 | Barometer |
| 2 | 4 | Compass |
| 3 | 8 | GPS lock |
| 4 | 16 | INS (accelerometer/gyro) |
| 5 | 32 | Parameters |
| 6 | 64 | RC channels |
| 7 | 128 | Board voltage |
| 8 | 256 | Battery level |
| 9 | 512 | (reserved) |
| 10 | 1024 | Logging available |
| 11 | 2048 | Hardware safety switch |
| 12 | 4096 | GPS configuration |
| 13 | 8192 | System |
| 14 | 16384 | Mission |
| 15 | 32768 | Rangefinder |
| 16 | 65536 | Camera |
| 17 | 131072 | Auxiliary authorization |
| 18 | 262144 | Visual odometry |
| 19 | 524288 | FFT |

To skip a specific category on the bench (e.g., GPS, bit 3 = value 8), subtract its value from `ARMING_CHECK`. Do not set `ARMING_CHECK = 0` — mandatory checks remain enforced via `ARMING_SKIPCHK`.

## Pre-Arm Check Reference

### IMU / Inertial Sensors

| Message | Cause | Fix |
|---------|-------|-----|
| 3D Accel calibration needed | No calibration stored | Complete accel calibration |
| Accels calibrated requires reboot | Cal saved, needs restart | Reboot |
| Accels inconsistent | Two IMUs differ ≥ 0.75 m/s² | Recalibrate; allow board to warm up; replace if persistent |
| Accels not healthy | No accel data | Reboot; check FC |
| Gyros not calibrated | Startup gyro cal failed | Reboot while holding vehicle perfectly still |
| Gyros inconsistent | Two gyros differ ≥ 5 °/s | Reboot; warm up board |
| Gyros not healthy | No gyro data | Reboot; check FC |
| Gyro x rate < loop rate | Gyro update rate below `SCHED_LOOP_RATE` | Lower `SCHED_LOOP_RATE` or use higher-rate IMU |
| heater temp low (x < 45) | Board heater below target | Wait for warmup; adjust `BRD_HEAT_TARG` |
| temperature cal running | Temperature cal in progress | Wait or reboot |

### Compass

| Message | Cause | Fix |
|---------|-------|-----|
| Compass not calibrated | No calibration stored | Run compass calibration |
| Compass calibration requires reboot | Cal saved, needs restart | Reboot |
| Compass offsets too high | Offset magnitude > 500 | Move away from metal/motors; recalibrate; disable internal compass |
| Compasses inconsistent | Internal/external disagree > 45° | Verify `COMPASS_ORIENT`; recalibrate; disable internal compass |
| Check mag field | Field strength 35% from expected | Relocate; recalibrate |
| EKF compass variance | Compass and EKF yaw disagree | Relocate; recalibrate; disable internal; check motor wiring routing |

### GPS and Position

| Message | Cause | Fix |
|---------|-------|-----|
| GPS x: Bad fix | Insufficient satellites | Move to clear sky; wait; check for RF interference |
| High GPS HDOP | HDOP > 2.0 | Wait; relocate; adjust `GPS_HDOP_GOOD` if permanently obstructed |
| GPS positions differ by Xm | Dual GPS disagree > 50 m | Wait for convergence; check antenna placement |
| AHRS: waiting for home | No GPS fix yet | Wait outdoors; allow ≥ 6 satellites |
| EKF position variance | GPS unstable | Wait; move outdoors |
| EKF velocity variance | GPS or optical flow unstable | Wait; check optical flow mounting |
| EKF attitude is bad | EKF attitude estimate poor | Wait; reboot |
| EKF3 Yaw inconsistent | Yaw estimates disagree | Wait; reboot; check compass |
| Need Position Estimate | No EKF position | Wait; complete calibrations; move outdoors |
| GPS alt error Xm | GPS and baro altitudes disagree | Review `BARO_ALTERR_MAX` |

### RC / Radio

| Message | Cause | Fix |
|---------|-------|-----|
| RC not calibrated | No radio calibration | Complete radio calibration |
| RC not found | No signal at RC input | Enable transmitter; check connection |
| Radio failsafe on | RC failsafe triggered | Enable transmitter; verify `FS_THR_VALUE` is below `RC3_MIN` |
| Pitch / Roll / Yaw not neutral | Stick not centered | Center sticks; check trims |
| RCx_MAX < RCx_TRIM | PWM range inverted | Recalibrate; adjust trim |
| Mode channel conflict | Flight mode switch overlaps aux function | Change `FLTMODE_CH` or reassign `RCx_OPTION` |
| Check FS_THR_VALUE | Failsafe value out of range | Set between 910 and `RC3_MIN` |

### Battery and Power

| Message | Cause | Fix |
|---------|-------|-----|
| Battery below minimum arming voltage | Voltage < `BATT_ARM_VOLT` | Charge battery; adjust `BATT_ARM_VOLT` |
| Battery below minimum arming capacity | Capacity < `BATT_ARM_MAH` | Charge or adjust `BATT_ARM_MAH` |
| Battery critical voltage failsafe | Voltage < `BATT_CRT_VOLT` | Charge; adjust failsafe thresholds |
| Battery voltage failsafe critical >= low | `BATT_CRT_VOLT ≥ BATT_LOW_VOLT` | Set `BATT_LOW_VOLT > BATT_CRT_VOLT` |
| Board Xv out of range 4.3–5.8v | Power supply voltage bad | Check USB cable or power module |

### Motors and ESCs

| Message | Cause | Fix |
|---------|-------|-----|
| Motors: Check frame class and type | Unknown FRAME_CLASS/TYPE | Set valid values; see [Motor Mixing](motor-mixing.md) |
| Motors: MOT_SPIN_ARM > MOT_SPIN_MIN | ARM spin exceeds MIN | Reduce `MOT_SPIN_ARM` below `MOT_SPIN_MIN` |
| Motors: MOT_SPIN_MIN too high x > 0.3 | MIN spin too high | Reduce `MOT_SPIN_MIN` below 0.3 |
| Motors: no SERVOx_FUNCTION set to MotorX | Motor output unassigned | Configure `SERVOx_FUNCTION` for each motor output |
| Motors: Check MOT_PWM_MIN/MAX | PWM range misconfigured | Set `MOT_PWM_MIN=1000`, `MOT_PWM_MAX=2000`; recalibrate ESCs |

### Hardware Safety Switch

| Message | Cause | Fix |
|---------|-------|-----|
| Hardware safety switch | Switch not activated | Press safety switch until LED is solid, or set `BRD_SAFETY_DEFLT=0` and reboot |
| Motors Emergency Stopped | E-stop active | Release E-stop switch |
| Disarm Switch on | Disarm aux switch is high | Move switch to low position |

### Logging

| Message | Cause | Fix |
|---------|-------|-----|
| No SD card | SD missing or corrupt | Format or replace SD card |
| Logging failed | Write failure | Reboot; replace SD card |
| CrashDump data detected | CPU crashed on previous flight | Review crash dump; unsafe to fly until investigated |

### Mission

| Message | Cause | Fix |
|---------|-------|-----|
| Mode requires mission | Auto mode armed with no mission | Upload mission or switch mode |
| Missing mission item: takeoff/land/RTL | Incomplete mission | Add missing commands or adjust `ARMING_MIS_ITEMS` |

### System

| Message | Cause | Fix |
|---------|-------|-----|
| Internal errors 0x%x | Firmware internal error | Reboot; report to ArduPilot devs if persistent |
| Main loop slow (xHz < 400Hz) | CPU overloaded | Disable unused features; lower `SCHED_LOOP_RATE`; use faster board |
| Param storage failed | EEPROM hardware failure | Check power supply; replace FC |
| System not initialized | Still booting | Wait; if persistent, check sensors |

### DroneCAN

| Message | Cause | Fix |
|---------|-------|-----|
| DroneCAN: Duplicate Node x | Two devices with same node ID | Set `CAN_D1_UC_OPTION=1`; reboot |
| DroneCAN: Node x unhealthy | CAN device not responding | Check wiring and termination resistors |

### Remote ID

| Message | Cause | Fix |
|---------|-------|-----|
| OpenDroneID: operator location must be set | Remote ID requires operator position | Set operator location via GCS before arming |
| OpenDroneID: UA_TYPE required | RemoteID config incomplete | Review Remote ID setup |

### Vibration (FFT / Notch)

| Message | Cause | Fix |
|---------|-------|-----|
| FFT calibrating noise | FFT notch warmup incomplete | Wait 20–30 s after boot before arming |
| FFT self-test failed | FFT analysis error | Review `INS_HNTCH_MODE=4` setup |

## Diagnosing Unknown Failures

When a pre-arm message isn't self-explanatory:

1. **Check MAVLink messages** — Mission Planner HUD shows the first failure; MAVProxy `status` shows all active alerts.
2. **Check dataflash** — ARM/DISARM events and the reason code are logged even when disarmed.
3. **Try `ARMING_CHECK = 0` on bench with no props** — if the vehicle arms, a specific check is blocking. Add bits back one at a time to isolate it.
4. **Check EKF status** — **Setup → Flight Data → Status** tab in Mission Planner shows per-filter innovation values and health flags in real time.

## Related Concepts

- [First Flight Setup](first-flight.md)
- [Failsafes](failsafes.md)
- [Motor Mixing and Output](motor-mixing.md)
- [EKF and Navigation](ekf-navigation.md)
- [RC Systems and RCMAP](rc-systems.md)
- [Power Monitoring](power-monitoring.md)
- [CAN Bus and DroneCAN](can-dronecan.md)
- [Lua Scripting](lua-scripting.md)

## Sources

- [Pre-Arm Safety Checks — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-prearm-safety-checks.html) — 2026-05-22
- [Arming the Motors — ArduPilot Copter docs](https://ardupilot.org/copter/docs/arming_the_motors.html) — 2026-05-22
- [Arming and Safety Systems — ArduPilot DeepWiki](https://deepwiki.com/ArduPilot/ardupilot/2.2-arming-and-safety-systems) — 2026-05-22

<!-- linted: 2026-05-23 -->
