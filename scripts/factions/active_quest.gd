class_name ActiveQuest
extends RefCounted
## Runtime state for a single approved quest in progress.
## Created when a quest is approved; discarded on completion.

var quest_data: QuestData
var faction_id: StringName
var remaining_cycles: int


func _init(data: QuestData) -> void:
	quest_data = data
	faction_id = data.faction_id
	remaining_cycles = data.duration


## Apply one cycle tick. Returns true if quest completed (remaining <= 0).
func tick() -> bool:
	remaining_cycles -= 1
	return remaining_cycles <= 0


func is_completed() -> bool:
	return remaining_cycles <= 0
