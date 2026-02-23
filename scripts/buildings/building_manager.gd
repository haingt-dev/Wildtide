class_name BuildingManager
extends Node
## Manages building placement, construction progress, and metric effects.
## Add as a child node in the main game scene (NOT an autoload).

const SCAR_SPEED_PENALTY: float = 0.2  ## -20% speed on scarred hexes

var hex_grid: HexGrid
var building_registry: BuildingRegistry
var biome_registry: BiomeRegistry
var economy_manager: EconomyManager  ## Optional — if set, building costs are enforced.

## All placed buildings (both under construction and completed).
## Key: Vector3i (coord), Value: ActiveConstruction.
var _constructions: Dictionary = {}


func _ready() -> void:
	building_registry = BuildingRegistry.new()
	biome_registry = BiomeRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)


## Place a building at the given coordinate. Returns true if successful.
func place_building(coord: Vector3i, building_id: StringName) -> bool:
	if not hex_grid:
		return false
	var cell: HexCell = hex_grid.get_cell(coord)
	if not cell or not cell.is_buildable():
		return false
	var bdata: BuildingData = building_registry.get_data(building_id)
	if not bdata:
		return false
	if economy_manager and not economy_manager.spend(bdata.gold_cost, bdata.mana_cost):
		return false
	cell.building_id = building_id
	var active := ActiveConstruction.new(coord, bdata)
	_constructions[coord] = active
	EventBus.building_placed.emit(coord, building_id)
	return true


## Remove a building from the given coordinate. Returns true if successful.
func remove_building(coord: Vector3i) -> bool:
	if not hex_grid:
		return false
	var cell: HexCell = hex_grid.get_cell(coord)
	if not cell or cell.is_empty():
		return false
	var building_id: StringName = cell.building_id
	cell.building_id = &""
	_constructions.erase(coord)
	EventBus.building_removed.emit(coord, building_id)
	return true


## Get the ActiveConstruction at a coordinate, or null.
func get_construction(coord: Vector3i) -> ActiveConstruction:
	return _constructions.get(coord, null) as ActiveConstruction


## Get all buildings currently under construction.
func get_under_construction() -> Array[ActiveConstruction]:
	var result: Array[ActiveConstruction] = []
	for active: ActiveConstruction in _constructions.values():
		if not active.is_complete:
			result.append(active)
	return result


## Get all completed buildings.
func get_completed_buildings() -> Array[ActiveConstruction]:
	var result: Array[ActiveConstruction] = []
	for active: ActiveConstruction in _constructions.values():
		if active.is_complete:
			result.append(active)
	return result


## Get the total building count.
func get_building_count() -> int:
	return _constructions.size()


## Get building count filtered by type.
func get_count_by_type(btype: BuildingType.Type) -> int:
	var count: int = 0
	for active: ActiveConstruction in _constructions.values():
		if active.building_data.building_type == btype:
			count += 1
	return count


## Calculate the effective construction speed multiplier for a hex.
func get_speed_multiplier(coord: Vector3i, building_data: BuildingData) -> float:
	if not hex_grid or not biome_registry:
		return 1.0
	var cell: HexCell = hex_grid.get_cell(coord)
	if not cell:
		return 1.0
	var bdata: BiomeData = biome_registry.get_data(cell.biome)
	var biome_speed: float = bdata.construction_speed if bdata else 1.0
	if building_data.biome_affinity == cell.biome:
		biome_speed += building_data.affinity_bonus
	var scar_mult: float = 1.0
	if cell.scar_state > 0.0:
		scar_mult = 1.0 - SCAR_SPEED_PENALTY
	return maxf(biome_speed * scar_mult, 0.01)


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_tick_constructions()
		_apply_completed_effects()


func _tick_constructions() -> void:
	for coord: Vector3i in _constructions:
		var active: ActiveConstruction = _constructions[coord]
		if active.is_complete:
			continue
		var speed: float = get_speed_multiplier(coord, active.building_data)
		active.tick(speed)


func _apply_completed_effects() -> void:
	for active: ActiveConstruction in _constructions.values():
		if not active.is_complete:
			continue
		_push_building_effects(active.building_data)


func _push_building_effects(bdata: BuildingData) -> void:
	for metric_name: StringName in bdata.metric_effects:
		var delta: float = bdata.metric_effects[metric_name]
		MetricSystem.push_metric(metric_name, delta)
	if bdata.alignment_push != 0.0:
		MetricSystem.push_alignment(bdata.alignment_push)
