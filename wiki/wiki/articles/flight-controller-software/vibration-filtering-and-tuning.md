# Vibration, Filtering, and Tuning

Frame resonance and motor/propeller vibration are the primary source of noise that degrades PID loop performance. Understanding the frequency domain — where noise originates, how it propagates, and how filters attenuate it — is prerequisite to systematic tuning.

## Overview

A drone's flight controller samples its gyroscope thousands of times per second and feeds that data into the PID controller, which issues motor commands. Any vibration that the gyroscope cannot distinguish from real angular motion is treated as a flight error, causing the PID controller to fight phantom movements. The result is motor heat, increased current draw, oscillation, and at the extreme, uncontrollable resonance divergence. Filtering sits between the raw gyro signal and the PID loops; it removes noise while introducing delay (latency). Every filter decision is a tradeoff between noise rejection and control responsiveness.

## Noise Sources and Frequency Bands

On a typical 5″ quadcopter, noise occupies predictable frequency ranges:

| Frequency Band | Source |
|----------------|--------|
| < 20 Hz | Actual flight motion — do not filter |
| 20–100 Hz | Propwash, PID oscillation, ESC or RC link timing issues |
| 100–250 Hz | Frame structural resonance, loose hardware |
| > 250 Hz | Motor and propeller noise, harmonics |

These bands shift with frame size and motor KV. Larger, slower frames push motor noise lower; smaller, higher-KV builds can push it above 400 Hz.

## Motor Noise: Frequencies and Harmonics

Motor noise frequency scales directly with throttle. As RPM increases, the fundamental noise frequency and its harmonics sweep upward.

**Fundamental motor noise frequency:**

```
f_motor (Hz) = RPM / 60 × (pole_pairs)
```

where `pole_pairs = motor_poles / 2`.

A 14-pole motor (7 pole pairs) at 20,000 RPM:

```
f_motor = (20,000 / 60) × 7 = 2,333 Hz   (electrical frequency)
```

The mechanical (structural vibration) frequency seen by the IMU is the rotational frequency:

```
f_mech (Hz) = RPM / 60
```

Same motor: `f_mech = 333 Hz`

Harmonics are integer multiples: 333 Hz, 666 Hz, 999 Hz, etc. Two-blade propellers produce stronger harmonics than three-blade; three-blade distributes energy across more frequencies at lower individual amplitude.

**Blade pass frequency** (tonal aerodynamic noise):

```
f_BPF (Hz) = (RPM / 60) × blade_count
```

This contributes to acoustic noise and low-level IMU excitation, typically 100–400 Hz for small drones.

**Identifying motor noise in blackbox data:** Motor noise appears as a diagonal line in a frequency-vs-throttle heatmap — frequency rises with throttle. Frame resonance appears as a horizontal line — fixed frequency independent of throttle. Propwash and PID oscillations appear as a diffuse cloud below 100 Hz.

## Frame Resonance

Every frame has structural resonant frequencies determined by:

- **Arm stiffness** (material, thickness, length)
- **Joint stiffness** (standoff torque, plate contact area)
- **Attached mass** (motor, battery, camera)

Carbon fiber arms on 5″ frames typically resonate between 100–300 Hz. This overlaps the upper motor noise band, making it one of the harder noise sources to isolate. Damage to a frame lowers its resonant frequency; a crack in an arm can shift resonance from 250 Hz into the 80–150 Hz range, suddenly degrading a previously well-tuned quad.

Physical remedies before software:

1. Check arm screws and motor mount screws for tightness.
2. Inspect props for damage — a 0.5 mm bent blade at 25,000 RPM causes massive vibration.
3. Use soft-mounted flight controllers (silicone grommets or foam tape) to break the mechanical vibration path.
4. File all carbon fiber edges to reduce delamination and micro-crack propagation.

## Filter Types

### Low-Pass Filter (LPF)

Passes frequencies below a cutoff; attenuates above it. Applied to the gyro signal (gyro LPF) and separately to the D-term (D-term LPF, since D amplifies high-frequency noise by differentiation).

**Latency introduced by a biquad LPF:**

| Cutoff (Hz) | Approximate Delay |
|-------------|-------------------|
| 30 | ~8 ms |
| 60 | ~3.8 ms |
| 120 | ~1.9 ms |

Even 1 ms of additional latency measurably affects the maximum stable P gain. Raising the LPF cutoff reduces latency at the cost of more noise reaching the PID loops.

**Betaflight parameters:** `gyro_lpf2_hz`, `dterm_lpf_hz`, `dterm_lpf2_hz`  
**PX4 parameters:** `IMU_GYRO_CUTOFF`, `IMU_DGYRO_CUTOFF`  
**ArduPilot parameters:** `INS_GYRO_FILTER`

### Notch Filter

A notch filter (band-stop filter) sharply attenuates a narrow frequency band while leaving frequencies above and below unaffected. It is the right tool for known, discrete resonance peaks (frame resonance, specific harmonic).

**Key parameters:**

| Parameter | Effect |
|-----------|--------|
| Center frequency | The frequency to attenuate |
| Q factor | Sharpness of the notch — higher Q = narrower bandwidth, less latency, more precise targeting |
| Bandwidth | Frequency range of attenuation: `BW = center_freq / Q` |

Typical Q range: 350–700. At Q=500 and 200 Hz center, bandwidth ≈ 0.4 Hz — a very narrow, efficient cut.

### Dynamic Notch Filter

A dynamic notch automatically tracks the center frequency of a noise peak as it moves with RPM. Used to follow motor noise as throttle changes. Betaflight's dynamic notch uses an FFT to locate the peak in real time; ArduPilot's `INS_HNTCH` uses ESC telemetry or in-flight FFT.

With RPM filtering active, the dynamic notch can be configured with a single notch at higher Q (Betaflight: 500–700) since it only needs to catch frame resonance — motor noise is handled by RPM filtering.

### RPM Filter (Motor Frequency Notch)

The most effective filter in modern FPV tuning. Uses ESC telemetry (BLHeli_32, AM32, or Bidirectional DSHOT) to read actual motor RPM and place a notch precisely on the motor noise frequency and its harmonics — updated in real time.

This eliminates the fundamental, 2nd, and 3rd harmonics for each motor independently. Because it tracks each motor, it handles the case where motors run at different RPMs (e.g., during a tight turn).

**Typical configuration (Betaflight):**

| Parameter | Recommended Value | Notes |
|-----------|-------------------|-------|
| Harmonics | 3 | Reduce to 2 only if 3rd harmonic is negligible |
| Min RPM frequency | 20 Hz below where motor noise starts | Catch bent-prop noise at low throttle |
| Q value | 500 (default) | Raise to 600–700 for less latency on clean builds |

**ArduPilot equivalent:** `INS_HNTCH_MODE=3` (ESC telemetry), `INS_HNTCH_HMNCS` for harmonic count.

RPM filtering requires:
- Bidirectional DSHOT enabled in Betaflight (`motor_poles` must be set correctly)
- ESC firmware supporting telemetry (BLHeli_32, AM32)

## Filter Stack: Recommended Architecture

A well-ordered filter stack for a modern 5″ build with RPM filtering enabled:

```
Raw gyro
  → Gyro LPF1 (anti-aliasing, fixed ~500 Hz at 4K loop)
  → RPM Filter (per-motor notches, 3 harmonics)
  → Dynamic Notch (1–2 notches, Q=500–700, targets frame resonance)
  → Gyro LPF2 (optional; raise or disable on clean builds)
  → PID loops
       └─ D-term → D-term LPF (independent, lower cutoff acceptable)
```

Without RPM filtering (legacy or no telemetry ESCs):

```
Raw gyro
  → Dynamic Notch (5 harmonics, Q=350, Min=100 Hz)
  → Gyro LPF1 (~200 Hz)
  → Gyro LPF2 (~150–200 Hz)
  → PID loops
```

## Spectral Analysis Workflow

The tuning process is: **fly → log → analyze → adjust → repeat.**

1. **Enable blackbox logging** at full gyro rate. Log `gyroADC`, `gyroUnfiltered`, `motor`.
2. **Open in PIDtoolbox or Blackbox Explorer.** Generate a frequency vs. throttle heatmap.
3. **Identify features:**
   - Diagonal lines → motor noise (fundamental + harmonics)
   - Horizontal lines → frame resonance
   - Low-frequency diffuse cloud → propwash or PID oscillation
4. **Set RPM filter min frequency** below the lowest diagonal line at minimum throttle.
5. **Set dynamic notch range** to bracket each horizontal resonance line with ±20–30 Hz margin.
6. **Raise LPF cutoffs** incrementally until noise floor rises to an acceptable level.
7. **Re-fly and log.** Check motor temperature after a 2-minute punch-out session — hot motors indicate residual noise.

**Post-filter noise targets (5″ race/freestyle build):**

| Signal | Noise Floor Target |
|--------|--------------------|
| Filtered gyro (> 50 Hz) | < −30 dB |
| D-term (> 50 Hz) | < −10 dB |

Exceeding these targets indicates mechanical issues that software cannot fully compensate.

## Over-Filtering

Over-filtering is a common mistake. Removing too much noise with low LPF cutoffs introduces enough latency that the PID controller can no longer correct disturbances in time, causing low-frequency (< 100 Hz) oscillations that look like noise but are actually phase-delayed P or D responses. Symptoms:

- Wobbles visible in FPV footage that disappear when P or D is reduced.
- Motor temperatures high despite clean-looking gyro traces.
- Filtering delay visible as gap between `gyroUnfiltered` and `gyro` traces in blackbox.

The fix is to raise LPF cutoffs and use narrower, targeted notch filters rather than broad low-pass suppression.

## Firmware Filter Parameters (Quick Reference)

### Betaflight

| Parameter | Purpose | Typical Value |
|-----------|---------|---------------|
| `gyro_lpf2_hz` | Gyro second low-pass cutoff | 500 Hz (4K loop) |
| `dterm_lpf_hz` | D-term first low-pass | 100–150 Hz |
| `dterm_lpf2_hz` | D-term second low-pass | 150–200 Hz |
| `dyn_notch_q` | Dynamic notch Q factor | 500 |
| `dyn_notch_min_hz` | Dynamic notch lower bound | 100 Hz |
| `dyn_notch_max_hz` | Dynamic notch upper bound | 350–500 Hz |
| `dyn_notch_count` | Number of dynamic notches | 1 (with RPM filter) |
| `motor_poles` | Pole count for RPM filter | Per motor spec |
| `rpm_filter_harmonics` | RPM notch harmonic count | 3 |
| `rpm_filter_q` | RPM notch Q factor | 500 |

### ArduPilot (Copter)

| Parameter | Purpose |
|-----------|---------|
| `INS_HNTCH_ENABLE` | Enable harmonic notch 1 |
| `INS_HNTCH_MODE` | Frequency source (3 = ESC telemetry, 4 = FFT) |
| `INS_HNTCH_FREQ` | Base frequency (throttle mode) |
| `INS_HNTCH_HMNCS` | Harmonic bitmask (7 = 1st+2nd+3rd) |
| `INS_HNTCH_ATT` | Attenuation in dB (default 40) |
| `INS_HNTCH_BW` | Notch bandwidth in Hz |
| `INS_GYRO_FILTER` | Gyro low-pass cutoff |

### PX4

| Parameter | Purpose |
|-----------|---------|
| `IMU_GYRO_CUTOFF` | Gyro LPF cutoff (Hz) |
| `IMU_DGYRO_CUTOFF` | D-term LPF cutoff (Hz) |
| `IMU_GYRO_NF0_FRQ` | Static notch 1 center frequency |
| `IMU_GYRO_NF0_BW` | Static notch 1 bandwidth |
| `IMU_GYRO_DNF_EN` | Dynamic notch enable bitmask |
| `IMU_GYRO_DNF_HMC` | Dynamic notch harmonic count |

## Related Concepts

- [Airframes](../airframes/airframes.md) — Frame stiffness, material, arm thickness effects on resonance
- [Rotor Configurations](../airframes/rotor-configurations.md) — Motor count and geometry effects on vibration
- [ArduPilot](ardupilot.md) — Overview and article map for all ArduPilot topics
- [ESC — Electronic Speed Controller](../propulsion/esc.md) — Motor poles, KV, and their effect on noise frequency; bidirectional DShot and telemetry required for RPM filtering

## Sources

- [How to Tune FPV Drone Filters & PID with Blackbox — Oscar Liang](https://oscarliang.com/pid-filter-tuning-blackbox/) — 2026-05-21
- [Managing Gyro Noise with Dynamic Harmonic Notch Filters — ArduPilot](https://ardupilot.org/copter/docs/common-imu-notch-filtering.html) — 2026-05-21
- [MC Filter Tuning & Control Latency — PX4](https://docs.px4.io/main/en/config_mc/filter_tuning) — 2026-05-21
- [Noise Analysis — BlackBox Mate Wiki](https://pitronic.gitbook.io/bbm/advance-topics/noise-analysis) — 2026-05-21

<!-- linted: 2026-05-23 -->
