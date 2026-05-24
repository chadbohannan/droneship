# Navio2 Python and C++ Programming

Direct sensor access and custom autopilot logic using Emlid's open-source C++ and Python libraries.

## Overview

Emlid provides an open-source library at [github.com/emlid/Navio2](https://github.com/emlid/Navio2) containing C++ and Python examples that access Navio2 hardware directly through Linux kernel interfaces, bypassing ArduPilot entirely. Each sensor is wrapped in a minimal driver class that handles the SPI/I2C transactions and parsing. This approach enables custom autopilot logic, hardware-in-the-loop testing, sensor data logging experiments, or alternative flight stacks written in Python or C++.

C++ is preferred for anything timing-sensitive (attitude estimation loops, PWM output) because Python's GIL and interpreter overhead can introduce jitter. Python is convenient for rapid prototyping, data collection scripts, and integration with ROS Python nodes.

## Repository Structure

```
emlid/Navio2/
├── C++/
│   ├── Navio/            # Driver library classes
│   │   ├── MPU9250.h/.cpp
│   │   ├── LSM9DS1.h/.cpp
│   │   ├── MS5611.h/.cpp
│   │   ├── Ublox.h/.cpp
│   │   ├── ADC.h/.cpp
│   │   ├── RCInput.h/.cpp
│   │   └── RCOutput.h/.cpp
│   └── Examples/         # Standalone example programs
│       ├── AccelGyroMag/
│       ├── Barometer/
│       ├── GPS/
│       ├── ADC/
│       ├── RCInput/
│       └── Servo/
└── Python/
    ├── navio/            # Python driver modules
    │   ├── mpu9250.py
    │   ├── lsm9ds1.py
    │   ├── ms5611.py
    │   ├── ublox.py
    │   ├── adc.py
    │   └── rcio.py
    └── AccelGyroMag.py   # Example scripts
```

## Setup

Clone the repository and build the C++ examples on the Navio2 Raspberry Pi:

```bash
git clone https://github.com/emlid/Navio2.git
cd Navio2/C++/Examples/AccelGyroMag
make
sudo ./AccelGyroMag
```

Python examples require no build step:

```bash
sudo python3 Navio2/Python/AccelGyroMag.py
```

Root privileges are required because the sysfs and SPI device nodes are owned by root in the Emlid image. Add the `pi` user to the `spi` and `i2c` groups to run without `sudo`.

## Reading IMU Data (C++)

```cpp
#include "MPU9250.h"

MPU9250 imu;
imu.initialize();

float ax, ay, az, gx, gy, gz, mx, my, mz;
while (true) {
    imu.getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);
    printf("Accel: %.2f %.2f %.2f m/s²\n", ax, ay, az);
    usleep(10000);  // 100 Hz
}
```

The LSM9DS1 uses an identical interface; swap `MPU9250` for `LSM9DS1`.

## Reading IMU Data (Python)

```python
import navio.mpu9250 as MPU9250

imu = MPU9250.MPU9250()
imu.initialize()

while True:
    m9 = imu.getMotion9()
    print(f"Accel: {m9[0]:.2f} {m9[1]:.2f} {m9[2]:.2f}")
```

## Reading Barometer (Python)

```python
import navio.ms5611 as MS5611

baro = MS5611.MS5611()
baro.initialize()

while True:
    baro.refreshPressure()
    baro.readPressure()
    baro.refreshTemperature()
    baro.readTemperature()
    baro.calculatePressureAndTemperature()
    print(f"Pressure: {baro.PRES:.2f} mbar  Temp: {baro.TEMP:.2f} °C")
```

Note the two-step read cycle (refresh then read) — the MS5611 requires a conversion delay between the trigger command and the result read. The Python library handles the correct OSR timing internally.

## Reading GPS (Python)

```python
import navio.ublox as ublox

gps = ublox.UBlox("spi", deviceId=1, baudrate=5000000)
gps.configure_poll_port()
gps.configure_solution_rate(rate_ms=200)  # 5 Hz

while True:
    msg = gps.receive_message()
    if msg.name() == "NAV_POSLLH":
        print(f"Lat: {msg.Lat/1e7:.6f}  Lon: {msg.Lon/1e7:.6f}  Alt: {msg.height/1000:.1f} m")
```

The u-blox receiver communicates over SPI in binary UBX protocol. The library handles framing and checksum validation.

## PWM Output (C++)

```cpp
#include "RCOutput.h"

RCOutput servo;
servo.initialize(0);   // channel index 0 = servo rail pin 1

servo.set_frequency(50);    // 50 Hz
servo.enable(0);

servo.set_duty_cycle(0, 1500);  // 1500 µs = center position
```

PWM channels must be written at least every 100 ms or the kernel driver freezes them at the last value.

## RC Input (Python)

```python
import navio.rcio as rcio

rcinput = rcio.RCInput()

while True:
    for ch in range(8):
        val = rcinput.read(ch)
        print(f"CH{ch+1}: {val} µs", end="  ")
    print()
```

Values are in microseconds (typically 1000–2000).

## ADC — Battery Voltage and Current

```python
import navio.adc as ADC

adc = ADC.ADC()

while True:
    voltage_raw = adc.read(2)   # channel 2 = voltage sense
    current_raw = adc.read(3)   # channel 3 = current sense
    # Apply calibration multipliers from ArduPilot BATT_VOLT_MULT / BATT_AMP_PERVLT
    voltage = voltage_raw * 11.3
    current = current_raw * 17.0
    print(f"Battery: {voltage:.2f} V  {current:.1f} A")
```

## Real-Time Scheduling

For tight control loops (1 kHz attitude estimator, 400 Hz PWM update), set the Python or C++ process to SCHED_FIFO:

```python
import os, ctypes

SCHED_FIFO = 1
class sched_param(ctypes.Structure):
    _fields_ = [("sched_priority", ctypes.c_int)]

param = sched_param(sched_priority=10)
libc = ctypes.CDLL("libc.so.6", use_errno=True)
libc.sched_setscheduler(0, SCHED_FIFO, ctypes.byref(param))
```

Run with `sudo` or grant `CAP_SYS_NICE` to the process. SCHED_FIFO prevents the Linux scheduler from preempting the loop mid-cycle, reducing jitter from ~10 ms to <100 µs on a Raspberry Pi 3B+.

## Related Concepts

- [Navio2](../flight-controller-hardware/navio2/navio2.md)
- [Navio2 AHRS](../flight-controller-hardware/navio2/ahrs.md)
- [Navio2 ADC](../flight-controller-hardware/navio2/adc.md)
- [Navio2 RGB LED](../flight-controller-hardware/navio2/led.md)
- [Navio2 Dual IMU](../flight-controller-hardware/navio2/imu.md)
- [Navio2 GNSS Receiver](../flight-controller-hardware/navio2/gnss.md)
- [Navio2 PWM Output](../flight-controller-hardware/navio2/pwm-output.md)
- [Navio2 Barometer](../flight-controller-hardware/navio2/barometer.md)
- [Navio2 ROS and MAVROS](navio2-ros.md)
- [PyMAVLink](pymavlink.md)

## Sources

- [Navio2 GitHub — emlid/Navio2](https://github.com/emlid/Navio2) — 2026-05-22
- [Examples setup — Emlid Navio2 docs](https://docs.emlid.com/navio2/dev/navio-repository-cloning/) — 2026-05-22

<!-- linted: 2026-05-23 -->
