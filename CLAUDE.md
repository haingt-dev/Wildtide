# Wildtide — Project Context for Claude

## Quick Facts

| Field | Value |
|-------|-------|
| **Genre** | Auto-City Builder / Indirect Management / Strategy |
| **Engine** | Godot 4.6 stable (pinned via `.godot-version`) |
| **Language** | GDScript only (GDExtension C++ only for surgical optimization) |
| **Renderer** | Forward+ |
| **Platform** | PC — Linux Native (primary) |
| **Target HW** | AMD integrated GPU (Steam Deck tier), 60 fps |
| **Campaign** | ~2 hours (16 cycles x ~8 min/cycle) |
| **Dev Team** | Solo developer |

## Architecture Overview

Data-driven architecture using Godot Resources (`.tres`) as the backbone for all game data.

### 9 Core Systems

| # | System | Key Responsibility |
|---|--------|--------------------|
| 1 | **HexGrid** | Flat-top hex grid, cube coords (q,r,s), ~250 hexes, custom Resource (no GridMap) |
| 2 | **MetricSystem** | 4 state metrics (Pollution, Anxiety, Solidarity, Harmony) + Alignment axis (Science/Magic) |
| 3 | **CycleTimer** | 4-phase loop: Observe→Influence→Wave→Evolve, speed 1x/2x/3x |
| 4 | **Factions/Quests** | 4 factions (Lens, Veil, Coin, Wall), 1 quest/cycle each, approve/reject |
| 5 | **Wave** | 3 Rifts per map, Era-scaled enemies, History Scars on damaged tiles |
| 6 | **Buildings** | AI-placed structures, Science/Magic material swap, biome modifiers |
| 7 | **Ruins** | 3 types (Observatory, Energy Shrine, Archive Vault), exhaustible resources |
| 8 | **Art/Shaders** | Low Poly Diorama, 4 shaders max (wind, material swap, sky, water) |
| 9 | **SaveSystem** | JSON split files (meta, world, metrics, factions), autosave at Wave start |

### Biome System (5 types)

Plains (default), Forest (+Harmony), Rocky/Highland (+Defense), Swamp (+Pollution, near Rifts), Ruins (exploration).
Each hex stores biome type; biomes affect construction speed, resource yield, defense, metric push, alignment affinity.

## Autoload Singletons

These three autoloads are planned for global state management:

| Singleton | Purpose |
|-----------|---------|
| **GameManager** | Cycle state machine, game speed, phase transitions, pause |
| **MetricSystem** | Metric values, interaction matrix, alignment calculation |
| **EventBus** | Global signal bus for cross-system communication |

All other systems use composition and node-based architecture — no additional autoloads.

## Folder Structure

```
scripts/
  core/           # GameManager, CycleTimer, EventBus
  metrics/        # MetricSystem, interaction matrix
  ai/             # Utility AI, NPC decisions
  wave/           # Wave spawning, Rift management
  factions/       # Faction logic, quest system
  buildings/      # Building placement, construction
  ruins/          # Ancient ruins exploration
  ui/             # HUD, panels, menus
  data/           # Resource loaders, save/load
  shaders/        # Shader scripts (.gdshader)
  debug/          # MetricDebugPanel, CSV export
  mcp-start.sh    # Tooling (not game code)
  mcp-stop.sh     # Tooling (not game code)

scenes/
  main/           # Main game scene, camera
  hex/            # Hex grid, terrain, biomes
  buildings/      # Building scenes
  ui/             # UI scenes
  wave/           # Wave, Rift, enemy scenes
  debug/          # Debug overlays

test/
  unit/           # GUT unit tests
  integration/    # GUT integration tests
  fixtures/       # Test data, mock resources

addons/
  gut/            # GUT test framework plugin

assets/           # Art, audio, fonts (subdirs by type)
docs/gdd/         # Game Design Document (read-only reference)
```

## Coding Conventions

### Naming Rules

| Element | Convention | Example |
|---------|-----------|---------|
| **Files** | `snake_case` | `hex_grid.gd`, `cycle_timer.tscn` |
| **Classes** | `PascalCase` | `class_name HexGrid` |
| **Functions** | `snake_case` | `func calculate_damage()` |
| **Variables** | `snake_case` | `var health_points: int` |
| **Constants** | `SCREAMING_SNAKE_CASE` | `const MAX_HEALTH: int = 100` |
| **Signals** | `snake_case` past tense | `signal health_changed(new_value: int)` |
| **Enums** | `PascalCase` type, `SCREAMING_SNAKE` values | `enum BiomeType { PLAINS, FOREST }` |
| **Resources** | `snake_case.tres` | `metric_matrix.tres` |

### Style Rules

- **Type hints everywhere**: `var speed: float = 10.0`, `func move(delta: float) -> void:`
- **`@export`** for inspector-editable properties
- **`@onready`** for node references: `@onready var sprite: Sprite3D = $Sprite3D`
- **Composition over inheritance** — prefer child nodes and Resources over deep class hierarchies
- **Signals for loose coupling** — systems communicate via signals, not direct references
- **Resources (`.tres`) for data** — policies, quests, metric weights, game mode presets
- **Max line length**: 120 chars
- **Max function length**: 60 lines
- **Max file length**: 500 lines

### Patterns to Follow

- Data in `.tres` Resources, logic in `.gd` scripts attached to nodes
- Game mode presets (Normal/Hell/Zen) as alternative `.tres` weight files
- Split concerns: one script per system, compose via scene tree
- Use `StringName` for signal names in performance-critical code

### Patterns to Avoid

- No C# — GDScript only
- No Godot `GridMap` for hex (doesn't support hex natively)
- No singletons beyond the 3 planned autoloads
- No quest failure logic in MVP
- No player-initiated quests in MVP
- No save encryption in MVP

## GDD Reference

11-section Game Design Document in `docs/gdd/`:

| Section | File |
|---------|------|
| Master GDD | `GDD - Wildtide.md` |
| Project Overview | `Project - Wildtide.md` |
| Core Vision & Lore | `WT - Core Vision & Lore.md` |
| Design Pillars | `WT - Design Pillars.md` |
| Core Loop | `WT - Core Loop.md` |
| Metric System | `WT - Metric System.md` |
| Quest System | `WT - Quest System.md` |
| The Wave | `WT - The Wave.md` |
| Hexagonal Terrain | `WT - Hexagonal Terrain.md` |
| Biomes | `WT - Biomes.md` |
| Ancient Ruins | `WT - Ancient Ruins.md` |
| Art Direction | `WT - Art Direction.md` |
| Technical Stack | `WT - Technical Stack.md` |

**Do not modify GDD files** without explicit instruction.

## Testing

- **Framework**: GUT 9.x (Godot Unit Testing) — `addons/gut/`
- **Config**: `.gutconfig.json` at project root
- **Test dirs**: `test/unit/`, `test/integration/`
- **Naming**: `test_*.gd` files, extend `GutTest`
- **Run CLI**: `godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd`
- **Run editor**: Project Settings → Plugins → Enable GUT → GUT panel

## Tooling

| Tool | Purpose | Config |
|------|---------|--------|
| **gdtoolkit 4.5.0** | GDScript linter + formatter | `.gdtoolkit` |
| **gdlint** | Lint check | `gdlint <file>` |
| **gdformat** | Auto-format | `gdformat <file>` |
| **pre-commit** | Hooks for gdformat + gdlint | `.pre-commit-config.yaml` |
| **GUT 9.x** | Unit/integration testing | `.gutconfig.json` |

## Memory Bank (for Kilo Code / Antigravity agents)

Context files in `.agent/rules/memory-bank/`:
- `brief.md` — Project goals and scope
- `product.md` — Product context and constraints
- `context.md` — Current focus, active workstreams, recent changes
- `architecture.md` — System architecture and structure
- `tech.md` — Tech stack and tooling

Update these after completing major tasks or architectural changes.
