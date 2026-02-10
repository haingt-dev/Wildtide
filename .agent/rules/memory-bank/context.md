# Context: Wildtide

## Current Phase
**Prototype Setup** — GDD is complete and production-ready. No code written yet.

## Project Timeline

| Date | Event |
|------|-------|
| 2026-02-01 | Initial GDD drafted as "Emergent City" |
| 2026-02-08 | GDD restructured into modular notes |
| 2026-02-09 | Renamed to **Wildtide**. All open questions resolved. GDD production-ready. Memory Bank initialized. |
| 2026-02-11 | Added 3 new GDD sections — Hexagonal Terrain (hex grid decision), Biomes (5 biome types), Ancient Ruins (exploration mechanic). GDD now has 11 sections total. |

## Recent Decisions

- **Renamed** from "Emergent City" to "Wildtide"
- **4 Factions**: The Lens, The Veil, The Coin, The Wall
- **3 Rifts per map** (triangle threat pattern)
- **No quest failure in MVP** — approved quests always complete
- **No player-initiated quests in MVP** — approve/reject only + 1 Sovereign Quest per Era
- **4 custom shaders max** for MVP
- **JSON-based save system** (split files)
- **Observe phase cannot be skipped** — it defines the game identity
- **Flat-top hexagonal grid** — cube coordinates internally, ~200-300 hexes per map. Custom `HexGrid` Resource class (Godot GridMap doesn't support hex).
- **5 Biome types** — Plains, Forest, Rocky/Highland, Swamp, Ruins. Each hex stores biome type. Biomes affect construction speed, resource yield, defense bonus, metric push, alignment affinity.
- **Ancient Ruins** — 3 ruin types (Observatory, Energy Shrine, Archive Vault). Exhaustible resources (Tech Fragments, Rune Shards). States: Undiscovered → Discovered → Being Explored → Depleted/Damaged.

## Active Workstreams

- **Hex grid terrain system** needs implementation — custom `HexGrid` Resource class, no Godot GridMap support for hex. Each hex = 1 `Node3D` with `MeshInstance3D`. MultiMesh optimization for large hex counts.
- **Biome system** design complete — 5 types: Plains, Forest, Rocky, Swamp, Ruins. Procedural generation with rules (Swamp near Rifts, Ruins scattered, Forest clusters).
- **Ancient Ruins exploration mechanic** designed — 3 ruin types, exhaustible resources, faction quests to exploit.

## Open Tasks

- [ ] Set up Godot 4.4 project structure
- [ ] Implement Hex Grid system (`HexGrid` Resource, cube coordinates, flat-top hexagons)
- [ ] Implement Biome system (5 types, procedural generation rules)
- [ ] Implement Ancient Ruins (3 types, exploration states, exhaustible resources)
- [ ] Implement Core Loop (`CycleTimer` resource with phase durations)
- [ ] Implement Metric System (4 state metrics + alignment axis)
- [ ] Implement Utility AI for NPC autonomous building
- [ ] Art style proof-of-concept (Low Poly Diorama)
- [ ] Integrate selected asset packs (kenney_pirate-kit, kenney_fantasy-town-kit_2.0)

## Known Risks

- GDScript performance for 500+ NPCs pathfinding — may need GDExtension C++ surgical optimization
- Godot C# on Linux has occasional export issues (reason for GDScript-only decision)

## What's Working
- GDD is fully authored and internally consistent
- All design questions resolved

## What's Not Working Yet
- No codebase exists yet — prototype has not started
