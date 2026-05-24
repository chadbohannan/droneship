# Propulsion System Design

Matching motor, propeller, ESC, and battery as a coherent system — rather than selecting components independently — is the single most effective way to maximize thrust, efficiency, and component longevity.

## Overview

Each propulsion component constrains the others. A motor's KV and stator volume determine which propellers it can turn efficiently. The propeller's diameter and pitch set the current demand, which must stay within ESC and battery limits. Battery cell count sets voltage, which multiplies through KV to determine RPM. Optimizing any one component in isolation while ignoring the rest produces a system that underperforms or fails early.

This article covers the design workflow: how to calculate requirements, select components in the correct order, and validate the final combination before committing to hardware.

## Core Relationships

### Motor RPM

```
RPM = KV × V_nominal
```

Example: a 2300 KV motor on a 4S pack (14.8 V nominal) spins at ~34,000 RPM unloaded; on 6S (22.2 V) the same motor reaches ~51,000 RPM — exceeding safe limits for most 5″ props. This is why 6S builds use lower KV motors.

### Thrust and Propeller Diameter

Thrust scales approximately with the fourth power of propeller diameter at constant tip speed. Doubling diameter roughly quadruples thrust capacity, which is why large agricultural drones use 15–30″ props rather than spinning many small ones.

### Battery Discharge

```
Max current = Capacity (Ah) × C-rating
```

Example: 1300 mAh 75C battery → 1.3 × 75 = 97.5 A maximum discharge. Total system current draw (all motors at full throttle) must stay below this figure with margin.

## Thrust-to-Weight Ratio

Thrust-to-weight ratio (TWR) is total motor thrust at full throttle divided by all-up weight (AUW) including battery.

| Application | TWR Target | Character |
|-------------|-----------|-----------|
| Heavy-lift / agricultural | 1.5:1–2:1 | Stable, payload-focused |
| Aerial photography | 2:1–3:1 | Smooth hover, extended flight time |
| Freestyle / cinematic FPV | 5:1–8:1 | Agile, punchy |
| Racing | 10:1–14:1 | Maximum acceleration |

A TWR below 2:1 leaves almost no throttle headroom for wind gusts or attitude correction. Design to at least 2:1 for any outdoor application; 3:1 for reliable payload work.

### Calculating Required Thrust per Motor

```
Required thrust per motor = (AUW × TWR_target) / motor_count
```

Example: 700 g AUW quad, 6:1 TWR, 4 motors → 700 × 6 / 4 = 1,050 g per motor.

Look up the motor's thrust table at the target voltage and prop combination to confirm it reaches 1,050 g without exceeding the continuous current rating.

## Selection Workflow

Work through these steps in order; each step constrains the next.

### 1. Define AUW and Use Case

Estimate all-up weight including frame, FC, ESC, battery, camera, and payload. Use case determines the TWR target from the table above.

### 2. Calculate Required Total Thrust

```
Total thrust = AUW × TWR_target
```

Add 10–15% margin for estimation error in AUW.

### 3. Choose Battery Voltage

| Voltage | Use Case |
|---------|---------|
| 1S–3S | Micro / tiny whoop |
| 4S | Standard 5″ freestyle, efficient 7″ |
| 6S | High-performance 5″, long-range 7″, most efficiency-sensitive builds |

6S delivers the same power at lower current than 4S, reducing I²R losses in wiring and ESCs and extending component life. The tradeoff is higher cost and slightly more weight.

### 4. Select Propeller

Maximum prop diameter is set by the frame. Within that constraint, choose diameter and pitch for the use case:

- **Efficiency / hover time**: larger diameter, lower pitch, fewer blades.
- **Speed / racing**: smaller diameter, higher pitch.
- **Freestyle**: medium pitch, 3-blade — balances response and grip.

See [Propellers](./propellers.md) for a full selection table.

### 5. Select Motor

Choose stator size and KV to spin the chosen prop at the right RPM on the chosen voltage:

```
Target KV ≈ (Desired RPM) / V_nominal
```

Cross-reference the motor's thrust table to verify thrust per motor meets the requirement at acceptable current. See [Brushless Motors](./motors.md) for the full frame-to-motor mapping.

### 6. Select ESC

ESC continuous current rating must exceed the motor's maximum continuous current with a **20–30% margin**:

```
ESC_rating ≥ Motor_max_current × 1.25
```

| Application | Typical ESC Rating |
|-------------|-------------------|
| 5″ racing/freestyle | 40–45 A per motor |
| Cinewhoop | 25–35 A per motor |
| 7″ long-range | 30–45 A per motor |

PWM frequency also matters: high-KV motors benefit from 48 kHz+; efficiency-focused builds may run lower frequencies to reduce switching losses. See [ESC](./esc.md) for protocol and configuration details.

### 7. Select Battery

Choose capacity for target flight time, C-rating for current demand:

```
Required C-rating ≥ (Total max current draw) / Capacity (Ah)
```

| Application | C-rating |
|-------------|---------|
| Racing / freestyle | ≥75C |
| Freestyle | ≥60C |
| Cinewhoop | ≥50C |
| Aerial photo / long-range | ≥45C |

Higher C-rating cells are heavier; diminishing returns appear beyond what the system actually demands. See [Battery](../power-systems/battery.md) for cell chemistry and capacity tradeoffs.

## Reference Configurations

| Build | Motors | Props | Battery | ESC |
|-------|--------|-------|---------|-----|
| 5″ FPV racing | 2207/2306, 2300–2800 KV | 5×4.6×3 | 4S 1300 mAh 75C | 40–45 A |
| 5″ freestyle (6S) | 2207, 1750–2100 KV | 5×4.3×3 | 6S 1050 mAh 60C | 40–45 A |
| Cinewhoop 3.5″ | 2004/2204, 1400–2300 KV | 3.5×4-blade | 4S 1300 mAh 50C | 25–35 A |
| 7″ long-range | 2806.5/3110, 800–1500 KV | 7×3.5×3 | 6S 3000–5000 mAh 45C | 30–45 A |
| 10″ aerial photo | 3110, 900–1100 KV | 10×4.5×3 | 6S 5000 mAh 45C | 40 A |
| Agricultural heavy-lift | varies, 60–400 KV | 15–30″ low pitch | 6S–12S high capacity | varies |

## Validation Checklist

Before first flight, verify:

- [ ] Motor thrust table confirms each motor meets required thrust at chosen voltage and prop.
- [ ] Peak current (all motors full throttle) ≤ battery max discharge current.
- [ ] Peak current per motor ≤ ESC continuous rating × 0.8.
- [ ] Motor temperature after 2-minute full-throttle test ≤ 65 °C.
- [ ] ESC temperature after test within rated range.
- [ ] No resonant vibration frequencies in motor logs (check RPM filter in Betaflight/ArduPilot).

## Common Mistakes

**Mismatched KV and voltage**: running a 2300 KV motor on 6S with a 5″ prop causes extreme current draw and rapid motor destruction. Use the RPM formula to check before powering up.

**Ignoring burst vs. continuous current**: ESC and motor burst ratings are short-term peaks. Size components to continuous current with margin.

**Optimizing peak thrust only**: evaluate efficiency across the entire throttle range. A motor with high peak thrust but poor mid-throttle efficiency wastes battery and generates heat during normal flight.

**Underestimating AUW**: add 15–20% to estimated weight for wiring, hardware, and unexpected additions. TWR degrades quickly if actual weight exceeds estimates.

## Related Concepts

- [Brushless Motors](./motors.md)
- [Propellers](./propellers.md)
- [ESC](./esc.md)
- [Battery](../power-systems/battery.md)
- [Airframes](../airframes/airframes.md)

## Sources

- [LigPower – Drone Propulsion Matching Guide](https://www.ligpower.com/blog/drone-propulsion-matching.html) — 2024
- [Oscar Liang – How to Choose FPV Drone Motors](https://oscarliang.com/motors/) — 2024
- [Grepow – Choosing Motors and Propellers for Different Applications](https://www.grepow.com/blog/how-to-choose-right-motors-and-propeller-for-different-drone-applications.html) — 2024
- [T-Motor – Motor and Propeller Matching Guide](https://shop.tmotor.com/blog/drone-motor-propeller-matching-guide) — 2024
- [Engineers Garage – How to Select Drone Motors](https://www.engineersgarage.com/how-to-select-drone-motors/) — 2024

<!-- linted: 2026-05-23 -->
