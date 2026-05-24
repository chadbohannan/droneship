# Custom Firmware — ArduPilot

ArduPilot's modular architecture and Waf build system make it straightforward to build customised firmware: disable features to reclaim flash on memory-constrained boards, add new sensor drivers, write custom control modes, or extend the Lua scripting API.

## Overview

Custom builds fall into three categories: **configuration builds** (disable/enable features at compile time without modifying C++ source), **library extensions** (add or modify C++ libraries), and **Lua scripting** (add vehicle logic without recompiling). Lua scripting is the easiest and safest path for most customisation — see [Lua Scripting](lua-scripting.md).

## Configuration Builds

Disable unused features to reduce flash usage on F4 boards or to produce a minimal build:

```bash
./waf configure --board=CubeOrange \
  --disable-scripting \
  --disable-logging \
  --disable-terrain
```

Enable optional features:
```bash
./waf configure --board=CubeOrange \
  --enable-dds       # ROS2/DDS support
```

Run `./waf configure --help` for the full list of `--enable-*` and `--disable-*` flags. Each flag corresponds to a `AP_FEATURE_*` compile-time constant.

## Extra hwdef Customisation

For board-level customisation (pin reassignments, enabling additional peripherals) without modifying the source tree:

```bash
./waf configure --board=CubeOrange --extra-hwdef=my_board.dat
./waf copter
```

`my_board.dat` uses the same syntax as the board's built-in `hwdef.dat` and is applied on top of the base configuration.

## Writing a Custom Library

1. Create `libraries/AP_MyFeature/AP_MyFeature.h` and `.cpp`.
2. Declare parameters using `AP_PARAM_TABLE` and the `AP_Param` macros.
3. Register the library's scheduler task in the vehicle's task table (e.g., `ArduCopter/Copter.h`).
4. Build with `./waf copter`.

The [ArduPilot developer documentation](https://ardupilot.org/dev/) provides tutorials for adding parameters, sensor backends, and motor mixing extensions.

## Custom Motor Mixing

Set `FRAME_CLASS = 15` (scripting matrix) to define motor mixing entirely in Lua, or implement a new mixing matrix in `AP_MotorsMatrix` if you need a frame type not covered by the built-in set. See [Motor Mixing and Output](motor-mixing.md).

## Extending the Lua API

ArduPilot's Lua API is code-generated from `libraries/AP_Scripting/generator/src/desc.desc`. Adding a new binding exposes C++ functionality to Lua:

1. Add the method signature to `desc.desc`.
2. Regenerate bindings: `Tools/scripts/generate_scripting_bindings.py`
3. Implement the wrapped C++ function if it doesn't already exist.

## Coding Conventions

ArduPilot C++ uses a project-specific style documented in `AGENTS.md`. Key rules beyond standard formatting:

- **Singleton access:** use `get_singleton()` and `CLASS_NO_COPY()` macros; never create multiple instances of core subsystem objects.
- **Hardware access:** declare `extern const AP_HAL::HAL& hal;` at the top of any `.cpp` that touches hardware directly.
- **Float comparisons:** prefer `is_zero()`, `is_positive()`, `is_negative()` over `== 0.0f` or `> 0`.
- **User messages:** use `GCS_SEND_TEXT(MAV_SEVERITY_INFO, "msg")`, not `printf()` or raw `gcs().send_text()`.
- **Time:** use `AP_HAL::millis()` / `AP_HAL::micros()` — never platform-specific `millis()` or `clock()`.
- **Optional features:** wrap feature code in `#if AP_<FEATURE>_ENABLED` / `#endif` guards. Register non-trivial build options in `Tools/scripts/build_options.py` (150+ options already defined). A core subsystem must compile fully when any optional feature is disabled.
- **Formatting:** format only the lines you changed — do not reformat whole files; doing so breaks `git blame`.

## Commit Message Format

```
Subsystem: short description of the change

Optional longer body explaining why, not what.
```

Rules:
- First line must contain `:` (e.g., `Copter:`, `AP_NavEKF3:`, `GCS_MAVLink:`, `Tools:`). Use `git blame` to find the conventional prefix for the changed file.
- First line ≤ 72 characters.
- No merge commits — always rebase onto the target branch.
- No `fixup!` commits — squash before review.
- One logical change per commit.

## CI Gates

Every pull request triggers these checks (see `.github/workflows/`). Run them on your fork's Actions tab before opening a PR against master:

| Check | What it validates |
|-------|-----------------|
| SITL tests | Full autotest suite for Copter, Plane, Rover, Sub, Tracker, Blimp |
| C++ unit tests | GCC + Clang matrix (GTest) |
| ChibiOS hardware builds | Firmware compiles for representative boards |
| `astyle` | C++ formatting matches project style |
| `flake8` | Python linting in `Tools/` |
| Commit format | `:` prefix present, no merge commits, no `fixup!` |
| Binary size | Tracks flash usage; large regressions block merge |
| Pre-commit hooks | Line endings, codespell, large files, XML/YAML validity |
| Markdown linting | Wiki and docs files |

All checks must pass. Check your fork's Actions tab before requesting review.

## Contributing Upstream

ArduPilot uses GitHub pull requests. The process:

1. Fork `ArduPilot/ardupilot`.
2. Create a feature branch: `git checkout -b my-feature`.
3. Follow the coding conventions above and the [style guide](https://ardupilot.org/dev/docs/style-guide.html).
4. Add or update autotest coverage if the change affects flight behaviour — the autotest framework is the canonical regression layer.
5. Open a PR with a clear description of what changed and why.
6. CI runs [SITL](sitl.md) tests automatically; all must pass before review.

Most contributions start as forum discussions at discuss.ardupilot.org before a PR is opened. Check if a related PR is already open — duplicate work within six months is discouraged.

## Versioning Custom Builds

Custom builds should set `GIT_VERSION` or include a build tag so the autopilot reports its version distinctly. Mission Planner and MAVProxy display firmware version in the status window. Use a fork or a branch name that distinguishes your builds from official releases.

## Related Concepts

- [Architecture](architecture.md)
- [Build System](build-system.md)
- [AP_HAL](ap-hal.md)
- [Lua Scripting](lua-scripting.md)
- [SITL Simulation](sitl.md)

## Sources

- [Building the Code — ArduPilot dev docs](https://ardupilot.org/dev/docs/building-the-code.html) — 2026-05-22
- [Developer Introduction — ArduPilot dev docs](https://ardupilot.org/dev/docs/learning-ardupilot-introduction.html) — 2026-05-22
- [AGENTS.md — ArduPilot GitHub](https://github.com/ArduPilot/ardupilot/blob/master/AGENTS.md) — 2026-05-23
- [Coding Style — ArduPilot dev docs](https://ardupilot.org/dev/docs/style-guide.html) — 2026-05-23

<!-- linted: 2026-05-23 -->
