# Build System — ArduPilot

ArduPilot uses the Waf build system to compile firmware for the flight controller hardware, SITL simulation, or a Linux target. Waf handles dependency tracking, board-specific configuration, and incremental builds.

## Prerequisites

ArduPilot requires different dependency sets depending on build target. The `install-prereqs-ubuntu.sh` script handles all of them on Ubuntu/Debian:

```bash
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot
cd ardupilot
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile    # reload PATH — the script appends to it
```

On macOS use Homebrew (`brew`); on Windows use WSL2 running Ubuntu and run the script inside WSL.

### What the script installs

| Group | Key packages |
|-------|-------------|
| **Build tools** | `build-essential`, `g++`, `ccache`, `gawk`, `make`, `git`, `wget`, `valgrind`, `screen`, `astyle` |
| **Python (all targets)** | `pymavlink`, `MAVProxy`, `lxml`, `pyserial`, `geocoder`, `empy==3.3.4`, `ptyprocess`, `dronecan`, `flake8`, `junitparser`, `tabulate` |
| **SITL** | `libtool`, `libxml2-dev`, `libxslt1-dev`, Python dev headers/pip, `numpy`, `pyparsing`, `psutil`, `matplotlib`, `scipy`, `opencv`, SFML graphics libraries, `pyyaml` |
| **Bare-metal (STM32)** | `gcc-arm-none-eabi` 10-2020-q4 — downloaded from `firmware.ardupilot.org/Tools/STM32-tools/` |
| **ARM Linux cross-compile** | `g++-arm-linux-gnueabihf` |

> **`empy==3.3.4` pin is required.** Newer `empy` versions break MAVLink code generation. The script pins the version automatically; manual `pip install empy` without the version pin will break your build environment.

`ccache` is configured automatically during the install and can cut rebuild times by 5–10× on repeated incremental builds. The script adds `ccache` wrappers to your PATH.

## Basic Build

```bash
# Configure for a board
./waf configure --board=CubeOrange

# Build ArduCopter firmware
./waf copter

# Build ArduPlane
./waf plane

# Build all vehicles
./waf bin

# Build and upload to connected board
./waf copter --upload
```

`--upload` waits for the bootloader, then flashes via USB. Do not use `sudo`.

## Common Board Targets

| Board name | Hardware |
|------------|---------|
| `CubeOrange` | CubePilot Cube Orange |
| `CubeOrangePlus` | CubePilot Cube Orange+ |
| `CubeBlack` | Hex/ProfiCNC Cube Black (formerly Pixhawk 2.1) |
| `Pixhawk1` | Original 3DR Pixhawk |
| `Pixhawk6C` | Holybro Pixhawk 6C |
| `Pixhawk6X` | Holybro Pixhawk 6X |
| `MatekH743` | Matek H743-Wing |
| `MatekH743-slim` | Matek H743-Slim |
| `Durandal` | Holybro Durandal |
| `navio2` | Emlid Navio2 on Raspberry Pi (Linux target) |
| `fmuv3` | Generic 3DR Pixhawk 2 boards |
| `bebop` | Parrot Bebop / Bebop 2 (static build required) |
| `sitl` | Software in the Loop simulation |
| `sitl --debug` | SITL with debug symbols for gdb |
| `linux` | Generic Linux target |

List all supported boards:
```bash
./waf list_boards
```

### Vehicle Targets

```bash
./waf copter          # All multirotor types → arducopter
./waf heli            # Helicopter types → arducopter
./waf plane           # Fixed-wing including VTOL
./waf rover           # Wheeled rovers and surface boats
./waf sub             # ROV and submarines
./waf antennatracker  # Antenna trackers
./waf AP_Periph       # CAN peripheral firmware
./waf bin             # All vehicle types in one pass
```

### Single-Binary Targets

Use `--targets` to build exactly one binary without building the whole vehicle group:

```bash
# Build only the ArduCopter binary
./waf --targets bin/arducopter

# Build one unit test
./waf --targets tests/test_math
```

`./waf list` prints every available target name.

### Parallel Builds

Waf auto-detects CPU count and parallelises accordingly. Override with `-j`:

```bash
./waf -j8 copter     # Force 8 parallel jobs (useful with icecc)
./waf -j1 copter     # Single-threaded (reduces heat on slow hosts)
```

### Building with Clang

GCC is the default on Linux; Clang is the default on macOS. To use Clang on Linux:

```bash
CXX=clang++ CC=clang ./waf configure --board=sitl
./waf copter
```

Clang builds are part of the CI matrix — firmware must compile cleanly under both compilers.

## Building for Navio2

Navio2 runs ArduPilot as a Linux userspace process on Raspberry Pi rather than as bare-metal firmware. The board target is `navio2`. You can build directly on the Pi (simple but slow — roughly 15 minutes) or cross-compile on a Linux PC (faster, requires one-time toolchain setup).

### On the Raspberry Pi (native build)

```bash
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot
cd ardupilot
git checkout ArduCopter-stable   # pin to a release tag
./waf configure --board=navio2
./waf copter
```

The binary is placed in `build/navio2/bin/arducopter`. Copy it to `/usr/bin/` or use the systemd service's `ExecStart` override in `/etc/systemd/system/ardupilot.service` to point to the custom binary path.

### Cross-compilation on Linux

Cross-compilation is much faster. Install the Raspberry Pi Foundation toolchain:

```bash
sudo git clone --depth 1 https://github.com/raspberrypi/tools.git /opt/rpi-tools
# For 64-bit host:
export PATH=/opt/rpi-tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin:$PATH
```

Build and transfer:

```bash
./waf configure --board=navio2
./waf copter
rsync -avz build/navio2/bin/arducopter pi@192.168.1.3:/home/pi/
```

On the Pi, make the binary executable and configure the systemd service to use it:

```bash
chmod +x ~/arducopter
# Edit /etc/systemd/system/ardupilot.service:
# ExecStart=/bin/sh -c "/home/pi/arducopter ${ARDUPILOT_OPTS}"
sudo systemctl daemon-reload && sudo systemctl restart ardupilot
```

## Build Options

```bash
./waf configure --board=MatekH743 --debug       # include debug symbols for gdb
./waf configure --board=sitl --consistent-builds # deterministic output
./waf configure --help                           # list all feature flags
```

Feature flags enable or disable compile-time options:
```bash
./waf configure --board=CubeOrange --disable-scripting   # remove Lua to save flash
./waf configure --board=CubeOrange --enable-dds          # enable ROS2/DDS support
```

The `--extra-hwdef <file>` flag applies board customisations without modifying the source tree — useful for field builds that need specific pinout changes:
```bash
./waf configure --board=CubeOrange --extra-hwdef=my_custom.dat
```

## Incremental Builds

Waf tracks dependencies automatically. After `./waf configure`, run `./waf copter` to rebuild only changed files. A full rebuild from scratch:

```bash
./waf distclean   # remove all build artifacts
./waf configure --board=<target>
./waf copter
```

Build output goes to `build/<board>/`. The firmware binary is `build/<board>/bin/arducopter.apj` (for Pixhawk-family boards).

## Uploading via USB Bootloader

`--upload` flashes the compiled binary to a connected board via USB bootloader:

```bash
./waf --targets bin/arducopter --upload
```

For Linux-based boards (Navio2, Raspberry Pi-based targets), configure an rsync destination during `configure`:

```bash
./waf configure --board=navio2 --rsync-dest root@192.168.1.2:/
./waf --targets bin/arducopter --upload
```

The `--upload` option then copies the binary via `rsync` rather than via USB. For package-based deployment, use the explicit `install` step:

```bash
./waf copter
DESTDIR=/tmp/staging ./waf install
# Produces installable tree under /tmp/staging
```

## Uploading via MAVFTP

Instead of physical reflashing, upload firmware to a running vehicle via MAVLink File Transfer Protocol:

1. In Mission Planner: Help → About → Load custom firmware → select `.apj` file
2. Or via MAVProxy: `ftp put arducopter.apj @ROMFS/ardupilot.apj` (board dependent)

MAVFTP upload is slower than USB bootloader but requires no physical access to the board.

## CI/CD

ArduPilot's CI runs the full autotest suite on every pull request via GitHub Actions. Tests build SITL for multiple vehicle types and run scripted flight scenarios. Contributing requires passing all CI checks. See [SITL Simulation](sitl.md) for the autotest framework.

## Related Concepts

- [AP_HAL](ap-hal.md)
- [SITL Simulation](sitl.md)
- [Custom Firmware](custom-firmware.md)
- [Architecture](architecture.md)

## Sources

- [Building the Code — ArduPilot dev docs](https://ardupilot.org/dev/docs/building-the-code.html) — 2026-05-22
- [BUILD.md — ArduPilot GitHub](https://github.com/ArduPilot/ardupilot/blob/master/BUILD.md) — 2026-05-22
- [Building ArduPilot from sources — Emlid Navio2 docs](https://docs.emlid.com/navio2/ardupilot/building-from-sources/) — 2026-05-23

- [AGENTS.md — ArduPilot GitHub](https://github.com/ArduPilot/ardupilot/blob/master/AGENTS.md) — 2026-05-23

<!-- linted: 2026-05-23 -->
