# Tech Stack: Wildtide

## Engine & Language

| Component | Choice | Notes |
|-----------|--------|-------|
| **Engine** | Godot 4.4 stable | Pinned via `.godot-version` at repo root |
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
- **Structure**: Split files for debug friendliness
  - `save/meta.json` — save name, timestamp, era, cycle count
  - `save/world.json` — terrain, building positions, rift states
  - `save/metrics.json` — all metric values
  - `save/factions.json` — faction states, active quests
- **Autosave**: At start of each Wave phase
- **Encryption**: None for MVP (single-player)

## Data Architecture

- All game data stored as Godot Resources (`.tres`)
- Policy data, Quest definitions, Metric interaction matrix → `.tres` files
- Game mode presets (Normal/Hell/Zen) → alternative `.tres` weight files

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

## Debug & Tooling

- `MetricDebugPanel` — in-game overlay (debug builds only), real-time metric display
- CSV metric snapshots per cycle — balance via data, not theory
- `.godot-version` file pinning engine version

## Excluded from MVP

- Dynamic water, weather system, tilt-shift post-process
- GPU particles (use MultiMesh instead for compatibility)
- C# bindings
- Save encryption
- Quest failure logic
- Player-initiated quest builder
