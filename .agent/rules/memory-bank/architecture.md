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
- "Summon the Tide" early trigger: 50% resource cost, 80% power, 60% rewards
- History Scars: permanent visual + -20% construction speed on damaged tiles

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
- **Biome effects** (per-hex modifiers):
  - Construction speed modifier
  - Resource yield modifier (Gold / Mana)
  - Defense bonus
  - Metric push (e.g., Forest → +Harmony, Swamp → +Pollution)
  - Alignment affinity (Science / Magic / Neutral)
- **Procedural generation rules**:
  - Swamp clusters near Rifts
  - Ruins scattered (low density, semi-random)
  - Forest forms clusters (Perlin noise or similar)
  - Plains as default / filler biome
  - Rocky/Highland at map edges or elevated areas

### 8. Ancient Ruins
- **3 ruin types**:
  - **Observatory** → Tech Fragments + Wave preview intel
  - **Energy Shrine** → Rune Shards + temporary Mana buff
  - **Archive Vault** → Mixed resources + Sovereign Quest unlock
- **Exploration states**: Undiscovered → Discovered → Being Explored → Depleted/Damaged
- **Resources are exhaustible** — ruins deplete after extraction
- **Faction interaction**: Factions may submit quests to exploit specific ruins
- **Environmental lore delivery**: Ruins provide world-building context through exploration

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
