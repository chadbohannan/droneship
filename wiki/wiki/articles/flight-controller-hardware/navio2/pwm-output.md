# Navio2 PWM Output

14-channel 5 V PWM servo rail driven by an onboard co-processor for motor ESCs, servos, and accessories.

## Overview

Navio2 provides 14 PWM output channels on a 2.54 mm (0.1 in) header, numbered 1–14. An onboard microcontroller co-processor generates the PWM signals independently from the Raspberry Pi CPU, ensuring consistent pulse timing regardless of Linux scheduling jitter. Outputs are 5 V logic and 50 Hz by default — compatible with standard hobby ESCs and analog servos. Digital high-speed servos (PWM 333 Hz+) are also supported by changing the output frequency.

ArduPilot maps vehicle functions (motors, camera triggers, landing gear, etc.) to output channels via SERVO_FUNCTION parameters. The co-processor communicates with ArduPilot over an internal SPI link; a kernel module exposes the interface via Linux sysfs, making channels accessible from any programming language.

## Channel Specifications

| Parameter | Value |
|-----------|-------|
| Channels | 14 (numbered 1–14) |
| Connector pitch | 2.54 mm (0.1 in) |
| Output voltage | 5 V logic |
| Default frequency | 50 Hz |
| Frequency range | 50–400 Hz |
| Pulse width range | 1000–2000 µs (standard); 700–2300 µs extended |
| Refresh watchdog | 100 ms — output holds last value on timeout |

## ArduPilot Motor and Servo Mapping

Channel mapping depends on FRAME_CLASS and FRAME_TYPE. For a standard quadcopter (FRAME_CLASS=1, FRAME_TYPE=1 — Quad X):

| Channel | Function | Motor position |
|---------|----------|----------------|
| 1 | Motor 1 | Rear right (CW) |
| 2 | Motor 2 | Front right (CCW) |
| 3 | Motor 3 | Front left (CW) |
| 4 | Motor 4 | Rear left (CCW) |
| 5–14 | Auxiliary | Camera, gimbal, lights, etc. |

Set SERVO1_FUNCTION through SERVO14_FUNCTION to override default mappings. Commonly used function values: 33 (motor 1), 34 (motor 2), ..., 22 (camera trigger), 28 (landing gear).

## PWM Frequency Configuration

Standard 50 Hz is compatible with all analog servos and most ESCs in PWM mode. ArduPilot on Navio2 uses 50 Hz for all outputs by default; there is no ArduPilot parameter to change the RCIO co-processor's output rate per channel. To run a channel at a higher frequency (e.g., 400 Hz for fast-update digital servos), bypass ArduPilot and set the period via sysfs directly:

```bash
# Change channel 0 to 400 Hz (period = 2,500,000 ns)
echo 2500000 > /sys/class/pwm/pwmchip0/pwm0/period
```

BLHeli_32 and AM32 ESCs in standard PWM mode function correctly at 50–400 Hz. DSHOT digital protocols are not supported on Navio2 — the co-processor generates analog PWM only.

`SERVO_BLH_POLES` is an unrelated ArduPilot parameter that sets the motor pole count for RPM telemetry via BLHeli passthrough; it has no effect on PWM frequency.

## Sysfs Interface

When bypassing ArduPilot, channels are accessible through sysfs. The kernel driver exposes each PWM channel under `/sys/class/pwm/`:

```bash
# Enable PWM channel 0 (servo rail pin 1)
echo 0 > /sys/class/pwm/pwmchip0/export
echo 20000000 > /sys/class/pwm/pwmchip0/pwm0/period   # 50 Hz in nanoseconds
echo 1500000  > /sys/class/pwm/pwmchip0/pwm0/duty_cycle  # 1.5 ms pulse
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
```

The kernel driver requires a write at least every 100 ms. If the writing process stalls, outputs freeze at the last commanded value. This behavior differs from hardware failsafe on dedicated flight controllers (Pixhawk) which can output predefined failsafe values — Navio2 has no hardware failsafe on PWM outputs beyond process watchdog.

## GPIO Mode (Alternative to PWM)

Each servo rail pin can be switched from PWM output to a plain digital GPIO output. This is useful for triggering relays, cameras, or LEDs from ArduPilot's relay system or from user scripts.

GPIO numbers are computed by the formula: **GPIO = 500 + (servo rail pin number − 1)**

```bash
# Export servo rail pin 2 as GPIO 501
echo 501 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio501/direction
echo 1 > /sys/class/gpio/gpio501/value   # set high
echo 0 > /sys/class/gpio/gpio501/value   # set low
```

Do not use a pin as GPIO and PWM simultaneously — the co-processor cannot serve both roles on the same channel. See [RCIO Co-Processor](rcio.md) for the full pin-to-GPIO mapping table including IO17/IO18 and LED lines.

## Servo Rail Power

PWM outputs carry signal only; the center rail (+5 V) draws power from whatever BEC is plugged into the servo rail. Size the BEC for peak servo current: a quadcopter with no servos requires only enough current for four ESC signal lines (negligible), while a fixed-wing with multiple control surface servos may need 3–5 A.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Hardware Setup](hardware-setup.md)
- [Navio2 Power System](power-system.md)
- [ESC — Electronic Speed Controller](../../propulsion/esc.md)
- [Motor Mixing](../../flight-controller-software/ardupilot/motor-mixing.md)
- [RCIO Co-Processor](rcio.md)
- [Navio2 Python/C++ Programming](../../programming/navio2-python.md)

## Sources

- [PWM output — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/pwm-output/) — 2026-05-22
- [NAVIO2 Assembly and Wiring Quick Start — ArduPilot](https://ardupilot.org/copter/docs/common-navio2-wiring-and-quick-start.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
