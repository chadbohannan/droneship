# AP_HAL — Hardware Abstraction Layer

AP_HAL (Hardware Abstraction Layer) decouples ArduPilot's flight logic from the underlying microcontroller and operating system. The same application code compiles for STM32-based Pixhawk hardware, Linux-based boards, and the SITL PC simulator — only the HAL implementation changes.

## Overview

AP_HAL defines a set of pure virtual C++ interfaces: GPIO, UART, SPI, I2C, storage, semaphore, scheduler, and utility functions. Vehicle and library code calls these interfaces without knowing which MCU or OS sits underneath. Board-specific implementations provide the concrete classes.

The global HAL instance is accessed via `hal` — a reference to the board-specific `AP_HAL::HAL` object:

```cpp
hal.console->printf("Hello from ArduPilot\n");
hal.gpio->pinMode(LED_PIN, HAL_GPIO_OUTPUT);
hal.gpio->write(LED_PIN, 1);
```

## Implementations

| Implementation | Boards | Runtime |
|----------------|--------|---------|
| `HAL_ChibiOS` | Pixhawk, Cube, Matek (STM32) | ChibiOS RTOS |
| `HAL_Linux` | Navio2, BeagleBone, generic Linux | Linux userspace |
| `HAL_SITL` | PC (Windows, macOS, Linux) | Native OS process |
| `HAL_ESP32` | ESP32 microcontrollers | FreeRTOS |

## Key Interfaces

### UART (Serial)

```cpp
hal.serial(1)->begin(57600);           // open TELEM1 at 57600 baud
hal.serial(1)->write(buf, len);        // write bytes
int n = hal.serial(1)->available();    // bytes ready to read
hal.serial(1)->read();                 // read one byte
```

### GPIO

```cpp
hal.gpio->pinMode(pin, HAL_GPIO_OUTPUT);
hal.gpio->write(pin, 1);              // set high
bool val = hal.gpio->read(pin);       // read pin
```

### SPI

SPI device access via `DeviceBus`. Sensor drivers obtain a `SPIDeviceHandle` for their chip and call `transfer()` for register reads/writes.

### I2C

Similar to SPI — drivers get an `I2CDeviceHandle` and call `transfer()`. Multiple devices on the same bus share the handle with address-level multiplexing.

### Storage

```cpp
hal.storage->read_block(data, addr, len);   // read from EEPROM/FRAM
hal.storage->write_block(addr, data, len);  // write to EEPROM/FRAM
```

Storage is used by the parameter system and mission storage. See [Parameter System](parameters.md).

## Board Configuration Files

Each supported board has a `hwdef.dat` file in `libraries/AP_HAL_ChibiOS/hwdef/`. This file declares:
- MCU type and clock speed
- UART assignments (which hardware UART maps to which logical serial port)
- SPI device definitions (chip select pins, bus)
- I2C bus assignments
- ADC pin mappings
- CAN bus configuration
- PWM output groups and timers

The build system processes `hwdef.dat` with `chibios_hwdef.py` to generate `hwdef.h` and associated initialisation code. Adding a new board requires writing a `hwdef.dat` that matches the PCB schematic.

## Scheduler Integration

`AP_HAL::Scheduler` provides `delay()` and `delay_microseconds()` for time-based waits. On ChibiOS, these yield to other threads rather than busy-waiting. The main ArduPilot scheduler (`AP_Scheduler`) builds on top of the HAL scheduler to provide the task dispatch described in [Architecture](architecture.md).

## SITL HAL

`HAL_SITL` simulates all hardware interfaces in software:
- Serial ports as TCP sockets or pipes
- Sensor data from the physics simulator
- GPIO as flags in memory
- Storage as a file (`eeprom.bin`)
- Scheduler as host OS sleep calls

This allows SITL to exercise the full AP_HAL interface path, catching board-portability bugs before they reach hardware. See [SITL Simulation](sitl.md).

## Porting to New Hardware

1. Create `libraries/AP_HAL_ChibiOS/hwdef/<board_name>/hwdef.dat` mapping PCB signals to HAL interfaces.
2. Run `Tools/scripts/chibios_hwdef.py` to validate and generate headers.
3. Add the board to the waf build system (`waf list_boards` should include it).
4. Build and test: `./waf configure --board=<board_name> && ./waf copter`.

## Related Concepts

- [Architecture](architecture.md)
- [Hardware](hardware.md)
- [Build System](build-system.md)
- [SITL Simulation](sitl.md)

## Sources

- [Learning ArduPilot: Introduction — ArduPilot dev docs](https://ardupilot.org/dev/docs/learning-ardupilot-introduction.html) — 2026-05-22
- [AP_HAL Design — Erlerobotics gitbook](https://erlerobotics.gitbooks.io/erlerobot/content/en/beaglepilot/ap_hal.html) — 2026-05-22
- [HAL Implementations — ArduPilot DeepWiki](https://deepwiki.com/ArduPilot/ardupilot/4.2-board-and-hardware-support) — 2026-05-22

<!-- linted: 2026-05-23 -->
