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
- JSON-based, split files: `meta.json`, `world.json`, `metrics.json`, `factions.json`
- Autosave at start of each Wave phase
- No encryption for MVP

## Rendering
- Godot 4.x Forward+ renderer
- `MultiMeshInstance3D` for mass objects (grass, birds, drones)
- 4 custom shaders max (terrain wind, building material swap, sky shift, water tint)
- Target: 60fps on integrated AMD Radeon (Steam Deck tier)

## Key Patterns
- **Resources everywhere**: Policy data, Quest data, Metric matrix all in `.tres`
- **No C#**: GDScript only. C++ GDExtension only if pathfinding bottleneck for 500+ NPCs.
