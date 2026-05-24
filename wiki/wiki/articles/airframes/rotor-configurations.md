# Rotor Configurations

The number, placement, and rotational direction of a multirotor's motors determines its aerodynamic authority, redundancy, efficiency, and handling character.

## Overview

Every multirotor achieves attitude control by differentially varying motor thrust. Yaw is produced by imbalancing the net torque of clockwise (CW) vs. counter-clockwise (CCW) motors. Roll and pitch are produced by raising thrust on one side and lowering it on the other. A configuration with more motors can distribute these forces across more actuators, improving redundancy and smoothness — but at the cost of weight, power draw, and mechanical complexity.

Motor spin directions follow a standard pattern: adjacent motors spin opposite directions so that their torques partially cancel during level flight, and differential torque produces yaw.

## By Motor Count

### Bicopter (2 motors)

Two motors with servo-controlled tilt for pitch, roll, and yaw. Mechanically the simplest possible powered-lift design but the hardest to stabilize. No commercial hobby ecosystem; niche experimental builds only.

### Tricopter (3 motors)

Three motors in a Y or T layout (120° spacing). Yaw is produced by a servo that tilts the rear motor, not by torque imbalance — this preserves full thrust for yaw maneuvers and gives tricopters notably better yaw authority than quadcopters of equivalent size. The servo introduces a mechanical failure point and adds weight; tricopters have largely been displaced by quadcopters in the hobby market despite their aerodynamic elegance.

### Quadcopter (4 motors)

The dominant configuration. Four motors at the corners of an X (or + layout) provide full six-degree-of-freedom control with no moving parts beyond the motors themselves. Yaw is produced by torque imbalance, sacrificing some thrust — but the tradeoff is acceptable for most uses. Simple mechanics, abundant parts availability, and a large firmware/tuning ecosystem make quadcopters the default choice for FPV, racing, freestyle, and light cinematic work.

Layout geometry within quadcopters varies significantly; see [Quadcopter Geometry](#quadcopter-geometry) below.

### Hexacopter (6 motors)

Six motors at 60° intervals (three CW/CCW pairs). If one motor fails, the aircraft can continue flying with degraded but controlled performance. Higher lifting capacity per frame size than a quadcopter. Preferred for professional aerial photography and industrial inspection where redundancy and payload matter more than agility. Larger, heavier, and more expensive than equivalent quadcopter builds.

### Octocopter (8 motors)

Eight motors (four CW/CCW pairs). Maximum payload capacity and the highest motor-failure tolerance in a single-layer configuration. Commonly used for cinema rigs carrying large gimbals. High cost, current draw, and physical size limit octocopters to professional applications.

### Coaxial Variants (Y6, X8, Y4)

Coaxial arrangements stack two motors on each arm with counter-rotating props. This achieves the redundancy and count of a hex or octo within the footprint of a tri or quad frame.

**Efficiency penalty:** The lower motor operates in the disturbed wake of the upper prop, reducing combined efficiency by approximately 10–20% compared to a flat layout with equivalent motor separation.

**Common coaxial types:**

| Type | Arms | Motors per Arm | Total Motors |
|------|------|----------------|--------------|
| Y6 | 3 | 2 | 6 |
| X8 | 4 | 2 | 8 |
| Y4 | 2+1 | 1/2 mixed | 5 effective |

Coaxial variants are rarely used in new hobby builds; the efficiency penalty and tuning complexity outweigh the compactness benefit for most applications.

## Motor Count Comparison

| Configuration | Motors | Yaw Method | Motor-Failure Tolerance | Relative Efficiency | Typical Use |
|---------------|--------|------------|------------------------|---------------------|-------------|
| Tricopter | 3 | Servo tilt | None | High | Experimental, niche |
| Quadcopter | 4 | Torque diff | None | High | FPV, racing, freestyle |
| Hexacopter | 6 | Torque diff | 1 motor | Moderate | Cinematic, industrial |
| Octocopter | 8 | Torque diff | 2 motors | Moderate | Heavy-lift cinema |
| X8 (coaxial) | 8 | Torque diff | 1 coaxial pair | Low (−10–20%) | Compact heavy-lift |

## Quadcopter Geometry

Within quadcopters, the angular relationship between the four motor positions significantly affects flight characteristics.

### True X

All four arms intersect the center point at equal angles (90°), placing motors equidistant from center on all axes. Roll and pitch moment arms are identical, so the aircraft responds equally in both axes. True X is the standard for racing and technical freestyle where symmetrical, predictable handling is required. Compact motor-to-motor spacing improves yaw authority.

### Stretched X

The front and rear motor pairs are moved further apart relative to the left-right pairs, elongating the frame along the pitch axis. This increases the front-rear moment arm, giving more pitch authority and reducing propwash interference (the turbulence from rear props passing through the wake of front props). Preferred by racers who favor aggressive forward pitching and clean air through the propeller disk in forward flight.

### Wide X / Squished X

Motor pairs are spread laterally more than fore-aft, widening the roll axis. More central body space is available for mounting an action camera or larger battery. Smoother roll behavior at the cost of slightly reduced roll agility. Common in freestyle frames.

### Deadcat

Asymmetric layout: front motors wider apart, rear motors closer together. Designed to push the front propellers outside the camera's field of view for clean cinematic footage without a true camera-forward offset. Unequal motor geometry creates asymmetric thrust authority; flight controllers compensate in software, but handling is less crisp than True X.

### Plus (+) Frame

Motors aligned on cardinal axes (N/S/E/W). Front motor is directly ahead of the camera, so it appears in forward-facing footage — unacceptable for FPV. Plus frames were common in early consumer drones for their intuitive orientation; largely obsolete for FPV applications.

### H Frame

Arms perpendicular to a central spine forming an H shape. Roomy chassis for electronics, but long fore-aft moment arm raises pitch-axis inertia, making the aircraft sluggish on pitch. Rarely used in new designs.

## Geometry Comparison

| Layout | Pitch/Roll Balance | Yaw Authority | Prop Wash | Camera View | Common Use |
|--------|--------------------|---------------|-----------|-------------|------------|
| True X | Symmetric | High | Moderate | Clean | Racing, freestyle |
| Stretched X | Pitch-biased | Moderate | Low | Clean | Racing |
| Wide X | Roll-biased | Moderate | Moderate | Clean | Freestyle |
| Deadcat | Asymmetric | Moderate | Moderate | Optimal | Cinematic |
| Plus (+) | Symmetric | Moderate | Low | Obstructed | Legacy |
| H | Pitch-sluggish | Moderate | Low | Clean | Legacy, long-range |

## Spin Direction Conventions

In a standard quadcopter the motor positions and spin directions are:

```
  CW (M2)  CCW (M1)
      \      /
       \    /
        ----
       /    \
      /      \
 CCW (M3)  CW (M4)
```

Betaflight and ArduPilot number motors differently; consult the firmware motor order diagram before connecting ESCs. Reversed spin direction ("props-in" vs "props-out") shifts the vortex ring toward or away from the center of the frame and subtly affects propwash behavior. Props-out is most common in modern FPV builds.

## Related Concepts

- [Airframes](airframes.md)
- [ESC](../propulsion/esc.md)
- [Flight Controllers](../flight-controller-software/ardupilot.md)
- [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md)

## Sources

- [Types of Multirotor — Oscar Liang](https://oscarliang.com/types-of-multicopter/) — 2026-05-21
- [What to Consider in FPV Drone Frames — Oscar Liang](https://oscarliang.com/fpv-drone-frames/) — 2026-05-21
- [Drone Frame Size Chart — Ligpower](https://www.ligpower.com/blog/drone-frame-size-chart.html) — 2026-05-21

<!-- linted: 2026-05-23 -->
