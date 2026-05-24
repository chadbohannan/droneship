# ArduCopter Flight Modes

ArduCopter flight modes define the control law active at any moment: how the pilot's stick inputs translate to motor commands, which sensors are required, and how much the autopilot assists or overrides the pilot.

## Overview

Modes are selected via RC switch (up to 6 positions on channel 5 by default, expandable to 21 positions using auxiliary channels) or commanded via MAVLink from a GCS or companion computer. Every mode can be entered in flight; some cannot be armed in directly.

Modes fall into three broad categories:
- **Manual-assist** — pilot controls angle or rate; autopilot provides stabilisation only
- **Position-hold** — autopilot holds position/altitude; pilot provides velocity commands
- **Autonomous** — autopilot executes a mission or responds to external commands

Altitude sensing (barometer or rangefinder) is required for any mode that controls throttle. GPS or another position source (optical flow, beacon, visual odometry) is required for any mode that controls lateral position.

## Mode Reference

| Mode | Throttle | Lateral | GPS Req | Arm OK | Notes |
|------|----------|---------|---------|--------|-------|
| Stabilize | Manual | Angle | No | Yes | Baseline mode; master this before others |
| Acro | Manual | Rate | No | Yes | No self-levelling; full pilot authority |
| AltHold | Auto | Angle | No | Yes | Baro required |
| Sport | Auto | Rate | No | Yes | AltHold variant; faster rate response |
| Drift | Auto | Angle+Yaw | Yes | Yes | Coordinates yaw with roll like a fixed-wing |
| Loiter | Auto | Velocity | Yes | Yes | GPS hold; stick gives velocity setpoint |
| PosHold | Auto | Velocity | Yes | Yes | Loiter with larger stick authority |
| Brake | Auto | Stopped | Yes | No | Decelerates to hover and holds |
| FlowHold | Auto | Velocity | No* | Yes | Optical flow position hold; no GPS |
| AltHold (Flow) | Auto | Velocity | No | Yes | AltHold + optical flow lateral damping |
| Auto | Auto | Auto | Yes | No† | Executes waypoint mission |
| Guided | Auto | Auto | Yes | No† | GCS/companion sends position/velocity targets |
| RTL | Auto | Auto | Yes | No | Return to launch and land |
| SmartRTL | Auto | Auto | Yes | No | Retrace outbound path home |
| Land | Auto | Manual | Optional | No | Descend and disarm; lateral with stick |
| Circle | Auto | Auto | Yes | No | Orbit a fixed point |
| Follow | Auto | Auto | Yes | No | Track another vehicle via MAVLink |
| ZigZag | Auto | Auto | Yes | No | Alternating spraying pattern |
| Throw | Auto | Auto | Yes | No | Stabilise after a throw launch |
| AutoTune | Auto | Auto | Yes | No | System ID twitches to derive PID gains |
| Flip | Auto | Auto | No | No | Executes a roll flip manoeuvre |
| Turtle | Manual | Manual | No | No | Inverted motor spin to self-right after crash |
| SysID | Manual | Manual | No | Yes | Frequency-sweep system identification |

*FlowHold requires an [optical flow sensor](optical-flow.md).  
†Can be armed with `AUTO_OPTIONS` bit 0 set.

## Manual-Assist Modes

### Stabilize

The fundamental mode. Pilot controls roll and pitch angle directly with the sticks; autopilot returns the frame to level when sticks are centred. Throttle is fully manual — the pilot must manage altitude. Yaw is rate-controlled.

No GPS or barometer is required to fly Stabilize. It is the only mode that works with a completely failed sensor suite (beyond the IMU itself) and is therefore the recommended fallback for all builds.

**First flight always starts in Stabilize.** Tune PIDs to a clean hover in Stabilize before enabling any assisted mode. See [First Flight Setup](first-flight.md) and [PID Tuning](pid-tuning.md).

### Acro

Rate control on all axes with no levelling. The frame holds whatever angle the pilot commands — releasing the sticks does not return to level. Throttle is manual. Preferred for freestyle aerobatics and for builds with custom control requirements (e.g., inverted flight frames).

`ACRO_BAL_ROLL` and `ACRO_BAL_PITCH` (0–1 scale) add a small levelling tendency proportional to angle, easing recovery from aggressive manoeuvres without fully enabling self-levelling.

### Sport

AltHold with rate control instead of angle control for roll and pitch. Provides faster, more direct stick response than AltHold while still holding altitude. Altitude hold requires a functioning barometer.

---

## Altitude-Hold Modes

### AltHold

Altitude is held automatically via barometer; pilot controls roll/pitch angle and yaw rate. Throttle stick controls climb/descent rate around a neutral deadband. The zero-climb-rate stick position is auto-detected from `MOT_THST_HOVER`.

AltHold is the recommended second mode to learn after Stabilize is mastered. GPS is not required, making it functional indoors or in GPS-denied environments.

The control loop (`mode_althold.cpp`) runs a five-state machine each scheduler tick at 400 Hz:

| State | Trigger | Control action |
|-------|---------|---------------|
| `MotorStopped` | Motors disarmed/stopped | Resets I-terms and rate targets; decays throttle to zero |
| `Landed_Ground_Idle` | On ground, armed, not pre-takeoff | Resets yaw target; decays throttle |
| `Landed_Pre_Takeoff` | On ground, throttle stick rising | Smoothly resets I-terms; maintains zero throttle |
| `Takeoff` | Stick crosses takeoff threshold | Executes pilot takeoff to `g2.pilot_takeoff_alt_m` (clamped 0–10 m); avoidance-adjusted climb rate |
| `Flying` | Airborne | Full position-controller loop: adjusts roll/pitch for avoidance, updates vertical target from stick, calls `D_set_pos_target_from_climb_rate_ms()`, runs surface tracking if a rangefinder is present |

In the `Flying` state the mode:
1. Passes pilot lean-angle commands through Simple-mode transformation if active.
2. Optionally adjusts roll/pitch via `AP_Avoidance` if `AP_AVOIDANCE_ALTHOLD_ENABLED` is compiled in.
3. Passes the desired climb rate through avoidance limiting before sending it to the position controller.
4. Calls `surface_tracking.update_surface_offset()` when a rangefinder is fitted, enabling terrain following at low altitude.

### Loiter

GPS position and altitude held automatically. Sticks command horizontal velocity rather than angle — gentle inputs produce smooth, proportional movement. Releasing sticks decelerates to a stop.

`LOIT_SPEED` (cm/s, default 1250) caps maximum horizontal speed. `LOIT_ACC_MAX` controls acceleration feel. Loiter requires a reliable GPS fix (HDOP < 2.0, ≥ 6 satellites recommended).

### PosHold

Similar to Loiter but with a wider direct-control region — at small stick deflections it behaves like Loiter; at large deflections it behaves more like AltHold with direct angle control. The transition between regions is configurable. Preferred over Loiter for pilots who want more manual authority.

### FlowHold

Position hold using an [optical flow sensor](optical-flow.md) instead of GPS. Enables indoor hover stabilisation or GPS-denied environments. Altitude via barometer; lateral via optical flow. Performance degrades above ~3 m altitude (sensor field of view limits effective tracking area).

---

## Autonomous Modes

### Auto

Executes a pre-loaded waypoint mission. The vehicle navigates between NAV_ commands (TAKEOFF, WAYPOINT, LOITER_TIME, LAND, etc.) and executes DO_ commands (set speed, trigger camera, operate gimbal). Requires GPS and an uploaded mission.

The mission continues through most failsafes unless `FS_OPTIONS` bits are not set — see [Failsafes](failsafes.md). To arm directly in Auto mode, set `AUTO_OPTIONS` bit 0.

See [Mission Planning](mission-planning.md) for the full command reference.

### Guided

The autopilot navigates to positions or follows velocity vectors sent in real time by a GCS or companion computer via MAVLink. The primary mode for [DroneKit](../../programming/dronekit.md), [MAVSDK](../../programming/mavsdk.md), and ROS-based offboard control.

Guided has two sub-modes: **position** (fly to absolute or relative coordinates) and **velocity** (maintain a body-frame or earth-frame velocity setpoint). The companion computer must send setpoints frequently — if they stop arriving, the vehicle will loiter at the last commanded position.

### RTL

Climbs to `RTL_ALT` (default 15 m, or current altitude if higher), flies back to the home point (set at arming), and lands. Home is set at the first GPS fix after arming by default.

Key parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `RTL_ALT` | 1500 cm | Minimum return altitude |
| `RTL_ALT_FINAL` | 0 cm | Altitude to loiter at home before landing; 0 = land immediately |
| `RTL_LOIT_TIME` | 5000 ms | Time to loiter above home before descending |
| `RTL_SPEED` | 0 cm/s | Return speed; 0 = use `WPNAV_SPEED` |
| `RTL_CLIMB_MIN` | 0 cm | Minimum climb before departing on return |

### SmartRTL

Retraces the exact flight path home using breadcrumbs stored during flight. Avoids obstacles along the known route. Falls back to standard RTL if the breadcrumb buffer is exhausted or unavailable.

`SRTL_ACCURACY` controls the spacing of stored breadcrumbs (default 1 m). `SRTL_POINTS` limits buffer size (default 150 points — enough for ~150 m of non-repeating path).

### Land

Descends vertically to the ground and disarms. Pilot retains roll and pitch authority during descent. `LAND_SPEED` (default 50 cm/s) controls descent rate in the final phase; `LAND_SPEED_HIGH` controls the upper phase descent.

### Circle

Orbits a fixed GPS point at configurable radius and speed. Useful for aerial photography. `CIRCLE_RADIUS` (default 1000 cm), `CIRCLE_RATE` (°/s, negative = counter-clockwise).

---

## Special Modes

### AutoTune

Performs a structured series of attitude control twitches to measure the airframe's dynamic response and compute optimised `ATC_RAT_*` PID values. Fly to at least 10 m altitude in calm conditions, switch to AutoTune, and let it run — the vehicle will twitch on each axis in turn. Switch out of AutoTune to save the new values, or disarm to revert to the previous values.

AutoTune works best after the notch filter is configured — see [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md). One axis at a time (roll, pitch, yaw) is recommended for frames with significant coupling. See [PID Tuning](pid-tuning.md).

### Turtle

Activates on a crashed, inverted vehicle. Reverses motor spin direction to flip the frame upright. Configured via `SERVO_DSHOT_ESC` and requires DShot ESCs capable of 3D mode. Arm in Turtle mode via an RC switch (`RCx_OPTION = 166`).

### Throw

Stabilises the vehicle after a throw launch: hold the frame, arm, throw it upward, and Throw mode catches it and holds position. Useful for launches from confined spaces. Requires GPS.

---

## Configuring Mode Switches

Up to 6 modes are assigned in **Setup → Mandatory Hardware → Flight Modes** in Mission Planner, mapped to PWM ranges on `FLTMODE_CH` (default channel 5).

To expand beyond 6 modes, use auxiliary channel options:
- `RCx_OPTION = 174` — mode switch extending the flight mode count
- `RCx_OPTION = 300–307` — direct mode assignments for channels 8–14

MAVLink `SET_MODE` or `COMMAND_LONG` with `MAV_CMD_DO_SET_MODE` can command any mode from a GCS or companion computer regardless of switch position.

## Related Concepts

- [First Flight Setup](first-flight.md)
- [Arming and Pre-Flight Checks](arming-preflight.md)
- [PID Tuning](pid-tuning.md)
- [Failsafes](failsafes.md)
- [Mission Planning](mission-planning.md)
- [EKF and Navigation](ekf-navigation.md)
- [Optical Flow and Non-GPS Navigation](optical-flow.md)
- [RC Systems and RCMAP](rc-systems.md)
- [Companion Computers](companion-computers.md)

## Sources

- [Flight Modes — ArduPilot Copter docs](https://ardupilot.org/copter/docs/flight-modes.html) — 2026-05-22
- [Copter Flight Modes — DeepWiki](https://deepwiki.com/skybrush-io/ardupilot/2.1-copter-flight-modes) — 2026-05-22
- [mode_althold.cpp — ArduPilot GitHub](https://github.com/ArduPilot/ardupilot/blob/master/ArduCopter/mode_althold.cpp) — 2026-05-23

<!-- linted: 2026-05-23 -->
