class_name WaveManager
extends Node
## Simulates wave damage during the WAVE phase.
## Distributes damage from Rifts to nearby hexes based on wave power.
## Add as a child node in the main game scene (NOT an autoload).

var wave_config: WaveConfig
var hex_grid: HexGrid
var rift_positions: Array[Vector3i] = []
var biome_registry: BiomeRegistry

var _last_wave_power: float = 0.0
var _last_total_damage: float = 0.0


func _ready() -> void:
	wave_config = load("res://scripts/data/wave/wave_config_normal.tres") as WaveConfig
	biome_registry = BiomeRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)


## Return the wave power from the last wave.
func get_last_wave_power() -> float:
	return _last_wave_power


## Return the total scar damage dealt in the last wave.
func get_last_total_damage() -> float:
	return _last_total_damage


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.WAVE:
		_run_wave(GameManager.cycle_number)


func _run_wave(cycle: int) -> void:
	if not hex_grid or not wave_config or rift_positions.is_empty():
		return

	_last_wave_power = wave_config.get_wave_power(cycle)
	_last_total_damage = 0.0
	var rift_count: int = rift_positions.size()
	var rift_power: float = _last_wave_power / float(rift_count)
	var radius: int = wave_config.damage_radius

	EventBus.wave_started.emit(cycle)

	for rift_coord: Vector3i in rift_positions:
		_damage_around_rift(rift_coord, rift_power, radius)

	EventBus.wave_ended.emit(cycle)


func _damage_around_rift(rift_coord: Vector3i, rift_power: float, radius: int) -> void:
	var cells: Array[HexCell] = hex_grid.get_cells_in_range(rift_coord, radius)
	for cell: HexCell in cells:
		var dist: int = HexMath.distance(rift_coord, cell.coord)
		var damage: float = _calc_damage(rift_power, dist, radius, cell.biome)
		if damage > 0.0:
			cell.apply_scar(damage)
			_last_total_damage += damage
			EventBus.hex_scarred.emit(cell.coord, damage)


func _calc_damage(rift_power: float, dist: int, radius: int, biome: BiomeType.Type) -> float:
	if dist > radius:
		return 0.0
	var distance_factor: float = 1.0 - float(dist) / float(radius + 1)
	var raw: float = rift_power * wave_config.damage_per_power * distance_factor
	var defense: float = _get_defense(biome)
	return maxf(raw * (1.0 - defense), 0.0)


func _get_defense(biome: BiomeType.Type) -> float:
	if not biome_registry:
		return 0.0
	var bdata: BiomeData = biome_registry.get_data(biome)
	if not bdata:
		return 0.0
	return bdata.defense_bonus
