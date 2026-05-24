# Navio2 Hardware Setup

Physical assembly, wiring, and connector reference for the Navio2 autopilot HAT on Raspberry Pi.

## Overview

Navio2 attaches to a Raspberry Pi via the 40-pin GPIO header using an extension header that adds vertical clearance between the boards. Four M2.5 nylon spacers support the stack mechanically. The assembly is compact enough to mount in most 5 inch and larger frames using vibration-damping standoffs between the frame and the Raspberry Pi.

Compatible Raspberry Pi models: 2B, 3B, 3B+, 4B (all share the same 40-pin layout). The Raspberry Pi 4B is recommended for ROS workloads due to its faster CPU and 4 GB RAM option; the 3B+ is sufficient for ArduPilot-only flight. The Raspberry Pi 5 is **not supported** — its GPIO architecture changed in a way that is incompatible with the current Emlid kernel drivers.

## Mechanical Stack

1. Thread M2.5 screws up through the bottom of the Raspberry Pi PCB.
2. Thread nylon spacers onto the screws from the top.
3. Press the 40-pin extension header onto the Raspberry Pi GPIO pins.
4. Seat Navio2 onto the extension header, aligning pin 1.
5. Thread nylon screws down through Navio2 into the standoffs to secure.

The extension header matters — connecting Navio2 directly without it blocks the USB and Ethernet ports on Raspberry Pi 3/4.

## Connectors and Ports

| Connector | Location | Description |
|-----------|----------|-------------|
| POWER | 6-pin DF13 | Power module input; powers RPi via switching regulator |
| GPS/GNSS | MCX coax | External antenna for the onboard u-blox receiver |
| RC INPUT | 3-pin 2.54 mm | PPM or SBUS from RC receiver (signal, +5 V, GND) |
| RC OUTPUT 1–14 | 2.54 mm strip | PWM to ESCs and servos (signal, +5 V, GND per channel) |
| UART | 2-pin header | Serial expansion (GPS2, telemetry radio) |
| ADC | — | Onboard voltage/current sense from power module |

## Peripheral Bus Assignment

Every Navio2 sensor is assigned a fixed Linux bus. Knowing these paths is essential when debugging "device not found" errors or accessing sensors directly from user code.

| Device | Bus type | Linux device | Chip select / address |
|--------|----------|-------------|----------------------|
| MPU-9250 (IMU 1) | SPI0 | `/dev/spidev0.1` | CE1 |
| LSM9DS1 (IMU 2) | SPI1 (AUX) | `/dev/spidev1.0` | CE0 |
| u-blox NEO-M8N (GNSS) | SPI0 | `/dev/spidev0.0` | CE0 |
| MS5611 (barometer) | I2C1 | `/dev/i2c-1` | 0x77 |
| RCIO co-processor | SPI0 | kernel driver (`rcio_spi`) | CE2 |
| RGB LED | GPIO | `/sys/class/leds/` | — |
| ADC / RC input / PWM | RCIO sysfs | `/sys/kernel/rcio/` | — |

SPI1 (AUX) is not present in the stock Raspberry Pi kernel — the Emlid custom kernel activates the `spi-bcm2835aux` driver to expose `/dev/spidev1.0` for the LSM9DS1. This is why a standard Raspbian image cannot see IMU 2 without Emlid's kernel package.

To verify all buses are present after boot:

```bash
ls /dev/spidev*        # expect: spidev0.0 spidev0.1 spidev0.2 spidev1.0
ls /dev/i2c-*          # expect: i2c-1
cat /sys/kernel/rcio/status/alive   # expect: 1
```

## Servo Rail Wiring

Connect ESC signal wires (white or orange) to RC OUTPUT channels 1–14. For a quadcopter, motors connect to channels 1–4 per ArduPilot's motor numbering for the selected FRAME_CLASS/TYPE.

**BEC requirement:** The power module supplies the Raspberry Pi and Navio2 electronics, but does not power the 5 V servo rail. Plug a standalone BEC (4.8–5.3 V, sized for your total servo current draw) into any unused servo channel on the signal rail. Only connect a single BEC; multiple BECs on the same rail will fight each other and generate excess heat.

**ESC power wire:** If using ESCs with built-in BECs and you do not need the servo rail powered by them, cut or leave unconnected the red (center) wire from all but one ESC to prevent BEC contention. The black GND wire should always remain connected.

## RC Receiver Connection

Connect the receiver's PPM output to the three-pin RC INPUT header on Navio2 (signal on pin 1, 5 V on pin 2, GND on pin 3). Do not connect servos directly to the RC receiver port — the receiver port cannot supply servo current and doing so risks brownout.

For SBUS receivers, connect to the same RC INPUT header. SBUS uses an inverted 100 kBaud serial signal; the co-processor handles inversion internally.

Receivers without a PPM or SBUS output can be bridged using a PPM encoder board, which reads the receiver's individual PWM channels and encodes them into a PPM sum signal.

Compatible PPM receivers (ACCST protocol, most FrSky transmitters):
- FrSky D4R-II 4ch 2.4 GHz ACCST
- FrSky V8R7-SP ACCST 7-channel with PPM
- FrSky D8R-XP

Compatible PPM receivers (FASST protocol, Futaba and some FrSky transmitters):
- FrSky TFR4 4ch 2.4 GHz FASST

## GPS Antenna

Plug the MCX connector from the GPS patch antenna into the MCX port on the top side of the Navio2. Mount the antenna on the top of the aircraft with a clear sky view, away from the power distribution board and FPV video transmitter. For compass accuracy, keep the antenna and its cable at least 10 cm from high-current wiring.

## Anti-Vibration Mount

Emlid designed a 3D-printable anti-vibration mount that simplifies installation and decouples the Navio2 stack from frame vibrations. It uses eight blue rubber damping balls between two printed plates. STL files are available on GitHub:

- [Top plate (VibroNavio2top_rev_A.STL)](https://github.com/emlid/hardware/blob/master/VibroNavio2top_rev_A.STL)
- [Bottom plate (VibroNavio2bot_rev_A.STL)](https://github.com/emlid/hardware/blob/master/VibroNavio2bot_rev_A.STL)

Print in PLA or PETG at 40% infill. The damping balls press into slots in both plates and grip without adhesive.

## Vibration Isolation

Mount the Raspberry Pi / Navio2 stack on foam or rubber vibration isolators rated for the frame's vibration profile. Excessive vibration saturates the IMU accelerometers and degrades EKF performance. Target peak-to-peak vibration below ±3 m/s² on all axes when measured from ArduPilot VIBE logs.

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 Power System](power-system.md)
- [Navio2 PWM Output](pwm-output.md)
- [Navio2 RC Input](rc-input.md)
- [RCIO Co-Processor](rcio.md)
- [Navio2 Dual IMU](imu.md)
- [Vibration, Filtering, and Tuning](../../flight-controller-software/vibration-filtering-and-tuning.md)
- [Motor Mixing](../../flight-controller-software/ardupilot/motor-mixing.md)

## Sources

- [Hardware setup — Emlid Navio2 docs](https://docs.emlid.com/navio2/hardware-setup/) — 2026-05-22
- [NAVIO2 Assembly and Wiring Quick Start — ArduPilot](https://ardupilot.org/copter/docs/common-navio2-wiring-and-quick-start.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
