# PyMAVLink

PyMAVLink is the low-level Python MAVLink library. It parses and generates MAVLink messages for any dialect, handles connection multiplexing, and underlies both MAVProxy and DroneKit. Use it directly when you need raw MAVLink access beyond what higher-level SDKs expose.

## Overview

PyMAVLink generates dialect-specific Python modules from XML message definitions. The `mavutil` module provides connection management; the generated dialect module provides message constructors and constants. MAVProxy and DroneKit both use PyMAVLink internally — understanding it directly is valuable for protocol debugging and custom telemetry applications.

## Installation

```bash
pip install pymavlink
```

## Connecting

```python
from pymavlink import mavutil

# Serial
master = mavutil.mavlink_connection('/dev/ttyUSB0', baud=57600)

# UDP (listen)
master = mavutil.mavlink_connection('udpin:0.0.0.0:14550')

# UDP (connect)
master = mavutil.mavlink_connection('udpout:192.168.1.10:14550')

# TCP
master = mavutil.mavlink_connection('tcp:127.0.0.1:5760')

# SITL (pipe)
master = mavutil.mavlink_connection('tcp:localhost:5762')
```

## Waiting for Heartbeat

```python
master.wait_heartbeat()
print(f"Heartbeat from sysid {master.target_system}, "
      f"compid {master.target_component}")
```

## Receiving Messages

```python
# Receive any next message (non-blocking returns None if no data)
msg = master.recv_match(blocking=False)

# Receive specific type (blocking)
msg = master.recv_match(type='ATTITUDE', blocking=True)
if msg:
    print(f"Roll: {msg.roll:.3f} rad")

# Receive with condition filter
msg = master.recv_match(
    type='SYS_STATUS',
    condition='SYS_STATUS.voltage_battery > 14000',
    blocking=True,
    timeout=5)
```

`recv_match()` returns a message object with fields accessible as attributes. Returns `None` on timeout or if no matching message arrives.

## Sending Commands

### COMMAND_LONG

```python
# Arm
master.mav.command_long_send(
    master.target_system,
    master.target_component,
    mavutil.mavlink.MAV_CMD_COMPONENT_ARM_DISARM,
    0,      # confirmation
    1,      # param1: 1=arm, 0=disarm
    0, 0, 0, 0, 0, 0)

# Change mode
master.mav.command_long_send(
    master.target_system,
    master.target_component,
    mavutil.mavlink.MAV_CMD_DO_SET_MODE,
    0,
    mavutil.mavlink.MAV_MODE_FLAG_CUSTOM_MODE_ENABLED,
    4,      # ArduCopter mode 4 = Guided
    0, 0, 0, 0, 0)
```

### Request Data Stream (Legacy)

```python
master.mav.request_data_stream_send(
    master.target_system,
    master.target_component,
    mavutil.mavlink.MAV_DATA_STREAM_ALL,
    4,      # 4 Hz
    1)      # 1=start, 0=stop
```

### Parameter Get/Set

```python
# Request parameter
master.mav.param_request_read_send(
    master.target_system,
    master.target_component,
    b'ATC_RAT_RLL_P',
    -1)     # -1 = use name, not index

msg = master.recv_match(type='PARAM_VALUE', blocking=True, timeout=3)
if msg:
    print(f"{msg.param_id}: {msg.param_value}")

# Set parameter
master.mav.param_set_send(
    master.target_system,
    master.target_component,
    b'ATC_RAT_RLL_P',
    0.15,
    mavutil.mavlink.MAV_PARAM_TYPE_REAL32)
```

## Reading All Parameters

```python
master.mav.param_request_list_send(
    master.target_system,
    master.target_component)

params = {}
while True:
    msg = master.recv_match(type='PARAM_VALUE', blocking=True, timeout=2)
    if msg is None:
        break
    params[msg.param_id] = msg.param_value
    if msg.param_index + 1 == msg.param_count:
        break

print(f"Received {len(params)} parameters")
```

## Dialects

PyMAVLink generates Python modules for each MAVLink dialect:

```python
from pymavlink.dialects.v20 import ardupilotmega as mavlink2
```

`ardupilotmega` includes all ArduPilot-specific messages. `common` includes the base MAVLink common messages.

## Message Logging to File

```python
# Open a log connection to record all messages to a .tlog file
master = mavutil.mavlink_connection('udpin:0.0.0.0:14550')
log = mavutil.mavlink_connection('tlog:/tmp/flight.tlog', input=False)

while True:
    msg = master.recv_match(blocking=True)
    if msg:
        log.write(msg)
```

`.tlog` files are compatible with Mission Planner, MAVExplorer, and UAV LogViewer.

## Relationship to DroneKit and MAVProxy

- **MAVProxy** uses PyMAVLink for all MAVLink parsing and as its connection layer
- **DroneKit** wraps PyMAVLink with a higher-level Vehicle API
- **MAVSDK** has its own C++ MAVLink implementation; PyMAVLink is not involved

For protocol debugging or custom applications, PyMAVLink provides the most direct access to MAVLink without abstraction overhead.

## Related Concepts

- [MAVLink Protocol](../flight-controller-software/ardupilot/mavlink.md)
- [DroneKit](dronekit.md)
- [MAVSDK](mavsdk.md)
- [Ground Control Stations](../flight-controller-software/ardupilot/gcs.md)
- [SITL — Software in the Loop](../flight-controller-software/ardupilot/sitl.md)

## Sources

- [PyMAVLink Documentation — mavlink.io](https://mavlink.io/en/mavgen_python/) — 2026-05-22
- [PyMAVLink GitHub](https://github.com/ArduPilot/pymavlink) — 2026-05-22

<!-- linted: 2026-05-23 -->
