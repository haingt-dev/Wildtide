class_name AmbientThreatManager
extends Node
## Recalculates ambient_threat_level per hex each Evolve phase.
## Factors: rift_density, pollution, ruin proximity, post-wave respawn, biome base threat.
## Add as a child node in the main game scene (NOT an autoload).

const RIFT_DENSITY_WEIGHT: float = 0.3
const POLLUTION_WEIGHT: float = 0.4
const RUIN_PROXIMITY_WEIGHT: float = 0.2
const POST_WAVE_WEIGHT: float = 0.1

const RUIN_PROXIMITY_RADIUS: int = 3
const WATCHTOWER_SUPPRESS_RADIUS: int = 3
const WATCHTOWER_SUPPRESS_FACTOR: float = 0.5

const THREAT_LOW: float = 0.3
const THREAT_MEDIUM: float = 0.6
const THREAT_HIGH: float = 0.8

const CONSTRUCTION_PENALTY_LOW: float = 0.1
const CONSTRUCTION_PENALTY_MEDIUM: float = 0.25

var hex_grid: HexGrid
var biome_registry: BiomeRegistry
var building_manager: BuildingManager

## Cycles remaining until full ambient respawn (0 = full, 2 = just post-wave).
var _post_wave_timer: int = 0


func _ready() -> void:
	biome_registry = BiomeRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.wave_ended.connect(_on_wave_ended)


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_recalculate_all()
		_tick_post_wave_timer()


func _on_wave_ended(_cycle: int) -> void:
	_post_wave_timer = 2


## Recalculate ambient_threat_level for every hex in the grid.
func _recalculate_all() -> void:
	if not hex_grid:
		return
	var ruin_coords: Array[Vector3i] = _find_ruin_coords()
	var watchtower_coords: Array[Vector3i] = _find_watchtower_coords()
	var post_wave_factor: float = _get_post_wave_factor()
	for cell: HexCell in hex_grid.get_all_cells():
		var threat: float = _calculate_threat(
			cell, ruin_coords, watchtower_coords, post_wave_factor
		)
		cell.ambient_threat_level = clampf(threat, 0.0, 1.0)


## Calculate threat level for a single hex.
func _calculate_threat(
	cell: HexCell,
	ruin_coords: Array[Vector3i],
	watchtower_coords: Array[Vector3i],
	post_wave_factor: float,
) -> float:
	var bdata: BiomeData = biome_registry.get_data(cell.biome)
	var biome_base: float = bdata.base_threat if bdata else 0.0

	var rift_component: float = (cell.rift_density + biome_base) * RIFT_DENSITY_WEIGHT
	var pollution_component: float = cell.pollution_level * POLLUTION_WEIGHT
	var ruin_component: float = _get_ruin_proximity(cell.coord, ruin_coords) * RUIN_PROXIMITY_WEIGHT
	var post_wave_component: float = post_wave_factor * POST_WAVE_WEIGHT

	var raw_threat: float = (
		rift_component + pollution_component + ruin_component + post_wave_component
	)

	# Watchtower suppression (reduces Rift Fauna contribution only)
	var suppression: float = _get_watchtower_suppression(cell.coord, watchtower_coords)
	if suppression > 0.0:
		raw_threat -= rift_component * suppression

	return raw_threat


## Get ruin proximity factor (1.0 on ruin hex, falloff over distance).
func _get_ruin_proximity(coord: Vector3i, ruin_coords: Array[Vector3i]) -> float:
	if ruin_coords.is_empty():
		return 0.0
	var min_dist: int = RUIN_PROXIMITY_RADIUS + 1
	for ruin_coord: Vector3i in ruin_coords:
		var dist: int = HexMath.distance(coord, ruin_coord)
		if dist < min_dist:
			min_dist = dist
	if min_dist > RUIN_PROXIMITY_RADIUS:
		return 0.0
	return 1.0 - (float(min_dist) / float(RUIN_PROXIMITY_RADIUS + 1))


## Get watchtower suppression factor (0.0-0.5) based on proximity to watchtowers.
func _get_watchtower_suppression(coord: Vector3i, watchtower_coords: Array[Vector3i]) -> float:
	for wt_coord: Vector3i in watchtower_coords:
		if HexMath.distance(coord, wt_coord) <= WATCHTOWER_SUPPRESS_RADIUS:
			return WATCHTOWER_SUPPRESS_FACTOR
	return 0.0


## Get post-wave respawn factor (0.0 right after wave, 1.0 normally).
func _get_post_wave_factor() -> float:
	if _post_wave_timer >= 2:
		return 0.0
	if _post_wave_timer == 1:
		return 0.5
	return 1.0


func _tick_post_wave_timer() -> void:
	if _post_wave_timer > 0:
		_post_wave_timer -= 1


func _find_ruin_coords() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for cell: HexCell in hex_grid.get_all_cells():
		if cell.biome == BiomeType.Type.RUINS:
			result.append(cell.coord)
	return result


func _find_watchtower_coords() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	if not building_manager:
		return result
	for active: ActiveConstruction in building_manager.get_completed_buildings():
		if active.building_data.building_id == &"watchtower":
			result.append(active.coord)
	return result


## Get construction speed multiplier from threat level (1.0 = normal).
static func get_construction_modifier(threat_level: float) -> float:
	if threat_level >= THREAT_HIGH:
		return 0.0  # Blocked
	if threat_level >= THREAT_MEDIUM:
		return 1.0 - CONSTRUCTION_PENALTY_MEDIUM
	if threat_level >= THREAT_LOW:
		return 1.0 - CONSTRUCTION_PENALTY_LOW
	return 1.0


## Get resource yield multiplier from threat level (1.0 = normal).
static func get_yield_modifier(threat_level: float) -> float:
	if threat_level >= THREAT_HIGH:
		return 0.0  # Blocked
	if threat_level >= THREAT_MEDIUM:
		return 0.8
	if threat_level >= THREAT_LOW:
		return 0.9
	return 1.0
