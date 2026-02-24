# Product: Wildtide

## Core Vision

Post-apocalyptic indirect city builder. The Ancients' failed wormhole experiment shattered civilization and created dimensional Rifts. Players govern a **moving city** through policies and faction management, migrating across a large fixed map to find resources and leaving ghost footprints behind — mirroring The Ancients' cycle. Guide your civilization toward a Science or Magic endgame to deal with the Rifts permanently.

## Design Pillars

### 1. Indirect Sovereignty
Player never directly places buildings (except Emergency Powers during Wave phase: 1-2 barricades/healing zones). All influence via:
- **Edicts** (macro): City-wide policies, max 2-3 active.
- **Quest Approval** (meso): Approve/reject ~4 faction proposals per cycle.
- **Emergency Powers** (micro): Direct placement ONLY during Wave phase.

### 2. Emergent Growth
City is an ecosystem. AI builds autonomously based on Metric values. No manual zoning.
- **City Must Grow**: Horizontal sprawl visible each cycle, visual connectors between adjacent buildings, Era transition as "wow moment".

### 3. Living Diorama
Low Poly Stylized aesthetic. 3 visual layers:
1. Static buildings with Science/Magic material swap (required)
2. Ambient grass wind shader + sky color shift (required)
3. Flavor: MultiMesh birds/drones, smoke (nice-to-have)

**Metric Visual Feedback** (MVP): Pollution → sky/trees degrade, Anxiety → NPC chaos, Harmony → warm colors. Player reads city state visually.

### 4. The Wave
Periodic "unit test" for player governance. **Kaiju-class entities** from 3 fixed Rifts + high-density Rift regions. Escalates per Era.
- **Rift Density System**: Per-region density increases near win condition. Waves spawn from 3 fixed Rifts AND high-density regions city passes through.
- **Region Modifier**: Low ×0.8, Medium ×1.0, High ×1.5, Rift Core ×2.0. Formula: `base × Era_multiplier × Region_modifier`.
- **Regional Behavior**: Low density = predictable, 1-2 directions. High density = multi-directional, higher elite ratio.
- **Summon the Tide**: Player can trigger Wave early — cost 50% Mana/Gold, 80% power, 60% rewards, max 1/cycle.

## Terrain & Environment

### Hex Grid Terrain
- Flat-top hexagonal grid, **large fixed map ~1500-2000 hexes** (not procedural — hand-crafted)
- City footprint: sliding window ~200-300 active hexes at any time
- Cube coordinates internally (q, r, s)
- Custom `HexGrid` Resource (Godot GridMap doesn't support hex)
- **Fog of War**: Hidden → Revealed → Active → Inactive. Reveal radius ~3-4 hex around city. Scout quest (The Lens) reveals ahead.
- **Map regions**: Starting (low density) → Mid (medium) → Late (high) → Rift Core (endgame, ×2.0)

### Biomes (5 types)

Each hex belongs to one biome. Biomes apply gameplay modifiers:
- **Plains** — Default, balanced. No special modifiers. Neutral alignment.
- **Forest** — +Harmony push, 0.7x construction speed. **Magic alignment**.
- **Rocky/Highland** — +20% Defense, 1.5x Gold, 0.5x Mana. **Science alignment**.
- **Swamp** — +Pollution push, 0.5x construction speed, -10% Defense. Neutral alignment.
- **Ruins** — +Anxiety push, 0.6x construction speed. Contains Ancient Ruins. Neutral alignment.

Biomes are **static in MVP** — Pollution degrades visuals only (withered trees, water color change), not gameplay stats.

### Ancient Ruins Exploration

- 3 ruin types: Observatory (3 Tech Fragments + Wave preview), Energy Shrine (3 Rune Shards + Mana buff), Archive Vault (1+1 mixed + **Sovereign Quest unlock**)
- Exploration duration: 2 cycles (Observatory, Shrine), 3 cycles (Vault)
- Exhaustible resources — ruins deplete after extraction
- Depleted ruins: buildable but -30% construction speed. Damaged by Wave: yield reduced 50%
- Environmental lore delivery via tooltip flavor text
- Faction quests can target specific ruins

## Core Loop

**Observe (3min)** → **Influence (3min)** → **Wave (1min)** → **Evolve (1min)**

- ~8 min/cycle at 1x speed
- 16 cycles to endgame (~2 hour campaign)
- Speed options: 1x, 2x, 3x
- Observe phase cannot be hard-skipped (it IS the game identity)

## Factions (4)

| Faction | Alignment | Role |
|---------|-----------|------|
| **The Lens** | Science | Engineers, restore Ancient tech |
| **The Veil** | Magic | Mages, channel Rift energy |
| **The Coin** | Neutral | Commerce, resource supply |
| **The Wall** | Neutral | Military, defense focus |

Each submits 1 quest/cycle. Player approves/rejects during Influence phase.

## Moving City

City is not stationary — it migrates across a large fixed map.

**Migration triggers:** Resource depletion, Pollution/damage too heavy, Faction request, Migration Edict (triggers faction proposals), Sovereign Quest "Mandate Migration" (override — 70% reserves, 1/Era cooldown). NO direct player trigger (Indirect Sovereignty pillar).

**Movement Requests:** Factions submit movement requests alongside building quests during Influence phase:
- **The Lens** → Regions with Ancient Ruins / minerals (Tech Fragment farming)
- **The Veil** → High Rift density regions (Rune Shard farming)
- **The Coin** → Resource-diverse regions (trade route potential)
- **The Wall** → "Stay and Fortify" counter-proposal

**Ghost Footprints:** City leaves abandoned hexes behind. The Ancients' ruins ARE their ghost footprints — player repeats the same cycle (environmental storytelling through gameplay).

**Revisiting:** Player can return to old locations but land has changed (depleted resources, possible new ruins).

## Endgame Paths

- **Science Path — "Wormhole Stabilizer"**: Collect Tech Fragments from Ancient Ruins scattered across map. Build device to seal all Rifts permanently. Late-game heavy resource requirement (Factorio rocket analogy).
- **Magic Path — "The Accord"**: Gather Rune Shards from Energy Shrines + Rift-adjacent zones. Ritual to merge city energy with Wave — coexistence instead of conflict. Equivalent late-game cost.

## Wave Scaling

| Era | Cycles | Power | Enemies |
|-----|--------|-------|---------|
| 1 | 1-5 | base×1.0 | Rift Crawlers |
| 2 | 6-10 | base×1.8 | + Rift Stalkers |
| 3 | 11-15 | base×3.0 | + Rift Titan |
| Final | 16 | base×5.0 | All + Rift Core boss |

## Asset Pipeline

- **Tool**: Meshy.ai (text-to-3D), fallback Tripo3D. Workflow: Meshy → Blender (decimate) → Godot GLB.
- **No texture maps** — flat color materials only (consistent style, easy Science/Magic swap, better perf).
- **Building Evolution**: 3 mesh tiers per Era × 2 alignments = 6 visual states per type. MVP: ~30 meshes total (includes 4 weapon buildings).

## GDD Status

- **20 sections** total (as of 2026-02-25)
- All sections internally consistent, fully cross-referenced, production-ready
- All contradictions and ambiguities resolved (2 audit rounds complete)
