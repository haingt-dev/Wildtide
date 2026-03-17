# Wildtide

An indirect auto-city builder where you govern through policies, not direct placement.

*WorldBox meets Frostpunk in a Terra Nil aesthetic.*

## Design Pillars

**Indirect Control** -- You don't place buildings or move units. You issue edicts, set policies, and shape incentives. Your settlement grows (or collapses) based on the systems you put in motion.

**Living Ecosystem** -- Factions compete for resources and influence. The economy shifts with supply and demand. Threats emerge from the environment, not just from scripted events. The world doesn't wait for your input.

**Wave Survival** -- Periodic threat escalations force hard trade-offs. Each wave demands preparation, resource allocation, and sometimes sacrificing one system to save another.

## Project Status

Early prototype. Core systems are implemented: hex terrain generation, building placement, faction dynamics, threat/wave system, economic simulation, edict system, stability tracking, utility AI, save/load, and scenario loading. Unit and integration tests cover the major subsystems. Active development.

## Codebase

| | |
|---|---|
| Engine | Godot 4.6 (Forward+) |
| Language | GDScript |
| Physics | Jolt |
| Testing | GUT (Godot Unit Test) |
| Platform | PC (Linux native, Steam Deck tier) |

```
Wildtide/
├── scripts/         # GDScript source
├── scenes/          # Godot scenes (.tscn)
├── assets/          # Art, audio, fonts
├── test/            # Unit and integration tests (GUT)
├── docs/            # Game design documentation
├── addons/          # Godot plugins (GUT)
├── .gdtoolkit       # GDScript lint/format config
└── project.godot    # Godot project file
```

## Development Setup

### Prerequisites

- [Godot 4.6 stable](https://godotengine.org/download)
- Python 3.x with `gdtoolkit` (`pip install --user gdtoolkit`)

### Run

1. Clone the repository
2. Open `project.godot` in Godot 4.6
3. F5

### Lint and Format

```bash
gdlint scripts/
gdformat --check scripts/
gdformat scripts/
```

Configuration: [`.gdtoolkit`](.gdtoolkit)

---

All rights reserved. Source shared for portfolio and educational purposes.
