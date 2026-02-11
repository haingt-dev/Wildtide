class_name ActiveConstruction
extends RefCounted
## Runtime state for a single building under construction or completed.
## Created when placement starts; kept after completion for effect application.

var coord: Vector3i
var building_data: BuildingData
var progress: float = 0.0  ## Accumulated toward construction_duration
var is_complete: bool = false


func _init(build_coord: Vector3i, data: BuildingData) -> void:
	coord = build_coord
	building_data = data


## Apply one cycle tick with the given effective speed multiplier.
## Returns true if construction just completed this tick.
func tick(speed_multiplier: float) -> bool:
	if is_complete:
		return false
	progress += speed_multiplier
	if progress >= float(building_data.construction_duration):
		progress = float(building_data.construction_duration)
		is_complete = true
		return true
	return false


## Return construction progress as a ratio (0.0 to 1.0).
func get_progress_ratio() -> float:
	if building_data.construction_duration <= 0:
		return 1.0
	return clampf(progress / float(building_data.construction_duration), 0.0, 1.0)


## Estimate remaining cycles at the given speed.
func get_remaining_cycles_estimate(speed_multiplier: float) -> int:
	if is_complete or speed_multiplier <= 0.0:
		return 0
	var remaining: float = float(building_data.construction_duration) - progress
	return ceili(remaining / speed_multiplier)
