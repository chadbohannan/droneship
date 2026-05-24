# PID Tuning — ArduPilot

ArduPilot's attitude controller is a cascaded PID system: an outer angle loop produces desired rotation rates, which an inner rate loop translates to motor commands. Tuning those rate-loop gains — and the filters protecting them — determines how precisely and smoothly the vehicle responds.

## Overview

Before tuning, the vehicle must pass all pre-arm checks and complete a stable hover in Stabilize mode. Vibration must be under control first — excessive IMU noise forces lower gains and masks the response needed to tune well. See [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md) before proceeding.

Three automated paths exist: **AutoTune** (built-in, requires twitching room), **QuikTune** (Lua script, safer in tight spaces), and **Methodic Configurator** (guided manual process). All three produce the same `ATC_RAT_*` parameter set; manual tuning is also viable for experienced pilots.

## Control Architecture

ArduPilot's attitude controller is a two-layer cascade:

```
Pilot input / autopilot
        ↓
  Angle Controller (P only)
  ATC_ANG_RLL_P, ATC_ANG_PIT_P, ATC_ANG_YAW_P
        ↓ desired rotation rate
  Rate Controller (PID + FF)
  ATC_RAT_RLL_*, ATC_RAT_PIT_*, ATC_RAT_YAW_*
        ↓ motor output
```

The **angle controller** (proportional only, default P = 4.5) converts angle error into a desired rotation rate. The **rate controller** compares that desired rate to measured gyro rate and applies PID correction plus feedforward. Both loops run at 400 Hz.

## Parameter Reference

### Angle Controller

| Parameter | Default | Description |
|-----------|---------|-------------|
| `ATC_ANG_RLL_P` | 4.5 | Roll angle proportional gain |
| `ATC_ANG_PIT_P` | 4.5 | Pitch angle proportional gain |
| `ATC_ANG_YAW_P` | 4.5 | Yaw angle proportional gain |
| `ATC_INPUT_TC` | 0.15 s | Input shaping time constant — time to reach 63% of commanded angle |

`ATC_INPUT_TC` smooths pilot inputs to reduce abrupt attitude changes. Values 0.15–0.25 s are typical; higher values feel smoother but reduce crispness. Multiply by 3 to estimate full settling time.

### Rate Controller (per axis: RLL, PIT, YAW)

| Suffix | Default | Role |
|--------|---------|------|
| `_P` | 0.135 | Proportional: immediate correction proportional to rate error |
| `_I` | 0.135 | Integral: eliminates steady-state rate error over time |
| `_D` | 0.0036 | Derivative: damps rate change to prevent overshoot |
| `_FF` | 0.0 | Feedforward: pre-compensates commanded rate; reduces I term burden |
| `_IMAX` | 0.5 | Caps integrator to prevent windup |
| `_ILMI` | 0.05 | Integrator leak minimum; prevents I from zeroing at low speed |
| `_FLTT` | 12 Hz | Low-pass filter on target (commanded) rate |
| `_FLTD` | 3 Hz | Low-pass filter on D term — set to `INS_GYRO_FILTER / 2` |
| `_FLTE` | 0 Hz | Low-pass filter on rate error (0 = disabled) |

Defaults above are for roll/pitch. Yaw defaults are higher P/I (typically 0.18/0.018) with no D term by default.

### Acceleration Limits

| Parameter | Description |
|-----------|-------------|
| `ATC_ACCEL_R_MAX` | Max roll acceleration (centi-°/s²); 0 = no limit |
| `ATC_ACCEL_P_MAX` | Max pitch acceleration |
| `ATC_ACCEL_Y_MAX` | Max yaw acceleration |

Typical values by prop size: 1100 for 10-inch, 500 for 20-inch, 200 for 30-inch props. AutoTune cannot determine these — set them based on the frame before running AutoTune.

## Before Tuning

1. Complete vibration isolation and configure notch/RPM filters (see [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)).
2. Set `MOT_THST_HOVER = 0.25` initially — it will self-learn via `MOT_HOVER_LEARN = 2`.
3. Set `ATC_THR_MIX_MAN = 0.1` — keeps attitude control authority at low throttle.
4. Set `MOT_THST_EXPO` for your prop size: 0.55 for 5-inch, 0.65 for 10-inch, 0.75 for 20-inch+.
5. Verify a stable, low-oscillation hover in Stabilize mode before any systematic tuning.

If the vehicle oscillates before tuning begins, reduce all `ATC_RAT_*_P` and `_D` by 50% and re-hover.

## AutoTune

AutoTune performs structured roll and pitch twitches (~20° each axis) to measure the airframe's dynamic response, then computes optimal `ATC_RAT_*` gains automatically.

### Procedure

1. Assign AutoTune to an aux switch: `RCx_OPTION = 17` (or use AUTOTUNE flight mode directly).
2. Take off in AltHold mode and climb to at least 10 m in calm conditions.
3. Engage AutoTune via switch. The vehicle twitches each axis in sequence — roll, then pitch, then yaw.
4. Reposition with sticks if the vehicle drifts; AutoTune resumes when sticks are released.
5. When complete, switch back to AltHold. Test the new gains: the vehicle should feel crisp and stable.
6. **To save:** land and disarm. **To revert:** switch AutoTune off before disarming.

### AutoTune Parameters

| Parameter | Range | Description |
|-----------|-------|-------------|
| `AUTOTUNE_AGGR` | 0.05–0.10 | Aggressiveness: 0.05 = weak, 0.075 = medium, 0.10 = aggressive |
| `AUTOTUNE_AXES` | bitmask | 1=roll, 2=pitch, 4=yaw, 8=yaw D, 15=all axes |
| `AUTOTUNE_MIN_D` | 0.001 | Minimum allowed D gain |

Start with `AUTOTUNE_AGGR = 0.075`. If the result is too twitchy, re-run at 0.05; if too soft, try 0.10. AutoTune can produce an unflyable tune on badly vibrating frames — eliminate vibration first.

One axis at a time is safer on frames with strong roll/pitch coupling. Set `AUTOTUNE_AXES = 1` (roll only), fly, save, then repeat for pitch (2) and yaw (4).

## QuikTune

QuikTune is a Lua script alternative to AutoTune. It increases each gain until oscillation is detected, then reduces it by 60%, without requiring the vehicle to twitch. Safer in confined spaces; requires light wind to provide the disturbances needed for gain identification.

### Setup

1. Enable Lua scripting: `SCR_ENABLE = 1`.
2. Download `quiktune.lua` from the ArduPilot scripts library and place it on the SD card in `/APM/scripts/`.
3. Assign an RC switch: `RCx_OPTION = 300`.
4. Reboot.

### Procedure

1. Arm and climb to ~3 m in Loiter mode.
2. Engage QuikTune via switch. The GCS Messages tab shows progress.
3. QuikTune tunes roll D, then roll P/I, then pitch D, then pitch P/I, then yaw in sequence.
4. Disarm to save. Switch off before disarming to discard.

QuikTune cannot set `ATC_ACCEL_*_MAX` — configure those manually before running it. See [Lua Scripting](lua-scripting.md) for scripting setup.

## Manual Tuning

Manual tuning is systematic and iterative. Work in Stabilize mode; apply 5–10° control inputs and observe response. Tune roll and pitch independently; yaw last.

### D Term First

1. Set P and I to half of defaults. Set D to near zero.
2. Increase D in 50% steps until high-frequency oscillation appears (motor buzz, jittery attitude).
3. Reduce D until oscillation stops, then reduce a further 25%.

### P Term Second

1. Increase P in 50% steps until slow oscillation appears.
2. Reduce in 10% steps until stable.
3. Reduce a further 25%.

### I Term

Set `ATC_RAT_xxx_I = ATC_RAT_xxx_P`. The vehicle should hold attitude against wind without drifting. If it drifts slowly, increase I. If it hunts around a setpoint, reduce I.

### Feedforward

Set `ATC_RAT_xxx_FF ≈ ATC_RAT_xxx_I`. FF reduces the error that I must correct, enabling faster response with less lag.

## Oscillation Diagnosis

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| High-freq buzz, motor noise | P or D too high | Reduce P/D by 25% |
| Slow pendulum rock | P or I too low | Increase P/I |
| Oscillation only at full throttle | Notch filter not covering motor harmonics | Reconfigure notch filter |
| Oscillation after aggressive input | D too low | Increase D |
| Drift in wind, no oscillation | I too low | Increase I |
| Copter overshoots and rings | D too low | Increase D |
| Copter sluggish | P too low | Increase P |

After any gain change: hover, make a sharp roll or pitch input, and observe whether the vehicle returns to level cleanly without ringing or oscillation.

## Filter Interaction

The `_FLTD` filter (D-term low-pass) must be set to approximately `INS_GYRO_FILTER / 2`. For example, with `INS_GYRO_FILTER = 40 Hz`, set `ATC_RAT_RLL_FLTD = 20 Hz`. For large-prop frames (≥13-inch props), reduce to 10 Hz.

Over-filtering the D term introduces phase lag that reduces its damping effectiveness and can itself cause oscillation. Under-filtering allows gyro noise to drive the D term, also causing oscillation. See [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md) for the full filter stack.

## Tuning in SITL

[SITL](sitl.md) lets you rehearse the entire tuning workflow — AutoTune runs, manual gain sweeps, filter changes, and failure-mode response — against a physics model before risking a real airframe. SITL is not a substitute for a final on-vehicle tune (the simulated FDM does not match your exact mass, prop, and motor dynamics), but it is the right place to learn the procedure, validate Lua tuning scripts, and pre-screen gain ranges.

### AutoTune in SITL

AutoTune runs identically in SITL to a real vehicle. Launch a copter, take off in AltHold, switch to AutoTune, and let it complete:

```bash
sim_vehicle.py -v ArduCopter -f quad --console --map --speedup 4
# In MAVProxy:
mode guided
arm throttle
takeoff 10
mode althold
rc 7 2000          # if RC7_OPTION = 17 (AutoTune)
```

`--speedup 4` runs the sim at 4× real time, cutting a 20-minute AutoTune to ~5 minutes. Higher speedups (`10`+) work on fast hosts but eventually break EKF timing — back off if you see `EKF variance` warnings.

### Disturbance and Plant Variation

`SIM_*` parameters perturb the simulated plant so you can stress-test a tune against realistic conditions:

| Parameter | Effect | Typical Range |
|-----------|--------|---------------|
| `SIM_WIND_SPD` | Steady wind speed | 0–15 m/s |
| `SIM_WIND_DIR` | Wind direction | 0–360 ° |
| `SIM_WIND_TURB` | Turbulence intensity | 0–5 m/s |
| `SIM_BATT_VOLTAGE` | Battery voltage (affects thrust headroom) | 10.5–12.6 V (3S) |
| `SIM_ENGINE_MUL` | Per-motor thrust scale (set one motor < 1.0 to model degradation) | 0.7–1.0 |
| `SIM_VIB_FREQ_*` | Injected vibration frequency per axis | 50–250 Hz |
| `SIM_VIB_MOT_MAX` | Vibration amplitude at full throttle | 0–10 m/s² |
| `SIM_GYR_RND` | Gyro noise stddev | 0–5 |

A tune that holds altitude in `SIM_WIND_SPD = 10, SIM_WIND_TURB = 3` is far more likely to survive an outdoor flight than one tested only in still air.

### Replay-Based Filter Tuning

Log Replay re-runs the EKF and (optionally) the attitude controller against sensor data from a real flight. This is the canonical workflow for tuning `EK3_*` and `INS_*` filter parameters without re-flying:

```bash
# On the vehicle, before the reference flight:
param set LOG_REPLAY 1
param set LOG_DISARMED 1

# After downloading the .BIN log:
./waf configure --board=sitl --debug && ./waf replay
build/sitl/tool/Replay logs/00000042.BIN
```

The replay binary reads parameters from the log header but lets you override any of them. Iterate `EK3_GYRO_P_NSE`, `INS_HNTCH_FREQ`, notch bandwidth, etc., and compare the resulting `XKF*` innovations against the original. See [Logging and Analysis](logging.md) for innovation interpretation.

### Frequency-Domain Workflow

For notch filter setup, fly an `FFT` log in SITL with `SIM_VIB_FREQ_*` set to your real airframe's measured vibration peak (read from a prior `VIBE` log). Confirm that `INS_HNTCH_FREQ` / `INS_HNTCH_BW` attenuate the peak in `FTN1.PkX/Y/Z` before deploying to the real vehicle. This catches notch misconfiguration on the bench rather than mid-flight.

### Parameter Sweeps via Autotest

The [autotest framework](sitl.md#automated-testing) can script gain sweeps. A Python test that arms, flies a step-response mission, and records `ATT` tracking error for each `ATC_RAT_RLL_P` value produces a quantitative response curve in minutes — useful for understanding sensitivity around an AutoTune result.

> **Limitation:** SITL's default multirotor FDM uses a generic thrust/drag model. Absolute gain values from SITL rarely transfer one-to-one to a real airframe; treat SITL tunes as starting points and ratios (e.g., D ≈ P/10) rather than final values.

## Log Review for Tuning

Enable `LOG_BITMASK` to include IMU and attitude data. Key log messages:

| Log Message | Fields to Check |
|-------------|----------------|
| `ATT` | `DesRoll/Roll`, `DesPitch/Pitch` — tracking error between desired and actual |
| `RATE` | `RDes/R`, `PDes/P` — rate tracking error |
| `CTUN` | `ThO` — throttle output; confirms hover point |
| `VIBE` | `VibeX/Y/Z` — verify < 15 m/s² before trusting gains |

Plot `ATT.DesRoll` vs `ATT.Roll` in Mission Planner's Log Analysis. Good tuning shows actual closely tracking desired with no sustained lag or overshoot. See [Logging and Analysis](logging.md).

## Related Concepts

- [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)
- [First Flight Setup](first-flight.md)
- [Flight Modes](flight-modes.md)
- [Motor Mixing and Output](motor-mixing.md)
- [Logging and Analysis](logging.md)
- [Parameters](parameters.md)
- [Lua Scripting](lua-scripting.md)
- [SITL](sitl.md)

## Sources

- [Tuning Process Instructions — ArduPilot Copter docs](https://ardupilot.org/copter/docs/tuning.html) — 2026-05-22
- [AutoTune — ArduPilot Copter docs](https://ardupilot.org/copter/docs/autotune.html) — 2026-05-22
- [QuikTune — ArduPilot Copter docs](https://ardupilot.org/copter/docs/quiktune.html) — 2026-05-22
- [Input Shaping — ArduPilot Copter docs](https://ardupilot.org/copter/docs/input-shaping.html) — 2026-05-22
- [Roll/Pitch Rate Controller Tuning — ArduPilot Copter docs](https://ardupilot.org/copter/docs/ac_rollpitchtuning.html) — 2026-05-22
- [Multirotor Control Systems — ArduPilot DeepWiki](https://deepwiki.com/ArduPilot/ardupilot/3.1.2-multirotor-control-systems) — 2026-05-22
- [SITL Simulator — ArduPilot dev docs](https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html) — 2026-05-23
- [Testing with Replay — ArduPilot dev docs](https://ardupilot.org/dev/docs/testing-with-replay.html) — 2026-05-23

<!-- linted: 2026-05-23 -->
