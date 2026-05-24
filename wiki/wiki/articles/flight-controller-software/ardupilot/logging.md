# Logging and Analysis — ArduPilot

ArduPilot's dataflash logging system records flight data to an SD card in binary `.bin` format at rates up to 400 Hz. Logs are the primary diagnostic tool: every tuning iteration, failsafe event, EKF health check, and vibration measurement should be reviewed in logs before drawing conclusions.

## Overview

Logs are written to the `LOGS/` directory on the SD card. Each arm/disarm cycle creates a new numbered file (e.g., `00000001.BIN`). Files can be retrieved by removing the SD card, downloading via Mission Planner over USB/telemetry, or streamed in real time via MAVLink.

Every log contains a `FMT` header block defining the schema for all message types in that file — analysis tools read this to decode the binary format, so logs are self-describing.

## Configuration

### LOG_BITMASK

`LOG_BITMASK` controls which message categories are enabled. Set to `65535` to enable all. Selective logging reduces file size and SD card wear on long flights.

| Bit | Value | Category |
|-----|-------|----------|
| 0 | 1 | Fast attitude (ATT at 10 Hz) |
| 1 | 2 | Medium attitude (50 Hz) |
| 2 | 4 | GPS |
| 3 | 8 | System performance (PM) |
| 4 | 16 | Control tuning (CTUN) |
| 5 | 32 | Navigation tuning (NTUN) |
| 6 | 64 | RC input (RCIN) |
| 7 | 128 | IMU |
| 8 | 256 | Mission commands |
| 9 | 512 | Battery monitor (BAT) |
| 10 | 1024 | RC output (RCOU) |
| 11 | 2048 | Optical flow |
| 12 | 4096 | PID error terms |
| 13 | 8192 | Compass |
| 17 | 131072 | Motors |
| 18 | 262144 | Fast IMU (raw batch sampler) |
| 21 | 2097152 | Fast harmonic notch FFT data |

For post-flight PID tuning review, enable bits 0, 4, 7, 9, 10 at minimum. For vibration analysis, add bit 18. For EKF diagnostics, enable bit 5.

### Other Logging Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `LOG_DISARMED` | 0 | 0=log when armed only, 1=always, 2=not on USB power, 3=erase logs where vehicle never armed |
| `LOG_BACKEND_TYPE` | 1 | 1=SD card, 2=dataflash chip, 4=MAVLink stream |
| `LOG_FILE_RATEMAX` | 0 | Cap logging rate (Hz) to limit file size; 0=unlimited |
| `INS_LOG_BAT_MASK` | 0 | Enable IMU batch sampler for FFT vibration analysis; set to 1 |

Set `LOG_DISARMED = 1` temporarily when diagnosing pre-arm failures — it captures sensor data and EKF initialisation before arming, which is otherwise unavailable.

## Downloading Logs

**SD card (fastest):** Power off, remove the SD card, copy `APM/LOGS/*.BIN` directly.

**Mission Planner over USB:**
1. Connect via USB. Go to **Flight Data → DataFlash Logs**.
2. Click **Download DataFlash Log Via Mavlink**.
3. Logs save to `MissionPlanner/logs/[VEHICLE_TYPE]/`.

**MAVProxy:**
```
log list              # list available logs
log download 1        # download log number 1
log download latest   # download most recent
```

## Key Log Messages

### Attitude and Control

| Message | Key Fields | Use |
|---------|-----------|-----|
| `ATT` | `DesRoll`, `Roll`, `DesPitch`, `Pitch`, `DesYaw`, `Yaw` | Tracking quality; compare desired vs actual |
| `RATE` | `RDes`, `R`, `PDes`, `P`, `YDes`, `Y`, `ROut`, `POut`, `YOut` | Rate controller error and output |
| `CTUN` | `ThO`, `ThH`, `Alt`, `BarAlt`, `DCRt` | Throttle output, hover throttle, altitude tracking |
| `RCIN` | `C1`–`C14` | Raw RC input PWM per channel |
| `RCOU` | `C1`–`C14` | Motor/servo output PWM |

### Navigation and Position

| Message | Key Fields | Use |
|---------|-----------|-----|
| `GPS` | `Lat`, `Lng`, `Alt`, `Spd`, `HDOP`, `NSats` | GPS quality and fix |
| `NTUN` | `WpDist`, `DesVelX/Y`, `VelX/Y`, `PosErrX/Y` | Navigation tracking (Auto/Loiter modes) |
| `XKF1` | `VN`, `VE`, `VD`, `PN`, `PE`, `PD` | EKF velocity and position estimates |
| `XKF4` | `SV`, `SP`, `SH`, `SM` | EKF state variances — high values indicate EKF stress |
| `BARO` | `Press`, `Temp`, `Alt` | Barometric altitude and temperature |

### Power and Health

| Message | Key Fields | Use |
|---------|-----------|-----|
| `BAT` | `Volt`, `Curr`, `EnrgTot`, `Rem` | Voltage, current draw, capacity consumed |
| `VIBE` | `VibeX`, `VibeY`, `VibeZ`, `Clip0`, `Clip1`, `Clip2` | Vibration levels per axis and IMU clipping |
| `IMU` | `AccX/Y/Z`, `GyrX/Y/Z` | Raw inertial sensor data |
| `PM` | `NLon`, `MaxT`, `LogDrop` | Scheduler overruns, loop timing, dropped log messages |

### Events

| Message | Key Fields | Use |
|---------|-----------|-----|
| `EV` | `Id` | Flight events: arm, disarm, takeoff, land, failsafe |
| `ERR` | `Subsys`, `ECode` | Subsystem errors with numeric code |
| `ARM` | `ArmState`, `ArmChecks` | Arming status and which checks passed |
| `MODE` | `Mode`, `Rsn` | Flight mode changes and the reason |

## Analysis Tools

### UAV Log Viewer

Browser-based, no installation: [plot.ardupilot.org](https://plot.ardupilot.org). Drag-and-drop `.bin` or `.tlog` files. Supports 3D flight replay, customisable multi-axis plots, and expressions combining fields. The recommended starting point for quick reviews.

### Mission Planner Log Analysis

**Flight Data → Review a Log**. Select message types from the dropdown; click field names to graph them. Right-click for zoom and scale options. Generates KMZ files for Google Earth path overlay. Best for single-field comparisons and quick ATT tracking review.

### MAVExplorer

Command-line tool bundled with MAVProxy. More powerful than Mission Planner for conditional analysis:

```bash
mavlogdump.py --type ATT log.bin      # print ATT messages as text
mavexplorer.py log.bin                 # interactive graphing
graph ATT.Roll ATT.DesRoll             # overlay two fields
condition GPS.Spd>4                    # filter by condition
```

### Log Replay in SITL

Dataflash logs captured with `LOG_REPLAY = 1` and `LOG_DISARMED = 1` can be re-run through the EKF inside [SITL](sitl.md) using the bundled `Replay` tool. This rebuilds estimator state from the original sensor stream, so EKF parameter changes (innovation gates, noise terms, sensor affinity) can be evaluated against a real flight without re-flying it. Replay is the standard workflow for diagnosing EKF failsafes and validating filter tuning before deployment — see [Log Replay](sitl.md#log-replay) for the build and run commands.

## Common Analysis Workflows

### Vibration Check (always first)

Plot `VIBE.VibeX`, `VibeY`, `VibeZ`. Targets:

| Level | m/s² | Status |
|-------|-------|--------|
| < 15 | Good | Reliable navigation |
| 15–30 | Marginal | May affect AltHold accuracy |
| > 30 | Bad | Position/altitude hold unreliable |
| > 60 | Critical | EKF failures likely |

`Clip0/1/2` should remain zero throughout flight — any clipping means the IMU is saturating and data is being corrupted. See [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md).

### PID Tuning Review

Plot `ATT.DesRoll` vs `ATT.Roll` and `ATT.DesPitch` vs `ATT.Pitch`. Well-tuned: actual closely follows desired with no sustained lag, overshoot, or oscillation. Oscillation appears as rapid divergence between desired and actual. See [PID Tuning](pid-tuning.md).

For rate controller detail, plot `RATE.RDes` vs `RATE.R` (roll rate demand vs actual) and examine `RATE.ROut` for saturation.

### EKF Health Review

Plot `XKF4.SV` (velocity variance), `XKF4.SP` (position variance), `XKF4.SH` (height variance), `XKF4.SM` (magnetic variance). Values approaching `FS_EKF_THRESH` (default 0.8) indicate impending EKF failsafe. Correlate spikes with `ERR` or mode change events. See [EKF and Navigation](ekf-navigation.md).

### Battery Trend Analysis

Plot `BAT.Volt` and `BAT.Curr`. Normal voltage sag under throttle inputs is 0.1–0.2 V; sag exceeding 0.5 V suggests an undersized pack or degraded cells. Rising current at constant throttle over a flight indicates increasing mechanical load (wind, payload shift). Cross-reference with `CTUN.ThO` to distinguish flight-demand increases from ESC/motor issues.

### Motor Output Imbalance

Plot `RCOU.C1`–`C4` (or higher for more motors). At hover, all motor outputs should be within ~10% of each other. Persistent asymmetry indicates frame twist, CG offset, or a motor/prop that is underperforming. An offset that corrects with altitude changes suggests compass/EKF yaw drift rather than a mechanical issue.

## Related Concepts

- [PID Tuning](pid-tuning.md)
- [Vibration, Filtering, and Tuning](../vibration-filtering-and-tuning.md)
- [EKF and Navigation](ekf-navigation.md)
- [Ground Control Stations](gcs.md)
- [Parameters](parameters.md)
- [First Flight Setup](first-flight.md)

## Sources

- [Logs — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-logs.html) — 2026-05-22
- [Log Messages — ArduPilot Copter docs](https://ardupilot.org/copter/docs/logmessages.html) — 2026-05-22
- [Downloading and Analyzing Data Logs — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-downloading-and-analyzing-data-logs-in-mission-planner.html) — 2026-05-22
- [Measuring Vibration — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-measuring-vibration.html) — 2026-05-22
- [UAV Log Viewer — ArduPilot dev docs](https://ardupilot.org/dev/docs/common-uavlogviewer.html) — 2026-05-22
- [MAVExplorer — ArduPilot dev docs](https://ardupilot.org/dev/docs/using-mavexplorer-for-log-analysis.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
