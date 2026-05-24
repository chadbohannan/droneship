# RTK GPS

Centimetre-level positioning using a base station and rover GNSS receiver pair, with corrections delivered in real time.

## Overview

A standard GNSS receiver — the type found in a smartphone or the u-blox NEO-M8N on the Navio2 — achieves 2–4 m (Circular Error Probable) accuracy. Signals travel through the ionosphere and atmosphere, accumulating unpredictable delays that single-receiver firmware cannot fully compensate.

Real-Time Kinematic (RTK) overcomes this by pairing a **base station** (static, at a known location) with a **rover** (mounted on the drone). The base continuously transmits correction data to the rover in RTCM3 format, allowing the rover to cancel out the shared atmospheric and satellite-clock errors. A correctly initialised RTK solution — called a **Fix** — achieves 1–2 cm horizontal accuracy.

RTK is the foundation of precision drone applications: photogrammetric surveying, precision agriculture, and infrastructure inspection.

## Solution Statuses

| Status | Accuracy | Description |
|--------|----------|-------------|
| Fix | 1–2 cm | Integer carrier-phase ambiguities fully resolved (AR ratio > 3) |
| Float | ~30–50 cm | Base corrections applied but ambiguities not resolved |
| Single | 2–4 m | No base corrections; standalone GNSS only |

ArduPilot logs solution status in the GPS message field `Status`. Use Float as a fallback only; never as a precision reference.

**AR ratio** is the ratio of the best ambiguity solution to the second-best. Emlid Reach devices declare Fix when AR ratio > 3.

**Age of differential** is the elapsed time since the last correction message was received. Normal RTK operation maintains an age of 1–2 s; values above 5 s degrade solution quality.

## Single-Band vs Multi-Band

| | Single-band (L1 only) | Multi-band (L1/L2+) |
|---|---|---|
| Example | Reach M+ | Reach M2 |
| Max RTK baseline | 10 km (6 miles) | 60 km (36 miles) |
| Challenging sky view | Reduced reliability | Maintained reliability |

Multi-band receivers resolve ambiguities faster and maintain Fix longer in urban canyons, forests, and other partially obstructed environments. See [Emlid Reach M+ and M2](reach-m.md) for hardware specifications.

## Base Station Options

### Local Base

Mount a dedicated base receiver on a tripod at a known point and configure it to transmit RTCM3 corrections over TCP, serial radio, or LoRa. A local base operates without internet and is the preferred option in remote areas.

Base position accuracy directly sets rover absolute accuracy. An averaged Single base coordinate introduces a constant offset equal to its own position error (typically 1–3 m). For absolute accuracy, survey the base over a known benchmark or use NTRIP to establish an accurate base position before the flight.

### NTRIP

Networked Transport of RTCM via Internet Protocol (NTRIP) lets the rover receive corrections from a national reference-station network over 3G/LTE — no second receiver needed. Requires reliable cellular coverage at the flight site.

## ArduPilot Integration

Reach M+/M2 connects to an autopilot as a **second GPS** alongside the primary onboard receiver. ArduPilot selects the source with the better solution automatically.

ReachView 0.3.0 introduced the ERB (Emlid Reach Binary) protocol. ERB is now deprecated — configure Reach to output NMEA.

Minimum ArduPilot versions for RTK support: ArduCopter ≥ 3.4, ArduPlane ≥ 3.5.0, APMrover ≥ 3.1.

### Physical Connection

**Navio2 via UART** — connect Reach S1 (lower JST-GH) to Navio2's UART header. For the M2, supply power from an independent 5 V BEC — the Navio2 UART cannot source the M2's 3 A peak draw.

**Navio2 via USB** — connect Reach Micro-USB to a Raspberry Pi USB port; ArduPilot addresses it as `/dev/ttyACM0`.

**Pixhawk via Serial 4/5** — connect Reach S1 to Pixhawk Serial 4/5 using the 6P-to-6P cable. This single connection handles power (for M+), correction data in, and RTK solution out.

### Reach Configuration

**Correction input** — Reach receives RTCM3 from the autopilot:

1. ReachView → Correction input → Serial
2. Device: UART (or USB-to-PC); baud rate: 38400; format: RTCM3
3. Apply

**Position output** — Reach sends NMEA to the autopilot:

1. ReachView → Position output → Serial
2. Device: UART (or USB-to-PC); baud rate: 38400; format: NMEA
3. Apply

### ArduPilot Parameters

For Navio2 UART, add `-E /dev/ttyAMA0` to the ArduPilot start command (USB: `-E /dev/ttyACM0`).

| Parameter | Value | Notes |
|-----------|-------|-------|
| GPS_TYPE2 | 5 | NMEA — enables second GPS input |
| SERIAL4_BAUD | 38 | 38400 baud (ArduPilot encoded scale) |
| SERIAL4_PROTOCOL | 5 | GPS protocol on Serial 4 |
| GPS_AUTO_SWITCH | 1 | UseBest: auto-select lower-HDOP receiver |
| GPS_INJECT_TO | 1 | Forward RTCM corrections to second GPS port |

Set `GPS_AUTO_SWITCH = 1` (UseBest), not 2 (Blend), when mixing an RTK receiver with a standard receiver — blending a Fix and a Single solution degrades the Fix. If Reach is the first GPS input, set `GPS_INJECT_TO = 0`.

If the GCS reports **Bad GPS Signal Health**, confirm that the Reach GNSS update rate is ≥ 5 Hz in ReachView RTK settings.

### Injecting Corrections via Telemetry Radio

The existing telemetry radio can carry RTCM corrections embedded in the MAVLink stream, avoiding a separate correction radio. In Mission Planner, press Ctrl+F → Inject GPS, then connect to the base Reach TCP server (default port 9000).

Before enabling GPS inject, open the SiK radio settings, clear **ECC**, and set Mavlink to **Raw Data**. Default ECC settings introduce latency and packet loss that degrade RTK initialisation.

## Base Configuration (Reach RS2 Example)

In Reach Panel → Base mode:

- Correction output: TCP → Server → port 9000
- RTCM3 messages for a Reach rover:

| Message | Rate | Description |
|---------|------|-------------|
| 1006 | 0.1 Hz | ARP station coordinates (mandatory) |
| 1074 | 1 Hz | GPS MSM4 (mandatory) |
| 1084 | 1 Hz | GLONASS MSM4 |
| 1094 | 1 Hz | Galileo MSM4 |
| 1124 | 1 Hz | BeiDou MSM4 |

Set the base RTK update rate to 1 Hz before enabling correction messages.

- Base position: Averaged Single (relative accuracy) or Manual (absolute accuracy)

## Antenna Placement

See [Emlid Reach M+ and M2 — Antenna Placement](reach-m.md#antenna-placement) for rover antenna guidelines. Apply the same 30° unobstructed sky view and 70 × 70 mm ground plane requirements to the base antenna.

## Related Concepts

- [PPK — Post-Processed Kinematic](ppk.md)
- [Emlid Reach M+ and M2](reach-m.md)
- [Navio2 GNSS Receiver](../flight-controller-hardware/navio2/gnss.md)
- [GPS/GNSS — ArduPilot](../flight-controller-software/ardupilot/gps-gnss.md)
- [EKF & Navigation](../flight-controller-software/ardupilot/ekf-navigation.md)

## Sources

- [Emlid Documentation](https://docs.emlid.com/) — RTK introduction, ArduPilot integration, RS2 base mode — 2026-05-22

<!-- linted: 2026-05-23 -->
