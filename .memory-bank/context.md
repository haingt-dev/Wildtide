# Context: Wildtide

## Current Phase
**Early Prototype — All 9 core systems COMPLETE.** HexGrid, MetricSystem, CycleTimer/GameManager, EventBus, Factions/Quests, Wave, Ancient Ruins, Buildings, SaveSystem. Ready for Utility AI, Art POC, or UI.

## Project Timeline

| Date | Event |
|------|-------|
| 2026-02-01 | Initial GDD drafted as "Emergent City" |
| 2026-02-08 | GDD restructured into modular notes |
| 2026-02-09 | Renamed to **Wildtide**. All open questions resolved. GDD production-ready. Memory Bank initialized. |
| 2026-02-11 | Added 3 new GDD sections — Hexagonal Terrain (hex grid decision), Biomes (5 biome types), Ancient Ruins (exploration mechanic). |
| 2026-02-11 | GDScript linting/formatting set up — gdtoolkit 4.5.0 installed via `pip install --user`, `.gdtoolkit` config created (120-char lines, 60-line functions, 500-line files). |
| 2026-02-11 | Dev environment setup: Fixed `.vscode/launch.json` (Godot path + scene), created `README.md`, set up pre-commit hooks (gdformat + gdlint), added Kilo Code project rules. |
| 2026-02-11 | Created `.kilocodemodes` with 4 custom modes — GDScript Dev, Resource Designer, GDD Writer, Godot Architect. Each mode has scoped file permissions and project-specific instructions. |
| 2026-02-11 | Pre-implementation scaffold: Rebuilt CLAUDE.md (self-contained, ~180 lines), restored Memory Bank, created folder structure (20 dirs), installed GUT test framework, created hex math test template. |
| 2026-02-11 | HexGrid data layer: HexMath (static hex math), BiomeType enum, BiomeData Resources (5 .tres files), BiomeRegistry, HexCell Resource, HexGrid Resource. Full test coverage (60+ tests). |
| 2026-02-11 | HexGrid rendering: HexMeshBuilder, HexGridRenderer (MultiMesh), HexHighlight, hex_terrain.gdshader, debug scene with orbit camera and HUD overlay. |
| 2026-02-11 | Procedural map generation: MapGenerator (seed-based RNG), RiftPlacer (triangle pattern), biome placement rules (Swamp→Ruins→Rocky→Forest→Plains). Tests for all generation rules. |
| 2026-02-12 | SaveSystem: SaveSerializer (pure data conversion, static methods for all 8 systems) + SaveSystem Node (4 JSON files per slot, autosave on WAVE phase, all-or-nothing load). All 9 core systems complete. |
| 2026-02-23 | GDD updates: Added WT - Building Evolution (12th section). Expanded Art Direction (Asset Pipeline, Building Visual Tiers). Expanded Design Pillars (City Must Grow, Metric Visual Feedback). Coding conventions with code examples added to wildtide-conventions.md. Memory Bank synced with GDD (biome stats, ruin details, Summon the Tide). |
| 2026-02-23 | GDD update: Added Moving City system to WT - Core Vision & Lore (city migration, ghost footprints, Rift density system, endgame artifacts). |
| 2026-02-23 | GDD update: WT - Core Loop (Move/Stay Decision phase, Movement Triggers, Movement Consequences). WT - The Wave (Kaiju-class framing, Region Modifier table, Regional Wave Behavior). |
| 2026-02-23 | GDD update: WT - Hexagonal Terrain (Map Structure — large fixed map ~1500-2000 hexes, 4 region progression, Fog of War with 4 hex states, Scout mechanic). |
| 2026-02-23 | GDD update: WT - Quest System (Movement Requests section, faction movement motivations). Fixed Indirect Sovereignty violation — removed direct player movement trigger from Core Loop, Core Vision, Memory Bank. Two legitimate paths: Migration Edict + Sovereign Quest "Mandate Migration". |
| 2026-02-23 | GDD update: Created WT - Movement System (13th section). Consolidates map structure, city footprint, movement triggers, transit phase, fog of war, ghost footprint, win condition integration. Added to master GDD sections table. |
| 2026-02-23 | GDD review: Full 13-section analysis — found 6 contradictions, 5 ambiguities, 4 missing high-priority sections. |
| 2026-02-23 | GDD update: Created 4 new sections (14-17): WT - Economy & Resources, WT - Edict System, WT - Game Over Conditions, WT - Utility AI. GDD now 17 sections total. |
| 2026-02-23 | GDD fix: Resolved 5 ambiguities — Sovereign Quest shared slot (trade-off: migrate vs upgrade), The Wall "Strategic Retreat" (conditional move when Wave damage >50%), Wave During Transit (power -50%), Era transitions (automatic by cycle count), cross-references added. |
| 2026-02-23 | GDD fix: Resolved 6 contradictions — FoW "Scouted"→"Revealed", resource depletion 30%→20%, transit 1-2→1 cycle, pollution trigger 80%/2 cycles, hand-crafted→procedural+hand-tuned, biome composition 250→1750 scale. Files: Movement System, Core Loop, Hex Terrain, Biomes. |
| 2026-02-23 | GDD re-review: Full 17-section analysis. Fixed 3 contradictions (Rift Shards/Era auto, edicts "2-3"→"2", Mandate Migration cost standardized to "70% Gold + 70% Mana"). Defined 3 undefined mechanics (Faction Morale 0-100 range, edict expiry auto-disable, wave transit probability 50%). Added 4 cross-references (Core Loop→Edict/Utility AI, Metric System→Edict, Design Pillars references section). Files: Economy, Design Pillars, Quest System, Edict System, The Wave, Core Loop, Metric System, Core Vision. |

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
- **3 Autoload singletons**: GameManager (cycle state), MetricSystem (metrics + alignment), EventBus (global signals). No additional autoloads.
- **GUT 9.x** for testing — unit tests in `test/unit/`, integration tests in `test/integration/`
- **Asset pipeline**: Meshy.ai → Blender (decimate) → Godot GLB. Flat color materials only (no textures)
- **Building Evolution**: 3 mesh tiers per Era, Science/Magic swap = 6 visual states per building type
- **City Must Grow**: Horizontal sprawl, visual connectors between adjacent buildings, Era transition "wow moment"
- **Metric Visual Feedback** (MVP): Pollution → sky/trees degrade, Anxiety → NPC chaos, Harmony → warm colors
- **Moving City**: City moves across large fixed map. Triggers: resource depletion, pollution/damage, faction request, Migration Edict, Sovereign Quest "Mandate Migration" (70% reserves, 1/Era). NO direct player trigger (Indirect Sovereignty). Ghost footprints left behind (mirrors The Ancients' history).
- **Rift Density System**: Per-region density increases near win condition location. Waves spawn from 3 fixed Rifts + high-density regions city passes through.
- **Endgame Artifacts**: Science → "Wormhole Stabilizer" (Tech Fragments from ruins, seal Rifts). Magic → "The Accord" (Rune Shards from shrines + Rift zones, merge with Wave).
- **Kaiju-class Wave framing**: Wave enemies are Kaiju-class entities. Region Modifier scales wave power (Low ×0.8, Medium ×1.0, High ×1.5, Rift Core ×2.0). Formula: `base × Era × Region`.
- **Move/Stay Decision**: Conditional 5th phase every 3-4 cycles. Movement triggers: resource depletion (<20% capacity), pollution critical (>80% for 2 cycles), faction request, Migration Edict, Sovereign Quest "Mandate Migration". Transit costs 1 cycle (-50% production, +Anxiety).
- **Movement Requests**: Factions submit movement requests alongside building quests. Lens→ruins, Veil→high Rift density, Coin→resource diversity, Wall→"Stay and Fortify". Same approve/reject flow in Influence phase.
- **Indirect Sovereignty for Movement**: Player CANNOT directly trigger city movement. Two paths: (1) Migration Edict → faction proposals → approve/reject, (2) Sovereign Quest "Mandate Migration" — override, 70% reserves, 1/Era cooldown.
- **Large Fixed Map**: ~1500-2000 hexes total, city footprint ~200-300 active hexes (sliding window). Seed-based procedural generation with hand-tuned biome rules (MapGenerator).
- **Fog of War**: 4 hex states (Hidden → Revealed → Active → Inactive). Reveal radius ~3-4 hex. Scout quest (The Lens) reveals ahead of movement.
- **Map Regions**: Starting (low density, rich) → Mid (medium, ruins-rich) → Late (high, scarce) → Rift Core (×2.0, endgame artifacts).

## Active Workstreams

- **Hex grid terrain system** — COMPLETE. HexGrid Resource, cube coordinates, flat-top hexagons, MultiMesh rendering, procedural biome generation, debug visualization scene.
- **EventBus autoload** — COMPLETE. Global signal bus with 24 signals across 7 groups (Cycle, Metrics, HexGrid, Wave, Buildings, Quests, Ruins). Registered in project.godot.
- **CycleTimer + GameManager** — COMPLETE. CycleTimer Resource (4 phase durations), GameManager autoload (state machine, speed 1-3x, pause/resume, EventBus integration). Both registered in project.godot.
- **MetricSystem** — COMPLETE. InteractionMatrix Resource (4x4 weight matrix), MetricSystem autoload (4 metrics [0,1], Science/Magic alignment, biome pushes, interaction matrix per EVOLVE phase). Registered in project.godot.
- **Factions/Quests** — COMPLETE. FactionType enum, FactionData + QuestData Resources, FactionRegistry + QuestRegistry, 4 factions + 12 quest templates (.tres). QuestManager Node (propose on INFLUENCE, tick on EVOLVE, approve/reject API). ActiveQuest RefCounted for runtime state.
- **Wave System** — COMPLETE. WaveConfig Resource (Era scaling, 4 Eras across 16 cycles, multipliers [1.0, 1.8, 3.0, 5.0]). WaveManager Node (abstract damage simulation — wave power split across 3 Rifts, distance falloff, biome defense reduction). wave_config_normal.tres for Normal mode.
- **Ancient Ruins** — COMPLETE. RuinType enum (Observatory, Energy Shrine, Archive Vault) + 6 exploration state constants. RuinData Resource (yields, duration, rarity, damage penalty). RuinRegistry with weighted-random type selection. 3 .tres files. RuinsManager Node (type assignment, discovery, exploration lifecycle on EVOLVE, wave damage via hex_scarred). ActiveExploration RefCounted for runtime state.
- **Buildings** — COMPLETE. BuildingType enum (6 categories), BuildingData Resource (id, duration, metric_effects, alignment_push, biome_affinity). BuildingRegistry (DirAccess scan pattern). 6 .tres templates (homestead, reactor, shrine, market, watchtower, workshop). BuildingManager Node (place/remove API, float-progress construction ticking on EVOLVE, biome speed + scar penalty + affinity bonus, completed building metric effects). ActiveConstruction RefCounted.
- **SaveSystem** — COMPLETE. SaveSerializer RefCounted (static methods, pure data conversion for all 8 systems, Vector3i→array encoding, Resource ref by ID). SaveSystem Node (4 JSON files per save slot at user://saves/<slot>/, autosave on WAVE phase, all-or-nothing load validation, slot management API).
- **Next up**: Utility AI, Art POC, UI/HUD, or asset pack integration.

## Open Tasks

- [x] Set up Godot 4.6 project structure
- [x] Rebuild CLAUDE.md and restore Memory Bank
- [x] Create game code folder structure
- [x] Install GUT test framework and create test template
- [x] Implement Hex Grid system (`HexGrid` Resource, cube coordinates, flat-top hexagons)
- [x] Implement Biome system (5 types, procedural generation rules)
- [x] Implement Ancient Ruins (3 types, exploration states, exhaustible resources)
- [x] Implement Core Loop (`CycleTimer` resource + `GameManager` autoload)
- [x] Implement Metric System (4 state metrics + alignment axis)
- [x] Implement Wave System (WaveConfig resource, WaveManager damage simulation)
- [x] Implement Buildings (placement, construction, metric effects)
- [x] Implement SaveSystem (JSON split files, autosave, slot management)
- [ ] Implement Utility AI for NPC autonomous building
- [ ] Art style proof-of-concept (Low Poly Diorama)
- [ ] Integrate selected asset packs (kenney_pirate-kit, kenney_fantasy-town-kit_2.0)

## Known Risks

- GDScript performance for 500+ NPCs pathfinding — may need GDExtension C++ surgical optimization
- Godot C# on Linux has occasional export issues (reason for GDScript-only decision)

## What's Working
- GDD is fully authored and internally consistent (17 sections)
- CLAUDE.md is self-contained with all project context (~180 lines)
- Memory Bank restored and up-to-date for all agents
- Game code folder structure in place (scripts/, scenes/, test/)
- GUT test framework installed with hex math test template
- GDScript linting (`gdlint`) and formatting (`gdformat`) configured — gdtoolkit 4.5.0, gdlintrc (YAML), .gdtoolkit (INI)
- Pre-commit hooks installed (`gdformat` + `gdlint`, `exclude: ^addons/`)
- **HexGrid data layer**: HexMath, BiomeType, BiomeData (5 .tres), BiomeRegistry, HexCell, HexGrid
- **HexGrid rendering**: HexMeshBuilder, HexGridRenderer (MultiMesh), HexHighlight, hex_terrain.gdshader
- **Procedural generation**: MapGenerator (seeded), RiftPlacer, biome placement rules
- **Debug scene**: hex_debug_scene.tscn with orbit camera, HUD overlay, procedural map
- **MetricSystem**: InteractionMatrix Resource, MetricSystem autoload, BiomeRegistry integration
- **Factions/Quests**: FactionType, FactionData, QuestData, FactionRegistry, QuestRegistry, QuestManager, ActiveQuest
- **Wave System**: WaveConfig Resource, WaveManager Node, wave_config_normal.tres
- **Ancient Ruins**: RuinType, RuinData, RuinRegistry, 3 .tres, RuinsManager, ActiveExploration
- **Buildings**: BuildingType, BuildingData, BuildingRegistry, 6 .tres, BuildingManager, ActiveConstruction
- **SaveSystem**: SaveSerializer (pure data conversion), SaveSystem Node (file I/O, autosave, slot management)
- **Tests**: 381 unit tests across 25 test files

## What's Not Working Yet
- GUT plugin needs to be enabled in Godot editor (Done)
- Tests have not been run in Godot yet (need editor or CLI execution to verify)
- Debug scene needs visual verification (run with F6 in Godot)
