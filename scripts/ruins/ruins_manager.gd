class_name RuinsManager
extends Node
## Manages ruin type assignment, discovery, exploration, and wave damage.
## Add as a child node in the main game scene (NOT an autoload).

var hex_grid: HexGrid
var ruin_registry: RuinRegistry
var edict_manager: EdictManager

## Ruin type assigned to each RUINS biome hex. Key: Vector3i, Value: RuinType.Type.
var _ruin_types: Dictionary = {}

## Currently running explorations. Key: Vector3i, Value: ActiveExploration.
var _active_explorations: Dictionary = {}

## Accumulated fragment counters from completed explorations.
var _tech_fragments: int = 0
var _rune_shards: int = 0

var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func _ready() -> void:
	ruin_registry = RuinRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.hex_scarred.connect(_on_hex_scarred)


## Initialize ruin types for all RUINS biome hexes.
## Call after hex_grid is set and map is generated.
func initialize_ruins() -> void:
	_ruin_types.clear()
	_active_explorations.clear()
	_tech_fragments = 0
	_rune_shards = 0
	if not hex_grid or not ruin_registry:
		return
	var ruins_cells: Array[HexCell] = hex_grid.get_cells_by_biome(BiomeType.Type.RUINS)
	for cell: HexCell in ruins_cells:
		var ruin_type: RuinType.Type = ruin_registry.pick_random_type(_rng)
		_ruin_types[cell.coord] = ruin_type
		cell.exploration_state = RuinType.STATE_UNDISCOVERED


## Initialize with a specific seed for deterministic tests.
func initialize_ruins_seeded(seed_value: int) -> void:
	_rng.seed = seed_value
	initialize_ruins()


## Discover a ruin. Returns true if state changed to DISCOVERED.
func discover_ruin(coord: Vector3i) -> bool:
	if not _ruin_types.has(coord):
		return false
	var cell: HexCell = hex_grid.get_cell(coord)
	if not cell or cell.exploration_state != RuinType.STATE_UNDISCOVERED:
		return false
	cell.exploration_state = RuinType.STATE_DISCOVERED
	var ruin_data: RuinData = ruin_registry.get_data(_ruin_types[coord])
	var type_name: StringName = ruin_data.display_name if ruin_data else &""
	EventBus.ruin_discovered.emit(coord, type_name)
	_push_discovery_metrics()
	return true


## Start exploring a discovered ruin. Returns true if exploration started.
func start_exploration(coord: Vector3i) -> bool:
	if not _ruin_types.has(coord):
		return false
	var cell: HexCell = hex_grid.get_cell(coord)
	if not cell or cell.exploration_state != RuinType.STATE_DISCOVERED:
		return false
	var ruin_data: RuinData = ruin_registry.get_data(_ruin_types[coord])
	if not ruin_data:
		return false
	cell.exploration_state = RuinType.STATE_EXPLORING
	var active := ActiveExploration.new(coord, ruin_data)
	_apply_discovery_bonus(active)
	_active_explorations[coord] = active
	EventBus.ruin_exploration_started.emit(coord)
	return true


## Get the ruin type at a coordinate, or null if not a ruin.
func get_ruin_type(coord: Vector3i) -> Variant:
	if _ruin_types.has(coord):
		return _ruin_types[coord] as RuinType.Type
	return null


## Get the RuinData for the ruin at a coordinate.
func get_ruin_data(coord: Vector3i) -> RuinData:
	if not _ruin_types.has(coord):
		return null
	return ruin_registry.get_data(_ruin_types[coord])


## Get all active explorations.
func get_active_explorations() -> Array[ActiveExploration]:
	var result: Array[ActiveExploration] = []
	for val: ActiveExploration in _active_explorations.values():
		result.append(val)
	return result


## Get the total count of ruin hexes.
func get_ruin_count() -> int:
	return _ruin_types.size()


## Get count of ruins in a specific exploration state.
func get_count_by_state(state: int) -> int:
	var count: int = 0
	for coord: Vector3i in _ruin_types:
		var cell: HexCell = hex_grid.get_cell(coord)
		if cell and cell.exploration_state == state:
			count += 1
	return count


## Check if any ruin of given type has reached at least the given state.
func has_ruin_at_state(ruin_type: RuinType.Type, min_state: int) -> bool:
	for coord: Vector3i in _ruin_types:
		if _ruin_types[coord] == ruin_type:
			var cell: HexCell = hex_grid.get_cell(coord)
			if cell and cell.exploration_state >= min_state:
				return true
	return false


## Get accumulated tech fragment count.
func get_tech_fragments() -> int:
	return _tech_fragments


## Get accumulated rune shard count.
func get_rune_shards() -> int:
	return _rune_shards


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_tick_explorations()


func _on_hex_scarred(coord: Vector3i, _amount: float) -> void:
	_check_wave_damage(coord)


func _tick_explorations() -> void:
	var completed_coords: Array[Vector3i] = []
	for coord: Vector3i in _active_explorations:
		var active: ActiveExploration = _active_explorations[coord]
		if active.tick():
			completed_coords.append(coord)
	for coord: Vector3i in completed_coords:
		_complete_exploration(coord)


func _complete_exploration(coord: Vector3i) -> void:
	var active: ActiveExploration = _active_explorations.get(coord, null)
	if not active:
		return
	_active_explorations.erase(coord)
	_tech_fragments += active.get_effective_tech_fragments()
	_rune_shards += active.get_effective_rune_shards()
	var cell: HexCell = hex_grid.get_cell(coord)
	if cell:
		cell.exploration_state = RuinType.STATE_DEPLETED
	EventBus.ruin_depleted.emit(coord)
	EventBus.fragments_changed.emit(_tech_fragments, _rune_shards)


func _check_wave_damage(coord: Vector3i) -> void:
	if not _active_explorations.has(coord):
		return
	var active: ActiveExploration = _active_explorations[coord]
	active.apply_damage()
	var cell: HexCell = hex_grid.get_cell(coord)
	if cell:
		cell.exploration_state = RuinType.STATE_DAMAGED


func _apply_discovery_bonus(active: ActiveExploration) -> void:
	if not edict_manager:
		return
	var bonus: float = edict_manager.get_discovery_bonus()
	if bonus <= 0.0:
		return
	var reduction: int = ceili(float(active.remaining_cycles) * bonus)
	active.remaining_cycles = maxi(active.remaining_cycles - reduction, 1)


func _push_discovery_metrics() -> void:
	MetricSystem.push_metric(&"anxiety", 0.02)
	MetricSystem.push_metric(&"solidarity", 0.02)
