# Motor Mixing and Output — ArduPilot

Motor mixing translates roll, pitch, yaw, and throttle demands into per-motor output values. ArduPilot's `AP_MotorsMatrix` library encodes frame-specific mixing coefficients and handles output scaling, spin limits, ESC protocol selection, and voltage compensation.

## Overview

The mixing matrix assigns each motor a signed coefficient for roll, pitch, and yaw contribution based on the motor's position and spin direction. Throttle distributes equally across all motors. Roll and pitch take priority over yaw, which takes priority over throttle — ensuring attitude control is never sacrificed for altitude.

Frame geometry is selected via two parameters — `FRAME_CLASS` and `FRAME_TYPE` — which together select the appropriate mixing matrix from the firmware's built-in set.

## Frame Configuration

### FRAME_CLASS

| Value | Class | Motors |
|-------|-------|--------|
| 1 | Quad | 4 |
| 2 | Hexa | 6 |
| 3 | Octa | 8 |
| 4 | OctaQuad | 8 (4 coaxial pairs) |
| 5 | Y6 | 6 (3 coaxial pairs) |
| 7 | Tri | 3 |
| 10 | BiCopter | 2 |
| 12 | DodecaHexa | 12 |
| 14 | Deca | 10 |

### FRAME_TYPE

| Value | Layout | Notes |
|-------|--------|-------|
| 0 | Plus (+) | Motor at 0/90/180/270° |
| 1 | X | Motor at 45/135/225/315° (default) |
| 2 | V | Narrower front, wider rear |
| 3 | H | H-frame, motors at corners |
| 10 | Y6B | Y6 Betaflight motor order variant |

After changing either parameter, reboot and re-run motor tests to verify output assignments.

## Motor Numbering and Spin Direction

ArduPilot numbers motors starting from front-right and proceeding clockwise. Diagrams use green arrows for clockwise (CW) props and blue for counter-clockwise (CCW).

**Quad X (FRAME_CLASS=1, FRAME_TYPE=1):**

```
         Front
    3 (CCW)  1 (CW)
         ✈
    2 (CW)   4 (CCW)
```

| Motor | Position | Spin | Output |
|-------|----------|------|--------|
| 1 | Front-right | CW | MAIN 1 |
| 2 | Rear-left | CW | MAIN 2 |
| 3 | Front-left | CCW | MAIN 3 |
| 4 | Rear-right | CCW | MAIN 4 |

For hexacopters and octocopters, motors continue numbering clockwise from front-right. Consult the [Frame Type Configuration](https://ardupilot.org/copter/docs/frame-type-configuration.html) page for full diagrams of each frame variant.

## Mixing Matrix

For Quad X, each motor output = `throttle + roll_coeff×roll + pitch_coeff×pitch + yaw_coeff×yaw`:

| Motor | Roll | Pitch | Yaw |
|-------|------|-------|-----|
| 1 (FR) | + | − | + |
| 2 (RL) | − | + | + |
| 3 (FL) | − | − | − |
| 4 (RR) | + | + | − |

Roll positive = right roll. Pitch positive = forward pitch. Yaw positive = clockwise yaw when viewed from above.

When a motor would be driven below its minimum or above its maximum, the mixer scales all outputs down to keep relative ratios intact — attitude authority is preserved.

## Motor Spin Parameters

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `MOT_SPIN_ARM` | 0.10 | fraction (0–1) | Throttle fraction when armed but not flying |
| `MOT_SPIN_MIN` | 0.13 | fraction (0–1) | Minimum throttle fraction during flight |
| `MOT_SPIN_MAX` | 0.95 | fraction (0–1) | Maximum throttle fraction |
| `MOT_THST_HOVER` | 0.35 | fraction (0–1) | Estimated hover throttle; self-learns via `MOT_HOVER_LEARN` |

`MOT_SPIN_MIN` must be at least 0.03 above `MOT_SPIN_ARM` to prevent stalls when attitude correction demands a rapid increase from armed-idle. `MOT_SPIN_MAX` caps at 0.95 because most ESCs produce no additional thrust above ~95% PWM while still drawing full current.

### Calibrating Spin Parameters

With props off, use Mission Planner Motor Test to find each motor's minimum spinning threshold:

1. Start Motor Test at 5% and increase until each motor spins.
2. Record the highest percentage — this is the minimum spin threshold.
3. Set `MOT_SPIN_MIN` to that value + 3%.
4. Set `MOT_SPIN_ARM` to that value − 2% (should be visibly spinning but slowly).

## ESC Protocol

| `MOT_PWM_TYPE` | Protocol | Notes |
|----------------|----------|-------|
| 0 | PWM (1000–2000 µs) | Default; universal compatibility |
| 1 | OneShot | Frame-rate matched; faster than PWM |
| 2 | OneShot125 | Pulse widths ÷8; AUX outputs only on IOMCU boards |
| 4 | DShot150 | Digital; AUX outputs only on Pixhawk/Cube |
| 5 | DShot300 | Digital; preferred for BLHeli_32 |
| 6 | DShot600 | Digital; highest update rate |

On IOMCU boards (Pixhawk 4/6, Cube Orange), DShot and OneShot125 are available **only on AUX outputs**. MAIN outputs support PWM and OneShot only. Reboot after changing `MOT_PWM_TYPE`. All outputs sharing a hardware timer must use the same protocol — check the board's output group table.

See [ESC — Electronic Speed Controller](../../propulsion/esc.md) for protocol configuration on the ESC side.

## Thrust Linearisation

Motor thrust is not proportional to PWM — it follows a roughly square-law relationship with commanded throttle. `MOT_THST_EXPO` compensates:

| `MOT_THST_EXPO` | Prop size |
|-----------------|-----------|
| 0.55 | 5-inch |
| 0.65 | 10-inch (default) |
| 0.75 | 20-inch+ |
| 0.0 | Use if ESC firmware already linearises thrust |

Higher values apply more correction for motors with strongly non-linear thrust curves. If you have thrust-stand data for your motor/prop/ESC combination, compute the actual curve and derive the expo from it rather than using these estimates.

## Battery Voltage Compensation

As battery voltage drops, motors produce less thrust for the same PWM output. Voltage compensation increases the commanded PWM proportionally to maintain consistent thrust throughout the discharge cycle.

| Parameter | Unit | Description |
|-----------|------|-------------|
| `MOT_BAT_VOLT_MAX` | V | Fully-charged pack voltage (e.g., 16.8 V for 4S LiPo) |
| `MOT_BAT_VOLT_MIN` | V | Minimum operating voltage (set to match battery failsafe) |
| `MOT_BAT_CURR_MAX` | A | Current limit; throttle reduces to 60% if exceeded |

Set `MOT_BAT_VOLT_MAX` to the resting voltage at full charge (4.2 V/cell × cell count) and `MOT_BAT_VOLT_MIN` to the low-battery failsafe threshold. Compensation is disabled if either is zero.

`MOT_BAT_CURR_MAX` protects the pack from burst overdraw. Set it to the rated continuous current of the battery rather than the burst rating — ArduPilot will reduce collective throttle if this threshold is exceeded.

## Motor Test

Before first flight, verify motor order and spin direction using Mission Planner:

1. Go to **Setup → Optional Hardware → Motor Test**.
2. Test each motor individually with props off. The mission planner diagram shows which physical position each lettered test (A–D) corresponds to.
3. Confirm each motor spins at the expected position and in the correct direction.
4. Fix spin direction by swapping any two of the three motor phase wires (PWM/analogue ESCs) or via DShot direction commands (BLHeli ESCs).

See [First Flight Setup](first-flight.md) for the complete pre-flight motor verification procedure.

## Redundancy and Motor Loss

On frames with 6 or more motors, ArduPilot includes motor-loss detection. If a motor output drops to zero (ESC failure or disconnection), the firmware redistributes control authority across remaining motors and attempts to maintain attitude. Performance degrades and yaw authority is typically lost first, but the vehicle can often continue to a controlled landing.

## Related Concepts

- [Rotor Configurations](../../airframes/rotor-configurations.md)
- [First Flight Setup](first-flight.md)
- [Arming and Pre-Flight Checks](arming-preflight.md)
- [PID Tuning](pid-tuning.md)
- [ESC — Electronic Speed Controller](../../propulsion/esc.md)
- [Power Monitoring](power-monitoring.md)

## Sources

- [Frame Type Configuration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/frame-type-configuration.html) — 2026-05-22
- [Setting Motor Range — ArduPilot Copter docs](https://ardupilot.org/copter/docs/set-motor-range.html) — 2026-05-22
- [Motor Thrust Scaling — ArduPilot Copter docs](https://ardupilot.org/copter/docs/motor-thrust-scaling.html) — 2026-05-22
- [Current Limiting and Voltage Scaling — ArduPilot Copter docs](https://ardupilot.org/copter/docs/current-limiting-and-voltage-scaling.html) — 2026-05-22
- [Connect ESCs and Motors — ArduPilot Copter docs](https://ardupilot.org/copter/docs/connect-escs-and-motors.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
