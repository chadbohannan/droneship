# Glossary

Definitions of abbreviations and technical terms used throughout the Drone Wiki.

## Overview

This glossary covers terminology from airframes, propulsion, flight controllers, GNSS/RTK positioning, radio systems, and drone programming. Terms are grouped alphabetically within each section. Cross-references link to full articles where deeper treatment exists.

Entries marked *(see also)* have a dedicated wiki article covering the concept in full.

---

## A

**Accuracy** — The closeness of a measurement to the true value. Distinct from [precision](#precision), which describes repeatability. RTK GPS achieves centimetre-level accuracy; single-point GPS is typically 1–3 m.

**ADC (Analog-to-Digital Converter)** — Hardware that converts continuous analog voltages to digital values. On the [Navio2](../flight-controller-hardware/navio2/navio2.md), a 6-channel ADC monitors battery voltage, current, and servo-rail voltage.

**Age of Corrections** — The elapsed time since the last correction packet was received by a rover from its base station. Standard RTK systems expect 1–2 s; values above 5 s degrade positioning accuracy.

**AHRS (Attitude and Heading Reference System)** — A sensor fusion algorithm combining accelerometer, gyroscope, and magnetometer data to produce roll, pitch, and yaw estimates. *(see also [Navio2 AHRS](../flight-controller-hardware/navio2/ahrs.md))*

**Antenna Phase Center** — The effective point in a GNSS antenna to which satellite signal reception is referenced. Varies slightly with signal frequency and elevation angle; high-accuracy surveys apply phase-center offsets.

**Antenna Reference Point (ARP)** — The physical center point on the bottom of a GNSS receiver used as a mechanical reference when measuring antenna height.

**AR Ratio** — The ratio of the second-best integer ambiguity solution to the best solution in RTK processing. A value above 3 is conventionally taken as a confident Fix; values below 3 indicate Float status.

**Arming** — The process of enabling motor output on a flight controller. ArduPilot requires pre-arm checks to pass (GPS lock, compass calibration, RC signal present) before arming is allowed. *(see also [Arming & Pre-Flight](../flight-controller-software/ardupilot/arming-preflight.md))*

---

## B

**Barometer** — A pressure sensor used by flight controllers to estimate altitude above the launch point. Absolute accuracy is ±10–30 m; relative accuracy between consecutive readings is ±0.1–0.3 m, sufficient for stable altitude hold. Sensitive to prop wash — mount in a vented foam-padded enclosure away from airflow.

**Base Station** — A static GNSS receiver at a known location that broadcasts correction data to a rover. Corrections cancel common-mode errors (atmospheric delays, satellite clock drift) shared by both receivers. *(see also [RTK GPS](../gnss/rtk-gps.md))*

**Baseline** — The distance between a GNSS base station and rover. RTK accuracy degrades with increasing baseline; practical limits are 10–30 km for single-band receivers and 60+ km for multi-band.

**BEC (Battery Eliminator Circuit)** — A voltage regulator that derives 5 V (or 3.3 V) from the main battery, eliminating the need for a separate receiver battery. Linear BECs are simple but inefficient; switching BECs are efficient but can introduce electrical noise.

**BeiDou** — China's global navigation satellite system (BDS), achieving global coverage in 2015. Designated B1/B2/B3 frequency bands. Supported by u-blox M8N and later receivers.

**Bidirectional DSHOT** — An extension of the DSHOT ESC protocol that allows ESCs to transmit motor eRPM back to the flight controller for RPM-based notch filtering and desync detection. *(see also [ESC](../propulsion/esc.md))*

**Brushless Motor** — A DC motor using electronic commutation (via ESC) rather than mechanical brushes. Dominant in hobby and commercial drones for their efficiency, power density, and longevity. *(see also [Brushless Motors](../propulsion/motors.md))*

---

## C

**C-Rating** — A multiplier expressing a battery's maximum continuous discharge current relative to its capacity. A 5000 mAh, 30C pack can sustain 150 A continuous discharge. *(see also [Battery](../power-systems/battery.md))*

**Companion Computer** — A single-board computer (e.g., Raspberry Pi, NVIDIA Jetson) mounted on an aircraft alongside the flight controller. Runs computationally intensive tasks (computer vision, path planning) and communicates via MAVLink. *(see also [Companion Computers](../flight-controller-software/ardupilot/companion-computers.md))*

**Carrier Phase** — The phase of the GNSS carrier wave (e.g., L1 at 1575.42 MHz, wavelength ≈ 19 cm) measured at the receiver. Carrier-phase measurements are far more precise than pseudorange (millimetre noise vs. metre noise) but include an unknown integer number of full wavelengths — the [integer ambiguity](#integer-ambiguity) — that must be resolved to achieve RTK Fix accuracy.

**CORS (Continuously Operating Reference Station)** — A network of fixed GNSS stations that provide real-time correction data over the internet, usable as a base station alternative for RTK rovers.

**CRSF (Crossfire Serial)** — A full-duplex serial RC protocol developed by Team BlackSheep for use with TBS Crossfire and Tracer radio links. Operates at 416700 or 3333333 baud; carries up to 16 channels plus telemetry in a single UART connection. Adopted by ExpressLRS as its native over-the-air frame format and widely supported in ArduPilot (RC_PROTOCOLS bitmask).

**Continuous AR Mode** — An RTK ambiguity-resolution strategy that solves integer ambiguities independently each [epoch](#epoch). More robust to [cycle slips](#cycle-slip) than Fix-and-Hold but slower to achieve Fix on noisy signals.

**Cycle Slip** — An abrupt jump in a GNSS receiver's carrier-phase measurement by an integer number of wavelengths, caused by momentary signal loss (obstruction, multipath, or low SNR). Cycle slips reset the ambiguity resolution process; Fix-and-Hold mode is more susceptible to false fixes after a slip than Continuous mode.

---

## D

**Dilution of Precision (DOP)** — A dimensionless scalar evaluating satellite geometry quality. Lower DOP values indicate better positioning geometry. PDOP (Position Dilution of Precision) < 2 is considered excellent; values > 6 degrade accuracy significantly. HDOP (horizontal) and VDOP (vertical) decompose position error into planar and altitude components.

**DroneCAN** — A lightweight, fault-tolerant CAN bus protocol for drone peripherals (ESCs, GPS, airspeed sensors). Formerly called UAVCAN v0. *(see also [CAN/DroneCAN](../flight-controller-software/ardupilot/can-dronecan.md))*

**DSHOT** — A digital serial protocol between flight controllers and ESCs. Versions: DSHOT150, 300, 600, 1200 (speed in kbit/s). Eliminates calibration drift inherent in analog PWM. *(see also [ESC](../propulsion/esc.md))*

---

## E

**EKF (Extended Kalman Filter)** — A recursive state estimator fusing IMU, GPS, barometer, compass, and optical-flow data into a position/velocity/attitude estimate. ArduPilot uses EKF3 by default. *(see also [EKF & Navigation](../flight-controller-software/ardupilot/ekf-navigation.md))*

**Elevation Mask** — A GNSS receiver setting that excludes satellites below a specified elevation angle (default: 15°). Satellites near the horizon have longer signal paths through the atmosphere, increasing multipath and delay errors.

**ELRS (ExpressLRS)** — An open-source long-range RC link protocol using LoRa modulation. Operates at 900 MHz or 2.4 GHz; achieves 100–500 mW link budgets and packet rates from 25 Hz to 1000 Hz selectable by the user. Uses CRSF as its serial protocol to the flight controller. Common in long-range fixed-wing and freestyle builds.

**Epoch** — A single measurement interval in a GNSS receiver's processing cycle. At 5 Hz update rate, one epoch occurs every 200 ms. RTK ambiguity resolution operates epoch-by-epoch; "continuous" mode re-solves ambiguities each epoch independently.

**eRPM (Electrical RPM)** — RPM measured in electrical cycles per minute, equal to mechanical RPM multiplied by the number of motor pole pairs. Reported by ESCs using Bidirectional DSHOT.

**ERB (Emlid Reach Binary)** — A compact binary protocol used by Emlid Reach receivers to stream position data to ArduPilot over serial.

**ESC (Electronic Speed Controller)** — Converts flight-controller PWM/DSHOT signals into three-phase AC current to drive brushless motors. *(see also [ESC](../propulsion/esc.md))*

---

## F

**Failsafe** — Automated flight-controller response to a lost signal or low-battery condition (e.g., Return-to-Launch, land, or hold position). *(see also [Failsafes](../flight-controller-software/ardupilot/failsafes.md))*

**Fix** — In RTK positioning, the highest-quality solution status indicating integer ambiguities have been resolved. Typically yields horizontal accuracy of 1–2 cm. Requires AR ratio > 3.

**Fix-and-Hold** — An RTK ambiguity-resolution strategy that constrains ambiguities once a Fix is achieved. More stable than Continuous mode in noisy conditions but slower to recover after signal loss.

**Flight Controller** — The autopilot hardware running firmware (ArduPilot, PX4, Betaflight) that stabilises and navigates the aircraft. Integrates IMU, barometer, compass, and GPS.

**Float** — An RTK solution status where ambiguities are estimated as real numbers rather than resolved to integers. Accuracy is typically 0.1–0.5 m, significantly worse than Fix.

**FPV (First-Person View)** — Video transmission from a camera mounted on the drone to pilot goggles or a monitor, enabling remote piloting from the aircraft's perspective.

---

## G

**Galileo** — The European Union's global navigation satellite system, reaching full operational capability in 2016. Operates on E1/E5a/E5b/E6 bands.

**GCP (Ground Control Point)** — A surveyed reference point on the ground with known coordinates, used to georeference aerial maps produced by photogrammetry.

**GCS (Ground Control Station)** — Software (Mission Planner, QGroundControl, MAVProxy) used to plan missions, monitor telemetry, and configure flight controllers. *(see also [GCS](../flight-controller-software/ardupilot/gcs.md))*

**Geofence** — A virtual boundary enforced by the flight controller to contain or exclude aircraft from defined areas. *(see also [Geofence](../flight-controller-software/ardupilot/geofence.md))*

**GIS (Geographic Information System)** — Software for collecting, storing, analysing, and visualizing spatial data. Output of drone mapping missions is often imported into a GIS.

**GLONASS** — Russia's Global Navigation Satellite System, operated since 1982. Uses FDMA (frequency-division) rather than CDMA like GPS; designated G1/G2 frequency bands.

**GNSS (Global Navigation Satellite System)** — The umbrella term for all satellite-based positioning systems: GPS, GLONASS, Galileo, BeiDou, QZSS, and NavIC. *(see also [RTK GPS](../gnss/rtk-gps.md))*

**GPS (Global Positioning System)** — The United States satellite navigation system, operational since 1978. Defined in WGS 84. L1 (1575.42 MHz) and L2/L5 frequencies.

**Ground Plane** — A conductive plate placed under a GNSS antenna to reduce multipath from reflections below the antenna. Minimum recommended size: 70 × 70 mm.

---

## H

**HAL (Hardware Abstraction Layer)** — A software layer separating flight-controller firmware from hardware specifics. ArduPilot's AP_HAL allows the same firmware to run on diverse platforms. *(see also [AP_HAL](../flight-controller-software/ardupilot/ap-hal.md))*

**Hot-Shoe Adapter** — A camera sync adapter that triggers a GNSS time-mark signal at the moment of each photo, enabling precise geotagging for PPK mapping. *(see also [PPK](../gnss/ppk.md))*

---

## I

**IMU (Inertial Measurement Unit)** — A sensor package combining accelerometer and gyroscope (and optionally magnetometer) to measure linear acceleration and angular rates. *(see also [Navio2 IMU](../flight-controller-hardware/navio2/imu.md))*

**Integer Ambiguity** — In RTK/carrier-phase GNSS, the unknown integer number of full carrier wavelengths in the signal path between satellite and receiver. Resolving it to a fixed integer value enables centimetre-level positioning.

**Ionospheric Delay** — Delay the ionosphere (60–1000 km altitude) introduces into GNSS signals by slowing propagation through free electrons. One of the largest GNSS error sources (up to 10 m on L1 at high solar activity); dual-band receivers model it directly from frequency dispersion; RTK cancels most of it by differencing signals common to base and rover.

---

## K

**KV Rating** — Motor speed constant, expressing revolutions per minute per volt of applied voltage (RPM/V) under no load. A 2300 KV motor on 12 V produces ~27,600 RPM unloaded. *(see also [Brushless Motors](../propulsion/motors.md))*

---

## L

**LiPo (Lithium Polymer)** — The dominant battery chemistry in hobby drones. Nominal cell voltage: 3.7 V; fully charged: 4.20 V; storage voltage: 3.80–3.85 V; minimum safe discharge: 3.5 V. *(see also [Battery](../power-systems/battery.md))*

**LoRa (Long Range)** — A radio modulation scheme using spread-spectrum chirp, enabling kilometre-scale low-power links. Emlid Reach modules use LoRa for base-to-rover correction links up to 19 km.

**LPF (Low-Pass Filter)** — A signal-processing filter that passes frequencies below a cutoff frequency and attenuates those above it. ArduPilot applies LPFs in its IMU pipeline to remove high-frequency vibration noise before PID loops; typical gyro LPF cutoffs range from 80–200 Hz. *(see also [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md))*

---

## M

**Magnetometer (Compass)** — A sensor measuring Earth's magnetic field to determine heading. Subject to interference from motor currents; typically mounted on a mast or external GPS puck to increase separation from power wiring.

**MAVLink** — A lightweight binary telemetry protocol for UAV communication. Defines message types for telemetry, commands, parameters, and missions. *(see also [MAVLink](../flight-controller-software/ardupilot/mavlink.md))*

**Multi-band Receiver** — A GNSS receiver that tracks signals on two or more frequency bands (e.g., L1+L2, L1+L5). Multi-band receivers model the ionospheric delay directly, resolving integer ambiguities faster and supporting longer baselines than single-band units.

**Multipath** — GNSS signal error caused by reflections from nearby surfaces (ground, buildings, aircraft body) arriving at the antenna via indirect paths, adding false delay to the measurement. Reduced by ground planes, elevated antenna placement, and elevation masking.

---

## N

**NMEA 0183** — The industry-standard ASCII sentence format for GNSS position output. Sentences include GGA (position), RMC (position+velocity), and GSA/GSV (satellite status). Most autopilots accept NMEA on a serial port.

**Notch Filter** — A narrow band-stop filter that attenuates a specific frequency. ArduPilot uses static and dynamic (RPM-tracking) notch filters to suppress motor-frequency vibration. *(see also [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md))*

**NTRIP (Networked Transport of RTCM via Internet Protocol)** — A protocol for streaming GNSS correction data over the internet. Rovers connect to an NTRIP caster (e.g., CORS network) to receive corrections from a distant base.

---

## O

**Optical Flow** — A sensor (downward-facing camera + sonar) that measures ground-relative velocity by comparing successive image frames. Enables GPS-denied position hold at low altitude. *(see also [Optical Flow](../flight-controller-software/ardupilot/optical-flow.md))*

---

## P

**PID (Proportional-Integral-Derivative)** — A feedback control algorithm computing corrective output from the weighted sum of error, accumulated error, and rate of change of error. Flight controllers use PIDs for stabilisation and navigation. *(see also [PID Tuning](../flight-controller-software/ardupilot/pid-tuning.md))*

**PPK (Post-Processed Kinematic)** — A GNSS technique where base and rover raw logs are combined after a flight in RTKLIB to produce centimetre-accurate trajectories. Requires no real-time data link. *(see also [PPK](../gnss/ppk.md))*

**PPM (Pulse-Position Modulation)** — A legacy RC signal format encoding up to 8 channels in a single wire by varying pulse timing. Superseded by SBUS and digital protocols for most applications.

**Pseudorange** — A GNSS range measurement derived from the signal travel time multiplied by the speed of light. Called "pseudo" because it includes receiver clock error and atmospheric delays not yet corrected. Pseudorange accuracy is 0.3–3 m; [carrier phase](#carrier-phase) measurements are three orders of magnitude more precise but ambiguous.

**PPP (Precise Point Positioning)** — A single-receiver GNSS technique achieving centimetre-level accuracy using precise satellite orbit and clock products rather than a local base station. Requires hours of data collection.

**Precision** — The closeness of repeated measurements to each other, independent of their accuracy. A well-calibrated system can be both accurate and precise; a noisy system may be accurate on average but imprecise.

**PWM (Pulse-Width Modulation)** — The legacy RC signal format encoding commands as pulse widths (1000–2000 µs). Used for servo and ESC control. Replaced by DSHOT for ESC communication in modern builds.

---

## Q

**QZSS (Quasi-Zenith Satellite System)** — Japan's regional navigation satellite system serving the Asia-Pacific region with additional satellites at high elevation angles, improving urban-canyon GNSS availability.

---

## R

**RINEX (Receiver Independent Exchange Format)** — A standard text format for storing raw GNSS observations (pseudorange, carrier phase, Doppler). Base and rover RINEX logs are the inputs to RTKPOST for PPK processing.

**RMS (Root Mean Square)** — A statistical measure of position error: the square root of the mean of squared deviations. Used to characterise GNSS solution accuracy.

**Rover** — A moving GNSS receiver that receives corrections from a base station to compute precise position in real time (RTK) or in post-processing (PPK). *(see also [RTK GPS](../gnss/rtk-gps.md))*

**RPM Filter** — See *Notch Filter*. In ArduPilot, the RPM-based dynamic notch filter tracks motor eRPM via Bidirectional DSHOT to adaptively suppress motor harmonics.

**RTCM3** — The industry-standard binary format for differential GNSS corrections. Transmitted by base stations to rovers via serial, LoRa, NTRIP, or TCP.

**RTK (Real-Time Kinematic)** — A GNSS technique using carrier-phase measurements and real-time base corrections to achieve centimetre-level accuracy. Solution quality reported as Single / Float / Fix. *(see also [RTK GPS](../gnss/rtk-gps.md))*

**RTKLIB** — An open-source GNSS processing suite providing RTKPOST (PPK processing), RTKPLOT (trajectory visualisation), RTKCONV (format conversion), and RTKNAVI (real-time processing). *(see also [PPK](../gnss/ppk.md))*

---

## S

**SBUS** — A Futaba serial RC protocol transmitting up to 16 channels at 100000 baud, inverted logic. Widely supported by flight controllers. Replaces PPM for multi-channel RC input.

**Single** — The lowest RTK solution status, using pseudorange only without differential corrections. Accuracy is 1–5 m, similar to consumer GPS.

**SITL (Software In The Loop)** — A simulation mode where flight-controller firmware runs on a PC, interfacing with a simulated vehicle. Enables development and testing without hardware. *(see also [Navio2 SITL](../flight-controller-hardware/navio2/navio2-sitl.md))*

**SNR (Signal-to-Noise Ratio)** — The ratio of useful GNSS signal power to noise power. Values above 45 dB-Hz indicate strong reception and are highlighted green in Emlid tools; below 35 dB-Hz triggers SNR masking.

**SNR Mask** — A GNSS receiver filter that excludes satellites with SNR below a threshold (default: 35 dB-Hz) from position solutions, reducing multipath-corrupted measurements.

**Solution Status** — The quality classification of an RTK position fix: **Single** (1–5 m), **Float** (0.1–0.5 m), **Fix** (0.01–0.02 m).

---

## T

**TCP (Transmission Control Protocol)** — A reliable, ordered network protocol used to stream GNSS corrections or MAVLink telemetry between devices on the same network or over the internet.

**Telemetry Radio** — A low-power radio link (typically 433 MHz or 915 MHz) providing bidirectional MAVLink communication between aircraft and GCS. *(see also [Telemetry Radios](../flight-controller-software/ardupilot/telemetry-radios.md))*

**Thrust-to-Weight Ratio (TWR)** — Total maximum thrust divided by all-up weight. A TWR of 2:1 is a practical minimum for agile multirotor flight; racing quads may exceed 10:1. *(see also [Propulsion System Design](../propulsion/propulsion-system-design.md))*

**Time Mark** — A precise timestamp logged by a GNSS receiver at the moment a camera shutter fires, used in PPK workflows to associate each photo with a centimetre-accurate position. *(see also [PPK](../gnss/ppk.md))*

**Tropospheric Delay** — Delay the neutral troposphere (0–10 km altitude) introduces into GNSS signals by slowing their propagation through moist air. Standard atmospheric models approximate this correction; RTK partially cancels residual error by differencing signals common to base and rover.

---

## U

**UBX** — The proprietary binary protocol used by u-blox GNSS receivers for raw data logging and configuration. RTKCONV processes UBX files to RINEX for PPK.

**Update Rate** — The frequency at which a GNSS receiver outputs a position solution, in Hz. ArduPilot recommends 5–10 Hz for rover/aircraft GPS; 1 Hz suffices for a static base station.

---

## V

**VRS (Virtual Reference Station)** — A synthetic reference station generated by a CORS network near the rover's position, reducing effective baseline length for long-range RTK without a local physical base.

**Vibration Isolation** — Physical damping mounts (foam, gel, O-rings) between the flight controller and airframe that attenuate high-frequency motor vibration before it reaches IMU sensors. *(see also [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md))*

---

## W

**WGS 84 (World Geodetic System 1984)** — The reference ellipsoid and coordinate datum used by GPS. Defines geocentric latitude, longitude, and ellipsoidal height. Position error in the WGS 84 frame itself is less than 2 cm.

---

## Related Concepts

- [RTK GPS](../gnss/rtk-gps.md)
- [PPK — Post-Processed Kinematic](../gnss/ppk.md)
- [Emlid Reach M+ and M2](../gnss/reach-m.md)
- [ESC — Electronic Speed Controller](../propulsion/esc.md)
- [Brushless Motors](../propulsion/motors.md)
- [Battery](../power-systems/battery.md)
- [ArduPilot](../flight-controller-software/ardupilot.md)
- [Vibration, Filtering, and Tuning](../flight-controller-software/vibration-filtering-and-tuning.md)
- [Navio2](../flight-controller-hardware/navio2/navio2.md)

## Sources

- [RTK Modules Glossary — Emlid Docs](https://docs.emlid.com/reach/reference/glossary/) — 2026-05-23
- [Reach RS/RS+ Glossary — Emlid Docs](https://docs.emlid.com/reachrs/reference/glossary/) — 2026-05-23

<!-- linted: 2026-05-23 (pass 2) -->
