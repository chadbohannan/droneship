# GPS and GNSS — ArduPilot

GPS is the primary absolute position source for ArduPilot. Without a valid GPS fix, most autonomous modes are unavailable and many pre-arm checks block arming. Understanding GPS protocols, multi-constellation configuration, dual GPS blending, and RTK setup determines the positioning accuracy and robustness of the build.

## Overview

ArduPilot supports GPS receivers communicating via UART (most common), I2C, or DroneCAN. It auto-detects u-blox binary (UBX), NMEA, SBF (Septentrio), and RTCM3 protocols. u-blox UBX receivers are the most widely used and best-supported option; NMEA receivers are compatible but offer less stable flight performance.

## Key Parameters

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `GPS_TYPE` | 1 | enum | First GPS type (0=disabled, 1=auto, 5=NMEA, 9=DroneCAN, 17=moving-baseline base) |
| `GPS_TYPE2` | 0 | enum | Second GPS type (18=moving-baseline rover for GPS yaw) |
| `GPS_AUTO_CONFIG` | 1 | enum | 0=manual, 1=auto-configure serial, 2=auto-configure DroneCAN |
| `GPS_HDOP_GOOD` | 140 | 1/100 HDOP | Maximum HDOP accepted as "good" (140 = HDOP 1.4); arm blocked above this |
| `GPS_SBAS_MODE` | 0 | enum | Satellite-based augmentation (WAAS/EGNOS/MSAS): 0=auto, 1=enabled, 2=disabled |
| `GPS_GNSS_MODE` | 0 | bitmask | GNSS constellations: bit 0=GPS, bit 1=SBAS, bit 2=Galileo, bit 3=BeiDou, bit 5=GLONASS |

After changing `GPS_TYPE`, reboot. `GPS_AUTO_CONFIG = 1` instructs ArduPilot to configure the u-blox receiver's update rate, constellations, and message output automatically at startup.

## Multi-Constellation GNSS

Modern u-blox M8/M9/M10 receivers support simultaneous reception from multiple GNSS constellations. Using GPS+GLONASS+Galileo (or adding BeiDou) increases satellite count, reduces HDOP, and improves fix reliability — especially in urban canyons or under partial sky obstruction. Configure via `GPS_GNSS_MODE` or let `GPS_AUTO_CONFIG` handle it.

## Dual GPS Blending

A second GPS receiver provides redundancy and can improve position estimate quality through blending. ArduPilot blends the two GPS position estimates using a time-constant filter.

| Parameter | Default | Unit | Description |
|-----------|---------|------|-------------|
| `GPS_BLEND_MASK` | 5 | bitmask | What to blend: bit 0=position, bit 1=altitude, bit 2=speed (7 = all) |
| `GPS_BLEND_TC` | 10.0 | s | Time constant for blending filter; higher = smoother transitions |

The blended result appears as a virtual third GPS instance. If one receiver fails or degrades, the blend automatically favours the better source.

## RTK GPS

Real-Time Kinematic GPS achieves centimetre-level accuracy by correcting satellite measurement errors using a stationary base station. ArduPilot supports RTK via external RTK receivers (Emlid Reach M+/M2, u-blox F9P, Here+ RTK) connected as a second GPS.

**Base station**: Static receiver at a known location transmits RTCM3 correction data via radio (SiK, RFD900) or GCS injection (Mission Planner GPS inject, Ctrl+F).

**Rover (on vehicle)**: Receives corrections and outputs a Fix (1–2 cm), Float (~30–50 cm), or Single (~2–4 m) solution.

For Emlid Reach M+/M2 integration, set `GPS_TYPE2 = 5` (NMEA), `SERIAL4_PROTOCOL = 5`, `SERIAL4_BAUD = 38`, `GPS_AUTO_SWITCH = 1`, and `GPS_INJECT_TO = 1`. See [RTK GPS](../../gnss/rtk-gps.md) for the full wiring and configuration procedure.

For dual u-blox F9P GPS-for-yaw setups (moving baseline), configure with `GPS_TYPE = 17` and `GPS_TYPE2 = 18` at 460800 baud. Requires HPG firmware ≥ 1.12.

## GPS for Yaw (Dual Antenna)

Two GPS antennas spaced apart provide a heading independent of the compass. This eliminates compass interference as a source of EKF yaw errors — valuable on large-current builds.

```
GPS_TYPE  = 17    (moving baseline base)
GPS_TYPE2 = 18    (moving baseline rover)
GPS_AUTO_CONFIG = 2   (DroneCAN) or 1 (serial)
EK3_SRC1_YAW = 3      (GPS with compass fallback)
```

Antenna separation of at least 30 cm improves heading accuracy. The antennas must be rigidly mounted and their relative position set in `GPS1_POS_X/Y/Z` and `GPS2_POS_X/Y/Z`.

## GPS Glitch Protection

ArduPilot monitors GPS innovations in EKF3 and discards GPS measurements that deviate excessively from the predicted position/velocity. During a glitch, the vehicle coasts on IMU integration. Sustained glitches trigger the EKF failsafe. Common causes: multipath from buildings, RF interference, GPS jamming.

Mitigations: position GPS antenna with clear sky view, use external active antenna on cable, enable SBAS, use dual GPS blending.

## Pre-Arm GPS Checks

| Message | Cause |
|---------|-------|
| GPS x: Bad fix | < 6 satellites or HDOP > `GPS_HDOP_GOOD` |
| High GPS HDOP | Horizontal dilution of precision too high |
| GPS positions differ by Xm | Dual GPS disagree by > 50 m |
| AHRS: waiting for home | No GPS fix yet |

Wait for 6+ satellites and HDOP < 2.0 before arming in GPS-requiring modes.

## DroneCAN GPS

Many modern GPS modules communicate over CAN bus (DroneCAN). Set `GPS_TYPE = 9` and configure the CAN bus. Auto-configuration handles message rate and constellation setup. See [CAN Bus and DroneCAN](can-dronecan.md).

## Related Concepts

- [RTK GPS](../../gnss/rtk-gps.md)
- [PPK — Post-Processed Kinematic](../../gnss/ppk.md)
- [Emlid Reach M+ and M2](../../gnss/reach-m.md)
- [EKF and Navigation](ekf-navigation.md)
- [Sensors](sensors.md)
- [CAN Bus and DroneCAN](can-dronecan.md)
- [Optical Flow and Non-GPS Navigation](optical-flow.md)
- [Failsafes](failsafes.md)
- [Arming and Pre-Flight Checks](arming-preflight.md)

## Sources

- [GPS for Yaw (Moving Baseline) — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-gps-for-yaw.html) — 2026-05-22
- [GPS Blending (Dual GPS) — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-gps-blending.html) — 2026-05-22
- [GPS Failsafe and Glitch Protection — ArduPilot Copter docs](https://ardupilot.org/copter/docs/gps-failsafe-glitch-protection.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
