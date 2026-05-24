# ESC — Electronic Speed Controller

An ESC converts the flight controller's digital or analog motor command into three-phase AC power for a brushless motor. It is the link between the autopilot's mixing outputs and the physical propulsion hardware.

## Overview

The flight controller sends a throttle signal (PWM, DShot, or CAN) to each ESC independently. The ESC's firmware generates three sinusoidal or trapezoidal waveforms phase-shifted 120° apart to drive the motor's stator coils. Modern ESCs use silicon MOSFETs and run at 32 kHz or higher switching frequencies to produce smooth torque with minimal heat.

## Firmware Types

| Firmware | MCU | Notes |
|----------|-----|-------|
| **BLHeli_S** | 8-bit EFM8 | Legacy; no bidirectional DShot; development stopped |
| **AM32** | 8-bit (successor to BLHeli_S) | Open source; bidirectional DShot; better startup |
| **BLHeli_32** | 32-bit ARM | Full feature set; graphical configurator; smoothest response |
| **KISS** | Proprietary ARM | High performance; closed ecosystem |
| **APD** (Advanced Power Drives) | Proprietary | Industrial/heavy lift; high-current |

For new builds, **BLHeli_32** (proprietary but widely adopted) or **AM32** (open source) are recommended. BLHeli_S ESCs lack bidirectional DShot support and cannot provide RPM telemetry for notch filtering.

## Protocols

| Protocol | Type | Update rate | Calibration | Notes |
|----------|------|-------------|-------------|-------|
| **PWM** | Analog | ~500 Hz | Required | 1000–2000 µs; universal |
| **OneShot125** | Analog | ~4 kHz | Required | 125–250 µs; 8× faster than PWM |
| **Multishot** | Analog | ~32 kHz | Required | Fastest analog; rare |
| **DShot150** | Digital | 150 kbps | None | Noise immune |
| **DShot300** | Digital | 300 kbps | None | F4+ required |
| **DShot600** | Digital | 600 kbps | None | H7 recommended |

Digital protocols (DShot) are preferred: no calibration, immune to noise, exact throttle values, and enable bidirectional telemetry. Use DShot600 on H7 hardware.

## ESC Calibration (PWM/Analog)

PWM ESCs must learn the throttle range of the flight controller:

1. Power on transmitter, set throttle maximum.
2. Connect battery while holding the calibration button or arming channel high (procedure varies by ESC firmware).
3. ESC plays a tone; lower throttle to minimum.
4. ESC plays confirmation tones and is calibrated.

DShot ESCs require no calibration — the protocol is fully digital and always accurate.

## Bidirectional DShot and RPM Telemetry

Bidirectional DShot returns electrical RPM (eRPM) from the ESC to the flight controller on the same signal wire (no additional wiring). The flight controller converts eRPM to mechanical RPM using motor pole count:

```
RPM = eRPM / (pole_pairs)
pole_pairs = pole_count / 2
```

A 14-pole motor has 7 pole pairs. A motor reading 7000 eRPM = 1000 mechanical RPM.

Enable in ArduPilot with `SERVO_BLH_BDMASK` (bitmask of motor outputs). This RPM data drives the harmonic notch filter, which surgically removes motor noise at the exact frequencies — the most precise vibration filtering possible. See [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md).

## BLHeli Passthrough (Configuration via ArduPilot)

Configure BLHeli_32 and AM32 ESCs through the flight controller without disconnecting wiring:

```
SERVO_BLH_AUTO = 1     (auto-enable passthrough on motor outputs)
```

In Mission Planner: Setup → Optional Hardware → BLHeli ESC Configuration. This uses MAVLink to relay BLHeli passthrough commands to each ESC.

ESC telemetry (current, temperature, RPM per motor without bidirectional DShot):
```
SERIALx_PROTOCOL = 16     (ESC telemetry)
SERVO_BLH_TPORT  = x      (serial port number)
```

## 4-in-1 vs. Individual ESCs

**4-in-1 ESC**: All four motor controllers on a single PCB. Lower weight, cleaner wiring, common power distribution. Single point of failure for all four motors. Dominant in 5-inch FPV builds.

**Individual ESCs**: Independent failure domains. Heavier. Required for large frames where ESC power ratings exceed 4-in-1 options. Standard for 7-inch and larger.

## Current Rating Selection

Select ESC continuous current rating at least 20% above the motor's maximum current draw. Motors typically draw 20–50 A peak at full throttle.

Example: Motor rated 35 A maximum → use 40 A or higher ESC.

ESC temperature is the limiting factor. In practice, brief bursts to the rated limit are acceptable; sustained operation at limit generates heat that reduces lifespan.

## 3D / Reversible Mode

3D mode enables motor reversal mid-flight, used for inverted flying and cinematic dives. Requires an ESC firmware that supports 3D and the `MOT_PWM_TYPE` parameter set appropriately in ArduPilot.

## Related Concepts

- [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md)
- [Motor Mixing and Output](../flight-controller-software/ardupilot/motor-mixing.md)
- [CAN Bus and DroneCAN](../flight-controller-software/ardupilot/can-dronecan.md)
- [Battery](../power-systems/battery.md)

## Sources

- [DShot ESCs — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-dshot-escs.html) — 2026-05-22
- [ESC Calibration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/esc-calibration.html) — 2026-05-22
- [BLHeli32 Passthrough — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-blheli32-passthru.html) — 2026-05-22
- [ESC Firmware Overview — Oscar Liang](https://oscarliang.com/esc-firmware-protocols/) — 2026-05-22

<!-- linted: 2026-05-23 -->
