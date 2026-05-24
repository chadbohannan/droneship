# Navio2 Power System

Triple-redundant 5 V power architecture with ideal-diode arbitration, voltage/current sensing, and battery monitoring.

## Overview

Navio2 has three independent power inputs, all protected by ideal diodes that allow simultaneous connection without fighting each other. Ideal diodes are active MOSFET-based circuits that behave like diodes (block reverse current) but with much lower forward voltage drop (~20 mV vs. ~300 mV for a silicon diode), minimizing power loss. The highest-voltage source wins priority without needing manual switching.

Priority order (highest to lowest): power module → servo rail BEC (Battery Eliminator Circuit — a switching regulator that produces 5 V from the main LiPo) → Raspberry Pi USB. In a flying aircraft, the power module is always the primary source; the servo rail and USB provide fallback paths for bench work or the unlikely event of power module failure in flight.

## Power Sources

### Power Module (Primary)

The Emlid power module connects between the main battery and the Navio2 POWER port via a 6-position DF13 cable. It contains:
- A switching regulator rated at 5.3 V / 2.25 A output
- Voltage sense: resistor divider scaling battery voltage to 0–3.3 V ADC input
- Current sense: hall-effect sensor outputting 0–3.3 V proportional to current

| Specification | Value |
|---------------|-------|
| Input voltage (battery) | 2S–6S LiPo (7.4–25.2 V) |
| Output voltage | 5.3 V regulated |
| Output current | 2.25 A continuous |
| Current sensing range | 0–60 A (90 A with XT60 connector variant) |
| Connector to Navio2 | DF13 6-pin |
| Connector to battery | XT60 (Emlid module) |

### Servo Rail BEC (Secondary)

The servo rail +5 V pins form a shared power bus. Plugging a BEC into any servo channel powers this bus and, through the ideal diode, provides a fallback supply path to Navio2 and the Raspberry Pi. The BEC must supply 4.8–5.3 V; voltages above 5.3 V risk damaging the board.

**Important:** Only connect one BEC to the servo rail. Multiple BECs with slightly different output voltages will oscillate or heat each other through their internal regulation feedback loops.

### Raspberry Pi USB (Bench/Debug)

A 5 V USB power supply connected to the Raspberry Pi micro-USB or USB-C port powers both the RPi and Navio2 for bench configuration. Do not fly with USB power only — the USB power delivery is not rated for combined RPi + Navio2 + sensor current draw under flight load.

## Voltage and Current Monitoring

ArduPilot reads battery voltage and current through two ADC channels connected to the power module's sense outputs. Calibrate these values in Mission Planner under Initial Setup → Optional Hardware → Battery Monitor.

| Parameter | Function | Default (requires calibration) |
|-----------|----------|-------------------------------|
| BATT_MONITOR | Monitoring type | 4 (voltage + current) |
| BATT_VOLT_PIN | ADC pin for voltage | 2 (Navio2-specific) |
| BATT_CURR_PIN | ADC pin for current | 3 (Navio2-specific) |
| BATT_VOLT_MULT | Voltage scale factor | 11.3 |
| BATT_AMP_PERVLT | Current scale factor (A per V of sensor output) | ~17.0 |
| BATT_CAPACITY | Battery capacity (mAh) | Set to pack capacity |
| BATT_LOW_VOLT | Low battery warning voltage | ~3.5 V per cell × cells |
| BATT_CRT_VOLT | Critical battery failsafe voltage | ~3.3 V per cell × cells |

Calibration procedure: measure actual battery voltage with a multimeter, compare to Mission Planner's reading, and adjust `BATT_VOLT_MULT` until they match. Repeat with a known current load for `BATT_AMP_PERVLT`. The parameter name changed from `BATT_CURR_MULT` to `BATT_AMP_PERVLT` in ArduPilot 4.0; use the current name in all 4.x builds.

## Power Budget

| Component | Typical current at 5 V |
|-----------|------------------------|
| Raspberry Pi 3B+ (idle) | 500 mA |
| Raspberry Pi 3B+ (full load) | 980 mA |
| Raspberry Pi 4B (full load) | 1500 mA |
| Navio2 board electronics | 200 mA |
| GPS + compass | 100 mA |
| Total (RPi 3B+ + Navio2) | ~800–1200 mA |

The power module's 2.25 A rating is sufficient for a Raspberry Pi 3B+ and Navio2 under normal ArduPilot load. A Raspberry Pi 4 running heavy ROS workloads may approach or exceed this — consider a higher-rated power supply or use a separate 5 V BEC for the RPi when running compute-intensive applications.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Hardware Setup](hardware-setup.md)
- [Navio2 PWM Output](pwm-output.md)
- [Power Monitoring](../../flight-controller-software/ardupilot/power-monitoring.md)
- [Battery](../../power-systems/battery.md)

## Sources

- [Hardware setup — Emlid Navio2 docs](https://docs.emlid.com/navio2/hardware-setup/) — 2026-05-22
- [NAVIO2 Assembly and Wiring Quick Start — ArduPilot](https://ardupilot.org/copter/docs/common-navio2-wiring-and-quick-start.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
