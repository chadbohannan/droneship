# Brushless DC Motors

Brushless DC (BLDC) motors convert electrical energy into rotational force through electromagnetically commutated three-phase windings, and their topology, winding configuration, pole–slot geometry, and construction details determine the thrust, efficiency, response, and longevity of the entire propulsion system.

## Overview

A BLDC motor replaces the mechanical commutator of a brushed motor with electronic switching. The ESC energizes three stator phases in sequence, creating a rotating magnetic field that the permanent-magnet rotor follows. Because there is no brush contact, friction losses are eliminated, efficiency is higher, and service life extends to thousands of flight-hours under normal use.

Motor selection is inherently a system-level decision. Topology (outrunner vs. inrunner vs. axial flux) sets the torque–speed envelope and installation constraints. Winding configuration (star vs. delta) shifts the efficiency band. Pole–slot geometry determines smoothness and cogging. Construction details — magnet grade, lamination thickness, bearing quality, winding wire — determine the ceiling within a given design. No single parameter can be evaluated in isolation.

---

## Topology

### Outrunner (Radial Flux, External Rotor)

In an outrunner, the permanent magnets are bonded to the inside of a rotating outer bell (the rotor), while the stator windings remain fixed at the center. The prop mounts directly to the bell.

**Why outrunners dominate multirotors:**
- The large magnetic radius (rotor diameter ≈ motor OD) multiplies torque for a given stator volume
- Direct-drive large-diameter props are possible without a gearbox
- Moderate RPM range matches propeller aerodynamic requirements
- Low KV values are naturally achievable through high pole counts and tight windings

**Limitations:**
- Maximum RPM is bounded by rotor inertia and centrifugal stress on the bell
- The rotating outer surface generates slight aerodynamic drag at very high RPM
- Longer thermal path from stator to ambient (heat must conduct through air gap and housing)

**Typical specs:** KV 800–30,000 depending on stator size; 6–24 poles; stator codes 0702 through 4014 for hobby use, larger for commercial UAVs.

---

### Inrunner (Radial Flux, Internal Rotor)

In an inrunner, the rotor is a cylindrical core with magnets on its outer surface, spinning inside a stationary housing that holds the stator windings. The arrangement mirrors a conventional AC motor.

**Advantages:**
- Higher RPM ceiling: low-pole inrunners routinely reach 50,000–80,000 RPM, enabling Electric Ducted Fans (EDF) and micro props
- Superior thermal management: the stator contacts the stationary housing directly; heat dissipates efficiently, IP-rated sealed designs are practical
- Lower rotor inertia: the spinning mass is concentrated near the axis, giving faster throttle response
- Robustness in harsh environments: enclosed design resists dust, moisture, and debris
- Higher overall efficiency per unit mass at high power levels through reduced iron content in advanced designs

**Limitations:**
- Low torque output at low RPM — a gearbox or very high pole count is required for direct-drive large props
- Higher KV values standard; achieving low-KV inrunner characteristics requires many poles (modern designs reach up to 70 poles)
- Noise frequency is higher and more tonal than outrunners

**When to use inrunners:**
- EDF jets and ducted prop platforms
- Fixed-wing aircraft with folding or small-diameter props
- High-power delivery/cargo drones where environmental sealing is required
- Any application where long duty cycle and harsh conditions demand sealed IP-rated motors

---

### Axial Flux

In an axial flux motor, the magnetic flux flows parallel to the rotation axis rather than across a radial air gap. The stator is a flat disc with windings facing one or two rotor discs carrying magnets. The result is a pancake-shaped motor.

**Advantages:**
- Highest power-to-weight ratio of any BLDC topology: 20–30% weight reduction for equivalent power vs. radial flux
- 23% higher power density and 3–5% efficiency improvement over equivalent radial designs in research comparisons
- Excellent heat dissipation from the flat surface area
- Ultra-low profile, beneficial for aerodynamically integrated airframes

**Limitations:**
- Manufacturing complexity and cost are significantly higher
- Axial magnetic forces create large bearing loads requiring robust thrust bearings
- Less industrialized than radial flux; fewer off-the-shelf options for hobby scale
- Difficult to achieve high pole counts in a compact diameter

**When to use axial flux:**
- Long-endurance fixed-wing or hybrid VTOL UAVs where mass budget is critical
- Manned or large commercial UAVs targeting maximum efficiency
- Tightly integrated airframes where motor height must be minimized

---

### Coreless (Ironless Stator)

A coreless motor eliminates the iron stator core entirely. Windings are formed into a self-supporting cup or disc shape and suspended in the air gap between the magnets. There is no ferromagnetic material in the rotating assembly.

**Advantages:**
- Zero cogging torque: the motor starts and runs smoothly from any position at any speed, critical for gimbal stabilization
- Very low rotor inertia enables extremely fast speed changes
- No iron losses (hysteresis and eddy current), improving efficiency at moderate loads
- Lower inductance reduces PWM switching noise that can interfere with sensors

**Limitations:**
- Winding heat is harder to dissipate without a conductive iron core path
- Maximum power density is lower than slotted motors of equal size; copper fills the gap less efficiently than iron-backed windings
- Mechanically delicate — the unsupported coil is susceptible to deformation under thermal or mechanical stress

**When to use coreless motors:**
- Gimbal motors (camera stabilization axes): jitter-free from cogging dominates all other requirements
- Micro and nano quads (sub-65 mm props): coreless scales down more readily than slotted designs
- Precision positioning: medical, optical, robotic applications requiring smooth low-speed motion

**Distinguishing slotless from coreless:** A slotless motor retains an iron stator yoke but has no slots; windings sit in the smooth bore. Cogging torque is greatly reduced but not eliminated. A fully coreless motor has no iron at all. Both are sometimes marketed interchangeably — verify construction if cogging is critical.

---

## Winding Configuration: Star vs. Delta

Both configurations use three-phase windings; the difference is how those windings are interconnected.

### Star (Wye, Y)

The three winding ends connect to a common neutral point. Phase voltage is 1/√3 (≈ 58%) of line voltage.

- Lower phase current for a given line voltage → lower copper losses at low-to-moderate load
- Higher torque at low RPM
- Smoother, quieter operation
- Less heat generation; better thermal reliability
- **Best for:** photography/cinematic quads, long-endurance cruisers, gimbals, any application where hover efficiency and low-speed smoothness dominate

### Delta (Δ)

The three windings form a closed triangle; each winding sees the full line voltage.

- Phase current equals line current × √3 → higher current through each winding at the same bus voltage
- Higher torque at elevated RPM; better peak performance under high electrical demand
- More efficient at high speed and high power
- Higher heat generation per winding at low load
- **Best for:** racing, freestyle, EDF, high-RPM fixed-wing; any application where peak thrust at high throttle matters more than hover efficiency

### Practical Implications

Most hobby BLDC motors are factory-wound in star. Delta-wound motors of the same KV spin faster for the same voltage, equivalent to a star-wound motor of approximately √3 (≈ 1.73×) higher KV. A 2000 KV delta motor behaves similarly to a ~3460 KV star motor at full throttle, but the delta motor's efficiency advantage only appears near peak power; it runs hotter at partial throttle.

Rewinding a motor from star to delta (or vice versa) changes effective KV by ×√3 and requires repositioning Hall sensors if the motor is sensored.

---

## Pole and Slot Geometry

### Notation

Motor specs express stator and rotor geometry as **NxPy**: N is the number of stator slots (electromagnetic coils), P is the number of rotor magnetic poles.

Common configurations in hobby and commercial UAVs:

| Configuration | Characteristics | Typical Use |
|---------------|----------------|-------------|
| 9N12P | Compact; moderate cogging | Micro/toothpick motors |
| 12N14P | Industry standard; balanced cogging and efficiency | 5″ freestyle/racing |
| 12N16P | Slightly higher pole count; smoother | Mid-size freestyle |
| 18N16P | More slots; lower cogging torque | Cinematic, precision |
| 24N22P | High pole count; very smooth | Large commercial UAV |
| 36N42P | Industrial; very low RPM, very high torque | Agricultural, heavy lift |

### Why Pole–Slot Ratio Matters

**Cogging torque** is the detent force created by the interaction of rotor magnets with stator teeth. It manifests as vibration, jitter in gimbals, and rough low-throttle behavior. The slot-to-pole ratio determines how many times per revolution the rotor "snaps" between preferred positions.

- Ratios that are close to 1:1 (e.g., 12N14P, 12N16P) distribute cogging events evenly around the rotation, producing lower peak cogging torque
- Ratios far from 1:1 concentrate cogging events, increasing roughness
- Higher absolute pole counts reduce cogging amplitude because each individual event is smaller

**Winding symmetry** requires that N/3 be an integer (slots must be divisible equally among three phases). 9, 12, 18, 24, 36 slot counts all satisfy this; 10 or 14 slot counts require special winding schemes.

**GCD (Greatest Common Divisor) rule:** Lower GCD(N, P) → smoother rotation. 12N14P: GCD = 2. 12N16P: GCD = 4 (slightly rougher). 9N12P: GCD = 3.

### Pole Count and KV

More poles → lower synchronous speed for a given electrical frequency → lower KV for the same winding. Heavy-lift motors with many poles achieve low KV (100–800) without excessive turns of fine wire, enabling lower winding resistance and higher current capacity.

---

## KV Rating

KV is the no-load speed constant in RPM per volt. A 2300 KV motor at 16.8 V (4S fully charged) spins approximately 38,600 RPM unloaded; actual loaded RPM is lower.

KV is set by the number of winding turns per pole: more turns → lower KV → more torque at lower speed.

**KV and propeller size are inversely related.** A high-KV motor on a large prop draws excessive current, overheats, and stalls. A low-KV motor on a small prop never reaches the RPM required for meaningful thrust.

### KV–Voltage Relationship

| Battery | Nominal Voltage | Typical 5″ KV |
|---------|----------------|---------------|
| 4S | 14.8 V | 2300–2600 |
| 6S | 22.2 V | 1700–2100 |

The product `KV × voltage` should target the same RPM band regardless of cell count for a given propeller.

---

## Sensored vs. Sensorless Control

### Sensorless

The ESC infers rotor position from back-EMF (the voltage generated by spinning magnets as they pass windings). No physical sensors are required.

- Simpler, lighter, more reliable in high-vibration environments
- Performance degrades at very low RPM where back-EMF is too small to read accurately
- Requires a startup sequence (often audible as motor beeps) to synchronize commutation
- Standard for all hobby multirotor and FPV applications

### Sensored

Hall-effect sensors are embedded in the stator at 120° intervals. They directly detect rotor magnet position and report it to the ESC.

- Full torque and precise control from zero RPM
- No startup commutation problem; instant direction reversal
- Adds wiring complexity and sensor failure modes
- Required for: robotics joints, electric vehicles, precision industrial drives, some camera gimbal systems
- Rarely used in hobby UAVs; more common in commercial delivery drones with complex ground taxi requirements

---

## Construction Details

### Stator Laminations

The stator core is built from stacked silicon steel laminations. Eddy currents — induced by the alternating magnetic field — generate heat and loss; thinner laminations reduce eddy current paths.

| Lamination Thickness | Efficiency Impact |
|---------------------|------------------|
| 0.35 mm | Budget motors; acceptable up to ~20 kRPM |
| 0.2 mm | Mid-grade; reduced losses at 20–40 kRPM |
| 0.1 mm | Premium; optimized for high-RPM efficiency |

### Magnets

Magnets are sintered neodymium iron boron (NdFeB), graded by flux density and temperature resistance:

| Grade | Max Operating Temp | Notes |
|-------|-------------------|-------|
| N50, N52 | 80 °C | Standard; risk of demagnetization at sustained high temperature |
| N52H | 120 °C | High-temp variant; required for aggressive applications |
| N52SH | 150 °C | Superior temperature; used in premium racing and industrial motors |

Higher flux density grades (N54, N55) exist but are fragile and uncommon in production motors.

### Windings

- **Single-strand (magnet wire):** Better heat dissipation; handles higher continuous current; simpler to wind consistently
- **Multi-strand (Litz wire):** Reduces skin effect at high frequency; allows tighter slot fill; adds insulation mass
- **Winding turns (T):** More turns → lower KV → higher torque at lower speed; fewer turns → higher KV → higher speed

Slot fill factor (copper cross-section ÷ slot area) determines how much copper is in the motor. Premium hand-wound motors achieve 85–90% fill; machine-wound production motors typically reach 70–80%.

### Bearings

| Type | Characteristics | Use |
|------|----------------|-----|
| Steel ball bearings | Standard; good radial load | All hobby motors |
| Japanese bearings (NSK, NMB, EZO) | Tighter tolerances, longer life | Quality motors |
| Ceramic hybrid bearings | Lower friction, non-conductive | High-end/racing |
| Thrust bearings | Handle axial loads | Required in axial flux designs |

Standard hobbymotor bearing size: 9 × 4 mm or similar. Larger balls handle higher radial loads; smaller balls enable smoother high-RPM operation.

### Motor Shaft

| Shaft Type | Weight | Stiffness | Notes |
|-----------|--------|-----------|-------|
| Solid steel | Heaviest | Standard | Budget/mid motors |
| Hollow titanium | Lightest | Moderate | Premium; reduces unsprung mass |
| Steel-core titanium | Light | High | Best of both; titanium tube pressed over steel rod |

### CW / CCW Designation

CW and CCW motors differ only in prop shaft thread direction — not intrinsic spin direction (the ESC controls that). Reverse threading prevents the prop nut from loosening under gyroscopic reaction force. Standard quad layouts use two of each, positioned diagonally opposite.

---

## Stator Size and Frame Matching

The four-digit stator code encodes diameter and height in millimeters: a **2306** motor has a 23 mm diameter stator and 6 mm stack height.

- **Diameter** drives torque (larger moment arm for the magnetic field)
- **Height** drives power capacity (more copper, more heat absorption)

Stator volume approximation: `V = π × (diameter/2)² × height` — higher volume generally means more thrust capability and thermal headroom.

| Prop Size | Frame Class | Stator Size | KV Range |
|-----------|------------|-------------|----------|
| 1.2–1.6″ | Tiny whoop | 0702–1103 | 8,000–30,000 |
| 2.0″ | Cinewhoop / toothpick | 1003–1304 | 5,000–15,000 |
| 2.5–3.0″ | Small freestyle | 1203–1506 | 4,000–7,500 |
| 3.5–4.0″ | Mid freestyle / cine | 1404–2106 | 1,800–4,000 |
| 5.0″ | Standard freestyle / racing | 2207–2307 | 1,600–2,800 |
| 6.0–7.0″ | Long-range cruiser | 2306.5–2810 | 1,100–1,700 |
| 8–10″ | Heavy-lift / aerial photo | 2806–3110 | 800–1,300 |
| 12–15″ | Agricultural / delivery | varies | 60–800 |

## Prop–Motor–Battery Reference

Complete combinations by prop size, class, motor stator, KV, and battery cell count. Dry weight is the airframe without battery. Li-Ion cells noted where applicable; all others are LiPo.

| Prop | Class | Cell Count | Stator Size | KV | Battery (mAh) | Dry Weight |
|------|-------|-----------|------------|-----|--------------|-----------|
| 1.2″ triblade | Tiny whoop 65mm | 1S | 0702, 0802 | 23,000–30,000 | 260–450 | 16–22 g |
| 1.6″ triblade | Tiny whoop 75mm | 1S | 0802, 1002 | 20,000–23,000 | 450–550 | 20–30 g |
| 1.6″ triblade | Tiny whoop 75mm | 2S | 0802, 1002, 1102 | 12,000–14,000 | 450–650 | 30–50 g |
| 1.6″ triblade | Tiny whoop 75mm | 3S | 1102, 1103 | 8,000–11,000 | 300–650 | 40–70 g |
| 2.0″ triblade | Cinewhoop | 2S | 1003, 1103 | 11,000–15,000 | 450–650 | 70–90 g |
| 2.0″ triblade | Cinewhoop | 3S | 1103, 1104, 1203, 1303 | 6,000–7,500 | 450–650 | 80–100 g |
| 2.0″ triblade | Cinewhoop | 4S | 1303, 1304 | 5,000–6,000 | 450–720 | 120–140 g |
| 2.0″ triblade | Ultralight | 1S | 1002, 1003, 1102 | 20,000–23,000 | 450–650 | 30–40 g |
| 2.0″ triblade | Ultralight | 2S | 1002, 1003, 1103 | 10,000–14,000 | 450–650 | 30–50 g |
| 2.5″ triblade | Cinewhoop | 4S | 1404 | 4,500–5,000 | 650–850 | 140–180 g |
| 2.5″ triblade | Ultralight | 2S | 1203, 1204, 1303 | 7,500 | 450–650 | 55–70 g |
| 2.5″ triblade | Ultralight | 4S | 1404 | 4,500 | 450–850 | 140–180 g |
| 3.0″ triblade | Freestyle | 2S | 1303, 1404 | 4,500–5,500 | 550–650 | 70–100 g |
| 3.0″ triblade | Freestyle | 3S | 1303, 1404, 1407 | 4,000–5,000 | 550–850 | 90–200 g |
| 3.0″ triblade | Freestyle | 4S | 1404, 1407, 1506 | 3,000–4,200 | 450–850 | 140–260 g |
| 3.0″ triblade | Freestyle | 6S | 1506, 1507 | 2,700–3,000 | 550–850 | 150–280 g |
| 3.0″ triblade | Cinewhoop | 4S | 1404, 2004 | 3,000–4,000 | 850–1,300 | 180–300 g |
| 3.0″ triblade | Cinewhoop | 6S | 1404, 2004 | 2,500–3,000 | 850–1,300 | 180–300 g |
| 3.0″ two-blade | Long-range | 1S | 1103, 1202, 1203 | 10,000–12,000 | Li-Ion 2,500–3,000 | 60–80 g |
| 3.5″ triblade | Freestyle | 4S | 1404, 1504, 1604, 2004 | 3,500–4,000 | 850–1,000 | 150–200 g |
| 3.5″ triblade | Freestyle | 6S | 1504, 1604, 2004, 2006 | 2,500–3,000 | 850–1,000 | 150–200 g |
| 3.5″ triblade | Cinewhoop | 4S | 2004, 2006, 2106 | 2,500–3,500 | 1,000–1,500 | 250–350 g |
| 3.5″ triblade | Cinewhoop | 6S | 2004, 2006, 2106 | 1,800–2,500 | 1,000–1,300 | 250–350 g |
| 4.0″ triblade | Freestyle | 4S | 2004 | 2,400–3,000 | 850–1,000 | 120–200 g |
| 4.0″ triblade | Freestyle | 6S | 2004, 2106 | 1,800–2,500 | 650–850 | 120–180 g |
| 4.0″ two-blade | Long-range | 3S | 1404, 1504, 1604 | 3,000–4,000 | Li-Ion 2,500–3,000 | 120–150 g |
| 4.0″ two-blade | Long-range | 4S | 1404, 1504, 1604 | 2,500–3,000 | Li-Ion 2,500–3,000 | 150–200 g |
| 5.0″ triblade | Freestyle | 4S | 2207, 2208, 2306, 2308 | 2,300–2,700 | 1,300–1,500 | 300–450 g |
| 5.0″ triblade | Freestyle | 6S | 2207, 2208, 2306, 2308 | 1,700–2,100 | 1,000–1,300 | 300–450 g |
| 5.0″ triblade | Freestyle | 8S | 2207, 2208, 2306, 2308 | 1,500–1,700 | 1,000–1,100 | 300–450 g |
| 5.0″ triblade | Racing | 4S | 2207, 2208, 2306, 2308 | 2,500–3,000 | 1,300–1,500 | 250–300 g |
| 5.0″ triblade | Racing | 6S | 2207, 2208, 2306, 2308 | 1,900–2,300 | 1,000–1,300 | 250–300 g |
| 5.0″ two-blade | Ultralight | 4S | 2004, 2204, 2205 | 2,300–3,000 | 850–1,000 | 150–250 g |
| 5.0″ two-blade | Ultralight | 6S | 2004, 2204, 2205 | 1,600–2,300 | 650–850 | 150–250 g |
| 6.0″ triblade | Freestyle | 4S | 2207, 2208, 2308, 2407 | 2,100–2,500 | 1,300–1,800 | 300–450 g |
| 6.0″ triblade | Freestyle | 6S | 2207, 2208, 2308, 2407 | 1,500–1,900 | 1,000–1,500 | 300–450 g |
| 7.0″ triblade | Freestyle | 6S | 2806, 2807, 2808, 3106 | 1,200–1,400 | 2,200–3,000 | 400–500 g |
| 7.0″ two-blade | Long-range | 4S | 2806, 2807, 2808, 3106 | 1,600–1,900 | Li-Ion 2,500–4,000 | 350–500 g |
| 7.0″ two-blade | Long-range | 6S | 2806, 2807, 2808, 3106 | 980–1,300 | Li-Ion 2,500–4,000 | 350–500 g |
| 8.0″ | Long-range | 6S | 2808, 2810, 2814 | 900–1,200 | — | — |
| 10″ | Long-range | 6S | 2814, 3110, 3115, 3214 | 900 | — | — |
| 10″ | Long-range | 12S | 2814, 3110, 3115, 3214 | 450 | — | — |
| 13″ | Agricultural | 12S | varies | 330–360 | — | — |
| 15″ | Agricultural | 12S | varies | 250 | — | — |
| 24–28″ | Agricultural (small, <10 L) | 6S | 4114, 5010 | 150–200 | — | — |
| 28–32″ | Agricultural (medium, 10–30 L) | 12S | 6010, 6215 | 120–170 | — | — |
| 32–36″+ | Agricultural (large, >30 L) | 14S–16S | 8120, 9215 | 100–130 | — | — |

---

## Efficiency Metrics

Evaluate motors at **representative throttle points**, not just maximum thrust where efficiency drops sharply.

- **g/W (grams per watt):** Useful for comparing hover efficiency
- **g/A (grams per amp):** Useful when battery voltage is fixed
- **η = P_out / P_in:** Overall electrical-to-mechanical efficiency; quality motors reach 85–92% at optimal load

A motor that produces 12 g/W at 50% throttle but only 6 g/W at full throttle is optimized for endurance, not peak thrust. Match the efficiency curve to the flight profile.

---

## Thrust-to-Weight Requirements

| Use Case | TWR (total thrust : AUW) | Notes |
|----------|--------------------------|-------|
| Photography / cinematic | 3:1–4:1 | Stable hover, smooth response |
| Long-range / endurance | 2:1–3:1 | Cruise efficiency prioritized |
| Freestyle | 5:1–8:1 | Aggressive maneuvers |
| Racing | 10:1–14:1 | Maximum acceleration |

Total thrust is the sum across all motors. A 700 g freestyle quad targeting 6:1 TWR needs each of four motors to produce ≥ 1,050 g thrust.

---

## Motor Internal Resistance and No-Load Current

**Internal resistance (Rm):** Lower is better. Resistance converts current to heat; Rm should be specified at operating temperature (cold Rm is ~30% lower than hot). Values below 50 mΩ are typical for 5″ motors; racing motors often hit 20–30 mΩ.

**No-load current (I₀):** Current drawn at rated voltage with no propeller attached. Represents friction, windage, and iron losses. Lower I₀ indicates better bearing quality and lamination efficiency. Typical values: 0.3–1.5 A at 10 V.

---

## Failure Modes

| Symptom | Likely Cause |
|---------|-------------|
| Motor hot after short flight | KV too high for prop; excessive current draw |
| Gradual power loss over weeks | Magnet demagnetization from sustained overtemp |
| Vibration / grinding | Bearing failure; bent shaft; prop imbalance |
| One-phase stutter; won't spin up | Burnt winding; ESC phase FET failure |
| Cogging at low throttle | Normal for slotted motors; excessive if new — may indicate bearing binding |
| Bell wobble | Damaged or loose bearing; impact deformation |

Verify motor temperature after first full-throttle run. Above 65 °C after a 2-minute hover indicates the prop–motor–voltage combination is outside its efficiency band.

---

## Motor Type Selection Summary

| Requirement | Recommended Topology | Notes |
|-------------|---------------------|-------|
| Standard multirotor (5″) | Outrunner, slotted, sensorless, star | 12N14P; 2207–2307 stator |
| Cinematic / smooth low throttle | Outrunner, 18N or higher, sensorless, star | Higher pole count reduces cogging |
| Racing / peak thrust | Outrunner, sensorless, delta or star | Low-lamination, high slot fill |
| EDF / ducted fan | Inrunner, sensorless | High KV; fits within duct |
| Harsh environment / sealed | Inrunner, IP-rated | Higher pole count offsets low-torque limitation |
| Long-endurance fixed-wing | Outrunner or axial flux, star | Maximize g/W at cruise throttle |
| Large commercial UAV | Axial flux or high-pole inrunner | Weight budget dominates |
| Camera gimbal | Coreless or slotless outrunner, sensored | Cogging-free from zero RPM |
| Micro / nano (sub-65 mm) | Coreless | Scale advantage; lower complexity |

---

## Selection Workflow

1. **Fix frame size** → determines maximum prop diameter.
2. **Choose topology** → outrunner for direct-drive multirotor; inrunner for EDF or harsh environment; axial flux for mass-critical long-range; coreless for gimbal or micro.
3. **Choose winding config** → star for hover/efficiency; delta for peak-thrust/racing.
4. **Set battery voltage** → 4S for lighter builds, 6S for efficiency headroom.
5. **Calculate KV** → target RPM ÷ nominal voltage; select nearest standard.
6. **Verify pole–slot combo** → 12N14P or 12N16P for balanced cogging; higher N and P for cinematic smoothness.
7. **Confirm thrust table** → motor/prop/voltage combo meets TWR at acceptable current.
8. **Size ESC** → motor max continuous current + 20–30% margin.

---

## Related Concepts

- [Propellers](./propellers.md)
- [Propulsion System Design](./propulsion-system-design.md)
- [ESC](./esc.md)
- [Battery](../power-systems/battery.md)

## Sources

- [Oscar Liang – How to Choose FPV Drone Motors](https://oscarliang.com/motors/) — 2024
- [Mechtex – Types of BLDC Motors](https://mechtex.com/blog/types-of-bldc-motors) — 2024
- [Mechtex – Star vs Delta Winding Configurations](https://mechtex.com/blog/star-winding-vs-delta-winding-configurations-in-bldc-motors) — 2024
- [Ligpower – Outrunner vs Inrunner Brushless Motor](https://www.ligpower.com/blog/outrunner-brushless-motor-vs-inrunner.html) — 2024
- [Plettenberg Motors – Why Inrunners Are Growing in Popularity for UAV Applications](https://plettenbergmotors.com/why-inrunners-are-growing-in-popularity-for-uav-applications/) — 2024
- [Unmanned Systems Technology – Inrunner BLDC Motors for UAV Applications](https://www.unmannedsystemstechnology.com/feature/inrunner-bldc-motors-for-uav-applications/) — 2024
- [Zbotic – Coreless DC Motor for Drones and Robotics](https://zbotic.in/coreless-dc-motor-ultra-light-drone-robotics-applications/) — 2024
- [Lammotor – 11 Drone Motor Parameters](https://lammotor.com/11-drone-motor-parameters/) — 2024
- [Unmanned Tech – Motor Selection Guide by Frame Class](https://www.unmannedtechshop.co.uk/blogs/knowledge-base/motor-selection-guide-fpv-drones-by-class-frame-size) — 2024
- [T-Motor – Motor and Propeller Matching Guide](https://shop.tmotor.com/blog/drone-motor-propeller-matching-guide) — 2024
- [Oscar Liang – Prop, Motor, LiPo, and Weight Lookup Table](https://oscarliang.com/table-prop-motor-lipo-weight/) — 2024
- [Ligpower – Comprehensive Guide to Agriculture Drone Motors](https://www.ligpower.com/blog/comprehensive-guide-to-agriculture-drone-motors-2025.html) — 2025

<!-- linted: 2026-05-23 -->
