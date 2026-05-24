# Emlid Reach M+ and M2

Compact UAV-grade GNSS modules from Emlid for RTK and PPK positioning on drones.

## Overview

The Reach M+ and Reach M2 are centimetre-accuracy GNSS receivers designed to mount directly on a drone airframe. Both share the same 35 g form factor, JST-GH connectors, and MCX antenna port. The key difference is frequency band: Reach M+ is single-band (L1), and Reach M2 is multi-band (L1/L2), giving M2 a longer baseline, faster ambiguity fix, and better performance under obstructed sky.

Both modules run ReachView — Emlid's browser-based configuration interface — and are compatible with ArduPilot, Pixhawk, and Navio2 autopilots via NMEA or the legacy ERB protocol.

## Reach M+ (Single-Band L1)

| Parameter | Value |
|-----------|-------|
| Constellations | GPS, GLONASS, Galileo, BeiDou, QZSS |
| Frequency | L1 |
| Supply voltage | 4.75–5.5 V |
| Normal current | 200 mA @ 5 V |
| Peak current | 500 mA @ 5 V |
| Logic level | 3.3 V (5 V tolerant) |
| Antenna connector | MCX |
| Connectors | 4× JST-GH |
| Weight | 35 g |
| Operating temperature | −20 to +65 °C |

## Reach M2 (Multi-Band L1/L2)

| Parameter | Value |
|-----------|-------|
| Constellations | GPS, GLONASS, Galileo, BeiDou, QZSS |
| Frequencies | L1, L2 |
| Supply voltage | 4.75–5.5 V |
| Average current | 200 mA @ 5 V |
| Peak current | 3 A @ 5 V |
| Logic level | 3.3 V (5 V tolerant) |
| Antenna connector | MCX |
| Connectors | 4× JST-GH |
| Weight | 35 g |
| Operating temperature | −20 to +65 °C |
| Antenna phase centers (L1/L2) | 0.035 m / 0.037 m |

The M2's 3 A peak draw exceeds what Navio2 UART and Pixhawk Serial 4/5 can supply. Power the M2 from an independent 5 V BEC and use the autopilot connection for data only.

## Baseline Comparison

The maximum usable baseline — distance between base and rover — depends on the receiver's frequency band.

| | Reach M+ (L1) | Reach M2 (L1/L2) |
|---|---|---|
| Max RTK baseline | 10 km (6 miles) | 60 km (36 miles) |
| Max PPK baseline | 30 km (18 miles) | 100 km (60 miles) |

Multi-band processing resolves ionospheric divergence over longer baselines and maintains Fix in obstructed environments (forests, urban canyons, quarries) where single-band receivers fall to Float or Single.

## Connectors and Interfaces

Both modules expose four JST-GH ports:

- **S1 (lower)**: UART — used for autopilot connection (correction input + position output)
- **S2 (upper)**: used for external LoRa radio connection
- **Micro-USB**: configuration and USB-OTG (host mode for LTE modem or USB radio); requires JST-GH 5 V power when in OTG mode
- **MCX antenna**: active GNSS antenna, 3.3 V bias, 100 mA max

UART logic is 3.3 V; pins are 5 V tolerant. The S1 UART device appears as `ttyMFD2` within ReachView for radio attachment.

## Connecting a Radio for Corrections

Connect a 3DR or RFD900 radio to S1 (UART) or via USB-OTG for receiving base corrections or transmitting the solution. Pin mapping for UART radio:

| Reach S1 pin | Radio pin |
|:---:|:---:|
| +5 V | +5 V |
| TX | RX |
| RX | TX |
| GND | GND |

The RFD900 can draw up to 800 mA peak — verify your 5 V supply can support both Reach and the radio simultaneously.

Connect a LoRa radio to S2. LoRa operates one-way: a module set to transmit sends corrections; a module set to receive accepts them. Base and rover LoRa air rates must match. Line-of-sight range reaches up to 19 km at 20 dBm output power.

## Antenna Placement

Mount the GNSS antenna flat, sky-facing, at the highest point of the airframe. Maintain an unobstructed view above 30° elevation. Keep at least 10 cm from 5.8 GHz video transmitters, power distribution wiring, and motor ESCs. A carbon-fibre plate attenuates L-band signals significantly — use a non-conductive standoff or a 70 × 70 mm aluminium ground plane if the antenna must sit near carbon.

## Related Concepts

- [RTK GPS](rtk-gps.md)
- [PPK — Post-Processed Kinematic](ppk.md)
- [Navio2 GNSS Receiver](../flight-controller-hardware/navio2/gnss.md)

## Sources

- [Emlid Documentation](https://docs.emlid.com/) — Reach M+ and M2 specs, hardware integration — 2026-05-22

<!-- linted: 2026-05-23 -->
