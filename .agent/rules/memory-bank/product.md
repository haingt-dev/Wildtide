# Product: Wildtide

## Core Vision

Post-apocalyptic indirect city builder. The Ancients' failed wormhole experiment shattered civilization and created dimensional Rifts. Players govern a reborn city through policies and faction management, guiding it toward a Science or Magic endgame to deal with the Rifts permanently.

## Design Pillars

### 1. Indirect Sovereignty
Player never directly places buildings (except Emergency Powers during Wave phase: 1-2 barricades/healing zones). All influence via:
- **Edicts** (macro): City-wide policies, max 2-3 active.
- **Quest Approval** (meso): Approve/reject ~4 faction proposals per cycle.
- **Emergency Powers** (micro): Direct placement ONLY during Wave phase.

### 2. Emergent Growth
City is an ecosystem. AI builds autonomously based on Metric values. No manual zoning.

### 3. Living Diorama
Low Poly Stylized aesthetic. 3 visual layers:
1. Static buildings with Science/Magic material swap (required)
2. Ambient grass wind shader + sky color shift (required)
3. Flavor: MultiMesh birds/drones, smoke (nice-to-have)

### 4. The Wave
Periodic "unit test" for player governance. Monsters from 3 Rifts. Escalates per Era.

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

## Endgame Paths

- **Science Path**: Restore Ancient stabilization device → seal Rifts.
- **Magic Path**: Tame Rift energy → transform world to coexist with Waves.

## Wave Scaling

| Era | Cycles | Power | Enemies |
|-----|--------|-------|---------|
| 1 | 1-5 | base×1.0 | Rift Crawlers |
| 2 | 6-10 | base×1.8 | + Rift Stalkers |
| 3 | 11-15 | base×3.0 | + Rift Titan |
| Final | 16 | base×5.0 | All + Rift Core boss |
