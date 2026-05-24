# Supported Hardware — ArduPilot

ArduPilot runs on a broad range of flight controller hardware, from compact FPV boards to redundant professional autopilots. Processor choice determines looptime capability, available memory, peripheral count, and long-term feature support.

## Processor Tiers

| Tier | MCU | Max loop rate | DShot | Typical boards |
|------|-----|--------------|-------|----------------|
| F4 | STM32F4 (168 MHz) | 4 kHz | DShot300 | Older boards; limited RAM |
| F7 | STM32F7 (216 MHz) | 8 kHz | DShot600 | Good balance of cost and capability |
| H7 | STM32H7 (480 MHz) | 8 kHz | DShot600 | Current standard; 2 MB flash / 1 MB RAM |

ArduPilot's full feature set (EKF3, Lua scripting, terrain following, DroneCAN) requires an H7-class processor. F4 boards are no longer recommended for new ArduPilot builds.

## Minimum Requirements

- **Flash**: 2 MB (1 MB for stripped builds without some features)
- **RAM**: 512 KB minimum; 1 MB recommended for EKF3 + scripting
- **IMUs**: At least 1; 2–3 for redundancy (Pixhawk standard)
- **Barometer**: At least 1
- **Serial ports**: At minimum UART0 (USB), 1 GPS port, 1 telemetry port

## Popular Hardware

### Pixhawk Series (Holybro)

**Pixhawk 6C**: Compact H7 board. STM32H743, 480 MHz, 2 MB flash / 1 MB RAM. Triple IMU (ICM-42688-P × 2, ICM-20649), dual baro, dual CAN. JST-GH connectors throughout. Built-in vibration isolation for IMUs. Good general-purpose choice.

**Pixhawk 6X**: Full-size H7 board. Same processor as 6C plus Ethernet port for companion computer integration. Three low-noise IMUs, dual baro on separate buses for redundancy. Professional/commercial focus.

### CubePilot Series

**Cube Orange+**: STM32H753 at 400 MHz, 2 MB flash / 1 MB RAM. Three IMUs on temperature-controlled, vibration-isolated board. IOMCU co-processor for IO failsafe redundancy. Industry standard for commercial builds. Connector: standard Cube carrier boards (Pixhawk 2 ecosystem).

### Matek

**Matek H743-Wing**: H7 at 480 MHz. 7 UARTs, 13 PWM outputs (DShot + PWM), dual SPI IMUs (ICM-42688-P), DPS310 baro, onboard OSD chip, 8–36 V power input (3–8S LiPo). No IOMCU — all outputs from FMU. Well-suited for fixed-wing and VTOL. Popular for ArduPlane and ArduCopter.

**Matek H743-Slim / Mini**: Smaller variants of H743 for tighter builds.

### Linux Targets

ArduPilot runs on Linux-based autopilot boards for applications needing high-performance companion compute alongside flight control:

- **Navio2 (Emlid)**: Raspberry Pi HAT; runs ArduPilot directly on Pi CPU; connects to Linux via native SPI/I2C
- **BeagleBone Blue**: Integrated Linux SBC + ArduPilot
- **Qualcomm Snapdragon Flight**: High-compute; camera pipeline integration

### mRo

mRo X2.1 and M9N GPS: community-focused alternatives to Pixhawk family with similar capability.

## FMU vs. IOMCU Architecture

Most Pixhawk-family boards split outputs into two groups:

**MAIN outputs (IOMCU)**: Driven by a separate STM32F103 co-processor (IO Microcontroller Unit). Provides failsafe-redundant output — if the main FMU CPU crashes, the IOMCU continues sending last known outputs. Limited to PWM and OneShot protocols.

**AUX outputs (FMU)**: Driven directly by the H7 FMU CPU. Supports DShot, bidirectional DShot, and GPIO. More flexible but no separate failsafe path.

For multirotor builds, connect motors to AUX outputs to use DShot. For critical fixed-wing surfaces (elevator, rudder), MAIN outputs provide the failsafe benefit.

## Connector Standards

| Standard | Pitch | Max current | Common on |
|----------|-------|-------------|-----------|
| JST-GH | 1.25 mm | 1 A/pin | Modern Pixhawk, Holybro |
| DF-13 | 1.25 mm | 1 A/pin | Legacy Pixhawk 1 |
| Dupont / 0.1" | 2.54 mm | 3 A/pin | DIY, Matek |

JST-GH is the current standard. Adapters from DF-13 to JST-GH are widely available.

## Hardware Selection by Use Case

| Use case | Recommendation |
|----------|---------------|
| Racing / FPV freestyle | Betaflight on F7/H7 — ArduPilot adds unnecessary overhead |
| Long-range FPV with GPS modes | iNav or ArduPilot on H7 board (Matek H743) |
| Autonomous missions (medium) | Pixhawk 6C or Matek H743 |
| Commercial / professional | Cube Orange+ |
| Research / companion compute | Navio2 on Raspberry Pi or Pixhawk 6X + companion |
| Heavy lift (hexacopter+) | Cube Orange+ with redundant IMU and CAN peripherals |

## Related Concepts

- [Architecture](architecture.md)
- [AP_HAL](ap-hal.md)
- [CAN Bus and DroneCAN](can-dronecan.md)
- [Sensors](sensors.md)
- [Motor Mixing and Output](motor-mixing.md)

## Sources

- [Supported Autopilots — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-autopilots.html) — 2026-05-22
- [Pixhawk 6C — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-holybro-pixhawk6C.html) — 2026-05-22
- [Cube Orange Overview — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-thecubeorange-overview.html) — 2026-05-22
- [Matek H743-Wing — ArduPilot Copter docs](https://ardupilot.org/copter/docs/common-matekh743-wing.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
