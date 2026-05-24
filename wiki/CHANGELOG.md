# Changelog

## 2026-05-24 — Compass sensor content lint & refine

Refined compass/magnetometer coverage using source detail from the ardupilot `AP_Compass` library (verified via code-rag).

- `sensors.md`: expanded the Compass section — added hard-iron vs. soft-iron distortion theory (`COMPASS_OFS_*` offsets vs. `COMPASS_DIA_*`/`COMPASS_ODI_*` elliptical correction), a CompassMot motor-compensation subsection, calibration fitness scoring, the ~200–800 mGauss field sanity band, and added `COMPASS_OFFS_MAX`/`COMPASS_MOTCT` parameter rows.
- `imu.md` (Navio2): clarified motor-compensation guidance (`COMPASS_MOTCT = 2`) and cross-linked the canonical Sensors compass procedure instead of duplicating it.
- `first-flight.md`: resolved a contradiction — corrected the stated `COMPASS_OFFS_MAX` default from 850 to the current 1800 and cross-linked the Sensors compass section.

## 2026-05-23 — Full wiki lint

All 65 articles linted across all 6 passes (Structure, Completeness, Contradictions, Enrichment, Cross-links, Prose).

**Key fixes:**
- `vibration-filtering-and-tuning.md`: removed erroneous `*(stub)*` label from ArduPilot link; merged duplicate ESC entry in Related Concepts into a single descriptive line.
- `power-system.md` (Navio2): corrected parameter name `BATT_CURR_MULT` → `BATT_AMP_PERVLT` throughout; added note that the parameter was renamed in ArduPilot 4.0.
- `navio2-python.md`: corrected code comment referencing old `BATT_CURR_MULT` parameter name.
- `sensors.md`: added Unit column to IMU, Compass, Barometer, and Rangefinder parameter tables.
- `motor-mixing.md`: added Unit column to Motor Spin parameters and Battery Voltage Compensation tables.
- `gps-gnss.md`: added Default and Unit columns to Key Parameters and Dual GPS Blending tables.
- `optical-flow.md`: added Default and Unit columns to FlowHold parameters table.
- `lua-scripting.md`: added Unit column to SCR_* parameters table.
- `airframes.md`: added cross-links on first mention of motors, ESC, battery; added Brushless Motors and Propellers to Related Concepts.
- Updated linted date from 2026-05-21/22 to 2026-05-23 on all 55 articles that had stale dates.

**Contradictions resolved:** None found beyond the `BATT_CURR_MULT` vs `BATT_AMP_PERVLT` naming issue already listed above.

**No new stubs created.** All referenced articles exist.

## 2026-05-23 (SITL — lint, enrich, cross-reference)
- Linted wiki/articles/flight-controller-software/ardupilot/sitl.md: cross-linked first occurrences of MAVLink, EKF, Lua, GCS, MAVProxy, parameters, build system, AP_HAL, Gazebo, ROS, logging, pymavlink.
- Enriched `sim_vehicle.py` flags table (`-L`, `-I`, `-D`, `--valgrind`); added Failure Injection section covering `SIM_GPS_DISABLE`, `SIM_GPS_GLITCH_*`, `SIM_RC_FAIL`, `SIM_BARO_DISABLE`, `SIM_MAG_FAIL`, `SIM_BATT_VOLTAGE`, `SIM_WIND_*`, `SIM_ENGINE_FAIL`, `SIM_VIB_FREQ_*`, `SIM_SPEEDUP`.
- Added Multi-Vehicle Simulation section; renamed/clarified Hardware-in-the-Loop section as Simulation on Hardware vs deprecated classic HITL.
- Added back-links from pymavlink, ekf-navigation, parameters, logging to sitl.

## 2026-05-23 (PID Tuning — added Tuning in SITL section)
- Added `## Tuning in SITL` section to wiki/articles/flight-controller-software/ardupilot/pid-tuning.md covering AutoTune-in-sim, `SIM_*` disturbance/plant-variation parameters, replay-based EKF/notch filter tuning, frequency-domain (FFT) workflow, and autotest-driven gain sweeps.
- Added FDM-transfer caveat: SITL gains are starting points/ratios, not final values.
- Cross-linked SITL in Related Concepts; added two ArduPilot dev-docs sources (SITL Simulator, Testing with Replay).


## 2026-05-23 (Glossary — new article)
- Created wiki/articles/glossary/glossary.md with ~70 terms spanning GNSS/RTK, propulsion, flight controller software, protocols (MAVLink, DSHOT, SBUS, RTCM3, NMEA, NTRIP), and sensor types.
- Source: Emlid RTK Modules Glossary plus wiki-internal terminology.
- Updated INDEX.md: Glossary section now populated.


## 2026-05-23 (Motors article — comprehensive BLDC type coverage)
- Rewrote motors.md with intricate coverage of all BLDC motor topologies: outrunner, inrunner, axial flux, coreless/slotless.
- Added star vs. delta winding configuration section with electrical characteristics, efficiency trade-offs, and selection criteria.
- Added pole–slot geometry section: NxPy notation, cogging torque mechanics, GCD rule, common configurations table.
- Added sensored vs. sensorless control section.
- Expanded construction details: lamination thickness grades, magnet temperature grades (N52/N52H/N52SH), winding strand types, slot fill factor, bearing types, shaft materials.
- Added motor internal resistance and no-load current parameters.
- Added motor type selection summary table mapping requirements to topology.
- Sources expanded from 5 to 12 authoritative references.

## 2026-05-23 (Wiki restructure: split flight-controllers into hardware and software categories)
- Renamed `wiki/articles/flight-controllers/` into two categories: `flight-controller-software/` (ArduPilot, vibration-filtering-and-tuning) and `flight-controller-hardware/` (Navio2).
- Updated all cross-links across 14 external articles and INDEX.md to reflect new paths.
- INDEX.md now has separate ## Flight Controller Software and ## Flight Controller Hardware sections.

## 2026-05-23 (Stubs filled and build-system enriched — sourced from Navio2 and emlid-docs repos)
- Filled mavproxy.md stub: full article covering installation, master/output connection strings, MAVLink routing, interactive commands, module system, scripting, SITL integration, daemon/systemd mode. Sourced from emlid-docs installation-and-running.md and MAVProxy docs.
- Filled gazebo-sitl.md stub: full article covering ardupilot_gazebo plugin, Gazebo Garden vs Classic, installation, dual-terminal launch, available worlds/models, sensor model table, ROS2 bridge, physics loop tuning, comparison table with built-in SITL.
- Updated build-system.md: added navio2 to board targets table; added "Building for Navio2" section with native on-Pi build and cross-compilation workflow (Raspberry Pi Foundation toolchain, waf --board=navio2, rsync transfer). Sourced from emlid-docs building-from-sources.md.
- Updated INDEX.md: removed *(stub)* markers from MAVProxy and Gazebo SITL entries.

## 2026-05-22 (Navio2 hardware gaps — sourced from Navio2 and emlid-docs repos)
- Created navio2/adc.md: 6-channel ADC channel map (board voltage, servo rail, power module V/I, 2 general-purpose), sysfs paths, conversion coefficients (×11.3 V, ×17.0 A), Python/C++ usage, ArduPilot BATT_VOLT_PIN/BATT_CURR_PIN parameters.
- Created navio2/led.md: RGB LED sysfs control (active-low, rgb_led0/1/2), 8-colour table, Python/C++ API, ArduPilot NTF status patterns.
- Created navio2/ahrs.md: Mahony complementary filter algorithm, quaternion state, supported sensors (MPU9250/LSM9DS1), gyro offset calibration, real-time priority with chrt, UDP quaternion streaming, Euler angle output, limitations vs EKF3.
- Updated imu.md, rcio.md, navio2-python.md: added cross-links to new articles.
- Updated INDEX.md: added AHRS, ADC, LED entries in Navio2 section.

## 2026-05-22 (RTK/PPK/GNSS — sourced from Navio2 and emlid-docs repos)
- Created new top-level GNSS category: wiki/articles/gnss/
- Created gnss/rtk-gps.md: RTK concepts (Fix/Float/Single statuses, AR ratio, age of differential), NTRIP vs local base, single-band vs multi-band baseline table, ArduPilot integration (UART/USB/Pixhawk wiring, ReachView config, GPS_TYPE2/SERIAL4/GPS_INJECT_TO parameters, GPS inject via telemetry radio), RS2 base RTCM3 message table, antenna placement.
- Created gnss/ppk.md: PPK vs RTK comparison table, camera hot-shoe sync with sub-microsecond time mark resolution, hardware setup (Reach M+/M2 + RS base), RTKLIB workflow (RTKCONV → RTKPOST → RTKPLOT → events.pos), RTKPOST settings table, baseline limits, accuracy expectations, DJI drone caveat.
- Created gnss/reach-m.md: Reach M+ and M2 full spec tables, baseline comparison, connector/interface map, radio wiring (3DR/RFD900/LoRa), antenna placement.
- Updated gps-gnss.md: expanded RTK section with parameter set and links to gnss/ articles.
- Updated navio2/gnss.md: RTK section links to gnss/rtk-gps.md; added reach-m.md to Related Concepts.
- Updated INDEX.md: added GNSS category with three articles; removed stray RTK/PPK entries from ArduPilot section.

## 2026-05-22 (Propulsion articles)
- Created motors.md: KV rating and stator naming convention, frame-to-motor mapping table (tiny whoop through agricultural), magnet/bearing/winding/lamination/shaft construction details, efficiency metrics, failure modes, selection workflow.
- Created propellers.md: notation system (diameter × pitch × blade count), diameter/pitch/blade-count tradeoffs, material types, mounting systems (prop nut / T-mount / press-fit), rotation layout, selection table by use case, failure modes.
- Created propulsion-system-design.md: core formulas (RPM, discharge current), TWR table by application, 7-step selection workflow, reference configurations table (5″ racing through agricultural heavy-lift), validation checklist, common mistakes.
- Updated INDEX.md: added all three articles under Propulsion.

## 2026-05-22 (Navio2 thin-coverage pass)
- gnss.md: Added External GPS / Dual GPS section (GPS_TYPE2, GPS_AUTO_SWITCH, blending caveats, dual-GPS log instances) and RTK section (NEO-M8N limitation, Reach/F9P external rover, RTCM injection via GPS_INJECT_TO, accuracy figures). Added GPS_INJECT_TO to parameter table.
- hardware-setup.md: Added Peripheral Bus Assignment table (SPI0/SPI1/I2C1 device paths, chip selects, addresses) with boot verification commands. Added RPi 5 unsupported note and RCIO/IMU cross-links.
- navio2-ros.md: Fixed fabricated `/sys/kernel/navio/imu/accel_x` sysfs path — replaced with accurate description of SPI device files and RCIO sysfs paths. Fixed stale `/etc/default/ardupilot` reference to vehicle-specific file.

## 2026-05-22 (Navio2 SITL + stubs)
- Created Navio2 SITL article: x86 vs. native RPi SITL workflows, GCS connection patterns, Navio2 parameter parity, MAVProxy essentials, Gazebo integration, RPi compile-time/speed benchmarks, SITL-to-hardware transition.
- Created MAVProxy stub and Gazebo SITL stub (both surfaced as cross-links from Navio2 SITL).
- Fixed stale `/etc/default/ardupilot` path in ardupilot-configuration.md Overview and navio2.md Getting Started (corrected to vehicle-specific file / emlidtool).
- Updated INDEX.md: Navio2 SITL entry, MAVProxy and Gazebo SITL stubs in ArduPilot section.

## 2026-05-22 (Navio2 enrichment round 2)
- Created 2 new articles from uningested Emlid docs: emlidtool (info/test/ardupilot/rcio subcommands, RCIO firmware update flags, connectivity check via sysfs); RCIO Co-Processor (rcio_core + rcio_spi kernel modules, full sysfs path map, ADC channel table, PWM watchdog, relay/GPIO formula, firmware update procedure, troubleshooting table).
- Enriched ardupilot-configuration.md: aux-channel-5–8 warning, relay/GPIO pin mapping table, compass configuration (AK8963 disabled by default, LSM9DS1 primary, external compass guidance, onboard calibration steps).
- Enriched imu.md: AK8963 magnetometer detail, LSM9DS1 as primary compass, Mahony AHRS example with 3D visualizer.
- Enriched pwm-output.md: GPIO mode section with sysfs commands and formula.
- Enriched barometer.md: Raspberry Pi heat conduction effect on temperature readings.
- Added emlidtool and RCIO to INDEX.md; removed all stale *(stub)* markers from INDEX.md.

## 2026-05-22 (Navio2 full expansion)
- Expanded all 12 Navio2 stubs to full articles. Coverage: Navio2 hub (comparison table vs. Pixhawk, software architecture, getting-started sequence), Hardware Setup (mechanical stack, connector pinout, BEC rules, vibration isolation), Dual IMU (MPU9250+LSM9DS1 specs, AUX SPI architecture, ArduPilot INS params, calibration), GNSS Receiver (NEO-M8N specs, constellation table, ArduPilot GPS params, antenna placement), Barometer (MS5611 specs, I2C isolation rationale, UV sensitivity mitigation, ground effect), PWM Output (channel specs, SERVO_FUNCTION mapping, sysfs interface, watchdog behavior), RC Input (PPM/SBUS wiring, protocol comparison table, sysfs readback, failsafe config), Power System (ideal diode arbitration, power module specs, BATT_ param calibration, power budget table), ArduPilot Configuration (systemd service, serial flag mapping, Navio2-specific params, calibration sequence, cross-compilation), Emlid Raspbian OS (kernel drivers, flashing procedure, WiFi config, update paths, RPi 5 caveat), Navio2 ROS/MAVROS (architecture diagram, launch commands, MAVROS topic table, GUIDED mode Python example, ROS 2 DDS path), Navio2 Python/C++ (repository layout, IMU/baro/GPS/PWM/ADC code examples, SCHED_FIFO real-time scheduling).
- Fixed two broken internal links (battery.md and esc.md relative paths).

## 2026-05-22 (Navio2 stubs)
- Created 11 Navio2 stub articles: Navio2 overview, Hardware Setup, Dual IMU (MPU9250+LSM9DS1), GNSS Receiver, Barometer (MS5611), PWM Output, RC Input (PPM/SBUS), Power System, ArduPilot Configuration, Emlid Raspbian OS, Navio2 ROS/MAVROS, Navio2 Python/C++ Programming.
- Updated INDEX.md with Navio2 section under Flight Controllers and two new Programming entries.

## 2026-05-22
- Enriched all 27 remaining stubs to full articles — wiki is now stub-free at 38 articles. New full articles: EKF Navigation, Ground Control Stations, Companion Computers, Optical Flow/Non-GPS Navigation, MAVLink Protocol, Parameter System, GPS/GNSS, Sensors, Lua Scripting, SITL Simulation, Power Monitoring, RC Systems/RCMAP, CAN Bus/DroneCAN, Telemetry Radios, Mission Planning, Geofencing, Hardware, Architecture, AP_HAL, Build System, Custom Firmware, Battery (power-systems), ESC (propulsion), DroneKit, MAVSDK, PyMAVLink, ROS/ROS2 Integration.
- Enriched PID Tuning stub: cascaded controller architecture (angle P → rate PID+FF), full ATC_RAT_* parameter reference, AutoTune procedure and parameters, QuikTune Lua script workflow, manual tuning sequence (D→P→I→FF), oscillation diagnosis table, filter interaction (FLTD = INS_GYRO_FILTER/2), log review workflow.
- Enriched Motor Mixing stub: FRAME_CLASS/TYPE tables, Quad-X motor numbering and mixing matrix, MOT_SPIN_ARM/MIN/MAX calibration procedure, ESC protocol table (PWM→DShot600) with IOMCU output group restrictions, MOT_THST_EXPO by prop size, battery voltage compensation parameters, motor redundancy on 6+ motor frames.
- Enriched Logging stub: LOG_BITMASK bit table, key message types reference (ATT, RATE, CTUN, GPS, XKF1/4, BAT, VIBE, RCOU, EV, ERR, ARM, MODE), log download methods, analysis tools (UAV Log Viewer, Mission Planner, MAVExplorer), common workflows (vibration check with thresholds, PID review, EKF health, battery trends, motor imbalance).

## 2026-05-21
- Initialized wiki structure and CLAUDE.md ruleset.
- Added Airframes article: frame classes, materials, construction types, resonance.
- Added Rotor Configurations article: motor count tradeoffs, quadcopter geometry (True X, Stretched X, Wide X, Deadcat, Plus, H), coaxial variants, spin direction conventions.
- Added Vibration, Filtering, and Tuning article: noise frequency bands, motor noise formulas (mechanical RPM, harmonics, blade pass frequency), frame resonance, filter types (LPF, notch, dynamic notch, RPM filter), filter stack architecture, spectral analysis workflow, firmware parameter tables for Betaflight/ArduPilot/PX4.
- Enriched Airframes article: expanded resonance section with damage effects and cross-link to Vibration article.
- Added 22 ArduPilot sub-topic stubs: architecture, AP_HAL, hardware, build system, custom firmware, first flight, arming/pre-flight, flight modes, motor mixing, PID tuning, parameters, logging, sensors, GPS/GNSS, EKF/navigation, optical flow, CAN/DroneCAN, RC systems, MAVLink, GCS, telemetry radios, companion computers, Lua scripting, mission planning, failsafes, geofencing, power monitoring, SITL.
- Added 4 Programming stubs: DroneKit, MAVSDK, PyMAVLink, ROS/ROS2 integration.
