# Architecture: Wildtide

## High-Level Design

**Data-driven architecture** using Godot Resources (`.tres`) as the backbone for all game data.

## Core Systems

### 1. Cycle System
- `CycleTimer` Resource with configurable durations per phase
- 4 phases: Observe (3min) → Influence (3min) → Wave (1min) → Evolve (1min)
- Game speed multiplier: 1x, 2x, 3x
- Observe auto-transitions when resource threshold met OR time expires

### 2. Metric System ("The Matrix")
- **Alignment Axis**: `Science (S) vs Magic (M)` — `Alignment = (S-M)/(S+M)`, range [-1.0, +1.0]
- **4 State Metrics**: Pollution, Anxiety, Solidarity, Harmony
- **Interaction Matrix** (4×4 weighted, applied per-cycle):

| Source ↓ / Target → | Pollution | Anxiety | Solidarity | Harmony |
|---|---|---|---|---|
| Pollution | — | +0.3 | 0 | -0.5 |
| Anxiety | 0 | — | -0.3 | -0.2 |
| Solidarity | 0 | -0.2 | — | +0.3 |
| Harmony | -0.4 | -0.1 | +0.2 | — |

- Stored in single `.tres` Resource for easy tweaking
- Game mode presets via alternative `.tres` files (Normal / Hell / Zen)
- `MetricDebugPanel` overlay (debug builds only)
- CSV metric snapshots exported each cycle for balancing

### 3. AI System — Utility AI
- Scoring-based decision system for NPCs
- NPCs autonomously build/act based on World Metrics
- No manual placement by player (except Emergency Powers during Wave)

### 4. Quest System
- 4 factions, each submits 1 quest/cycle
- Player approve/reject during Influence phase
- Quests always complete once approved (no failure in MVP)
- 1 Sovereign Quest slot per Era (pre-designed upgrade choices)

### 5. Wave System
- 3 Rifts per map (fixed positions, random composition)
- Linear scaling with Era step function (base constant in `.tres`)
- History Scars: permanent visual + -20% construction speed on damaged tiles
- **Summon the Tide** (early Wave trigger):
  - Cost: 50% current Mana/Gold reserves
  - Power: 80% of normal Wave
  - Rewards: 60% of normal Rift Shard rewards
  - Cooldown: max 1 per cycle
- **Wave-Biome interaction**:
  - Forest: slows enemies 20%
  - Rocky: natural chokepoints, enemies detour or slow
  - Swamp: no slowdown (enemies adapted to Rift environment)

### 6. Hex Grid System
- **Hex type**: Flat-top hexagons
- **Coordinates**: Cube coordinates internally (q, r, s), offset for display
- **Map size**: ~200-300 hexes per map
- **Implementation**: Custom `HexGrid` Resource class (Godot `GridMap` doesn't support hex natively)
- **Rendering**: Each hex = 1 `Node3D` with `MeshInstance3D`. `MultiMeshInstance3D` optimization for large hex counts.
- **Data**: Each hex stores biome type, building reference, terrain modifiers, exploration state

### 7. Biome System

- **5 biome types**: Plains, Forest, Rocky/Highland, Swamp, Ruins
- Each hex stores its biome type in the `HexGrid` Resource
- Biomes static in MVP — Pollution degrades visuals only (not gameplay stats)

**Biome Stats Table** (source: GDD WT - Biomes):

| Biome | Speed | Gold | Mana | Defense | Metric Push | Alignment |
|-------|-------|------|------|---------|-------------|-----------|
| Plains | 1.0x | 1.0x | 1.0x | 0 | Neutral | Neutral |
| Forest | 0.7x | 0.5x | 1.5x | 0 | +Harmony | Magic |
| Rocky | 0.8x | 1.5x | 0.5x | +20% | -Harmony | Science |
| Swamp | 0.5x | 0.8x | 1.2x | -10% | +Pollution | Neutral |
| Ruins | 0.6x | 1.0x | 1.0x | 0 | +Anxiety | Neutral |

**Map Composition** (~250 hexes, ±5% variance):
Plains 40%, Forest 25%, Rocky 15%, Swamp 10%, Ruins 10%

**Procedural generation rules**:
- Swamp clusters within 3-4 hex radius of Rifts
- Ruins scattered, minimum 5 hex distance apart
- Forest forms clusters (Perlin noise-based)
- Rocky/Highland as dais or clusters (mountain range simulation)
- Plains fill remainder

### 8. Ancient Ruins

**Ruin Types** (source: GDD WT - Ancient Ruins):

| Type | Primary Yield | Secondary | Bonus | Duration | Rarity |
|------|--------------|-----------|-------|----------|--------|
| Observatory | 3 Tech Fragments | — | Wave preview | 2 cycles | ~40% |
| Energy Shrine | 3 Rune Shards | — | Mana buff (3 hex, 2 cycles) | 2 cycles | ~40% |
| Archive Vault | 1 Tech Fragment | 1 Rune Shard | Sovereign Quest unlock | 3 cycles | ~20% |

**Exploration states**: Undiscovered → Discovered → Being Explored → Depleted or Damaged

| State | Interactable | Effect |
|-------|-------------|--------|
| Undiscovered | No | Needs scout/survey to reveal |
| Discovered | Yes | Ready for exploration |
| Being Explored | No | 2-3 cycles in progress |
| Depleted | Yes (buildable) | -30% construction speed |
| Damaged | No | Wave damage, yield reduced 50% |

- **Resources are exhaustible** — ruins deplete after extraction
- **Faction interaction**: Factions may submit quests to exploit specific ruins
- **Environmental lore delivery**: Ruins provide world-building via tooltip flavor text

### 9. Save System
- JSON-based, split files: 4 core (`meta.json`, `world.json`, `metrics.json`, `factions.json`) + 3 extra (`economy.json`, `stability.json`, `edicts.json` with embedded movement data)
- Autosave at start of each Wave phase
- Backward-compatible loading (core files required, extra files optional)
- No encryption for MVP

### 10. Economy System
- `EconomyConfig` Resource (starting gold/mana, capacity, transit penalty, income rates)
- `EconomyManager` Node (gold/mana tracking, spend/earn with capacity clamping, transit production penalty, EVOLVE income ticking)
- `economy_config_normal.tres` preset

### 11. Edict System
- `EdictData` Resource (id, effects dict, duration, cooldown, cost)
- `EdictRegistry` (DirAccess scan from `scripts/data/edicts/`)
- `EdictManager` Node (enact/expire, active edict tracking, EVOLVE tick for duration countdown)
- 8 edict `.tres` templates (boost production, festival, martial law, open borders, ration resources, science/magic priority, migration)

### 12. Stability System
- `StabilityConfig` Resource (thresholds, gain/loss multipliers, alert level breakpoints, stability floor)
- `StabilityTracker` Node (0-100 stability, wave damage/defense assessment, faction morale check, resource depletion tracking, solidarity bonus, festival bonus, artifact failure, 4 alert levels: normal→yellow→red→final, game over trigger)
- Auto-checks resource depletion and solidarity on EVOLVE phase via economy_manager ref

### 13. Movement System (skeleton)
- `MovementManager` Node (city_center Vector3i, transit state, propose/execute/end_transit API, EVOLVE phase hook for transit countdown)
- Full movement logic deferred until large map (~1500 hexes) implementation

### 14. Scenario System
- `ScenarioData` Resource (map_preset, faction_configs, win_conditions, era_cycle_thresholds, starting resources)
- Sub-resources: `MapPreset`, `FactionConfig`, `WinConditionData`, `ScenarioModifier`
- `ScenarioLoader` static utility (load from `res://scripts/data/scenarios/`, apply to game systems)
- `the_wildtide.tres` MVP scenario

### 15. Utility AI Config
- `UtilityAIConfig` Resource (scoring weights: need, affinity, adjacency, faction, penalty; pollution curve; era placement rates; alignment thresholds; performance settings)
- `ai_weights_normal.tres` Normal mode preset
- Behavior logic not yet implemented

## GameManager Extensions
- `scenario_id: StringName` — tracks active scenario (default: `&"the_wildtide"`)
- `era_cycle_thresholds: Array[int]` — cycle numbers where each era begins (default: `[1, 6, 11, 16]`)
- `get_current_era() -> int` — derived from cycle_number and thresholds

## HexCell Extensions
- `fog_state: int` — FogState enum (HIDDEN, REVEALED, ACTIVE, INACTIVE)
- `region: int` — RegionType enum (STARTING, MID, LATE, RIFT_CORE)
- `rift_density: float` — per-hex Rift density value
- `pollution_level: float` — per-hex pollution accumulation

## Rendering
- Godot 4.x Forward+ renderer
- `MultiMeshInstance3D` for mass objects (grass, birds, drones)
- 4 custom shaders max (terrain wind, building material swap, sky shift, water tint)
- Target: 60fps on integrated AMD Radeon (Steam Deck tier)

## Key Patterns
- **Resources everywhere**: Policy data, Quest data, Metric matrix all in `.tres`
- **No C#**: GDScript only. C++ GDExtension only if pathfinding bottleneck for 500+ NPCs.
