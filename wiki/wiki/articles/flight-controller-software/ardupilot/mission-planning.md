# Mission Planning — ArduPilot

An ArduPilot mission is a sequence of MAVLink command objects stored on the flight controller. In Auto mode, the vehicle executes the sequence top-to-bottom, navigating between waypoints, executing actions, and following any conditional logic defined by CONDITION_ commands.

## Overview

Missions are uploaded from a GCS (Mission Planner, QGroundControl, MAVProxy) or programmatically via DroneKit/MAVSDK. Up to ~650 waypoints fit in autopilot RAM; enable `BRD_SD_MISSION = 1` to move mission storage to the SD card for up to 4000+ waypoints.

The vehicle enters Auto mode with `mode auto` or by switch, then follows the mission. `FS_OPTIONS` bits allow the mission to survive radio and GCS failsafes — see [Failsafes](failsafes.md).

## Navigation Commands (NAV_)

| Command | Description |
|---------|-------------|
| `NAV_TAKEOFF` | Climb to specified altitude; should be first command |
| `NAV_WAYPOINT` | Fly to position (lat/lon/alt) |
| `NAV_SPLINE_WAYPOINT` | Fly curved spline path through position |
| `NAV_LOITER_TIME` | Loiter at position for N seconds |
| `NAV_LOITER_TURNS` | Circle position for N rotations (negative = CCW) |
| `NAV_LOITER_UNLIMITED` | Loiter indefinitely (mission pauses) |
| `NAV_LAND` | Descend and land at position |
| `NAV_RETURN_TO_LAUNCH` | Return to home and land |

All altitude fields are interpreted relative to the launch altitude by default. Set altitude type to **Terrain** in Mission Planner to interpret altitudes as height above ground via SRTM terrain data.

## Action Commands (DO_)

DO_ commands execute alongside navigation without pausing vehicle movement:

| Command | Description |
|---------|-------------|
| `DO_CHANGE_SPEED` | Set horizontal speed (cm/s) |
| `DO_SET_ROI` | Point camera at a region of interest |
| `DO_DIGICAM_CONTROL` | Trigger camera shutter |
| `DO_SET_RELAY` | Toggle relay output (param1=relay, param2=0/1/toggle) |
| `DO_REPEAT_SERVO` | Cycle a servo output N times |
| `DO_LAND_START` | Mark landing sequence start (used by `FS_THR_ENABLE = 6`) |
| `DO_GRIPPER` | Open/close gripper |
| `DO_SET_CAM_TRIGG_DIST` | Trigger camera every N metres |

## Condition Commands (CONDITION_)

CONDITION_ commands delay subsequent DO_ commands until a condition is met:

| Command | Description |
|---------|-------------|
| `CONDITION_DISTANCE` | Wait until within N metres of next waypoint |
| `CONDITION_ALTITUDE` | Wait until reaching altitude |
| `CONDITION_CHANGE_ALT` | Wait until altitude change completes |

If the condition is not met before the vehicle reaches the next waypoint, any unexecuted DO_ commands are skipped.

## Navigation Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `WPNAV_SPEED` | 1000 cm/s | Maximum horizontal mission speed |
| `WPNAV_ACCEL` | 250 cm/s² | Maximum horizontal acceleration |
| `WPNAV_SPEED_UP` | 300 cm/s | Climb rate limit |
| `WPNAV_SPEED_DN` | 150 cm/s | Descent rate limit |
| `WPNAV_RADIUS` | 200 cm | Radius at which waypoint is considered reached |

The vehicle auto-reduces speed below `WPNAV_SPEED` to stay within `WPNAV_ACCEL` limits and to turn corners smoothly.

## Terrain Following

Set altitude type to **Terrain** in Mission Planner to fly at constant height above ground rather than above the launch point. Terrain data comes from:

- **SRTM database** (~90 m grid spacing, 10–20 m typical accuracy) — downloaded to GCS SD card or injected by GCS during flight
- **Rangefinder** (`WP_RFND_USE = 1`) — real-time, more accurate at low altitude (< 60 m)

Parameters:
```
TERRAIN_ENABLE = 1    (enable terrain database)
WP_RFND_USE    = 1    (prefer rangefinder over terrain database)
```

If terrain data is unavailable for > 2 seconds during a terrain-following mission, ArduPilot triggers the terrain failsafe and switches to RTL.

## Survey / Grid Missions

Mission Planner auto-generates photogrammetry survey missions:
1. PLAN → right-click map → Polygon → draw survey area
2. Auto WP → Survey (Grid)
3. Set altitude, camera overlap, and flight speed
4. Click Accept → mission waypoints are generated

Spline waypoints (`NAV_SPLINE_WAYPOINT`) produce smoother curved paths for photogrammetry, reducing shutter blur compared to sharp-turn waypoints.

## Mission Upload

**Mission Planner**: PLAN screen → Write button.

**MAVProxy**:
```bash
wp load mission.txt    # upload from QGC WPL format file
wp list                # view current mission
wp set 3              # jump to waypoint 3 mid-mission
wp save backup.txt    # download to file
```

**MAVLink**: `MISSION_ITEM_INT` messages followed by `MISSION_ACK`. The GCS protocol negotiates upload via `MISSION_COUNT` → `MISSION_REQUEST_INT` → `MISSION_ITEM_INT` for each waypoint.

## Related Concepts

- [Flight Modes](flight-modes.md)
- [Ground Control Stations](gcs.md)
- [Failsafes](failsafes.md)
- [Geofencing](geofence.md)
- [EKF and Navigation](ekf-navigation.md)
- [Companion Computers](companion-computers.md)

## Sources

- [Planning a Mission — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-planning-a-mission-with-waypoints-and-events.html) — 2026-05-22
- [Mission Commands — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-mavlink-mission-command-messages-mav_cmd.html) — 2026-05-22
- [Terrain Following — ArduPilot Copter docs](https://ardupilot.org/copter/docs/terrain-following.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
