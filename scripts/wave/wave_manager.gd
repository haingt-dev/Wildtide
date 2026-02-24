class_name WaveManager
extends Node
## Simulates wave damage during the WAVE phase.
## Distributes damage from Rifts to nearby hexes based on wave power.
## Add as a child node in the main game scene (NOT an autoload).

var wave_config: WaveConfig
var hex_grid: HexGrid
var rift_positions: Array[Vector3i] = []
var biome_registry: BiomeRegistry
var quest_manager: QuestManager
var wave_intel: WaveIntel
var edict_manager: EdictManager
var economy_manager: EconomyManager

var _last_wave_power: float = 0.0
var _last_total_damage: float = 0.0
var _last_intel_level: int = 0
var _last_intel_report: Dictionary = {}
var _summon_used_this_cycle: bool = false


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


## Return the last computed intelligence level.
func get_last_intel_level() -> int:
	return _last_intel_level


## Return the last computed intelligence report.
func get_last_intel_report() -> Dictionary:
	return _last_intel_report


## Summon a voluntary wave: costs 50% resources, runs 80% power, yields shards.
## Returns shard reward (0 if failed). Max 1 per cycle.
func summon_the_tide() -> int:
	if _summon_used_this_cycle:
		return 0
	if not hex_grid or not wave_config or rift_positions.is_empty():
		return 0
	if economy_manager:
		var cfg: EconomyConfig = economy_manager.economy_config
		var gold_cost: int = roundi(
			float(economy_manager.get_gold()) * cfg.summon_tide_cost_fraction
		)
		var mana_cost: int = roundi(
			float(economy_manager.get_mana()) * cfg.summon_tide_cost_fraction
		)
		economy_manager.spend(gold_cost, mana_cost)
	_summon_used_this_cycle = true
	var saved_power: float = _last_wave_power
	var saved_damage: float = _last_total_damage
	_run_wave(GameManager.cycle_number)
	_last_wave_power *= 0.8
	var shard_reward: int = maxi(roundi(_last_total_damage * 0.6), 1)
	if economy_manager:
		economy_manager.add_rift_shards(shard_reward)
	_last_wave_power = saved_power
	_last_total_damage = saved_damage
	EventBus.summon_tide_completed.emit(shard_reward)
	return shard_reward


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.OBSERVE:
		_summon_used_this_cycle = false
		_update_intel()
	elif new_phase == CycleTimer.Phase.WAVE:
		_run_wave(GameManager.cycle_number)


func _update_intel() -> void:
	if wave_intel:
		_last_intel_level = wave_intel.compute_level()
		var region: RegionType.Type = _get_active_region()
		_last_intel_report = wave_intel.get_report(GameManager.cycle_number, wave_config, region)
	else:
		_last_intel_level = 0
		_last_intel_report = {&"level": 0}
	EventBus.wave_intel_updated.emit(_last_intel_level, _last_intel_report)


func _run_wave(cycle: int) -> void:
	if not hex_grid or not wave_config or rift_positions.is_empty():
		return

	var region: RegionType.Type = _get_active_region()
	_last_wave_power = wave_config.get_wave_power(cycle, region)
	_last_total_damage = 0.0

	# Apply offensive quest effects.
	var offensive: Dictionary = _get_offensive_effects()
	_last_wave_power *= offensive.get(&"power_multiplier", 1.0) as float
	var bonus_defense: float = offensive.get(&"defense_bonus", 0.0) as float
	var rift_spawn_mult: float = offensive.get(&"rift_spawn_multiplier", 1.0) as float

	# Full intel grants a small defense bonus.
	if _last_intel_level == WaveIntel.Level.FULL:
		bonus_defense += 0.05
	# Edict defense modifier stacks on top.
	if edict_manager:
		bonus_defense += edict_manager.get_defense_modifier()

	var rift_count: int = rift_positions.size()
	var rift_power: float = _last_wave_power / float(rift_count)
	var radius: int = wave_config.damage_radius

	EventBus.wave_started.emit(cycle)

	for rift_coord: Vector3i in rift_positions:
		var adjusted_power: float = rift_power * rift_spawn_mult
		_damage_around_rift(rift_coord, adjusted_power, radius, bonus_defense)

	EventBus.wave_ended.emit(cycle)


func _get_offensive_effects() -> Dictionary:
	if quest_manager:
		return quest_manager.get_active_offensive_effects()
	return {}


func _damage_around_rift(
	rift_coord: Vector3i, rift_power: float, radius: int, bonus_defense: float = 0.0
) -> void:
	var cells: Array[HexCell] = hex_grid.get_cells_in_range(rift_coord, radius)
	for cell: HexCell in cells:
		var dist: int = HexMath.distance(rift_coord, cell.coord)
		var damage: float = _calc_damage(rift_power, dist, radius, cell.biome, bonus_defense)
		if damage > 0.0:
			cell.apply_scar(damage)
			_last_total_damage += damage
			EventBus.hex_scarred.emit(cell.coord, damage)


func _calc_damage(
	rift_power: float,
	dist: int,
	radius: int,
	biome: BiomeType.Type,
	bonus_defense: float = 0.0,
) -> float:
	if dist > radius:
		return 0.0
	var distance_factor: float = 1.0 - float(dist) / float(radius + 1)
	var raw: float = rift_power * wave_config.damage_per_power * distance_factor
	var defense: float = clampf(_get_defense(biome) + bonus_defense, 0.0, 1.0)
	return maxf(raw * (1.0 - defense), 0.0)


func _get_active_region() -> RegionType.Type:
	if not hex_grid or rift_positions.is_empty():
		return RegionType.Type.MID
	var cell: HexCell = hex_grid.get_cell(rift_positions[0])
	if cell:
		return cell.region as RegionType.Type
	return RegionType.Type.MID


func _get_defense(biome: BiomeType.Type) -> float:
	if not biome_registry:
		return 0.0
	var bdata: BiomeData = biome_registry.get_data(biome)
	if not bdata:
		return 0.0
	return bdata.defense_bonus
