# Propellers

A propeller converts motor shaft rotation into thrust by accelerating air downward, and its diameter, pitch, blade count, and material determine how efficiently that conversion happens for a given motor and flying style.

## Overview

Propellers are the only point of contact between the powertrain and the air. Every other component — motor, ESC, battery — exists to spin the propeller at the right speed with the right torque. Because propellers directly set current draw and thrust character, selecting the wrong prop degrades both performance and component longevity regardless of how well the rest of the system is specced.

FPV and multirotor propellers are specified by three numbers. Understanding what each controls is the foundation of propulsion tuning.

## Notation

Propellers use a diameter × pitch × blade-count notation, e.g. **5×4.3×3** or compactly **5143**:

| Field | Meaning | Example |
|-------|---------|---------|
| Diameter | Tip-to-tip span in inches | 5.0″ |
| Pitch | Theoretical forward travel per revolution in inches | 4.3″ |
| Blade count | Number of blades | 3 |

In the compact four-digit form (e.g. 5045), the first two digits are diameter in tenths of an inch (50 = 5.0″) and the last two are pitch (45 = 4.5″). A blade count suffix is sometimes appended: 5045×3.

### Pitch Definition

Pitch is the distance a propeller would advance per revolution if it were screwing through a solid medium with no slip. In air, actual advance is less due to slip. Higher pitch moves more air per revolution at the cost of requiring more torque from the motor.

## Diameter

Larger diameter sweeps more air per revolution, generating more thrust at a given RPM. Thrust scales approximately with the **fourth power** of diameter, making diameter the dominant lever for total thrust capacity.

Practical constraints:
- Frame arm length and motor-to-motor spacing set the maximum diameter. Standard 5″ builds run 5.1″ props; anything larger risks tip strikes.
- Larger props have greater rotational inertia, slowing RPM changes and reducing responsiveness.
- Higher diameter at the same RPM demands more motor torque (lower KV and/or larger stator).

## Pitch

| Pitch | Characteristics | Best Application |
|-------|----------------|-----------------|
| Low (3.0–4.0″) | Quick RPM changes, less current, reduced propwash | Freestyle, cinematic, hover efficiency |
| Medium (4.3–5.0″) | Balanced thrust and response | All-round 5″ racing/freestyle |
| High (5.0″+) | Higher top speed and forward-flight efficiency, slower transient response | Racing, long-range |

High pitch increases maximum speed:

```
Max speed (in/s) = Max RPM × Pitch / 60
```

In practice, aerodynamic drag reduces realized speed below this theoretical maximum.

## Blade Count

| Blades | Efficiency | Thrust | Noise | Best For |
|--------|-----------|--------|-------|---------|
| 2 | Highest | Lowest per diameter | Lowest | Long-range, efficiency |
| 3 | Balanced | Balanced | Moderate | Racing, freestyle (standard) |
| 4+ | Lower | Highest per diameter | Higher | Cinewhoops, payload lifting |

More blades generate more thrust in a constrained diameter but consume more power to do so. Cinewhoops use 4- or 5-blade props inside prop guards to maximize thrust where diameter is limited.

## Materials

**Polycarbonate (PC) / nylon-reinforced plastic** — the standard for FPV. Lightweight, flexible enough to survive minor impacts without shattering, inexpensive. Cold weather makes plastic brittle; replace props that have been crashed in sub-zero conditions.

**Carbon fiber (CF)** — stiffer and lighter than plastic at the same diameter. Produces less vibration and may improve efficiency slightly. Brittle on hard impact; shards are a hazard. Used on larger, higher-end builds where vibration matters more than crash survivability.

**Wood** — negligible in modern hobby use. Historical baseline for efficiency comparisons.

## Mounting Systems

| Type | Typical Size | Fastener |
|------|-------------|----------|
| Prop nut (M5) | 5″ and larger | Self-locking nylon-insert nut, tightened by hand |
| T-mount | 2–4″ | Two M2 screws through motor bell |
| Press-fit | Micro / tiny whoop | Friction onto 1–1.5 mm shaft, no fastener |

CW and CCW prop variants correspond to CW and CCW motors. The prop nut thread direction reverses the tightening direction under thrust, preventing the nut from backing off during flight.

## Rotation Layout

Standard quadcopter configuration (Betaflight default "props in"):

```
CCW (↺)  CW (↻)
   \      /
    [QUAD]
   /      \
CW (↻)  CCW (↺)
```

Reversed layout ("props out") places CW motors at front-left and rear-right. Props-out reduces propwash slightly on some airframes at the cost of more dirt ingestion.

## Performance Tuning

### Propwash

Propwash is turbulence generated when a descending quad flies through its own prop downwash. Lower-pitch, lighter props reduce propwash because their faster RPM transients allow the flight controller to correct before turbulence amplifies. PID tuning also affects propwash significantly.

### Weight and Moment of Inertia

Lighter props change RPM faster, improving motor response and overall agility. Mass concentrated toward the hub favors quick acceleration; mass toward the tip increases gyroscopic stability but slows response. Racing props prioritize hub-concentrated mass.

### Altitude Compensation

At altitude, lower air density reduces thrust. Compensate by increasing pitch (moves more air per revolution at the cost of torque demand) or by increasing motor KV within thermal limits.

## Selection by Use Case

| Use Case | Diameter | Pitch | Blades | Example |
|----------|---------|-------|--------|---------|
| 5″ all-round | 5.1″ | 4.3″ | 3 | HQ 5×4.3×3 V2S |
| 5″ racing | 5.1″ | 4.6–5.0″ | 3 | Gemfan Hurricane 51466 |
| 5″ cinematic | 5.1″ | 2.5–3.0″ | 3 | HQ 5.1×2.5×3 |
| 7″ long-range | 7.0″ | 3.5″ | 3 | HQ DP 7×3.5×3 |
| 3″ freestyle | 3.0″ | 2.4″ | 3 | Avan Mini 3×2.4×3 |
| Cinewhoop 3.5″ | 90 mm | — | 4 | HQ DT90MM×3 |

Always cross-reference with the motor manufacturer's thrust table for the specific motor/prop/voltage combination before finalizing.

## Failure Modes

| Symptom | Cause |
|---------|-------|
| Props throwing off | Prop nut backed off; wrong thread direction; press-fit too loose |
| Cracking after mild impact | Cold temperature embrittlement; repeated micro-stress at root |
| Persistent vibration | Prop imbalance; tip damage; bent shaft |
| High current / hot motors | Pitch or diameter too large for motor KV |
| Poor high-throttle efficiency | Blade stall from excessive pitch relative to airspeed |

## Related Concepts

- [Brushless Motors](./motors.md)
- [Propulsion System Design](./propulsion-system-design.md)
- [ESC](./esc.md)
- [Vibration Filtering and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md)

## Sources

- [Oscar Liang – How to Choose FPV Propellers](https://oscarliang.com/propellers/) — 2024
- [UAVMODEL – Ultimate FPV Propeller Selection Guide](https://blog.uavmodel.com/the-ultimate-fpv-drone-propeller-selection-guide-pitch-size-and-material-explained/) — 2024
- [LigPower – Drone Propulsion Matching Guide](https://www.ligpower.com/blog/drone-propulsion-matching.html) — 2024
- [T-Motor – Motor and Propeller Matching Guide](https://shop.tmotor.com/blog/drone-motor-propeller-matching-guide) — 2024

<!-- linted: 2026-05-23 -->
