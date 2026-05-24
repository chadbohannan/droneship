# Navio2 SITL

Running ArduPilot Software in the Loop simulation on a Raspberry Pi or x86 host to develop and validate Navio2 firmware before connecting real hardware.

## Overview

SITL compiles ArduPilot for a software-only `sitl` board target and runs the full flight stack — EKF, MAVLink, parameter system, Lua scripts — against a built-in flight dynamics model (FDM). No ESCs, motors, or sensors are required. The simulated vehicle responds to GCS commands and RC input exactly as the real one would.

For Navio2 development, SITL fills two roles: rapid iteration on an x86 workstation before cross-compiling for the RPi, and hardware-free flight testing directly on the Raspberry Pi itself when the airframe is not assembled. Both approaches use the same ArduPilot parameter namespace, so parameters tuned or calibrated in SITL transfer directly to the real vehicle.

## Two Workflows

### x86 SITL (recommended for development)

Build and run SITL on a Linux workstation or laptop. Use this for: writing and testing code, validating parameter changes, testing Lua scripts, and mission planning before deploying to the Raspberry Pi.

```bash
# On x86 host — clone and set up build environment (once)
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot
cd ardupilot
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile

# Launch SITL for ArduCopter
Tools/autotest/sim_vehicle.py -v ArduCopter --console --map

# Or wipe parameters to defaults first:
Tools/autotest/sim_vehicle.py -v ArduCopter --console --map -w
```

When code is ready, cross-compile for Navio2 and deploy:

```bash
./waf configure --board=navio2
./waf copter
scp build/navio2/bin/arducopter pi@navio.local:/usr/bin/arducopter
ssh pi@navio.local "sudo systemctl restart ardupilot"
```

See [Building ArduPilot for Navio2](ardupilot-configuration.md#building-ardupilot-from-source) and the [Build System](../../flight-controller-software/ardupilot/build-system.md) article for full cross-compilation details.

### Native SITL on Raspberry Pi

Run SITL directly on the Raspberry Pi — useful when the airframe is not ready but the RPi and networking are available, or when you want to test a new ArduPilot binary in simulation before switching the live service.

```bash
# On the Raspberry Pi — build environment setup (once)
git clone --recurse-submodules https://github.com/ArduPilot/ardupilot
cd ardupilot
Tools/environment_install/install-prereqs-ubuntu.sh -y
. ~/.profile

# Build SITL binary on the Pi (slow — ~20 min on RPi 4)
./waf configure --board=sitl
./waf copter
```

Launch headlessly (no display attached to Pi):

```bash
Tools/autotest/sim_vehicle.py -v ArduCopter \
  -A "--serial0=udpclient:192.168.1.10:14550" \
  --no-rebuild
```

Replace `192.168.1.10` with your GCS laptop's IP. SITL forwards MAVLink over UDP so Mission Planner or QGroundControl connects identically to a real Navio2 flight.

## Connecting a GCS

SITL outputs MAVLink on UDP port 14550 by default. To connect:

- **Mission Planner:** Initial Setup → Connect → UDP → port 14550.
- **QGroundControl:** Detects UDP automatically on start.
- **MAVProxy (remote):** `mavproxy.py --master=udp:127.0.0.1:14550 --out=udp:<gcs_ip>:14551`

To forward MAVLink from a Pi running SITL to a GCS on the same LAN:

```bash
# On the Pi — add a MAVProxy output
# MAVProxy starts automatically with sim_vehicle.py
output add 192.168.1.10:14551
```

Or pass the GCS IP directly at launch:

```bash
sim_vehicle.py -v ArduCopter \
  -A "--serial0=udpclient:192.168.1.10:14550" --no-rebuild
```

## Navio2 Parameter Parity

The `sitl` build uses the same parameter names as the `navio2` build. Set Navio2-specific defaults in SITL before flight:

```
param set INS_USE 1
param set INS_USE2 1
param set BATT_MONITOR 4
param set BATT_VOLT_PIN 2
param set BATT_CURR_PIN 3
param set GPS_TYPE 2
```

Save these in a parameter file and load at SITL startup:

```bash
sim_vehicle.py -v ArduCopter --add-param-file=navio2_defaults.parm --console --map
```

This ensures SITL behaves identically to the real vehicle and that parameters are ready to upload when transitioning to hardware.

## Transitioning from SITL to Real Hardware

The SITL → hardware transition requires no GCS reconfiguration — only the ArduPilot process changes:

1. Stop the SITL process (Ctrl+C or `pkill sim_vehicle`).
2. Start the real ArduPilot service: `sudo systemctl start ardupilot`.
3. Connect Mission Planner to the same IP and port — the RPi still outputs MAVLink over UDP.
4. Upload any parameters changed during SITL via Mission Planner's Full Parameter List.

## MAVProxy Essentials for SITL

MAVProxy starts automatically with `sim_vehicle.py`. Key commands:

```bash
arm throttle              # arm (bypasses pre-arm checks in SITL)
mode guided               # switch to Guided mode
guided 37.123 -122.456 50 # fly to lat/lon/alt
mode auto                 # execute loaded mission
wp list                   # view waypoints
wp load mission.txt       # load a mission file
log download              # download last dataflash log
param save navio2.parm    # save current params to file
graph ATT.Roll            # live roll angle plot
output add 192.168.1.5:14551  # forward MAVLink to second GCS
```

See [MAVProxy](../../flight-controller-software/ardupilot/mavproxy.md) for the full command reference.

## Running SITL with Gazebo

For sensor-realistic simulation (lidar, cameras, optical flow) or complex environments, connect SITL to Gazebo. On an x86 host:

```bash
# Terminal 1 — Gazebo with ArduPilot plugin
gz sim -v4 -r iris_runway.sdf

# Terminal 2 — SITL connected to Gazebo FDM
sim_vehicle.py -v ArduCopter -f gazebo-iris --model JSON --map --console
```

See [Gazebo SITL](../../flight-controller-software/ardupilot/gazebo-sitl.md) for installation and ROS integration details.

## Performance Notes

Native SITL on Raspberry Pi is functional but slow to compile and runs at reduced simulation speed. For active development, build on an x86 host. Use native RPi SITL for final validation of a binary before deploying it to the flight service.

Raspberry Pi SITL performance by model:

| RPi Model | Compile time (ArduCopter) | Sim speed |
|-----------|--------------------------|-----------|
| RPi 3B+ | ~45 min | 0.5–0.8× |
| RPi 4B (4 GB) | ~20 min | 1.0–1.5× |

Run at reduced simulation time steps if the Pi cannot maintain real-time:

```bash
sim_vehicle.py -v ArduCopter --speedup 0.5 --no-rebuild
```

## Related Concepts

- [Navio2](navio2.md)
- [Navio2 ArduPilot Configuration](ardupilot-configuration.md)
- [SITL — Software in the Loop](../../flight-controller-software/ardupilot/sitl.md)
- [MAVProxy](../../flight-controller-software/ardupilot/mavproxy.md)
- [Build System](../../flight-controller-software/ardupilot/build-system.md)
- [Gazebo SITL](../../flight-controller-software/ardupilot/gazebo-sitl.md)
- [Navio2 ROS and MAVROS](../../programming/navio2-ros.md)

## Sources

- [SITL Simulator (Software in the Loop) — ArduPilot dev docs](https://ardupilot.org/dev/docs/sitl-simulator-software-in-the-loop.html) — 2026-05-22
- [Setting up SITL on Linux — ArduPilot dev docs](https://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html) — 2026-05-22
- [Building for NAVIO2 on RPi3 — ArduPilot dev docs](https://ardupilot.org/dev/docs/building-for-navio2-on-rpi3.html) — 2026-05-22
- [SITL with Gazebo — ArduPilot dev docs](https://ardupilot.org/dev/docs/sitl-with-gazebo.html) — 2026-05-22

<!-- linted: 2026-05-23 -->
