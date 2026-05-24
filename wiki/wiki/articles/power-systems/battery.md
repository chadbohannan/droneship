# Battery — LiPo, Li-Ion, and LiHV

Lithium-based batteries dominate hobby drone power systems. Lithium polymer (LiPo) cells offer the best balance of energy density, discharge rate, and cost. Li-Ion cells provide higher energy density at lower discharge rates. LiHV cells are a LiPo variant rated for a higher maximum charge voltage.

## Cell Chemistry

| Chemistry | Nominal V | Charged V | Storage V | Cutoff V |
|-----------|-----------|-----------|-----------|---------|
| LiPo | 3.7 V | 4.2 V | 3.8 V | 3.5 V |
| Li-Ion | 3.6 V | 4.1–4.2 V | 3.8 V | 3.0 V |
| LiHV | 3.8 V | 4.35 V | 3.8 V | 3.5 V |

**LiPo**: Most common for FPV and multirotors. High discharge rates (20–100C), moderate energy density (~150–200 Wh/kg). Performance degrades faster than Li-Ion.

**Li-Ion**: Higher energy density (~200–250 Wh/kg), lower discharge rate (5–10C max), longer cycle life. Best for long-endurance low-current applications (fixed-wing, mapping drones).

**LiHV**: Same chemistry as LiPo but cells charge to 4.35 V/cell rather than 4.2 V. Extra ~3–5% energy per charge. Especially valuable for 1S builds (whoop, toothpick) where voltage headroom matters most. Performance degrades slightly faster than standard LiPo.

## Cell Configuration

Series cells increase voltage; parallel cells increase capacity. A "4S2P" pack has 4 cells in series (nominal 14.8 V) and each series position contains 2 cells in parallel (doubled capacity).

| Config | Nominal V | Typical use |
|--------|-----------|-------------|
| 2S | 7.4 V | Micro/toothpick, small FPV |
| 3S | 11.1 V | Mid-size FPV, trainer builds |
| 4S | 14.8 V | Most 5-inch FPV and medium multirotors |
| 5S | 18.5 V | High-performance 5-inch |
| 6S | 22.2 V | Large/heavy multirotors, long-range fixed-wing |

## C-Rating and Current

The C-rating expresses maximum discharge current as a multiple of capacity:

```
Maximum current (A) = Capacity (Ah) × C-rating
```

A 1500 mAh (1.5 Ah) pack with a 40C rating delivers up to 60 A continuous.

Published C-ratings are frequently inflated. A practical rule: budget for 20–25 A/cell as a safe continuous draw regardless of C-rating. Internal resistance is the real determinant of performance — lower resistance means less voltage sag under load and more usable capacity.

**Voltage sag**: Under high current, voltage drops proportionally to internal resistance. A pack that reads 16.8 V at rest but drops to 15.0 V at full throttle has significant sag. Sag increases as the pack ages.

## Charging

**Balance charging** (CC/CV with individual cell monitoring) is mandatory for LiPo. A dedicated balance charger monitors each cell via the balance connector and terminates at 4.20 V/cell (4.35 V for LiHV). Never charge without balance.

**Charge rate**: 1C is standard (1500 mAh at 1.5 A). Up to 2C is safe on quality packs with good cooling. Higher charge rates reduce cycle life and increase thermal risk.

**Storage charging**: Discharge or charge to 3.80 V/cell for storage longer than a few days. Full-charge storage (4.2 V) causes capacity loss of ~20% over 6 months and accelerates electrolyte degradation.

**Parallel charging**: Multiple packs can be charged simultaneously via a parallel board, but all packs in the parallel group must be within 0.1 V of each other before connecting. Never parallel charge packs of different cell counts.

## Safe Discharge Limits

Never discharge below 3.5 V/cell under load (3.0 V at rest absolute minimum). Operating below 3.5 V per cell causes irreversible capacity loss and can trigger internal lithium plating. Configure ArduPilot battery failsafe to RTL at ~3.5 V/cell and land at ~3.3 V/cell. See [Power Monitoring](../flight-controller-software/ardupilot/power-monitoring.md).

## Failure Modes and Safety

**Puffing (swelling)**: Gas generation from overcharging, overdischarging, internal short, or age. A swollen pack must not be charged or flown. Discharge fully in a fireproof container (salt water), then dispose.

**Thermal runaway**: Uncontrolled exothermic reaction triggered by physical damage, overcharge, or internal short. Can propagate between cells. Always charge in a LiPo-safe bag or metal container. Never leave charging batteries unattended.

**Storage**: Keep at storage voltage (3.8 V/cell) in a cool, dry location. Avoid temperatures above 45 °C. Long-term storage at full charge permanently reduces capacity.

**Physical damage**: Puncture from crash impact can cause immediate or delayed thermal runaway. Inspect all packs after hard crashes; if dented, torn, or swollen, dispose safely.

## Selecting a Battery

| Criterion | Guidance |
|-----------|---------|
| Voltage (cell count) | Match to motor KV and ESC voltage rating |
| Capacity (mAh) | Higher capacity = more flight time, more weight |
| C-rating | Ensure max current ≥ motor count × peak motor current |
| Weight | Evaluate Wh/kg; diminishing returns above ~200 Wh/kg |
| Connector | XT30 for <30 A, XT60 for <60 A, XT90 for larger currents |

## Related Concepts

- [ESC — Electronic Speed Controller](../propulsion/esc.md)
- [Power Monitoring](../flight-controller-software/ardupilot/power-monitoring.md)
- [Failsafes](../flight-controller-software/ardupilot/failsafes.md)

## Sources

- [LiPo Battery Guide — Oscar Liang](https://oscarliang.com/lipo-battery-guide/) — 2026-05-22
- [A Guide to Lithium Polymer Batteries — Tyto Robotics](https://www.tytorobotics.com/blogs/articles/a-guide-to-lithium-polymer-batteries-for-drones) — 2026-05-22
- [Understanding LiHV Batteries — Oscar Liang](https://oscarliang.com/lihv-battery/) — 2026-05-22

<!-- linted: 2026-05-23 -->
