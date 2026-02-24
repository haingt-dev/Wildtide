# Context: Wildtide

## Current Phase

**Early Prototype — All 17+ systems COMPLETE + Phase 7 GDD Gap Closure + Ambient Threats.** GameSession bootstrap wires all managers, HexGrid, HUD, and SaveSystem into a playable scene. 856 GUT tests passing across 55 test files (54 unit + 1 integration). GDD: 20 sections, fully cross-referenced. Next: Art POC, CityFootprintInitializer, large map.

## Project Timeline

| Date | Milestone |
|------|-----------|
| 2026-02-01 | Initial GDD drafted as "Emergent City" |
| 2026-02-09 | Renamed to **Wildtide**. GDD production-ready. Memory Bank initialized. |
| 2026-02-11 | Dev environment + GDScript tooling (gdtoolkit, pre-commit, GUT, Kilo Code rules) |
| 2026-02-11 | HexGrid data layer + rendering + procedural map generation. 60+ tests. |
| 2026-02-12 | SaveSystem + all 9 core systems complete. |
| 2026-02-23 | GDD expanded: Building Evolution, Moving City, Core Loop, Hex Terrain, Quest Movement, Movement System (section 13). 13 → 17 sections. Contradictions + ambiguities resolved. |
| 2026-02-23 | GDD sections 18-19: Replayability, Scenario System. Full cross-reference audit. GDD internally consistent. |
| 2026-02-24 | GDD v19 prototype sync: 6 new systems (Economy, Edicts, Stability, Movement, Scenario, UtilityAIConfig). 524 tests. |
| 2026-02-24 | UtilityAI behavior logic + UI/HUD System (13 scripts, 10 panels). 659 tests. |
| 2026-02-24 | Zone Affinity + Skyline Rules + GDD Audit Round 2 (14 fixes). 667 tests. |
| 2026-02-24 | Wave Defense GDD + Weapon Buildings implementation. 683 tests. |
| 2026-02-24 | Phase 2-5: Cross-system wiring, Wave Intel, Offensive Quests, Main Game Scene, SaveSystem expansion. 753 tests. |
| 2026-02-25 | Phase 6: Movement System (settlement bonus, salvage, ghost footprint). 769 tests. |
| 2026-02-25 | Phase 7: GDD Gap Closure (7A-7D) — fragments, artifact, wave intel defense, edicts, migration, rift shards, building tier. 838 tests. |
| 2026-02-25 | Ambient Threat System: GDD section 20 + AmbientThreatManager prototype. 856 tests across 55 files. |

## Active Systems (all COMPLETE)

1. **HexGrid** — HexMath, BiomeType/Data/Registry, HexCell, HexGrid, MapGenerator, RiftPlacer, HexGridRenderer
2. **MetricSystem** — InteractionMatrix, 4 state metrics, alignment axis
3. **CycleTimer + GameManager** — 4-phase loop, speed 1-3x, era tracking, scenario_id
4. **Factions/Quests** — 4 factions, QuestManager (propose/approve/reject), offensive quests, movement proposals
5. **Wave** — WaveManager, WaveConfig, WaveIntel (4-level), offensive effects, Summon the Tide
6. **Buildings** — BuildingManager, 10 building types (6 base + 4 weapon), ActiveConstruction, tier advancement
7. **Ruins** — RuinsManager, 3 types, fragment/shard accumulation, discovery bonus
8. **SaveSystem** — SaveSerializer v3, 7 JSON files, backward-compatible
9. **Economy** — EconomyManager, gold/mana/capacity, rift shards, transit penalty
10. **Edicts** — EdictManager, 8 templates, defense/discovery aggregation, migration hook
11. **Stability** — StabilityTracker, 0-100, alert levels, game over
12. **Movement** — MovementManager, settlement bonus, salvage, ghost footprint, mandate migration
13. **Scenario** — ScenarioLoader, the_wildtide.tres, WinConditionData
14. **UtilityAI** — 8-factor scoring (need, affinity, adjacency, faction, zone, cluster, threat, weapon), zone fill cap, scar avoidance
15. **UI/HUD** — GameHUD + 10 panels, signal-driven via EventBus
16. **Artifact** — ArtifactController, win condition checking, fragment requirements
17. **Ambient Threats** — AmbientThreatManager, per-hex threat level, watchtower suppression, construction/yield modifiers

## Known Risks

- GDScript performance for 500+ NPCs pathfinding — may need GDExtension C++ surgical optimization
- Godot C# on Linux has occasional export issues (reason for GDScript-only decision)
