# CAN Bus and DroneCAN — ArduPilot

DroneCAN (formerly UAVCAN v0) is the preferred protocol for CAN-connected peripherals in ArduPilot. It carries GPS position, compass, barometric pressure, ESC commands and telemetry, power monitor data, and safety switch signals over a shared 2-wire bus at 1 Mbit/s.

## Overview

CAN bus reduces the number of dedicated peripheral cables, improves noise immunity over long harness runs, and enables daisy-chained device topologies. DroneCAN provides device discovery via node ID allocation, allowing the autopilot to identify and configure connected hardware automatically.

## Wiring

CAN bus uses two wires (CAN H and CAN L) plus ground. Topology is a single bus with **exactly two 120 Ω termination resistors**, one at each physical end.

- Most Pixhawk-family flight controllers have a built-in termination resistor (enabled by jumper or always-on).
- The last device on the bus at the far end must have a 120 Ω resistor across CAN H and CAN L.
- Daisy-chain devices: FC → device 1 → device 2 → terminator.
- Do not use a star topology.
- Maximum bus length: ~40 m at 1 Mbit/s with appropriate cable (twisted pair recommended).

Cable colour convention: CAN H = yellow, CAN L = green, GND = black. JST-GH 4-pin connectors are the standard on modern hardware.

## Configuration

| Parameter | Value | Description |
|-----------|-------|-------------|
| `CAN_P1_DRIVER` | 1 | Assign CAN port 1 to driver 1 |
| `CAN_D1_PROTOCOL` | 1 | Protocol on driver 1 (1=DroneCAN) |
| `CAN_D1_UC_NODE` | 10 | Autopilot node ID (default auto-assigned) |
| `CAN_D1_UC_OPTION` | 0 | Options bitmask (bit 2 = enable CANFD) |

Reboot after changing `CAN_P*_DRIVER` or `CAN_D*_PROTOCOL`.

## Node ID Assignment

DroneCAN supports dynamic node ID allocation — the autopilot assigns unique IDs to new devices automatically. No manual configuration is needed for most devices. If two devices end up with the same ID, set `CAN_D1_UC_OPTION` bit 0 to force re-allocation.

## GPS via DroneCAN

```
GPS_TYPE = 9    (DroneCAN)
```

ArduPilot automatically configures DroneCAN GPS modules (Here3, Here3+, ARK GPS, Holybro DroneCAN GPS). No additional parameters required beyond `GPS_TYPE`.

## ESC via DroneCAN

```
CAN_D1_UC_ESC_BM = 15    (motors 1-4 for a quadcopter)
```

`CAN_D1_UC_ESC_BM` is a bitmask of motor outputs to control via DroneCAN. Motors not in this mask use conventional PWM/DShot outputs.

For reversible motors: `CAN_D1_UC_ESC_RV` bitmask enables bi-directional control on specified motors.

Supported DroneCAN ESCs: Holybro Kotleta20 (Sapog firmware), T-Motor, Flame, Hargrave. ESC telemetry (RPM, current, temperature) is automatically available when using DroneCAN.

## Power Monitor via DroneCAN

```
BATT_MONITOR = 8    (DroneCAN battery info)
```

CUAV CAN PMU, Pomegranate Systems, and other DroneCAN power monitors publish voltage and current data that ArduPilot reads directly without analog sensor calibration. See [Power Monitoring](power-monitoring.md).

## DroneCAN Inspector (Mission Planner)

In Mission Planner: CTRL+F → SLCAN → opens the DroneCAN Inspector. The inspector shows:
- All discovered nodes with their hardware IDs and firmware versions
- Real-time DroneCAN message traffic
- Node health and operating mode
- Ability to configure per-node parameters (e.g., ESC node IDs, compass orientation)

## Typical Devices

| Device | Type | Notes |
|--------|------|-------|
| Here3 / Here3+ | GPS + compass + barometer | Common multi-function CAN peripheral |
| ARK GPS | GPS + compass | Open source |
| Zubax GNSS 2 | GPS + compass + barometer | High performance |
| Holybro Kotleta20 | 40 A ESC | Sapog firmware |
| Cube ID | Remote ID | OpenDroneID via CAN |
| CUAV CAN PMU | Power monitor | Voltage + current |

## Related Concepts

- [GPS and GNSS](gps-gnss.md)
- [Sensors](sensors.md)
- [Motor Mixing and Output](motor-mixing.md)
- [Power Monitoring](power-monitoring.md)
- [Hardware](hardware.md)

## Sources

- [CAN Bus Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-canbus-setup-advanced.html) — 2026-05-22
- [DroneCAN Setup — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-uavcan-setup-advanced.html) — 2026-05-22
- [DroneCAN ESCs — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-uavcan-escs.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
