class_name MovementManager
extends Node
## Tracks city footprint position, transit state, settlement bonus, and salvage.
## Add as a child node in the main game scene (NOT an autoload).

const TRANSIT_DURATION: int = 1  ## Transit lasts 1 cycle per GDD.
const FOOTPRINT_RADIUS: int = 9  ## Same as map_radius for MVP; shrink when map grows.
const SETTLEMENT_DURATION: int = 2  ## Cycles of bonus after arrival.
const SETTLEMENT_BUILD_RATES: Array[float] = [2.0, 1.5]  ## x2 then x1.5.
const SETTLEMENT_COST_DISCOUNTS: Array[float] = [0.3, 0.15]  ## -30% then -15%.
const SALVAGE_BASE: Array[int] = [1, 2, 3]  ## Per-building yield by era (index=era-1).
const SALVAGE_SCAR_THRESHOLD: float = 0.5
const SALVAGE_TIME_FACTORS: Array[float] = [0.3, 0.6, 1.0]  ## <3, 3-5, 6+ cycles.
const SALVAGE_TIME_BREAKS: Array[int] = [3, 6]  ## Cycle breakpoints for time factor.

var hex_grid: HexGrid
var economy_manager: EconomyManager  ## Optional — toggles transit income penalty.
var building_manager: BuildingManager  ## Optional — used for salvage building lookups.
var edict_manager: EdictManager  ## Optional — for mandate migration.

## Whether the city is awaiting a migration direction.
var awaiting_direction: bool = false

## Current city center in cube coordinates.
var city_center: Vector3i = Vector3i.ZERO

## Whether the city is currently in transit between locations.
var is_in_transit: bool = false

## Cycles remaining in the transit phase (0 = not transiting).
var transit_cycles_remaining: int = 0

## Settlement bonus cycles remaining after arrival (0 = normal).
var _settlement_cycles_remaining: int = 0

## Cycles spent in the current region (for salvage time factor).
var _cycles_in_region: int = 0

## Rift Shards from the last salvage operation.
var _last_salvage_yield: int = 0


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.migration_requested.connect(_on_migration_requested)


# --- Public API ---


## Propose a movement in the given direction. Returns true if valid.
func propose_movement(direction: Vector3i) -> bool:
	if is_in_transit:
		return false
	if direction == Vector3i.ZERO:
		return false
	EventBus.movement_proposed.emit(direction)
	return true


## Execute city movement: salvage, shift center, update footprint, enter transit.
func execute_movement(direction: Vector3i) -> bool:
	if is_in_transit:
		return false
	if direction == Vector3i.ZERO:
		return false
	var old_center: Vector3i = city_center
	_execute_salvage()
	city_center = city_center + direction
	_update_footprint(old_center, city_center)
	_cycles_in_region = 0
	_settlement_cycles_remaining = 0
	is_in_transit = true
	transit_cycles_remaining = TRANSIT_DURATION
	if economy_manager:
		economy_manager.set_transit(true)
	EventBus.city_moved.emit(old_center, city_center)
	EventBus.transit_started.emit()
	return true


## End transit immediately (for save loading or debug).
func end_transit() -> void:
	if not is_in_transit:
		return
	is_in_transit = false
	transit_cycles_remaining = 0
	_settlement_cycles_remaining = SETTLEMENT_DURATION
	if economy_manager:
		economy_manager.set_transit(false)
		if _last_salvage_yield > 0:
			economy_manager.add_rift_shards(_last_salvage_yield)
	EventBus.transit_ended.emit()


## Get settlement build rate multiplier (x2, x1.5, or x1.0).
func get_settlement_build_multiplier() -> float:
	if _settlement_cycles_remaining <= 0:
		return 1.0
	var idx: int = SETTLEMENT_DURATION - _settlement_cycles_remaining
	if idx >= 0 and idx < SETTLEMENT_BUILD_RATES.size():
		return SETTLEMENT_BUILD_RATES[idx]
	return 1.0


## Get settlement cost discount (0.3, 0.15, or 0.0).
func get_settlement_cost_discount() -> float:
	if _settlement_cycles_remaining <= 0:
		return 0.0
	var idx: int = SETTLEMENT_DURATION - _settlement_cycles_remaining
	if idx >= 0 and idx < SETTLEMENT_COST_DISCOUNTS.size():
		return SETTLEMENT_COST_DISCOUNTS[idx]
	return 0.0


## Get cycles spent in current region.
func get_cycles_in_region() -> int:
	return _cycles_in_region


## Get last salvage yield (Rift Shards).
func get_last_salvage_yield() -> int:
	return _last_salvage_yield


## Get settlement cycles remaining.
func get_settlement_cycles_remaining() -> int:
	return _settlement_cycles_remaining


# --- Salvage ---


## Calculate salvage yield from buildings in the old footprint.
func _execute_salvage() -> void:
	if not hex_grid or not building_manager:
		_last_salvage_yield = 0
		return
	var era: int = GameManager.get_current_era()
	var era_idx: int = clampi(era - 1, 0, SALVAGE_BASE.size() - 1)
	var base_yield: int = SALVAGE_BASE[era_idx]
	var time_factor: float = _get_salvage_time_factor()
	var total: float = 0.0
	var footprint: Array[HexCell] = hex_grid.get_cells_in_range(city_center, FOOTPRINT_RADIUS)
	for cell: HexCell in footprint:
		if cell.building_id == &"":
			continue
		var scar_penalty: int = 1 if cell.scar_state >= SALVAGE_SCAR_THRESHOLD else 0
		var cell_yield: int = maxi(base_yield - scar_penalty, 0)
		total += float(cell_yield) * time_factor
	_last_salvage_yield = roundi(total)


## Get time factor multiplier for salvage based on cycles in region.
func _get_salvage_time_factor() -> float:
	if _cycles_in_region < SALVAGE_TIME_BREAKS[0]:
		return SALVAGE_TIME_FACTORS[0]
	if _cycles_in_region < SALVAGE_TIME_BREAKS[1]:
		return SALVAGE_TIME_FACTORS[1]
	return SALVAGE_TIME_FACTORS[2]


# --- Ghost Footprint ---


## Transition old footprint hexes to INACTIVE, new footprint to ACTIVE.
func _update_footprint(old_center: Vector3i, new_center: Vector3i) -> void:
	if not hex_grid:
		return
	var old_cells: Array[HexCell] = hex_grid.get_cells_in_range(old_center, FOOTPRINT_RADIUS)
	for cell: HexCell in old_cells:
		if cell.fog_state == FogState.ACTIVE:
			cell.fog_state = FogState.INACTIVE
	var new_cells: Array[HexCell] = hex_grid.get_cells_in_range(new_center, FOOTPRINT_RADIUS)
	for cell: HexCell in new_cells:
		cell.fog_state = FogState.ACTIVE


# --- Migration ---


func _on_migration_requested() -> void:
	awaiting_direction = true


## Execute a mandate migration: pay 70% resources, then move.
func execute_mandate_migration(direction: Vector3i) -> bool:
	if not awaiting_direction or is_in_transit:
		return false
	if direction == Vector3i.ZERO:
		return false
	if economy_manager:
		var cfg: EconomyConfig = economy_manager.economy_config
		var gold_cost: int = roundi(float(economy_manager.get_gold()) * cfg.migration_cost_fraction)
		var mana_cost: int = roundi(float(economy_manager.get_mana()) * cfg.migration_cost_fraction)
		economy_manager.spend(gold_cost, mana_cost)
	awaiting_direction = false
	return execute_movement(direction)


# --- Phase Hook ---


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase != CycleTimer.Phase.EVOLVE:
		return
	_cycles_in_region += 1
	if _settlement_cycles_remaining > 0:
		_settlement_cycles_remaining -= 1
	if not is_in_transit:
		return
	transit_cycles_remaining -= 1
	if transit_cycles_remaining <= 0:
		end_transit()
