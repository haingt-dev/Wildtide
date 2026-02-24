class_name ArtifactController
extends RefCounted
## Tracks artifact construction state for the endgame win condition.
## Created when player initiates artifact building at a Rift Core hex.

enum State { IDLE, BUILDING, COMPLETE, FAILED }

var state: State = State.IDLE
var progress_cycles: int = 0
var required_cycles: int = 3
var construction_coord: Vector3i = Vector3i.ZERO


## Start artifact construction at the given location.
## Returns true if construction started successfully.
func start_construction(coord: Vector3i, cycles: int) -> bool:
	if state != State.IDLE:
		return false
	construction_coord = coord
	required_cycles = cycles
	progress_cycles = 0
	state = State.BUILDING
	return true


## Advance construction by one cycle. Returns true if just completed.
func tick() -> bool:
	if state != State.BUILDING:
		return false
	progress_cycles += 1
	if progress_cycles >= required_cycles:
		state = State.COMPLETE
		return true
	return false


## Mark artifact as failed (city moved away, stability collapsed, etc.).
func fail() -> void:
	if state == State.BUILDING:
		state = State.FAILED


## Whether artifact construction is complete.
func is_complete() -> bool:
	return state == State.COMPLETE


## Whether artifact is currently under construction.
func is_building() -> bool:
	return state == State.BUILDING


## Get current construction progress (cycles completed).
func get_progress() -> int:
	return progress_cycles


## Reset to idle state (e.g., after failure, for retry).
func reset() -> void:
	state = State.IDLE
	progress_cycles = 0
	construction_coord = Vector3i.ZERO
