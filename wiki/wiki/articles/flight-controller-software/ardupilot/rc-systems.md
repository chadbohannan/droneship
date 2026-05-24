# RC Systems and RCMAP — ArduPilot

RC (radio control) input provides the pilot's primary control interface. ArduPilot supports multiple RC protocols, configurable channel mapping, and a rich set of auxiliary channel functions for arming, mode switching, and peripheral control.

## Supported Protocols

| Protocol | Type | Connection | Notes |
|----------|------|------------|-------|
| PWM | Analog pulse | Individual pin per channel | Legacy; one wire per channel |
| PPM | Analog pulse | Single wire | Multiple channels multiplexed |
| SBUS | Digital serial | UART RX (inverted) | Futaba standard; requires inversion on F4 boards |
| IBUS | Digital serial | UART RX | FlySky protocol |
| CRSF | Digital serial | Full UART (TX+RX) | TBS Crossfire; bidirectional telemetry |
| ELRS | Digital serial | Full UART (TX+RX) | ExpressLRS; high refresh rate; CRSF compatible |
| DSM/Spektrum | Digital serial | UART | Spektrum 1024/2048 |
| SRXL2 | Digital serial | UART (TX+RX) | All Spektrum receivers since August 2019 |

ArduPilot auto-detects the protocol. CRSF, ELRS, and SRXL2 require both TX and RX pins connected. SBUS requires an inverter on F4-based flight controllers; F7/H7 boards support SBUS natively.

## Channel Mapping (RCMAP)

Default channel assignments follow Mode 2 convention:

| Channel | Default function | `RCMAP_*` parameter |
|---------|-----------------|---------------------|
| 1 | Roll | `RCMAP_ROLL` |
| 2 | Pitch | `RCMAP_PITCH` |
| 3 | Throttle | `RCMAP_THROTTLE` |
| 4 | Yaw | `RCMAP_YAW` |

Change by setting the corresponding `RCMAP_*` parameter to the desired channel number. Reboot after changing RCMAP parameters.

Per-channel parameters configure range and trim: `RCn_MIN`, `RCn_MAX`, `RCn_TRIM`, `RCn_REVERSED` (set to 1 to reverse direction without changing transmitter).

## RC Calibration

Run from GCS (Setup → Mandatory Hardware → Radio Calibration). Move all sticks and switches to their extremes. ArduPilot records the PWM range for each channel. After calibration, center sticks to set `RCn_TRIM`.

Pre-arm check: `RC not calibrated` appears if no calibration has been stored. `RC channels not neutral` appears if pitch/roll/yaw sticks are not centered at arm time.

## Auxiliary Channel Functions (RCx_OPTION)

Channels 5 and above can be assigned functions via `RCx_OPTION`. The function activates when the channel PWM exceeds 1800 µs (approximately switch high).

| Value | Function |
|-------|---------|
| 7 | Save waypoint |
| 9 | Camera trigger |
| 14 | Acro trainer / automode |
| 17 | AutoTune start/stop |
| 28 | Relay 1 toggle |
| 31 | Motor emergency stop (does NOT disarm) |
| 81 | Disarm |
| 90 | EKF (Extended Kalman Filter) position source select (GPS↔optical flow) |
| 153 | Arm/Disarm |
| 154 | Arm/Disarm toggle |
| 160 | Arm/Disarm (alternate) |
| 166 | Turtle mode (inverted recovery) |
| 300–307 | Lua scripting channel 1–8 |

ArduPilot defines over 300 auxiliary functions. See the full list in the ArduPilot parameters documentation.

## RSSI Monitoring

Received signal strength indicator from the receiver:

| `RSSI_TYPE` | Source |
|-------------|--------|
| 0 | Disabled |
| 1 | Analog voltage on dedicated pin |
| 2 | RC channel (set `RSSI_CHANNEL` to channel carrying RSSI) |
| 3 | PWM encoded in receiver stream |
| 5 | CRSF/ELRS link quality (LQ, not raw RSSI) |

For CRSF/ELRS, set `RSSI_TYPE = 5`. The GCS HUD displays RSSI as a percentage.

## CRSF and ELRS MAVLink Passthrough

ExpressLRS and TBS Crossfire support bidirectional MAVLink telemetry over the same RF link as RC control — no separate telemetry radio needed.

Configure on the flight controller:
```
SERIALx_PROTOCOL = 2     (MAVLink 2)
SERIALx_BAUD     = 460   (460800 for ELRS, 416000 for CRSF)
RSSI_TYPE        = 5
```

Enable MAVLink forwarding in the transmitter module (ExpressLRS Configurator or Crossfire configurator). Mission Planner connects via the transmitter's USB port as a MAVLink device.

## RC Feel

`RC_FEEL_RP` (0–100) smooths pilot stick input:

| Value | Feel |
|-------|------|
| 0 | Very soft |
| 25 | Soft |
| 50 | Medium (default) |
| 75 | Crisp |
| 100 | Very crisp |

Higher values give more immediate response but can feel jerky at low speeds.

## Radio Failsafe

Radio failsafe triggers when RC signal is lost. See [Failsafes](failsafes.md) for full configuration. Key parameters: `FS_THR_ENABLE`, `FS_THR_VALUE`, `RC_FS_TIMEOUT`.

## Related Concepts

- [Failsafes](failsafes.md)
- [Flight Modes](flight-modes.md)
- [Arming and Pre-Flight Checks](arming-preflight.md)
- [Telemetry Radios](telemetry-radios.md)
- [MAVLink Protocol](mavlink.md)

## Sources

- [Radio Control Systems — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-rc-systems.html) — 2026-05-22
- [Auxiliary Functions — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-auxiliary-functions.html) — 2026-05-22
- [Crossfire and ELRS RC Systems — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-tbs-rc.html) — 2026-05-22
- [RSSI — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-rssi-received-signal-strength-indication.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
