# Airframes

The physical structure of a multirotor drone — its frame — determines geometry, component placement, weight budget, repairability, and the resonant characteristics that shape flight feel and tuning difficulty.

## Overview

A drone frame provides the rigid skeleton to which [brushless motors](../propulsion/motors.md), flight controller, [ESC](../propulsion/esc.md), [battery](../power-systems/battery.md), and payload mount. Frame design involves tradeoffs between stiffness, weight, crash resistance, and arm geometry. The dominant material is carbon fiber composite; configuration choices (motor count, arm layout) determine what the aircraft can do and how it behaves when a component fails.

All frame dimensions discussed here follow the convention that **frame size** refers to the maximum propeller diameter the frame is designed to accept, and **wheelbase** refers to the diagonal motor-center-to-motor-center distance in millimeters.

## Frame Size Classes

| Frame Size | Wheelbase | Motor Range | Primary Use |
|------------|-----------|-------------|-------------|
| 2″ | 80–100 mm | 0802–1103 | Indoor, ultralight FPV |
| 3″ | 110–140 mm | 1103–1404 | Park flying, lightweight FPV |
| 3.5″ | 140–160 mm | 1404–1604 | Compact freestyle, efficiency builds |
| 4″ | 160–180 mm | 1407–1804 | Micro long-range, smooth FPV |
| 5″ | 210–230 mm | 2205–2307 | Mainstream FPV racing and freestyle |
| 6″ | 240–260 mm | 2306–2507 | Medium-range cruising |
| 7″ | 280–300 mm | 2507–2806 | Long-range, endurance |
| 8–10″+ | ≥320 mm | 2806+ | Payload, cinematic, industrial |

Frame size is a design target, not a structural dimension. A 5″ frame built for freestyle will be physically larger and heavier than a 5″ race frame.

## Construction Types

### Unibody

Arms and main bottom plate are cut from a single carbon piece. Lighter and simpler to assemble, but a broken arm requires replacing the entire plate. Common on racing and ultralight builds where total weight matters most.

### Separate Arms

Arms bolt between top and bottom plates and can be replaced individually. The friction interface between arm and plate damps vibration, reducing noise to the flight controller. Generally stiffer overall and preferred where repairability matters (freestyle, cinematic).

### Box / Enclosed Frame

An X-frame with a structural top plate that encloses the electronics bay. Extra durability and crash protection at the cost of added weight and aerodynamic drag. Used in long-range and cinematic builds where crashes are rare but catastrophic.

## Materials

### Carbon Fiber

Carbon fiber composite (CF) is the standard frame material. It is light, stiff, and strong — but electrically conductive (short-circuit risk) and RF-attenuating (route antennas outside the frame).

CF is sold by weave pattern and modulus grade:

| Specification | Detail |
|---------------|--------|
| 3K weave | 3,000 filaments per tow; common, balanced stiffness/cost |
| 12K weave | 12,000 filaments; slightly heavier, marginally less stiff |
| T300 | Standard modulus (~230 GPa); most hobby frames |
| T700 | Intermediate modulus (~230–250 GPa, higher tensile strength); premium frames |

**Arm thickness by frame class:**

| Frame Size | Minimum Arm Thickness |
|------------|-----------------------|
| 2–3″ | 2.5–3 mm |
| 4″ | 4 mm |
| 5″ | 5 mm (6 mm increasingly common with high-power motors) |
| 6–7″+ | 6 mm |

Thicker arms increase stiffness and vibration resistance but add weight. File all arm edges after cutting to prevent delamination and wire chafing.

### Hardware Metals

| Material | Weight | Strength | Notes |
|----------|--------|----------|-------|
| Steel | Heavy | High | Cheapest; used for standoffs in low-cost frames |
| Aluminum | Light | Moderate | Strips easily; bends on crash; common mid-tier |
| Titanium | Light | High | Best strength-to-weight; expensive |

## Frame Geometry (Motor Configuration)

Motor layout determines stability axes, yaw authority, and camera field of view. See [Rotor Configurations](rotor-configurations.md) for a full treatment of geometry options.

## Weight Benchmarks

| Class | Typical Frame Weight |
|-------|----------------------|
| 5″ racing | 60–90 g |
| 5″ freestyle | 90–120 g |
| 7″ long-range | 120–180 g |
| Cinematic / 10″+ | 200–400 g |

## Resonant Frequency and Tuning

Frame stiffness sets the structural resonant frequency. A frame resonating near motor/prop noise frequencies (typically 100–300 Hz) amplifies vibrations into the IMU, causing gyro noise that degrades PID loop performance and can produce oscillations. Stiffer, heavier arms push resonant frequency higher and out of band; notch filters on the flight controller compensate for unavoidable peaks. Frame damage — cracks, loose screws, bent arms — lowers resonant frequency and can destabilize a previously well-tuned aircraft.

See [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md) for spectral analysis, filter stack architecture, and firmware parameter reference.

## Related Concepts

- [Rotor Configurations](rotor-configurations.md)
- [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md)
- [ESC — Electronic Speed Controller](../propulsion/esc.md)
- [Brushless Motors](../propulsion/motors.md)
- [Propellers](../propulsion/propellers.md)
- [Flight Controllers](../flight-controller-software/ardupilot.md)

## Sources

- [What to Consider in FPV Drone Frames — Oscar Liang](https://oscarliang.com/fpv-drone-frames/) — 2026-05-21
- [Drone Frame Size Chart — Ligpower](https://www.ligpower.com/blog/drone-frame-size-chart.html) — 2026-05-21

<!-- linted: 2026-05-23 -->
