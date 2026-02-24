class_name EconomyManager
extends Node
## Manages gold/mana pools, capacity, and per-cycle income collection.
## Add as a child node in the main game scene (NOT an autoload).

var economy_config: EconomyConfig
var hex_grid: HexGrid
var biome_registry: BiomeRegistry
var edict_manager: EdictManager

var _gold: int = 0
var _mana: int = 0
var _gold_capacity: int = 0
var _mana_capacity: int = 0
var _rift_shards: int = 0

## Number of storage-type buildings (drives capacity growth).
var _storage_count: int = 0

## Whether the city is currently in transit (halves income).
var _in_transit: bool = false

## Additive income modifiers from edicts (e.g., +0.3 = +30%).
var _gold_income_modifier: float = 0.0
var _mana_income_modifier: float = 0.0


func _ready() -> void:
	if not economy_config:
		economy_config = EconomyConfig.new()
	biome_registry = BiomeRegistry.new()
	_gold = economy_config.starting_gold
	_mana = economy_config.starting_mana
	_gold_capacity = economy_config.starting_gold_capacity
	_mana_capacity = economy_config.starting_mana_capacity
	EventBus.phase_changed.connect(_on_phase_changed)


## Get current gold.
func get_gold() -> int:
	return _gold


## Get current mana.
func get_mana() -> int:
	return _mana


## Get current gold capacity.
func get_gold_capacity() -> int:
	return _gold_capacity


## Get current mana capacity.
func get_mana_capacity() -> int:
	return _mana_capacity


## Check if we can afford the given costs.
func can_afford(gold_cost: int, mana_cost: int) -> bool:
	return _gold >= gold_cost and _mana >= mana_cost


## Spend resources. Returns true if successful.
func spend(gold_cost: int, mana_cost: int) -> bool:
	if not can_afford(gold_cost, mana_cost):
		return false
	_set_gold(_gold - gold_cost)
	_set_mana(_mana - mana_cost)
	return true


## Add gold (clamped to capacity).
func add_gold(amount: int) -> void:
	_set_gold(mini(_gold + amount, _gold_capacity))


## Add mana (clamped to capacity).
func add_mana(amount: int) -> void:
	_set_mana(mini(_mana + amount, _mana_capacity))


## Get current Rift Shard count.
func get_rift_shards() -> int:
	return _rift_shards


## Add Rift Shards (from salvage or Summon the Tide).
func add_rift_shards(amount: int) -> void:
	if amount <= 0:
		return
	var old: int = _rift_shards
	_rift_shards += amount
	EventBus.rift_shards_changed.emit(_rift_shards, old)


## Set transit state (halves income during city movement).
func set_transit(active: bool) -> void:
	_in_transit = active


## Set edict income modifiers.
func set_income_modifiers(gold_mod: float, mana_mod: float) -> void:
	_gold_income_modifier = gold_mod
	_mana_income_modifier = mana_mod


## Recalculate capacity from storage building count.
func update_capacity(storage_building_count: int) -> void:
	_storage_count = storage_building_count
	_gold_capacity = (
		economy_config.starting_gold_capacity + _storage_count * economy_config.capacity_per_storage
	)
	_mana_capacity = (
		economy_config.starting_mana_capacity + _storage_count * economy_config.capacity_per_storage
	)


## Calculate and collect income for this cycle.
func collect_income() -> void:
	if not hex_grid or not biome_registry:
		return
	var raw_gold: float = 0.0
	var raw_mana: float = 0.0
	for coord: Vector3i in hex_grid.get_all_coords():
		var cell: HexCell = hex_grid.get_cell(coord)
		if not cell or cell.fog_state == FogState.HIDDEN or cell.fog_state == FogState.INACTIVE:
			continue
		var bdata: BiomeData = biome_registry.get_data(cell.biome)
		var gold_mult: float = bdata.gold_yield if bdata else 1.0
		var mana_mult: float = bdata.mana_yield if bdata else 1.0
		var scar_mult: float = economy_config.scar_modifier if cell.scar_state > 0.0 else 1.0
		raw_gold += economy_config.base_gold_yield * gold_mult * scar_mult
		raw_mana += economy_config.base_mana_yield * mana_mult * scar_mult
	var transit_mult: float = economy_config.transit_modifier if _in_transit else 1.0
	var final_gold: int = roundi(raw_gold * (1.0 + _gold_income_modifier) * transit_mult)
	var final_mana: int = roundi(raw_mana * (1.0 + _mana_income_modifier) * transit_mult)
	add_gold(final_gold)
	add_mana(final_mana)


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_sync_edict_modifiers()
		collect_income()


## Pull income modifiers from active edicts before collecting income.
func _sync_edict_modifiers() -> void:
	if not edict_manager:
		return
	var effects: Dictionary = edict_manager.get_economy_effects()
	_gold_income_modifier = effects.get(&"gold_income", 0.0) as float
	_mana_income_modifier = effects.get(&"mana_income", 0.0) as float


func _set_gold(value: int) -> void:
	var old: int = _gold
	_gold = clampi(value, 0, _gold_capacity)
	if _gold != old:
		EventBus.gold_changed.emit(_gold, old)


func _set_mana(value: int) -> void:
	var old: int = _mana
	_mana = clampi(value, 0, _mana_capacity)
	if _mana != old:
		EventBus.mana_changed.emit(_mana, old)
