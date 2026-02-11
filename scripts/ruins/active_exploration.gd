class_name ActiveExploration
extends RefCounted
## Runtime state for a single ruin exploration in progress.
## Created when exploration starts; discarded on completion.

var coord: Vector3i
var ruin_data: RuinData
var remaining_cycles: int
var is_damaged: bool = false


func _init(ruin_coord: Vector3i, data: RuinData) -> void:
	coord = ruin_coord
	ruin_data = data
	remaining_cycles = data.exploration_duration


## Apply one cycle tick. Returns true if exploration completed.
func tick() -> bool:
	remaining_cycles -= 1
	return remaining_cycles <= 0


func is_completed() -> bool:
	return remaining_cycles <= 0


## Mark as damaged by Wave. Reduces yield on completion.
func apply_damage() -> void:
	is_damaged = true


## Return tech fragment yield considering damage penalty.
func get_effective_tech_fragments() -> int:
	if is_damaged:
		return ceili(float(ruin_data.tech_fragments) * ruin_data.damage_yield_penalty)
	return ruin_data.tech_fragments


## Return rune shard yield considering damage penalty.
func get_effective_rune_shards() -> int:
	if is_damaged:
		return ceili(float(ruin_data.rune_shards) * ruin_data.damage_yield_penalty)
	return ruin_data.rune_shards
