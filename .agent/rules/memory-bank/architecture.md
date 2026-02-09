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

### 6. Save System
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
