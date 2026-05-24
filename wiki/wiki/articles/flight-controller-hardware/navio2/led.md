# Navio2 RGB LED

Onboard RGB LED controlled via sysfs, used by ArduPilot for flight-status indication and available for custom signalling in user applications.

## Overview

The Navio2 carries a single RGB LED driven through three independent sysfs entries under `/sys/class/leds/`. Each colour channel (red, green, blue) is toggled independently by writing to its `brightness` file. Combining channels produces eight colours. ArduPilot takes control of the LED at startup to indicate arming state, GPS lock, and error conditions; user code can only drive the LED when ArduPilot is not running.

## sysfs Interface

| sysfs path | Channel |
|-----------|---------|
| `/sys/class/leds/rgb_led0/brightness` | Red |
| `/sys/class/leds/rgb_led1/brightness` | Blue |
| `/sys/class/leds/rgb_led2/brightness` | Green |

Write `0` to turn a channel on, `1` to turn it off (active-low logic). If the `/sys/class/leds/rgb_led*` entries do not exist, the [RCIO co-processor](rcio.md) kernel module was not loaded — check `dmesg` for RCIO errors.

```bash
echo 0 > /sys/class/leds/rgb_led0/brightness  # red on
echo 1 > /sys/class/leds/rgb_led0/brightness  # red off
```

## Colour Table

| Colour | Red (rgb_led0) | Blue (rgb_led1) | Green (rgb_led2) |
|--------|:--------------:|:---------------:|:----------------:|
| Black (off) | 1 | 1 | 1 |
| Red | 0 | 1 | 1 |
| Green | 1 | 1 | 0 |
| Blue | 1 | 0 | 1 |
| Cyan | 1 | 0 | 0 |
| Magenta | 0 | 0 | 1 |
| Yellow | 0 | 1 | 0 |
| White | 0 | 0 | 0 |

## Python

```python
from navio.leds import Led

led = Led()
led.setColor('Green')   # solid green
led.setColor('Red')     # solid red
led.setColor('Black')   # off
```

`Led()` opens the three sysfs brightness files on init and turns all channels off. `setColor()` accepts any key from the colour table above.

## C++

```cpp
#include <Navio2/Led_Navio2.h>
#include <Common/Util.h>

Led_Navio2 led;
led.initialize();
led.setColor(Colors::Green);
sleep(1);
led.setColor(Colors::Red);
```

The C++ example in `C++/Examples/LED/` cycles through all colours with 1 s intervals. Run as root: `sudo ./LED`.

## ArduPilot LED Behaviour

ArduPilot drives the LED to communicate vehicle state. Standard meanings:

| Pattern | Meaning |
|---------|---------|
| Flashing blue | Disarmed, no GPS fix |
| Solid blue | Disarmed, GPS fix |
| Flashing green | Armed, no GPS fix |
| Solid green | Armed, GPS fix (ready to fly) |
| Flashing yellow | Failsafe active |
| Flashing red | Low battery or critical error |

These match the standard ArduPilot NTF (notify) LED conventions. Exact behaviour depends on ArduPilot firmware version and NTF_LED_TYPES parameter.

## Related Concepts

- [Navio2 RCIO Co-Processor](rcio.md)
- [Navio2 Python and C++ Programming](../../programming/navio2-python.md)
- [emlidtool](emlidtool.md)

## Sources

- Navio2 repository: `Python/navio/leds.py`, `C++/Examples/LED/LED.cpp` — 2026-05-22

<!-- linted: 2026-05-23 -->
