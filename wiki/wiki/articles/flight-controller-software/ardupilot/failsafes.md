# Failsafes — ArduPilot

Failsafes are automatic responses to loss-of-link, low battery, navigation failure, and other abnormal conditions. Each failsafe is independent; multiple can trigger simultaneously, and the highest-priority action wins.

## Overview

ArduPilot has six distinct failsafe systems for multirotors: radio (RC link loss), GCS (telemetry loss), battery (voltage or capacity), EKF (navigation uncertainty), crash detection, and terrain data loss. Each has its own enable parameter, threshold, action, and timeout. The shared `FS_OPTIONS` bitmask modifies behaviour across all of them — for example, allowing an autonomous mission to continue despite a radio loss.

Understanding the interaction between failsafes and `FS_OPTIONS` is critical: the default configuration is conservative and assumes a pilot is in direct control. Autonomous or companion-computer builds usually need `FS_OPTIONS` tuned to avoid unnecessary RTLs during planned telemetry gaps.

## Failsafe Actions Reference

Several action codes appear across multiple failsafes:

| Code | Action | Fallback |
|------|--------|----------|
| 0 | Disabled / Warn only | — |
| 1 | RTL | Land if no GPS |
| 2 | Continue in Auto | — |
| 3 | Land | — |
| 4 | SmartRTL → RTL | Land if GPS unavailable |
| 5 | SmartRTL → Land | Land |
| 6 | Brake → Land | Land |
| 7 | Auto DO_LAND_START → RTL | RTL |

**SmartRTL** retraces the exact outbound flight path home, avoiding obstacles along the known route. It requires the path breadcrumb buffer to be populated; if it isn't, ArduPilot falls back to RTL or Land.

### Behaviour When Already on Ground or Disarmed

Regardless of failsafe action configured, if the vehicle is:
- **Disarmed** — no action taken
- **Armed but landed** — motors disarm immediately
- **Armed in Stabilize/Acro at minimum throttle** — motors disarm immediately (unless AirMode is active)

After a failsafe clears, ArduPilot stays in the failsafe mode. It does not automatically return to the original flight mode — the pilot must switch explicitly.

---

## Radio Failsafe

Triggers when the RC signal is lost for longer than `RC_FS_TIMEOUT` seconds.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FS_THR_ENABLE` | 1 | Action: 0=disabled, 1=RTL, 3=Land, 4=SmartRTL/RTL, 5=SmartRTL/Land, 6=DO_LAND_START/RTL |
| `FS_THR_VALUE` | 975 | PWM threshold below which radio loss is declared |
| `RC_FS_TIMEOUT` | 1 s | Seconds of signal absence before failsafe triggers |

### Setting FS_THR_VALUE

The value must satisfy all three conditions:
- ≥ 10 PWM above the throttle channel PWM when the transmitter is **off**
- ≤ 10 PWM below the throttle channel PWM when the stick is at minimum and transmitter is **on**
- Above 910 PWM

Practical procedure: power on transmitter, lower throttle to minimum, read `RC3_MIN` (~1100). Power off transmitter, read the PWM the receiver outputs (typically ~900 for no-signal). Set `FS_THR_VALUE` midway between the two — e.g., 975.

### Receiver Failsafe Modes

| Method | Behaviour | Common receivers |
|--------|-----------|-----------------|
| Low-throttle | Receiver drives throttle channel below normal range | Futaba, older Spektrum |
| No-signal | Receiver stops transmitting entirely; FC detects signal absence | FrSky, ExpressLRS |

Both work correctly with ArduPilot. The no-signal method is preferred for modern receivers because it also detects receiver power loss.

### FS_OPTIONS Bits Affecting Radio Failsafe

| Bit | Value | Effect |
|-----|-------|--------|
| 0 | 1 | Continue Auto mission on radio failsafe |
| 2 | 4 | Continue Guided mode on radio failsafe |
| 3 | 8 | Continue landing if already descending |
| 5 | 32 | Release gripper payload during failsafe |

### Testing Radio Failsafe

1. Arm in Stabilize at minimum throttle — confirm immediate disarm when transmitter powers off.
2. Arm, raise throttle slightly, power off transmitter — confirm RTL or Land activates after `RC_FS_TIMEOUT`.
3. Restore transmitter signal — confirm ArduPilot stays in failsafe mode (does not auto-resume).
4. Switch flight modes manually to regain control.

---

## GCS Failsafe

Triggers when no MAVLink heartbeat is received for `FS_GCS_TIMEOUT` seconds (default 5 s). Applies to telemetry-connected builds; not active if `FS_GCS_ENABLE = 0`.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FS_GCS_ENABLE` | 0 | 0=disabled, 1=RTL, 3=SmartRTL/RTL, 4=SmartRTL/Land, 5=Land, 6=DO_LAND_START/RTL, 7=Brake/Land |
| `FS_GCS_TIMEOUT` | 5 s | Seconds without heartbeat before trigger |

Common causes: operator disconnects GCS, vehicle flies beyond telemetry range, telemetry radio loses power, wiring failure.

### FS_OPTIONS Bits Affecting GCS Failsafe

| Bit | Value | Effect |
|-----|-------|--------|
| 1 | 2 | Continue Auto mission on GCS failsafe |
| 3 | 8 | Continue landing if already descending |
| 4 | 16 | Continue in pilot-controlled modes (Stabilize, AltHold, etc.) |
| 5 | 32 | Release gripper payload |

For builds where the GCS connection is non-essential to the mission (e.g., a companion computer runs the mission via MAVLink on a separate link), set `FS_GCS_ENABLE = 0` or enable bit 1 of `FS_OPTIONS` to avoid spurious RTLs.

---

## Battery Failsafe

Two-tier voltage and capacity monitoring with independent actions for low and critical thresholds. Once triggered, the battery failsafe cannot be cleared until the autopilot is rebooted — even if voltage recovers.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BATT_LOW_VOLT` | 10.5 V | Low voltage threshold; set to 0 to disable |
| `BATT_LOW_MAH` | 0 | Low capacity remaining (mAh); 0 disables |
| `BATT_FS_LOW_ACT` | 2 (RTL) | Action at low threshold |
| `BATT_CRT_VOLT` | 0 V | Critical voltage threshold; 0 disables |
| `BATT_CRT_MAH` | 0 | Critical capacity remaining (mAh); 0 disables |
| `BATT_FS_CRT_ACT` | 1 (Land) | Action at critical threshold |
| `BATT_LOW_TIMER` | 10 s | Seconds voltage must be below threshold before triggering |
| `BATT_FS_VOLTSRC` | 0 | 0=raw voltage, 1=sag-corrected voltage |

**Recommended practice:** Set `BATT_LOW_VOLT` to ~20% remaining capacity for your pack chemistry and `BATT_FS_LOW_ACT = 2` (RTL). Set `BATT_CRT_VOLT` ~0.2 V lower than low with `BATT_FS_CRT_ACT = 3` (Land) — the vehicle should land immediately if RTL is still in progress when the critical threshold is hit.

LiPo voltage thresholds by cell count (approximate, chemistry-dependent):

| Cells | Low (3.5 V/cell) | Critical (3.3 V/cell) |
|-------|------------------|-----------------------|
| 3S | 10.5 V | 9.9 V |
| 4S | 14.0 V | 13.2 V |
| 5S | 17.5 V | 16.5 V |
| 6S | 21.0 V | 19.8 V |

### FS_OPTIONS Bits Affecting Battery Failsafe

| Bit | Value | Effect |
|-----|-------|--------|
| 3 | 8 | Continue landing if already descending |
| 5 | 32 | Release gripper payload |

---

## EKF Failsafe

Triggers when two or more EKF state variances (compass, position, velocity, or height) exceed `FS_EKF_THRESH` for 1 second continuously. Variances are unitless, ranging from 0 (fully trusted) to 1.0 (untrusted).

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FS_EKF_ACTION` | 1 | 0=report only, 1=Land (pilot can control roll/pitch), 2=AltHold, 3=Land (no pilot override) |
| `FS_EKF_THRESH` | 0.8 | Variance threshold; 0=disabled, 0.6=strict, 0.8=default, 1.0=relaxed |

`FS_EKF_ACTION = 1` is the safest default: the vehicle lands but the pilot retains roll/pitch authority to steer away from obstacles during descent. Use `FS_EKF_ACTION = 2` (AltHold) if the EKF loss is transient and the pilot can recover manually.

Common causes of EKF failsafe in flight:
- Compass interference from high motor current at full throttle
- GPS jamming or multipath in urban environments
- Vibration exceeding 30 m/s² (corrupts accelerometer-based velocity estimate)
- Rapid magnetic field changes (flying near metal structures)

See [EKF and Navigation](ekf-navigation.md) for diagnosing EKF health from logs.

---

## Crash Check

Detects when the vehicle has crashed and disarms motors automatically to prevent prop strikes, fire, and battery drain.

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FS_CRASH_CHECK` | 1 | 0=disabled, 1=disarm on crash detect, 2=disarm and trigger CRASH notify |

Detection heuristics: sustained large attitude error with low throttle output, sustained acceleration without corresponding attitude change, or uncontrolled angular rate. The check activates approximately 2 seconds after the condition is met.

---

## Vibration Failsafe

Triggers when accelerometer clipping (saturated samples) or raw vibration exceeds safe limits during flight, indicating the IMU data is too corrupted for reliable navigation.

Thresholds are hard-coded in firmware. The VIBE log message (`VibeX`, `VibeY`, `VibeZ` > 30 m/s², or `Clip0/1/2` > 0) indicates pre-failsafe vibration levels. Resolve vibration mechanically before flight rather than relying on this failsafe — see [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md).

---

## Terrain Data Loss Failsafe

Triggers during terrain-following missions when the terrain database cannot be accessed. Requires `TERRAIN_ENABLE = 1` and a populated terrain database on the SD card (or live GCS injection).

Action: switch to RTL. Configure with `FS_TERRAIN_CHECK = 1`.

---

## FS_OPTIONS Bitmask Summary

`FS_OPTIONS` is a single bitmask that modifies behaviour across radio, GCS, and battery failsafes.

| Bit | Value | Effect |
|-----|-------|--------|
| 0 | 1 | Continue Auto on radio failsafe |
| 1 | 2 | Continue Auto on GCS failsafe |
| 2 | 4 | Continue Guided on radio failsafe |
| 3 | 8 | Continue landing on any failsafe |
| 4 | 16 | Continue pilot-controlled modes on GCS failsafe |
| 5 | 32 | Release gripper on any failsafe |

**Example:** An autonomous survey build that uses a companion computer in Guided mode with a long-range telemetry link might set `FS_OPTIONS = 5` (bits 0+2) to allow the mission to complete even if the RC transmitter is switched off.

---

## Failsafe Priority

When multiple failsafes trigger simultaneously, ArduPilot processes them in this order (highest priority first):

1. Crash Check — immediate disarm
2. EKF Failsafe
3. Radio Failsafe
4. GCS Failsafe
5. Battery Critical
6. Battery Low
7. Terrain

A lower-priority failsafe that triggers during a higher-priority failsafe action is absorbed — e.g., battery critical triggering during an EKF-induced land will not override the land with a different action.

## Related Concepts

- [Arming and Pre-Flight Checks](arming-preflight.md)
- [Flight Modes](flight-modes.md)
- [EKF and Navigation](ekf-navigation.md)
- [Power Monitoring](power-monitoring.md)
- [Battery](../../power-systems/battery.md)
- [RC Systems and RCMAP](rc-systems.md)
- [MAVLink and Telemetry](mavlink.md)
- [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)
- [Geofencing](geofence.md)

## Sources

- [Radio Failsafe — ArduPilot Copter docs](https://ardupilot.org/copter/docs/radio-failsafe.html) — 2026-05-22
- [Battery Failsafe — ArduPilot Copter docs](https://ardupilot.org/copter/docs/failsafe-battery.html) — 2026-05-22
- [GCS Failsafe — ArduPilot Copter docs](https://ardupilot.org/copter/docs/gcs-failsafe.html) — 2026-05-22
- [EKF Failsafe — ArduPilot Copter docs](https://ardupilot.org/copter/docs/ekf-inav-failsafe.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
