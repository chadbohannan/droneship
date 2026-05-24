# Navio2 RCIO Co-Processor

The embedded microcontroller on Navio2 that handles real-time RC input decoding and PWM output generation, exposed to Linux via a kernel module and sysfs.

## Overview

RCIO (RC Input/Output) is Emlid's name for the STM32-based co-processor embedded on the Navio2 board. It communicates with the Raspberry Pi over SPI and handles all timing-critical I/O that Linux cannot reliably perform: generating precisely timed PWM pulses for ESCs and servos, and decoding the pulse-width timing of incoming PPM or SBUS RC frames.

The Emlid kernel module (`rcio_core` + `rcio_spi`) bridges the SPI link and exposes the co-processor's capabilities through standard Linux sysfs nodes under `/sys/kernel/rcio/` and `/sys/class/pwm/pwmchip0/`. Any programming language that can read and write sysfs files can interact with Navio2 I/O without hardware-specific libraries.

## Kernel Modules

Two kernel modules implement the RCIO interface:

| Module | Role |
|--------|------|
| `rcio_core` | Core driver: sysfs node creation, register map, state machine |
| `rcio_spi` | Transport: SPI communication between RPi and co-processor |

Both load automatically at boot via the Emlid image's `/etc/modules-load.d/` configuration. If they fail to load, the `/sys/kernel/rcio/` tree will not exist and ArduPilot will log "RCIO not connected."

Manual load for troubleshooting:
```bash
sudo modprobe -r rcio_spi          # unload (removes rcio_core as dependency)
sudo modprobe rcio_spi             # reload
dmesg | tail -20                   # check for SPI init errors
```

## Sysfs Interface Map

```
/sys/kernel/rcio/
├── status/
│   └── alive          # 1 = co-processor online, 0 = not connected
├── rcin/
│   ├── ch0            # RC input channel 1 (microseconds, typically 1000–2000)
│   ├── ch1            # RC input channel 2
│   ├── ...
│   └── ch15           # RC input channel 16 (SBUS max)
└── adc/
    ├── ch0            # ADC channel 0
    ├── ch1            # ADC channel 1 (current sense from power module)
    ├── ch2            # ADC channel 2 (voltage sense from power module)
    ├── ch3            # ADC channel 3
    ├── ch4            # ADC channel 4
    └── ch5            # ADC channel 5

/sys/class/pwm/pwmchip0/
├── export             # write channel index to activate
├── unexport           # write channel index to deactivate
└── pwm<N>/            # created after export
    ├── period         # period in nanoseconds (e.g., 20000000 = 50 Hz)
    ├── duty_cycle     # pulse width in nanoseconds (e.g., 1500000 = 1.5 ms)
    └── enable         # write 1 to enable output
```

## RC Input

Read decoded RC channel values (microseconds):
```bash
cat /sys/kernel/rcio/rcin/ch0    # channel 1 (roll)
cat /sys/kernel/rcio/rcin/ch2    # channel 3 (throttle)
```

Values are updated by the co-processor at the RC frame rate (PPM: ~50 Hz, SBUS: ~100 Hz). Reading from a shell script introduces jitter; use the C++ or Python libraries for control loops.

## PWM Output

```bash
# Activate channel 0 (servo rail pin 1)
echo 0 > /sys/class/pwm/pwmchip0/export

# Set 50 Hz (period = 20,000,000 ns)
echo 20000000 > /sys/class/pwm/pwmchip0/pwm0/period

# Set 1.5 ms pulse (center position)
echo 1500000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

# Enable output
echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable
```

**Watchdog:** The kernel driver expects a write to `duty_cycle` at least every 100 ms. If the process writing to sysfs stalls or crashes, outputs freeze at the last commanded value. There is no automatic failsafe return to neutral — design software accordingly by implementing a watchdog thread that writes current values periodically.

## ADC Channels

The RCIO ADC has six channels. The power module uses channels 1 and 2 (ArduPilot parameters BATT_CURR_PIN=3 and BATT_VOLT_PIN=2 refer to the same physical lines with a different indexing offset in the ArduPilot HAL):

| sysfs path | ArduPilot pin | Power module signal |
|-----------|---------------|---------------------|
| `adc/ch1` | pin 3 | Current sense (0–3.3 V = 0–60 A) |
| `adc/ch2` | pin 2 | Voltage sense (0–3.3 V = 0–~26 V) |

Raw ADC values are in millivolts (0–3300). Apply `BATT_VOLT_MULT` and `BATT_AMP_PERVLT` to convert to battery voltage and current.

## Firmware Updates

The RCIO co-processor runs its own firmware, independent of the Raspberry Pi OS and ArduPilot. Emlid bundles a firmware binary in the `rcio-dkms` package and updates it via `emlidtool`:

```bash
sudo emlidtool rcio check    # check if update is needed
sudo emlidtool rcio update   # flash the bundled firmware
```

The update process:
1. Halts ArduPilot service if running.
2. Loads the co-processor into bootloader mode via a SPI command.
3. Transfers the firmware binary over SPI.
4. Verifies the flashed firmware checksum.
5. Restarts the co-processor.

A failed update (power loss mid-flash, SPI error) can leave the co-processor in bootloader mode. Re-run `emlidtool rcio update` to retry; the bootloader persists until a successful flash or power cycle.

## Relay / GPIO Mode

The 14 servo rail pins can function as GPIO outputs instead of PWM channels. This allows triggering external devices (cameras, lights, relays) from ArduPilot's relay system.

GPIO numbers follow the formula: **GPIO = 500 + (header pin number − 1)**

| Servo rail pin | GPIO number | ArduPilot relay pin index |
|---------------|-------------|--------------------------|
| 1 | 500 | 0 |
| 2 | 501 | 1 |
| ... | ... | ... |
| 14 | 513 | 13 |
| IO17 | 514 | 14 |
| IO18 | 515 | 15 |
| LED R/G/B | 516–518 | 16–18 |

Configure in ArduPilot by setting `RELAY_PIN` to the desired relay pin index (0–18) in Mission Planner's Full Parameter List.

**Warning:** Do not assign digital relay pins to PWM channels simultaneously in use for motor/servo control — the co-processor cannot serve a channel as both GPIO and PWM at the same time.

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `alive` reads `0` | HAT not seated / screws missing | Reseat Navio2, add nylon standoff screws |
| ArduPilot: "RCIO not connected" | `rcio_spi` module not loaded | `sudo modprobe rcio_spi`; check dmesg |
| PWM outputs frozen | Watchdog timeout (>100 ms since last write) | Fix the writing loop; check for process stall |
| RCIO firmware update fails | ArduPilot running during update | `sudo systemctl stop ardupilot` first |
| Old firmware after `apt upgrade` | Package updated but firmware not flashed | `sudo emlidtool rcio update` |

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 ADC](adc.md)
- [Navio2 PWM Output](pwm-output.md)
- [Navio2 RC Input (PPM/SBUS)](rc-input.md)
- [emlidtool](emlidtool.md)
- [Navio2 Power System](power-system.md)

## Sources

- [RCIO — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/rcio/) — 2026-05-22
- [rcio-dkms — GitHub (emlid/rcio-dkms)](https://github.com/emlid/rcio-dkms) — 2026-05-22

<!-- linted: 2026-05-23 -->
