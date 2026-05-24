# First Flight Setup — ArduPilot

Getting an ArduCopter build airborne for the first time requires completing a mandatory calibration sequence, verifying hardware, and performing a disciplined hover test before any tuning begins. Skipping steps or reordering them causes pre-arm failures, unstable flight, or flyaways.

## Overview

The setup sequence progresses from firmware and frame configuration through hardware calibration to a controlled first hover. Each phase builds on the last: frame type must be correct before motor tests, calibrations must complete before arming checks pass, and hover tests must be stable before AutoTune is attempted. The entire process is managed through a [Ground Control Station](gcs.md) — Mission Planner is assumed here, but QGroundControl follows the same logical order.

Remove propellers for every bench step through motor testing. Do not reinstall them until you reach the hover test.

## Phase 1 — Firmware and Frame Configuration

### Install Firmware

In Mission Planner: **Setup → Install Firmware**. Select the ArduCopter target matching your board. For boards without existing ArduPilot firmware, use the DFU/bootloader path described in the [hardware](hardware.md) article.

### Set Frame Class and Type

**Setup → Mandatory Hardware → Frame Type**

`FRAME_CLASS` sets motor count and geometry; `FRAME_TYPE` sets arm layout within that geometry. An incorrect combination causes the vehicle to flip on first throttle application.

| FRAME_CLASS | Value | Vehicle |
|-------------|-------|---------|
| Quad | 1 | 4-motor |
| Hexa | 2 | 6-motor |
| Octa | 3 | 8-motor |
| OctaQuad | 4 | 8-motor coaxial pairs |
| Y6 | 5 | Coaxial tricopter |
| Tri | 7 | Tricopter |

| FRAME_TYPE | Value | Layout |
|------------|-------|--------|
| X | 1 | True X (default) |
| H | 3 | H-frame |
| V | 5 | V-tail |
| Plus | 0 | + layout |

See [Rotor Configurations](../../airframes/rotor-configurations.md) and [Motor Mixing](motor-mixing.md) for geometry details.

### Set Board Orientation

If the flight controller is not mounted arrow-forward and level, set `AHRS_ORIENTATION` before performing any calibration. All calibrations are relative to the declared orientation; calibrating with the wrong value stores incorrect offsets.

## Phase 2 — Mandatory Hardware Calibration

Complete these in order. Each step is accessible under **Setup → Mandatory Hardware** in Mission Planner.

### Accelerometer Calibration

**Setup → Mandatory Hardware → Accel Calibration → Calibrate Accel**

Place the vehicle in six orientations, pressing any key to capture each position. Hold still immediately after pressing — stillness matters more than exact angle (±20° tolerance except for the initial level position).

| Step | Orientation |
|------|-------------|
| 1 | Level — most critical; establishes the flying attitude reference |
| 2 | Right side down |
| 3 | Left side down |
| 4 | Nose down |
| 5 | Nose up |
| 6 | Upside down |

If your board has an IMU heater (most Pixhawk-family boards do), perform **IMU Temperature Calibration** afterward to reduce accel/gyro inconsistency errors at cold startup. Factory-calibrated boards (Cube Orange, Pixhawk 6X) can skip this.

### Compass Calibration

**Setup → Mandatory Hardware → Compass → Start**

Hold the vehicle in the air and rotate it so each of the six faces (front, back, left, right, top, bottom) points toward the ground for a few seconds. Listen for the three rising tones that signal completion, then reboot before arming.

Key points:
- Perform outdoors or away from ferrous structures, motors, and electronics.
- External compass (GPS module) should be set as Compass 1. Disable the internal compass if `EKF_CHECK` raises compass inconsistency warnings after flight.
- If calibration fails repeatedly, raise `COMPASS_OFFS_MAX` from 850 to 2000–3000 for setups with high magnetic interference (large motors close to FC), or reduce the **Fitness** threshold in Mission Planner.
- GPS lock is required before calibration completes on some firmware versions.

### Radio Calibration

**Setup → Mandatory Hardware → Radio Calibration → Calibrate Radio**

With battery disconnected and props off, move all sticks, switches, and knobs to their full extents. Expected PWM range: ~1100 µs minimum, ~1900 µs maximum.

Channel assignments (ArduCopter defaults):

| Channel | Function | Direction |
|---------|----------|-----------|
| 1 | Roll | Same as stick |
| 2 | Pitch | **Opposite** to stick — green bar moves opposite to physical input |
| 3 | Throttle | Same as stick |
| 4 | Yaw | Same as stick |
| 5 | Flight mode switch | — |
| 6 | Tuning knob (optional) | — |

Verify pitch direction carefully — it is deliberately reversed and often catches builders off guard. Correct channel reversal in the transmitter or via `RCx_REVERSED`.

### Flight Mode Configuration

**Setup → Mandatory Hardware → Flight Modes**

Assign at minimum: **Stabilize** on one switch position and **AltHold** on another. Add **RTL** to a third position and a Loiter or Auto mode if GPS is installed. Configure a dedicated **Emergency Stop Motors** auxiliary function (`RCx_OPTION = 31`) and test it on the bench before flight.

### Failsafe Configuration

**Setup → Mandatory Hardware → Failsafe**

Set radio failsafe action (RTL recommended). Verify `FS_THR_ENABLE = 1` and `FS_THR_VALUE` is below the minimum throttle PWM captured during radio calibration. Configure battery failsafe voltages to match your pack chemistry. See [Failsafes](failsafes.md) for full options.

## Phase 3 — Optional but Recommended Pre-Flight Setup

### Battery Monitor

**Setup → Optional Hardware → Battery Monitor**

Calibrate `BATT_VOLT_MULT` and `BATT_AMP_PERVLT` for your power module. Without this, the battery failsafe has no voltage reference and consumed-mAh tracking is unavailable. See [Power Monitoring](power-monitoring.md).

### ESC Protocol

Set `MOT_PWM_TYPE` to match your ESCs:

| Protocol | MOT_PWM_TYPE | Notes |
|----------|--------------|-------|
| PWM (standard) | 0 | Default; works with all ESCs |
| Oneshot125 | 1 | Faster; requires ESC support |
| Oneshot42 | 2 | |
| Multishot | 3 | |
| DShot150 | 4 | Digital; no calibration needed |
| DShot300 | 5 | Recommended digital protocol |
| DShot600 | 6 | High-speed; verify ESC support |

DShot eliminates ESC calibration and enables bidirectional telemetry for [RPM filtering](../vibration-filtering-and-tuning.md). Set `SERVO_BLH_BDMASK` to enable bidirectional DShot on all motor outputs, and set `MOT_POLES` to match your motors.

### MOT_SPIN Parameters

These set the usable throttle range and must be verified before flight to prevent motors stalling at low throttle or saturating at high throttle.

| Parameter | Purpose | Starting Value |
|-----------|---------|----------------|
| `MOT_SPIN_ARM` | Throttle at which motors start spinning on arm | 0.10 |
| `MOT_SPIN_MIN` | Minimum in-flight throttle (must be ≥ MOT_SPIN_ARM + 0.03) | 0.15 |
| `MOT_SPIN_MAX` | Maximum throttle ceiling | 0.95 |
| `MOT_THST_EXPO` | Thrust linearisation curve | 0.65 (typical 5″) |
| `MOT_THST_HOVER` | Expected hover throttle fraction | 0.35 (set lower initially) |

To find `MOT_SPIN_ARM` and `MOT_SPIN_MIN`: with props off, slowly raise the Motor Test throttle in Mission Planner (**Setup → Optional Hardware → Motor Test**) until all motors spin cleanly. That value is `MOT_SPIN_ARM`. Add 0.03–0.05 for `MOT_SPIN_MIN`.

## Phase 4 — Motor Test and Spin Direction

**Setup → Optional Hardware → Motor Test**

Test each motor individually at ~10% throttle. ArduPilot numbers motors differently by frame type — verify the diagram shown in Mission Planner matches your physical layout before connecting ESC signal wires.

**Spin direction by position (Quad X default):**

```
  CW (M2)   CCW (M1)
      \         /
       \       /
        -------
       /       \
      /         \
 CCW (M3)   CW (M4)
```

To reverse a motor, either swap any two of the three motor phase wires at the ESC, or (BLHeli_32/AM32) use the ESC configurator to reverse direction in firmware — do not change spin direction in ArduPilot software. See [Rotor Configurations](../../airframes/rotor-configurations.md) for props-in vs. props-out conventions.

## Phase 5 — Pre-Arm Check Verification

**Setup → Mandatory Hardware → Pre-Arm Safety Checks** (or review on the HUD)

`ARMING_CHECK` defaults to 1 (all checks enabled). Common pre-arm failures and fixes:

| Message | Cause | Fix |
|---------|-------|-----|
| EKF not healthy | EKF hasn't converged | Wait 30–60 s after boot with good GPS |
| Compass not healthy | Calibration not accepted | Redo compass cal outdoors |
| Compass variance | Large discrepancy between compasses | Disable internal compass; recheck motor/wiring routing |
| Gyro not healthy | IMU startup error | Power cycle; check FC mounting for vibration |
| Gyro inconsistent | Temperature delta too large | Enable temperature calibration; let board warm up |
| Need 3D fix | No GPS lock | Wait for ≥6 satellites, HDOP < 2.0 |
| Baro not healthy | Baro blocked or misconfigured | Check FC enclosure; ensure BARO_PROBE_EXT not conflicting |
| Battery failsafe | Voltage below threshold | Charge battery; adjust BATT_FS_VOLT |
| RC not calibrated | Radio cal not saved | Redo radio calibration |

See [Arming and Pre-Flight Checks](arming-preflight.md) for the full ARMING_CHECK bitmask and how to selectively disable checks for bench testing.

## Phase 6 — Initial PID Defaults

ArduPilot ships with conservative defaults that are safe for initial flight but not optimized. The Methodic Configurator recommends applying prop-size-specific rate gains before the first hover:

| Prop Size | ATC_RAT_RLL_P / ATC_RAT_PIT_P | ATC_RAT_RLL_D / ATC_RAT_PIT_D |
|-----------|-------------------------------|-------------------------------|
| 3–4″ | 0.15 | 0.003 |
| 5″ | 0.13 | 0.004 |
| 7–8″ | 0.10 | 0.005 |
| 10″+ | 0.07 | 0.006 |

These are starting points only. Set `ATC_THR_MIX_MAN` to 0.1 and `MOT_THST_HOVER` to 0.25 (lower than actual hover throttle) so ArduPilot learns the real value during the first flight.

## Phase 7 — First Hover Test

Install propellers. Conduct the first hover in a large open space, calm wind, 15–25 °C. Have an assistant hold a safety line or stand clear.

**Sequence:**

1. Arm in **Stabilize** mode. Apply minimum throttle briefly, then disarm — verifies arming and motor response.
2. Arm again. Slowly increase throttle while watching for any oscillation or yaw drift on the ground.
3. Lift off to ~0.5 m and immediately land. Assess if the vehicle felt stable.
4. If stable, hover at ~1 m. Apply small (5°) roll and pitch inputs and observe response.
5. Land, disarm, review.

**Abort if:** any single motor sounds different from the others, the vehicle oscillates at any throttle level, it yaws unexpectedly on liftoff (motor spin direction error), or it flips (frame type misconfiguration).

**If oscillations appear at hover:** reduce `ATC_RAT_RLL_P`, `ATC_RAT_RLL_D`, `ATC_RAT_PIT_P`, and `ATC_RAT_PIT_D` by 50% and retry. Repeat until stable. Do not attempt AltHold or GPS modes until Stabilize hover is clean.

Enable blackbox logging before this flight (`LOG_BITMASK = 65535` or at minimum include IMU and ATT). Set `INS_LOG_BAT_MASK = 1` to capture IMU batch samples for [notch filter analysis](../vibration-filtering-and-tuning.md).

## Phase 8 — Post-Hover Log Review

Download the log (**DataFlash Logs → Download DataFlash Log Via MAVLink**) and check:

| Log Message | What to Check |
|-------------|---------------|
| VIBE | VibeX, VibeY, VibeZ should be < 30 m/s²; Clip0/1/2 should be 0 |
| ATT | DesRoll vs. Roll and DesPitch vs. Pitch should track closely |
| RCOU | Motor outputs should be roughly equal at hover; large imbalance indicates motor/prop issue |
| BAT | Voltage sag under load; confirms power monitor calibration |
| XKF1 | EKF innovations — should be small and bounded |

With the batch IMU log, generate a frequency spectrum in Mission Planner or UAV Log Viewer to identify noise peaks for [notch filter configuration](../vibration-filtering-and-tuning.md).

## Tuning Progression After First Flight

A stable hover clears you to proceed in this order:

1. **Notch filter setup** — hover log FFT → set `INS_HNTCH_*` parameters → re-fly to confirm noise reduction.
2. **MOT_THST_HOVER** — ArduPilot learns this automatically after a few flights; verify it settled near actual hover throttle.
3. **Quiktune or AutoTune** — see [PID Tuning](pid-tuning.md). AutoTune requires stable Stabilize hover and at least 10 m altitude with no wind.
4. **MagFit compass calibration** — a dedicated in-flight compass calibration flight that corrects for motor/current interference; more accurate than bench calibration.
5. **AltHold and Loiter testing** — only after PIDs are tuned in Stabilize.

## Related Concepts

- [Arming and Pre-Flight Checks](arming-preflight.md)
- [Motor Mixing and Output](motor-mixing.md)
- [PID Tuning](pid-tuning.md)
- [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)
- [Logging and Analysis](logging.md)
- [Failsafes](failsafes.md)
- [Ground Control Stations](gcs.md)
- [Rotor Configurations](../../airframes/rotor-configurations.md)
- [Power Monitoring](power-monitoring.md)

## Sources

- [First Time Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/initial-setup.html) — 2026-05-22
- [Initial Tuning Flight — ArduPilot Copter docs](https://ardupilot.org/copter/docs/initial-tuning-flight.html) — 2026-05-22
- [Accelerometer Calibration — ArduPilot](https://ardupilot.org/copter/docs/common-accelerometer-calibration.html) — 2026-05-22
- [Compass Calibration — ArduPilot](https://ardupilot.org/copter/docs/common-compass-calibration-in-mission-planner.html) — 2026-05-22
- [Radio Control Calibration — ArduPilot](https://ardupilot.org/copter/docs/common-radio-control-calibration.html) — 2026-05-22
- [Methodic Tuning Guide — ArduPilot/MethodicConfigurator](https://ardupilot.github.io/MethodicConfigurator/TUNING_GUIDE_ArduCopter.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
