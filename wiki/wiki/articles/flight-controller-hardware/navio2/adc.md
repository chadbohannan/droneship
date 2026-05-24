# Navio2 ADC

Six-channel analog-to-digital converter exposed via sysfs for reading board voltage, servo rail voltage, power module voltage and current, and two general-purpose analog inputs.

## Overview

The Navio2 ADC is driven by the RCIO co-processor and exposed to Linux through the sysfs interface at `/sys/kernel/rcio/adc/`. Six channels are available, of which four are hardwired to internal power signals and two are routed to the external ADC connector on the board header.

ArduPilot reads channels 2 and 3 automatically for battery voltage and current monitoring when a power module is connected to the POWER port. Channels 4 and 5 are available for custom sensor integration via direct sysfs reads or the Navio2 Python/C++ libraries.

## Channel Map

| Channel | sysfs path | Signal | Notes |
|---------|-----------|--------|-------|
| A0 | `ch0` | Board 5 V rail | Always ~5 V when powered |
| A1 | `ch1` | Servo rail voltage | Reflects BEC/UBEC on servo rail |
| A2 | `ch2` | Power module voltage | POWER port; multiply by 11.3 for true voltage |
| A3 | `ch3` | Power module current | POWER port; multiply by 17.0 for true current (A) |
| A4 | `ch4` | ADC2 | External ADC connector pin |
| A5 | `ch5` | ADC3 | External ADC connector pin |

Raw sysfs values are in millivolts (mV). Divide by 1000 to get volts before applying any conversion coefficient. Channel numbering in ArduPilot parameter names (`BATT_VOLT_PIN`, `BATT_CURR_PIN`) matches the A0–A5 index directly.

A4 and A5 float at a few millivolts when nothing is connected to the ADC header — this is normal and not an error condition.

## Conversion Coefficients

The Emlid power module uses a resistor divider and current shunt with fixed scaling:

| Signal | Coefficient | Formula |
|--------|-------------|---------|
| Voltage (A2) | 11.3 | `V_batt = adc_volts × 11.3` |
| Current (A3) | 17.0 | `I_batt = adc_volts × 17.0` |

Where `adc_volts` = raw sysfs reading (mV) ÷ 1000. These coefficients match the default ArduPilot values for the Emlid power module. Third-party power modules use different resistor dividers and shunt values — calibrate them against a known-good meter before use.

## sysfs Interface

```bash
cat /sys/kernel/rcio/adc/ch0   # board voltage in mV
cat /sys/kernel/rcio/adc/ch2   # power module voltage in mV
cat /sys/kernel/rcio/adc/ch3   # power module current in mV
```

The `rcio_adc` kernel module must be loaded; it is included in Emlid Raspbian by default. If the path does not exist, the module was not loaded — check `dmesg` for RCIO errors.

## Python

```python
from navio.adc import ADC

adc = ADC()
for ch in range(6):
    print("A{}: {:.4f}V".format(ch, adc.read(ch) / 1000))
```

`ADC()` opens file handles for all six channels at `/sys/kernel/rcio/adc/ch0`–`ch5`. Call `read(n)` to get the raw millivolt value for channel `n`.

## C++

```cpp
#include <Navio2/ADC_Navio2.h>

ADC_Navio2 adc;
adc.initialize();
for (int i = 0; i < adc.get_channel_count(); i++)
    printf("A%d: %.4fV\n", i, adc.read(i) / 1000.0f);
```

The C++ example in `C++/Examples/ADC/` compiles with `make` and loops at 2 Hz. Do not run simultaneously with ArduPilot — the flight controller reads these channels directly via RCIO.

## ArduPilot Battery Monitor

ArduPilot maps ADC channels to its battery monitor system via parameters. With the Emlid power module:

| Parameter | Value | Notes |
|-----------|-------|-------|
| BATT_VOLT_PIN | 2 | Maps to A2 (POWER port voltage) |
| BATT_CURR_PIN | 3 | Maps to A3 (POWER port current) |
| BATT_VOLT_MULT | 11.3 | Voltage scaling coefficient |
| BATT_AMP_PERVLT | 17.0 | Current scaling coefficient |

Set these in Mission Planner under Optional Hardware → Battery Monitor, or via the full parameter list.

## Related Concepts

- [Navio2 RCIO Co-Processor](rcio.md)
- [Navio2 Power System](power-system.md)
- [ArduPilot Power Monitoring](../../flight-controller-software/ardupilot/power-monitoring.md)
- [Navio2 Python and C++ Programming](../../programming/navio2-python.md)

## Sources

- [ADC — Emlid Navio2 Docs](https://docs.emlid.com/navio2/dev/adc/) — 2026-05-22
- Navio2 repository: `Python/navio/adc.py`, `C++/Examples/ADC/ADC.cpp` — 2026-05-22

<!-- linted: 2026-05-23 -->
