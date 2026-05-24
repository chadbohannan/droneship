# Navio2 RC Input (PPM/SBUS)

RC receiver decoding via onboard co-processor, supporting PPM sum and SBUS protocols with up to 16 channels.

## Overview

Navio2 accepts RC receiver signals through the same onboard microcontroller co-processor that generates PWM outputs. The co-processor decodes PPM or SBUS frames and makes channel values available to ArduPilot via Linux sysfs — the same mechanism used for PWM output. Offloading RC decoding to the co-processor eliminates the latency and jitter that would result from the Raspberry Pi's Linux scheduler directly sampling the timing-sensitive PPM pulse train.

PPM (Pulse Position Modulation) sum encodes up to 8–12 channels in a single wire by varying the gap between pulses. SBUS (Serial Bus) encodes up to 16 channels in a 100 kBaud inverted UART frame. Navio2 handles both on the same physical connector; protocol selection is automatic based on signal characteristics.

## Wiring

The RC INPUT header on Navio2 is a standard three-pin 2.54 mm connector:

| Pin | Signal | Level |
|-----|--------|-------|
| 1 | Signal (PPM or SBUS) | 5 V |
| 2 | +5 V out (to power receiver) | 5 V |
| 3 | GND | — |

**PPM receivers:** Connect the PPM sum output to pin 1. Most modern RC receivers with a "PPM out" or "CPPM" mode output on a single 5 V wire. The Navio2 powers the receiver via pin 2 — no separate receiver BEC is needed.

**SBUS receivers:** Connect the SBUS output (FrSky, Futaba, Spektrum) to pin 1. SBUS is an inverted 3.3 V signal electrically, but the co-processor accepts 5 V levels and handles inversion internally. Do not connect servos to the receiver's PWM outputs while powering it from the Navio2's RC INPUT pin — servo current can brownout the Raspberry Pi.

## Supported Protocols

| Protocol | Channels | Update Rate | Notes |
|----------|----------|-------------|-------|
| PPM sum | 8–12 | ~50 Hz | Single wire, 5 V, positive polarity |
| SBUS | Up to 16 | ~100 Hz | Inverted UART, 100 kBaud, 3.3/5 V |

SBUS is preferred over PPM for higher channel count (16 vs. 8–12) and faster update rate (100 Hz vs. 50 Hz), which reduces control latency at the ArduPilot layer.

## ArduPilot RC Parameters

No special parameters are required to enable RC input on Navio2; ArduPilot auto-detects the sysfs RC input device provided by the kernel module.

| Parameter | Function | Notes |
|-----------|----------|-------|
| RCMAP_ROLL | Input channel for roll | Default 1 |
| RCMAP_PITCH | Input channel for pitch | Default 2 |
| RCMAP_THROTTLE | Input channel for throttle | Default 3 |
| RCMAP_YAW | Input channel for yaw | Default 4 |
| RC_OPTIONS | Bit flags for RC behavior | — |
| SBUS_OUT | Enable SBUS output (not input) | 0 (disabled) |

## Modern RC Protocols (ELRS, CRSF)

ExpressLRS (ELRS) and TBS Crossfire (CRSF) receivers are common on modern builds. Neither protocol is supported natively by the RCIO co-processor. Use the receiver's SBUS output mode as a compatibility bridge:

- **ELRS:** Configure the receiver output to SBUS in the ELRS Configurator or Betaflight Configurator. Connect the SBUS output to the Navio2 RC INPUT header.
- **CRSF/Crossfire:** Similarly, enable SBUS output on the TBS receiver. CRSF (serial) requires a UART and ArduPilot CRSF driver support — this is available on Pixhawk-class boards but **not** natively through the RCIO co-processor's single RC input pin.

Using SBUS output from ELRS or Crossfire receivers works reliably on Navio2 at 100 Hz with up to 16 channels. The additional latency versus native CRSF (≈2–4 ms extra) is acceptable for most applications.

## Failsafe Configuration

RC failsafe triggers when the RC link is lost. Configure it at two levels:

1. **Transmitter/receiver failsafe:** Program the receiver to output a specific SBUS frame or PPM pulse on link loss (e.g., throttle channel drops to 900 µs). This is receiver-model-specific.
2. **ArduPilot failsafe:** Set FS_THR_ENABLE=1 and FS_THR_VALUE to a pulse width below your lowest normal throttle value (typically 975 µs). When ArduPilot sees throttle below this threshold for FS_THR_TIMEOUT seconds, it triggers the configured failsafe action (RTL, Land, etc.).

## Testing RC Input

Use Mission Planner's Radio Calibration screen (Initial Setup → Mandatory Hardware → Radio Calibration) to verify channel ranges before arming. Alternatively, read raw values from sysfs:

```bash
# Read decoded RC channel values (channel 0 = roll, etc.)
cat /sys/kernel/rcio/rcin/ch0
cat /sys/kernel/rcio/rcin/ch1
```

Values are in microseconds (1000–2000 typical range).

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Hardware Setup](hardware-setup.md)
- [RC Systems](../../flight-controller-software/ardupilot/rc-systems.md)
- [RCIO Co-Processor](rcio.md)
- [Failsafes](../../flight-controller-software/ardupilot/failsafes.md)

## Sources

- [Hardware setup — Emlid Navio2 docs](https://docs.emlid.com/navio2/hardware-setup/) — 2026-05-22
- [NAVIO2 Overview — ArduPilot](https://ardupilot.org/copter/docs/common-navio2-overview.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
