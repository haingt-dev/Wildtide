---
description: Wildtide architecture, coding conventions, folder structure, GDD reference, testing and tooling. Loaded automatically for all coding tasks.
---

# Wildtide Conventions

## Architecture Overview

Data-driven architecture using Godot Resources (`.tres`) as the backbone for all game data.

### 9 Core Systems

| # | System | Key Responsibility |
|---|--------|--------------------|
| 1 | **HexGrid** | Flat-top hex grid, cube coords (q,r,s), ~250 hexes, custom Resource (no GridMap) |
| 2 | **MetricSystem** | 4 state metrics (Pollution, Anxiety, Solidarity, Harmony) + Alignment axis (Science/Magic) |
| 3 | **CycleTimer** | 4-phase loop: Observe→Influence→Wave→Evolve, speed 1x/2x/3x |
| 4 | **Factions/Quests** | 4 factions (Lens, Veil, Coin, Wall), 1 quest/cycle each, approve/reject |
| 5 | **Wave** | 3 Rifts per map, Era-scaled enemies, History Scars on damaged tiles |
| 6 | **Buildings** | AI-placed structures, Science/Magic material swap, biome modifiers |
| 7 | **Ruins** | 3 types (Observatory, Energy Shrine, Archive Vault), exhaustible resources |
| 8 | **Art/Shaders** | Low Poly Diorama, 4 shaders max (wind, material swap, sky, water) |
| 9 | **SaveSystem** | JSON split files (meta, world, metrics, factions), autosave at Wave start |

### Biome System (5 types)

Plains (default), Forest (+Harmony), Rocky/Highland (+Defense), Swamp (+Pollution, near Rifts), Ruins (exploration).
Each hex stores biome type; biomes affect construction speed, resource yield, defense, metric push, alignment affinity.

## Autoload Singletons

These three autoloads are planned for global state management:

| Singleton | Purpose |
|-----------|---------|
| **GameManager** | Cycle state machine, game speed, phase transitions, pause |
| **MetricSystem** | Metric values, interaction matrix, alignment calculation |
| **EventBus** | Global signal bus for cross-system communication |

All other systems use composition and node-based architecture — no additional autoloads.

## Folder Structure

```
scripts/
  core/           # GameManager, CycleTimer, EventBus
  metrics/        # MetricSystem, interaction matrix
  ai/             # Utility AI, NPC decisions
  wave/           # Wave spawning, Rift management
  factions/       # Faction logic, quest system
  buildings/      # Building placement, construction
  ruins/          # Ancient ruins exploration
  ui/             # HUD, panels, menus
  data/           # Resource loaders, save/load
  shaders/        # Shader scripts (.gdshader)
  debug/          # MetricDebugPanel, CSV export

scenes/
  main/           # Main game scene, camera
  hex/            # Hex grid, terrain, biomes
  buildings/      # Building scenes
  ui/             # UI scenes
  wave/           # Wave, Rift, enemy scenes
  debug/          # Debug overlays

test/
  unit/           # GUT unit tests
  integration/    # GUT integration tests
  fixtures/       # Test data, mock resources

addons/
  gut/            # GUT test framework plugin

assets/           # Art, audio, fonts (subdirs by type)
docs/gdd/         # Game Design Document (read-only reference)
```

## Coding Conventions

### Naming Rules

| Element | Convention | Example |
|---------|-----------|---------|
| **Files** | `snake_case` | `hex_grid.gd`, `cycle_timer.tscn` |
| **Classes** | `PascalCase` | `class_name HexGrid` |
| **Functions** | `snake_case` | `func calculate_damage()` |
| **Variables** | `snake_case` | `var health_points: int` |
| **Constants** | `SCREAMING_SNAKE_CASE` | `const MAX_HEALTH: int = 100` |
| **Signals** | `snake_case` past tense | `signal health_changed(new_value: int)` |
| **Enums** | `PascalCase` type, `SCREAMING_SNAKE` values | `enum BiomeType { PLAINS, FOREST }` |
| **Resources** | `snake_case.tres` | `metric_matrix.tres` |

### Style Rules

- **Type hints everywhere** — vars, params, returns, AND loop vars:
  `var speed: float = 10.0`, `func move(delta: float) -> void:`, `for cell: HexCell in cells:`
- **`@export`** for inspector-editable properties, **`@export_group()`** to organize sections
- **`@export_range()`** for constrained numerics: `@export_range(1, 8) var duration: int = 2`
- **`@onready`** for node references: `@onready var sprite: Sprite3D = $Sprite3D`
- **`##` docstrings** on class declarations and `@export` fields (not `#`)
- **`StringName` literals** (`&""`) for IDs and dictionary keys: `var id: StringName = &"reactor"`
- **Private fields** prefixed with `_`: `var _constructions: Dictionary = {}`
- **Comment sections** with `# --- Section Name ---` separators in long files
- **Composition over inheritance** — prefer child nodes and Resources over deep class hierarchies
- **Signals for loose coupling** — systems communicate via EventBus, not direct references
- **Resources (`.tres`) for data** — policies, quests, metric weights, game mode presets
- **Max line length**: 120 chars
- **Max function length**: 60 lines
- **Max file length**: 500 lines

### Patterns to Follow

- Data in `.tres` Resources, logic in `.gd` scripts attached to nodes
- Game mode presets (Normal/Hell/Zen) as alternative `.tres` weight files
- Split concerns: one script per system, compose via scene tree
- Use `StringName` for signal names in performance-critical code

### Patterns to Avoid

- No C# — GDScript only
- No Godot `GridMap` for hex (doesn't support hex natively)
- No singletons beyond the 3 planned autoloads
- No quest failure logic in MVP
- No player-initiated quests in MVP
- No save encryption in MVP

## Code Patterns

### 1. Resource Data (`scripts/data/*_data.gd`)

```gdscript
class_name BuildingData
extends Resource
## Template for a building type. Create one .tres per building type.

@export var building_id: StringName = &""
@export var building_type: BuildingType.Type = BuildingType.Type.RESIDENTIAL
@export var display_name: String = ""

@export_group("Construction")
@export_range(1, 8) var construction_duration: int = 2  ## Cycles to complete

@export_group("Metric Effects")
## Keys: metric StringNames (&"pollution", etc.). Values: float delta per EVOLVE.
@export var metric_effects: Dictionary = {}

@export_group("Alignment")
@export var alignment_push: float = 0.0
```

### 2. Registry — Dynamic (`scripts/data/building_registry.gd`)

```gdscript
class_name BuildingRegistry
extends RefCounted
## Loads all .tres from directory, caches by ID. Secondary index optional.

const BUILDING_DIR: String = "res://scripts/data/buildings/"

var _data: Dictionary = {}  ## StringName -> BuildingData
var _by_type: Dictionary = {}  ## BuildingType.Type -> Array[BuildingData]


func _init() -> void:
	_load_all()


func _load_all() -> void:
	var dir := DirAccess.open(BUILDING_DIR)
	if not dir:
		push_warning("BuildingRegistry: cannot open %s" % BUILDING_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res: BuildingData = load(BUILDING_DIR + file_name) as BuildingData
			if res and res.building_id != &"":
				_data[res.building_id] = res
		file_name = dir.get_next()


func get_data(building_id: StringName) -> BuildingData:
	return _data.get(building_id, null) as BuildingData


func get_all() -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for val: BuildingData in _data.values():
		result.append(val)
	return result
```

### 3. Registry — Fixed (`scripts/data/faction_registry.gd`)

```gdscript
class_name FactionRegistry
extends RefCounted
## Fixed file mapping, enum-keyed lookup.

const FACTION_DIR: String = "res://scripts/data/factions/"

const _FACTION_FILES: Dictionary = {
	FactionType.Type.LENS: "faction_lens.tres",
	FactionType.Type.VEIL: "faction_veil.tres",
	FactionType.Type.COIN: "faction_coin.tres",
	FactionType.Type.WALL: "faction_wall.tres",
}

var _data: Dictionary = {}  ## FactionType.Type -> FactionData


func _init() -> void:
	_load_all()


func _load_all() -> void:
	for faction_type: FactionType.Type in _FACTION_FILES:
		var path: String = FACTION_DIR + _FACTION_FILES[faction_type]
		var res: FactionData = load(path) as FactionData
		if res:
			_data[faction_type] = res
		else:
			push_warning("FactionRegistry: failed to load %s" % path)


func get_data(faction: FactionType.Type) -> FactionData:
	return _data.get(faction, null) as FactionData
```

### 4. RefCounted Runtime State (`scripts/*/active_*.gd`)

```gdscript
class_name ActiveConstruction
extends RefCounted
## Mutable runtime state. Created on placement, kept after completion.

var coord: Vector3i
var building_data: BuildingData
var progress: float = 0.0
var is_complete: bool = false


func _init(build_coord: Vector3i, data: BuildingData) -> void:
	coord = build_coord
	building_data = data


## Tick with speed multiplier. Returns true if just completed.
func tick(speed_multiplier: float) -> bool:
	if is_complete:
		return false
	progress += speed_multiplier
	if progress >= float(building_data.construction_duration):
		is_complete = true
		return true
	return false
```

### 5. Manager Node (`scripts/*/\*_manager.gd`)

```gdscript
class_name BuildingManager
extends Node
## Owns registries + state dicts. Connects to EventBus phases.
## Add as child node in main scene (NOT an autoload).

var hex_grid: HexGrid
var building_registry: BuildingRegistry

var _constructions: Dictionary = {}  ## Vector3i -> ActiveConstruction


func _ready() -> void:
	building_registry = BuildingRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)


func place_building(coord: Vector3i, building_id: StringName) -> bool:
	# ... validation ...
	var active := ActiveConstruction.new(coord, bdata)
	_constructions[coord] = active
	EventBus.building_placed.emit(coord, building_id)
	return true


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_tick_constructions()
```

### 6. Autoload Singleton (`scripts/core/event_bus.gd`)

```gdscript
extends Node
## Global signal bus. Register as autoload in Project Settings.
## No class_name — accessed via autoload name (EventBus).

# --- Cycle ---
signal phase_changed(new_phase: int, phase_name: StringName)
signal cycle_started(cycle_number: int)
signal game_paused
signal game_resumed

# --- Metrics ---
signal metric_changed(metric_name: StringName, new_value: float, old_value: float)

# --- Buildings ---
signal building_placed(coord: Vector3i, building_id: StringName)
```

### 7. Static Utility (`scripts/core/hex_math.gd`)

```gdscript
class_name HexMath
extends RefCounted
## Pure static utility. Do not instantiate.

const HEX_SIZE: float = 2.0
const SQRT_3: float = 1.7320508075688772

const NEIGHBOR_OFFSETS: Array[Vector3i] = [
	Vector3i(+1, -1, 0), Vector3i(+1, 0, -1), Vector3i(0, +1, -1),
	Vector3i(-1, +1, 0), Vector3i(-1, 0, +1), Vector3i(0, -1, +1),
]


static func distance(a: Vector3i, b: Vector3i) -> int:
	return (absi(a.x - b.x) + absi(a.y - b.y) + absi(a.z - b.z)) / 2


static func hex_to_world(coord: Vector3i) -> Vector3:
	var x: float = HEX_SIZE * 1.5 * coord.x
	var z: float = HEX_SIZE * (SQRT_3 * 0.5 * coord.x + SQRT_3 * coord.y)
	return Vector3(x, 0.0, z)
```

### 8. Type Enum (`scripts/data/*_type.gd`)

```gdscript
class_name RuinType
extends RefCounted
## Ruin type enum and exploration state constants.

enum Type { OBSERVATORY, ENERGY_SHRINE, ARCHIVE_VAULT }

const STATE_NONE: int = 0
const STATE_UNDISCOVERED: int = 1
const STATE_DISCOVERED: int = 2
const STATE_EXPLORING: int = 3
const STATE_DEPLETED: int = 4
const STATE_DAMAGED: int = 5
```

## GDD Reference

11-section Game Design Document in `docs/gdd/`:

| Section | File |
|---------|------|
| Master GDD | `GDD - Wildtide.md` |
| Project Overview | `Project - Wildtide.md` |
| Core Vision & Lore | `WT - Core Vision & Lore.md` |
| Design Pillars | `WT - Design Pillars.md` |
| Core Loop | `WT - Core Loop.md` |
| Metric System | `WT - Metric System.md` |
| Quest System | `WT - Quest System.md` |
| The Wave | `WT - The Wave.md` |
| Hexagonal Terrain | `WT - Hexagonal Terrain.md` |
| Biomes | `WT - Biomes.md` |
| Ancient Ruins | `WT - Ancient Ruins.md` |
| Art Direction | `WT - Art Direction.md` |
| Technical Stack | `WT - Technical Stack.md` |

**Do not modify GDD files** without explicit instruction.

## Testing

- **Framework**: GUT 9.x (Godot Unit Testing) — `addons/gut/`
- **Config**: `.gutconfig.json` at project root
- **Test dirs**: `test/unit/`, `test/integration/`
- **Naming**: `test_*.gd` files, extend `GutTest`
- **Run CLI**: `godot -d -s --path "$PWD" addons/gut/gut_cmdln.gd`
- **Run editor**: Project Settings → Plugins → Enable GUT → GUT panel

### Test File Structure

```gdscript
extends GutTest
## Tests for BuildingManager construction and metric effects.

var manager: BuildingManager
var grid: HexGrid


func before_each() -> void:
	manager = BuildingManager.new()
	add_child(manager)
	grid = HexGrid.new()
	grid.initialize_hex_map(3)
	manager.hex_grid = grid
	MetricSystem.reset_to_defaults()


func after_each() -> void:
	manager.queue_free()
	_disconnect_all(EventBus.building_placed)
	_disconnect_all(EventBus.building_removed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])
```

### Testing Conventions

- **Test naming**: `test_<behavior>_<condition>` — e.g., `test_place_building_on_empty_hex`
- **Setup**: `before_each()` creates fresh instances via `.new()`, `add_child()` to scene tree
- **Teardown**: `after_each()` calls `queue_free()`, disconnects EventBus signals
- **Assertions**: `assert_eq`, `assert_true/false`, `assert_not_null`, `assert_almost_eq(..., 0.001)`
- **Signal testing**: connect lambda → append to array → assert array after emit
- **Phase testing**: call `_on_phase_changed()` directly instead of waiting for timer
- **No mocking** — use real objects, mutate properties directly
- **No fixtures** — all test data created inline in `before_each()` or test functions

### Signal Test Pattern

```gdscript
func test_building_placed_signal() -> void:
	var received := []
	EventBus.building_placed.connect(
		func(c: Vector3i, id: StringName) -> void: received.append([c, id])
	)
	manager.place_building(Vector3i(0, 0, 0), &"homestead")
	assert_eq(received.size(), 1)
	assert_eq(received[0][1], &"homestead")
```

## Tooling

| Tool | Purpose | Config |
|------|---------|--------|
| **gdtoolkit 4.5.0** | GDScript linter + formatter | `.gdtoolkit` |
| **gdlint** | Lint check | `gdlint <file>` |
| **gdformat** | Auto-format | `gdformat <file>` |
| **pre-commit** | Hooks for gdformat + gdlint | `.pre-commit-config.yaml` |
| **GUT 9.x** | Unit/integration testing | `.gutconfig.json` |
