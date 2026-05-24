# Navio2 GNSS Receiver

Onboard u-blox NEO-M8N multi-constellation Global Navigation Satellite System (GNSS) receiver for position, velocity, and time.

## Overview

Navio2 integrates a u-blox NEO-M8N GNSS receiver connected to the Raspberry Pi over SPI. The NEO-M8N tracks up to four constellations simultaneously — GPS (L1 C/A), GLONASS (L1 OF), BeiDou (B1), and Galileo (E1) — along with SBAS (Satellite-Based Augmentation System) corrections from WAAS (North America), EGNOS (Europe), MSAS (Japan), and GAGAN (India). Multi-constellation tracking increases visible satellite count, shortens Time to First Fix (TTFF), and reduces position error during partial sky obstructions such as tree lines or urban canyons. The NEO-M8N tracks up to three constellations simultaneously (not all four at once) — a typical combination is GPS + GLONASS + either BeiDou or Galileo. ArduPilot does not configure the constellation set directly; this is managed by the u-blox firmware using its default concurrent-constellation policy.

An MCX antenna connector on the top of the board accepts the included ceramic patch antenna. The receiver outputs standard NMEA (National Marine Electronics Association) 0183 sentences and u-blox UBX binary messages; ArduPilot uses UBX by default for richer data (velocity accuracy, satellite health flags, RTK status).

## Specifications

| Parameter | Value |
|-----------|-------|
| Chip | u-blox NEO-M8N |
| Constellations | GPS L1, GLONASS L1, BeiDou B1, Galileo E1, SBAS |
| Max simultaneous constellations | 3 (configurable) |
| Position accuracy (autonomous) | 2.5 m CEP (Circular Error Probable — radius within which 50% of fixes fall) |
| Position accuracy (SBAS) | ~1.0 m CEP |
| Velocity accuracy | 0.05 m/s |
| Update rate | Up to 10 Hz (default 5 Hz in ArduPilot) |
| TTFF (cold start) | 26 s typical |
| TTFF (hot start) | 1 s typical |
| Interface | SPI (shared bus, chip select dedicated) |
| Antenna connector | MCX |
| Operating voltage | 3.3 V (via Navio2 regulator) |

## ArduPilot GPS Parameters

ArduPilot must know which serial or SPI device hosts the GPS. On Navio2, the receiver is accessed as a virtual serial port provided by the kernel driver.

| Parameter | Value | Notes |
|-----------|-------|-------|
| GPS_TYPE | 2 | u-blox auto-detect |
| SERIAL3_BAUD | 38400 | Default for GPS port (-B flag) |
| GPS_NAVFILTER | 8 | Airborne <4g model (recommended for copters) |
| GPS_MIN_ELEV | 10 | Reject satellites below 10° elevation |
| GPS_HDOP_GOOD | 140 | HDOP threshold for "good" GPS lock indication |
| GPS_INJECT_TO | 0 | Serial port index to forward RTCM (real-time correction messages) to rover (0 = Serial 4) |

Set GPS_NAVFILTER to 8 (Airborne <4g) for copters. The pedestrian and automotive dynamic models apply excessive velocity smoothing that causes lag at drone speeds.

## Antenna Placement

Mount the patch antenna flat, sky-facing, on the highest point of the airframe. Keep at least 10 cm clearance from video transmitters (5.8 GHz VTX in particular) and power distribution wiring. A carbon fiber top plate attenuates L1 signals significantly — use a non-conductive mount or a ground plane extension plate if the antenna must sit below carbon fiber.

## SBAS Configuration

SBAS correction is enabled by default in u-blox firmware and requires no ArduPilot parameter changes. Accuracy improvement from ~2.5 m to ~1 m is automatic when an SBAS satellite is in view. WAAS covers North America; EGNOS covers Europe; MSAS covers Japan.

## External GPS Module and Dual GPS

Navio2's onboard GPS receiver is suitable for general flight. For redundancy or a better-positioned compass, add a second GPS/compass module via the UART header (exposed on the DF13 connector, mapped to ArduPilot's `-E` / Serial 4 port).

| Parameter | Value | Notes |
|-----------|-------|-------|
| GPS_TYPE | 2 | Onboard NEO-M8N (u-blox auto-detect) |
| GPS_TYPE2 | 2 | External u-blox module on Serial 4 |
| GPS_AUTO_SWITCH | 1 or 2 | 1 = UseBest (lowest HDOP); 2 = Blend (weighted average) |
| SERIAL4_PROTOCOL | 5 | Assign Serial 4 to GPS |
| SERIAL4_BAUD | 38400 | Match GPS module baud rate |

GPS blending (`GPS_AUTO_SWITCH = 2`) works reliably only when both receivers are the same brand and report position accuracy in compatible units. Both u-blox modules meet this requirement. In dataflash logs, instance 0 is the primary, instance 1 is the secondary, and instance 2 is the blended result (GPS and GPA message types).

External modules such as the Here3 (CAN) or u-blox M9N (UART) also provide an external magnetometer, which should be set as Compass #1 in Mission Planner. The external compass sits farther from motor and ESC current noise than the onboard LSM9DS1.

## U-center Configuration

U-center is u-blox's free Windows GUI for receiver configuration, signal visualization, and firmware updates. Connect it to the Navio2's onboard receiver over TCP using the `ublox-spi-to-tcp` bridge utility included in the Navio2 repository:

```bash
# On Raspberry Pi
cd Navio2/Utilities/ublox-spi-to-tcp
make
./ublox-spi-to-tcp 5000   # opens TCP port 5000 and waits for connection
```

In U-center, navigate to Receiver → Port → Network connection → New, then enter the Raspberry Pi's IP address and port (e.g., `192.168.1.3:5000`). UBX messages appear in the packet console. Use U-center to verify constellation enable/disable settings, check fix quality, enable SBAS, or update u-blox firmware.

## RTK GPS

The onboard NEO-M8N does **not** support RTK — that requires an F9P-class receiver (e.g., Emlid Reach M+, Here+ RTK, SparkFun ZED-F9P). To achieve centimetre-level positioning with Navio2, replace or supplement the onboard GPS with an external RTK receiver connected via UART:

1. Connect the RTK rover to the Navio2 UART header (Serial 4).
2. Set `GPS_TYPE2 = 2` (or the appropriate type for the rover module).
3. A base station (e.g., Emlid Reach RS2) streams RTCM3 correction data to the flight controller via a telemetry radio or over WiFi using MAVProxy's `--inject-rtcm` option.
4. ArduPilot forwards RTCM data to the rover over Serial 4 via the `GPS_INJECT_TO` parameter.

RTK fix provides 1–2 cm horizontal accuracy when the baseline between rover and base is under 10 km. Float fix provides ~30–50 cm accuracy. See [RTK GPS](../../gnss/rtk-gps.md) for the full wiring and parameter reference.

## Related Concepts

- [Navio2](navio2.md)
- [RTK GPS](../../gnss/rtk-gps.md)
- [Emlid Reach M+ and M2](../../gnss/reach-m.md)
- [GPS/GNSS — ArduPilot](../../flight-controller-software/ardupilot/gps-gnss.md)
- [EKF & Navigation](../../flight-controller-software/ardupilot/ekf-navigation.md)
- [Navio2 ArduPilot Configuration](ardupilot-configuration.md)

## Sources

- [GPS — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/gps-ublox/) — 2026-05-22
- [NAVIO2 Overview — ArduPilot](https://ardupilot.org/copter/docs/common-navio2-overview.html) — 2026-05-22
- [GPS Blending — ArduPilot docs](https://ardupilot.org/copter/docs/common-gps-blending.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
