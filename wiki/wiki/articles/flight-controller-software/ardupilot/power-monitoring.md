# Power Monitoring — ArduPilot

ArduPilot's battery monitor system measures pack voltage and current draw, tracks consumed capacity, triggers failsafes at configurable thresholds, and displays state on the GCS HUD. Accurate power monitoring is prerequisite to reliable battery failsafe operation.

## Overview

Power monitoring hardware (a power module or standalone sensor) converts the battery voltage and current sense signal to an analog or digital value read by the flight controller. ArduPilot multiplies the raw ADC reading by calibration coefficients to produce voltage and current in physical units, then integrates current over time to track consumed capacity.

## BATT_MONITOR Types

| Value | Type | Notes |
|-------|------|-------|
| 0 | Disabled | |
| 3 | Analog voltage only | No current sensing |
| 4 | Analog voltage + current | Most common (Pixhawk power module) |
| 5 | Solo | 3DR Solo specific |
| 7 | SMBus-Maxell | Smart battery via SMBus |
| 8 | DroneCAN battery info | CAN-connected power monitors |
| 9 | BLHeli ESC telemetry | Current from ESC telemetry stream |
| 10 | Sum of following monitors | Aggregate multiple BATT instances |
| 13/14 | SMBUS-SUI3/SUI6 | Smart batteries |

Set `BATT_MONITOR = 4` for a standard analog power module. Reboot after changing.

## Calibration

### Voltage Calibration

`BATT_VOLT_MULT` converts the ADC voltage reading to battery voltage. The value is hardware-specific and usually provided by the power module manufacturer (e.g., 10.1 for the 3DR/Pixhawk power module). To calibrate manually:

1. Connect a known-accurate voltmeter to the battery.
2. Measure the raw voltage reported in Mission Planner (Setup → Optional Hardware → Battery Monitor).
3. `BATT_VOLT_MULT = (actual_voltage) / (reported_voltage)`.

### Current Calibration

`BATT_AMP_PERVLT` converts the current sense pin voltage to amperes. The manufacturer typically specifies this value (e.g., 17.0 A/V for the 3DR 90A module).

To calibrate with an ammeter:
1. Run motors at a known steady throttle.
2. Measure actual current with an inline ammeter.
3. `BATT_AMP_PERVLT = (actual_current) / (reported_current) × current_BATT_AMP_PERVLT`.

`BATT_AMP_OFFSET` corrects zero-current offset (the voltage output from the current sensor at zero amps). Measure the current sense pin voltage with motors off and no load.

### Capacity Tracking

`BATT_CAPACITY` sets the total pack capacity in mAh. ArduPilot integrates measured current over time to track `mAh_consumed`. The GCS displays remaining percentage as `(BATT_CAPACITY - mAh_consumed) / BATT_CAPACITY × 100`.

## Multiple Batteries

Up to 16 battery monitors are supported with parameter groups `BATT_`, `BATT2_`, `BATT3_`, ... `BATT9_`, `BATTA_`, ... `BATTF_`. Configure each independently with its own `MONITOR`, `VOLT_MULT`, `AMP_PERVLT`, and `CAPACITY` parameters.

`BATT_MONITOR = 10` (Sum) creates a virtual monitor aggregating voltage (averaged) and current (summed) from a specified set of monitors via `BATT_SUM_MASK`.

## Failsafe Thresholds

See [Failsafes](failsafes.md) for the full battery failsafe section. Quick reference:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `BATT_LOW_VOLT` | 10.5 V | Low voltage threshold |
| `BATT_LOW_MAH` | 0 mAh | Low remaining capacity threshold (0=disabled) |
| `BATT_FS_LOW_ACT` | 2 | Action at low threshold (2=RTL) |
| `BATT_CRT_VOLT` | 0 V | Critical voltage threshold (0=disabled) |
| `BATT_FS_CRT_ACT` | 1 | Action at critical threshold (1=Land) |
| `BATT_ARM_VOLT` | 0 V | Minimum voltage to allow arming |

## Power Module Hardware

| Module | Max voltage | Max current | Interface |
|--------|-------------|-------------|-----------|
| 3DR/Pixhawk standard | 18 V (4S) | 90 A | Analog |
| AttoPilot 180 A | 50 V (12S) | 180 A | Analog |
| Matek HUBOSD | 6S | 130 A | Analog |
| INA226 / INA219 | configurable | configurable | I2C |
| CUAV CAN PMU | 6S | 60 A | DroneCAN |
| SMBus smart battery | varies | varies | SMBus |

Use AttoPilot or equivalent for batteries above 4S (> 18 V) — the standard Pixhawk power module is rated for 4S maximum.

## GCS Display

Mission Planner displays voltage, current, and remaining capacity on the HUD in real time. The battery icon turns yellow at `BATT_LOW_VOLT` and red at `BATT_CRT_VOLT`. Consumed mAh appears in the extended status window.

MAVProxy: `status` command shows battery state; `graph BAT.Volt BAT.Curr` plots voltage and current from log.

## Related Concepts

- [Failsafes](failsafes.md)
- [Battery](../../power-systems/battery.md)
- [CAN Bus and DroneCAN](can-dronecan.md)
- [Logging and Analysis](logging.md)
- [First Flight Setup](first-flight.md)

## Sources

- [Power Module Configuration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-power-module-configuration-in-mission-planner.html) — 2026-05-22
- [Battery Monitors Overview — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-powermodule-landingpage.html) — 2026-05-22
- [Analog Current Calibration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-analog-current-calibration.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
