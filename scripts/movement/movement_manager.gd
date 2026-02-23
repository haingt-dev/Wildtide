class_name MovementManager
extends Node
## Tracks city footprint position and transit state.
## Skeleton for prototype — full fog/region logic deferred.
## Add as a child node in the main game scene (NOT an autoload).

const TRANSIT_DURATION: int = 1  ## Transit lasts 1 cycle per GDD.

var hex_grid: HexGrid
var economy_manager: EconomyManager  ## Optional — if set, toggles transit income penalty.

## Current city center in cube coordinates.
var city_center: Vector3i = Vector3i.ZERO

## Whether the city is currently in transit between locations.
var is_in_transit: bool = false

## Cycles remaining in the transit phase (0 = not transiting).
var transit_cycles_remaining: int = 0


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)


## Propose a movement in the given direction. Returns true if valid.
func propose_movement(direction: Vector3i) -> bool:
	if is_in_transit:
		return false
	if direction == Vector3i.ZERO:
		return false
	EventBus.movement_proposed.emit(direction)
	return true


## Execute city movement: shift center and enter transit.
func execute_movement(direction: Vector3i) -> bool:
	if is_in_transit:
		return false
	if direction == Vector3i.ZERO:
		return false
	var old_center: Vector3i = city_center
	city_center = city_center + direction
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
	if economy_manager:
		economy_manager.set_transit(false)
	EventBus.transit_ended.emit()


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase != CycleTimer.Phase.EVOLVE:
		return
	if not is_in_transit:
		return
	transit_cycles_remaining -= 1
	if transit_cycles_remaining <= 0:
		end_transit()
