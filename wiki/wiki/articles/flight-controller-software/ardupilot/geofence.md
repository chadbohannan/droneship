# Geofencing — ArduPilot

Geofencing defines spatial boundaries that the vehicle enforces automatically. When the vehicle approaches or crosses a fence boundary, ArduPilot triggers a configurable action (RTL, land, brake, or report-only). Fences are the primary software mechanism for constraining flight area in regulatory compliance, safety scenarios, and testing.

## Overview

ArduPilot supports four fence types that can be active simultaneously: maximum altitude, minimum altitude, circular (around home), and polygon. Polygon fences can be drawn as inclusion zones (vehicle must stay inside) or exclusion zones (vehicle must stay outside). Multiple polygon fences can be combined.

## Core Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `FENCE_ENABLE` | 0 | 1 = activate geofencing |
| `FENCE_TYPE` | 7 | Bitmask: bit 0=ALT_MAX, bit 1=ALT_MIN (Circle deprecated), bit 3=polygon |
| `FENCE_RADIUS` | 300 m | Radius of circular fence around home |
| `FENCE_ALT_MAX` | 100 m | Maximum altitude |
| `FENCE_ALT_MIN` | -10 m | Minimum altitude (negative = below launch) |
| `FENCE_MARGIN` | 2 m | Distance to maintain from fence boundary |
| `FENCE_ACTION` | 1 | Action on breach (see table below) |

## Fence Actions

| `FENCE_ACTION` | Response |
|----------------|---------|
| 0 | Report only — log and GCS warning, no automatic action |
| 1 | RTL or Land |
| 2 | Always Land |
| 3 | SmartRTL → RTL → Land |
| 4 | Brake → Land |
| 5 | SmartRTL → Land |

### Progressive Enforcement

When a fence is breached, ArduPilot erects a backup fence 20 m further out. If the vehicle breaches the backup fence (e.g., not responding to RTL), another backup fence is created. If the vehicle continues 100 m past the original boundary despite successive backup fences, it force-lands regardless of `FENCE_ACTION`.

After a breach, the fence is disabled for 10 seconds when the pilot changes flight mode manually, enabling recovery.

## Altitude Fences

`FENCE_ALT_MAX` limits climb in all modes. In altitude-hold modes (AltHold, Loiter, PosHold), the vehicle stops climbing at the fence altitude rather than immediately triggering the breach action — this creates a soft ceiling. At the altitude ceiling, the vehicle holds altitude and a warning is sent to the GCS.

`FENCE_ALT_MIN` prevents descent below the minimum (useful over water or terrain where low flight is dangerous).

## Polygon Fences

Polygon fences are drawn in Mission Planner (PLAN screen → polygon draw tool) and uploaded alongside the mission. Up to 70 vertices per polygon. Multiple inclusion and exclusion polygons can coexist.

**Inclusion polygon**: vehicle must remain inside this area.

**Exclusion polygon**: vehicle must not enter this area.

To upload: draw polygon → right-click → Fence Inclusion (or Exclusion) → Write (same as missions). Polygon fences require **MAVLink 2**; USB connections use MAVLink 2 by default. SiK radios may need `SERIAL1_PROTOCOL = 2` explicitly.

For complex fences exceeding internal memory, enable SD card storage: `BRD_SD_FENCE = 1`.

## Enabling and Disabling via RC Switch

Assign a channel: `RCx_OPTION = 11` toggles fence enable/disable via switch. This allows the pilot to momentarily disable the fence for a controlled boundary crossing without ground station interaction.

## Fence and Mission Interaction

By default, a fence breach during a mission triggers the fence action (e.g., RTL), interrupting the mission. To allow the mission to continue past the fence without triggering a breach, disable the fence for that portion of the mission via a DO_FENCE_ENABLE command or by disabling `FENCE_ENABLE` before launch if the mission path approaches the boundary.

## GPS Requirement

All fence types except altitude require a valid GPS fix. Pre-arm check `GPS x: Bad fix` must be resolved before arming when fences are enabled.

## Related Concepts

- [Failsafes](failsafes.md)
- [Flight Modes](flight-modes.md)
- [Mission Planning](mission-planning.md)
- [EKF and Navigation](ekf-navigation.md)

## Sources

- [Fences — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-geofencing-landing-page.html) — 2026-05-22
- [Polygon Fences — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-polygon_fence.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
