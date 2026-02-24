# Tech Stack: Wildtide

## Engine & Language

| Component | Choice | Notes |
|-----------|--------|-------|
| **Engine** | Godot 4.6 stable | Pinned via `.godot-version` at repo root |
| **Language** | GDScript only | Minimize toolchain; no .NET SDK dependency on Linux |
| **Fallback** | GDExtension (C++) | Only for surgical optimization (e.g., 500+ NPC pathfinding) |
| **Renderer** | Forward+ | Default Godot 4.x renderer |

## Platform

| Target | Details |
|--------|---------|
| **Primary** | PC — Linux Native (Nobara/Fedora) |
| **Performance** | 60fps on integrated AMD Radeon (Steam Deck tier) |

## Save System

- **Format**: JSON (Godot `FileAccess` + `JSON` classes)
- **Structure**: Split files for debug friendliness (7 JSON files per slot)
  - `save/meta.json` — save name, timestamp, era, cycle count, scenario_id
  - `save/world.json` — terrain, building positions, rift states, zone_type, ambient_threat_level
  - `save/metrics.json` — all metric values
  - `save/factions.json` — faction states, active quests, offensive quests
  - `save/economy.json` — gold, mana, capacity, rift shards
  - `save/stability.json` — stability value, alert level
  - `save/edicts.json` — active edicts + embedded movement data
- **Version**: SaveSerializer v3 (backward-compatible via `.get()` defaults)
- **Autosave**: At start of each Wave phase
- **Encryption**: None for MVP (single-player)

## Data Architecture

- All game data stored as Godot Resources (`.tres`)
- Policy data, Quest definitions, Metric interaction matrix → `.tres` files
- Game mode presets (Normal/Hell/Zen) → alternative `.tres` weight files

## Hex Grid & Terrain

- **Custom `HexGrid` Resource** — Godot `GridMap` doesn't support hexagonal grids natively; requires custom implementation
- **Coordinate system**: Cube coordinates (q, r, s) internally, offset coordinates for display/rendering
- **Per-hex data**: Biome type, building reference, terrain modifiers, exploration state — all stored in the `HexGrid` Resource
- **Rendering**: Each hex = 1 `Node3D` + `MeshInstance3D`; `MultiMeshInstance3D` for optimization at scale (~200-300 hexes)
- **Biome data**: 5 types (Plains, Forest, Rocky/Highland, Swamp, Ruins) stored per-hex, affects gameplay modifiers

## Shader Budget (MVP: 4 max)

1. Terrain grass-wind sway (vertex displacement)
2. Building material swap (Science/Magic toggle via uniform)
3. Sky/atmosphere color shift (Wave omen + day/night)
4. Water/pollution tint

## Selected Art Assets

| Asset Pack | Usage | Source |
|------------|-------|--------|
| **`kenney_pirate-kit`** | Coastal buildings, defense structures, docks, walls | [Kenney.nl](https://kenney.nl/assets/pirate-kit) — CC0 |
| **`kenney_fantasy-town-kit_2.0`** | City buildings, houses, market, town infrastructure | [Kenney.nl](https://kenney.nl/assets/fantasy-town-kit) — CC0 |

**Asset Strategy**: Use Kenney kits as prototype base. `pirate-kit` covers coastal/defense aesthetic (The Wall faction, docks, fortifications). `fantasy-town-kit_2.0` covers civilian city buildings (houses, markets, workshops). Both are CC0, low-poly, and stylistically compatible for the Living Diorama pillar.

## Art Style

- **Style**: Low Poly Stylized Diorama
- **Camera**: Limited Orbit (90° rotation), tilt-shift post-MVP
- **Visual Swap**: Shared mesh, swap Materials/Props based on Science/Magic alignment
- **Mass Objects**: `MultiMeshInstance3D` for birds (Magic) / drones (Science), grass, particles

## Testing

| Component | Choice | Notes |
|-----------|--------|-------|
| **Framework** | GUT 9.x (Godot Unit Testing) | `addons/gut/` plugin |
| **Config** | `.gutconfig.json` | Test dirs, prefix, log level |
| **Unit tests** | `test/unit/` | `test_*.gd` files extending `GutTest` |
| **Integration tests** | `test/integration/` | Cross-system tests |
| **Test fixtures** | `test/fixtures/` | Mock resources, test data |
| **CLI run** | `godot -d -s --path /absolute/path addons/gut/gut_cmdln.gd` | Use absolute path, `$PWD` fails |
| **Current** | 856 tests across 55 files | 54 unit + 1 integration |

## Debug & Tooling

- `MetricDebugPanel` — in-game overlay (debug builds only), real-time metric display
- CSV metric snapshots per cycle — balance via data, not theory
- `.godot-version` file pinning engine version
- `gdtoolkit 4.5.0` — GDScript linter (`gdlint`) and formatter (`gdformat`), configured via `.gdtoolkit` at project root
  - `pip install --user gdtoolkit` (Python 3.14, user-local install)
  - Settings: 120-char line length, 60-line max function, 500-line max file

## Excluded from MVP

- Dynamic water, weather system, tilt-shift post-process
- GPU particles (use MultiMesh instead for compatibility)
- C# bindings
- Save encryption
- Quest failure logic
- Player-initiated quest builder
