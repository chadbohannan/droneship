# PPK — Post-Processed Kinematic

High-accuracy GNSS positioning computed after the flight by processing raw logs from a base and rover together.

## Overview

Post-Processed Kinematic (PPK) is an alternative to [RTK GPS](rtk-gps.md) for achieving centimetre-level position accuracy. In RTK, a real-time correction link is required between base and rover during the flight. In PPK, both receivers independently log raw GNSS observations; the logs are processed together after landing using RTKLIB or equivalent software.

PPK is the preferred technique for UAV photogrammetric mapping because:

- No real-time correction link is needed — setup is simpler and more reliable over long baselines.
- Processing can be repeated with different parameters to optimise accuracy.
- Camera shutter events are time-tagged to sub-microsecond precision, yielding exact photo coordinates without a ground control point at every photo location.

PPK does not replace Ground Control Points (GCPs) entirely. Keep a small number on site as checkpoints to validate absolute accuracy.

## PPK vs RTK

| | PPK | RTK |
|---|---|---|
| Real-time link required | No | Yes |
| Results available | After flight | During flight |
| Camera sync method | Hot-shoe time mark | Not applicable |
| Processing flexibility | Re-run with any settings | Fixed at flight time |
| Max single-band baseline | 30 km | 10 km |
| Max multi-band baseline | 100 km | 60 km |
| Typical UAV use | Mapping, survey | Precision landing, waypoint accuracy |

## Camera Synchronisation

The critical accuracy element in UAV PPK mapping is timestamping the exact moment each photo is taken. At a typical survey speed of 10 m/s, a 1 s timestamp error produces a 10 m position error.

[Reach M+/M2](reach-m.md) connects to the camera via the **hot shoe** — an electrical contact on the camera body that fires at shutter open. Each hot-shoe pulse is recorded in the Reach raw log with a resolution of less than 1 µs. During post-processing, RTKLIB matches these precise shutter times to the computed rover trajectory, producing a coordinate for each photo.

The output is a text file listing each photo's latitude, longitude, ellipsoid height, and timestamp. Import it into photogrammetry software (Agisoft Metashape, Pix4D, DroneDeploy) to geotag images.

**DJI Mavic and Phantom** cameras lack a hot shoe. PPK is not practical with these platforms; use GCPs instead.

## Hardware Setup

A minimal PPK system consists of:

1. **Rover**: [Reach M+ or M2](reach-m.md) mounted on the drone, connected to the camera hot shoe via the provided adapter cable.
2. **Base**: Reach RS/RS+ or RS2 on a tripod at a surveyed or averaged point, logging raw GNSS data throughout the flight.
3. No radio link between base and rover is required during flight.

Both base and rover must log raw GNSS data (UBX or RINEX format) for the full flight duration, plus several minutes before takeoff and after landing. Extended pre- and post-flight logging improves backward ambiguity initialisation in RTKLIB.

## Post-Processing Workflow with RTKLIB

Emlid distributes a Reach-tuned build of RTKLIB. The standard workflow:

1. **Download logs** from base and rover via ReachView.
2. **Convert to RINEX** with RTKCONV if logs are in UBX format. Select the GNSS systems and observation interval to match the logging configuration.
3. **Process** with RTKPOST:
   - Input: rover RINEX obs, base RINEX obs, navigation file
   - Positioning mode: Kinematic
   - Elevation mask: 15° (default)
   - GNSS: match systems enabled during logging
   - Output: LLH position file (`*.pos`)
4. **Inspect** the solution with RTKPLOT. Fix (green) must cover the entire flight path; Float sections (yellow) degrade accuracy at those photo positions.
5. **Extract time marks** — RTKLIB produces a `*_events.pos` file listing the computed coordinates of each hot-shoe event.
6. **Import coordinates** into the photogrammetry application as image geolocation data.

### RTKPOST Key Settings

| Setting | Recommended value | Notes |
|---------|-------------------|-------|
| Positioning mode | Kinematic | Rover is in motion |
| Elevation mask | 15° | Excludes low-elevation noisy signals |
| SNR mask | 35 | Matches Reach default |
| Ambiguity resolution | Fix-and-Hold or Continuous | Fix-and-Hold is more stable; Continuous avoids holding a false fix |
| GLONASS AR | On | Reach corrects inter-channel biases, enabling GLONASS ambiguity resolution |

## Baseline Limits

Post-processed baselines can be longer than RTK because offline processing allows forward and backward smoothing over the entire dataset.

| Receiver type | Max PPK baseline |
|---------------|-----------------|
| Single-band (Reach M+) | 30 km (18 miles) |
| Multi-band (Reach M2) | 100 km (60 miles) |

Beyond these limits, ionospheric divergence between base and rover exceeds what single- or dual-frequency processing can resolve.

## Accuracy Expectations

- Fix solution: 1–3 cm horizontal, 3–5 cm vertical (typical UAV survey conditions)
- Float solution: 0.3–1 m — insufficient for precision mapping; investigate sky obstruction, baseline length, or insufficient log overlap

Absolute accuracy depends on base position accuracy. An averaged Single base introduces a constant offset equal to the base's GNSS error (typically 1–3 m). For sub-decimetre absolute accuracy, place the base on a known benchmark or derive an accurate base position via PPP or NTRIP before the flight.

## Related Concepts

- [RTK GPS](rtk-gps.md)
- [Emlid Reach M+ and M2](reach-m.md)
- [Navio2 GNSS Receiver](../flight-controller-hardware/navio2/gnss.md)
- [Mission Planning](../flight-controller-software/ardupilot/mission-planning.md)

## Sources

- [Emlid Documentation](https://docs.emlid.com/) — PPK introduction, RTK introduction, Reach glossary — 2026-05-22

<!-- linted: 2026-05-23 -->
