# 🌊 Wildtide

An indirect auto-city builder where you govern through policies, not direct placement.
*WorldBox meets Frostpunk in a Terra Nil aesthetic.*

## Tech Stack

| Component | Value |
|-----------|-------|
| Engine | Godot 4.6 (Forward+) |
| Language | GDScript |
| Physics | Jolt Physics |
| Platform | PC (Linux native, Steam Deck tier) |

## Getting Started

### Prerequisites

- [Godot 4.6 stable](https://godotengine.org/download)
- Python 3.x with `gdtoolkit` (`pip install --user gdtoolkit`)

### Setup

1. Clone the repository
2. Open `project.godot` in Godot 4.6
3. Run the project (F5)

### GDScript Linting & Formatting

```bash
# Lint all scripts
gdlint scripts/

# Check formatting (dry run)
gdformat --check scripts/

# Auto-format
gdformat scripts/
```

Configuration: [`.gdtoolkit`](.gdtoolkit)

## Project Structure

```
Wildtide/
├── assets/          # Art, audio, fonts
├── docs/gdd/        # Game Design Document (11 sections)
├── scenes/          # Godot scene files (.tscn)
├── scripts/         # GDScript files (.gd)
├── .agent/          # AI agent memory bank
├── .kilocode/       # Kilo Code MCP & container configs
├── .gdtoolkit       # GDScript lint/format config
├── .godot-version   # Pinned engine version (4.6.stable)
└── project.godot    # Godot project file
```

## Documentation

Game design documentation is in [`docs/gdd/`](docs/gdd/):

- [GDD Index](docs/gdd/GDD%20-%20Wildtide.md)
- [Core Vision & Lore](docs/gdd/WT%20-%20Core%20Vision%20%26%20Lore.md)
- [Design Pillars](docs/gdd/WT%20-%20Design%20Pillars.md)
- [Core Loop](docs/gdd/WT%20-%20Core%20Loop.md)
- [Hexagonal Terrain](docs/gdd/WT%20-%20Hexagonal%20Terrain.md)
- [Technical Stack](docs/gdd/WT%20-%20Technical%20Stack.md)
