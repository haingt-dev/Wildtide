class_name WaveIntel
extends RefCounted
## Computes wave intelligence level based on Observatory ruins,
## Lens faction morale, and active scout quests.

enum Level { BLIND, PARTIAL, GOOD, FULL }

const LENS_MORALE_THRESHOLD: int = 75
const SCOUT_QUEST_ID: StringName = &"wall_patrol"

var ruins_manager: RuinsManager
var quest_manager: QuestManager


func _init(p_ruins_manager: RuinsManager, p_quest_manager: QuestManager) -> void:
	ruins_manager = p_ruins_manager
	quest_manager = p_quest_manager


## Compute the current intelligence level.
func compute_level() -> Level:
	if not ruins_manager or not quest_manager:
		return Level.BLIND
	if _has_active_scout():
		return Level.FULL
	if _lens_morale_high():
		return Level.GOOD
	if _has_observatory_explored():
		return Level.PARTIAL
	return Level.BLIND


## Generate an intelligence report for UI consumption.
func get_report(cycle: int, wave_config: WaveConfig, region: RegionType.Type) -> Dictionary:
	var level: Level = compute_level()
	var report: Dictionary = {&"level": level}
	if level >= Level.PARTIAL:
		report[&"enemy_count"] = wave_config.get_enemy_count(cycle, region)
		report[&"power"] = wave_config.get_wave_power(cycle, region)
	if level >= Level.GOOD:
		report[&"spawn_directions"] = _get_spawn_direction_count(region)
	if level >= Level.FULL:
		var era: int = wave_config.get_era(cycle)
		report[&"has_elite"] = era >= 2
		report[&"timing_warning"] = true
	return report


func _has_observatory_explored() -> bool:
	return ruins_manager.has_ruin_at_state(RuinType.Type.OBSERVATORY, RuinType.STATE_DISCOVERED)


func _lens_morale_high() -> bool:
	return quest_manager.get_faction_morale(&"lens") > LENS_MORALE_THRESHOLD


func _has_active_scout() -> bool:
	for active: ActiveQuest in quest_manager.get_active_quests():
		if active.quest_data.quest_id == SCOUT_QUEST_ID:
			return true
	return false


func _get_spawn_direction_count(region: RegionType.Type) -> int:
	match region:
		RegionType.Type.STARTING:
			return 1
		RegionType.Type.LATE, RegionType.Type.RIFT_CORE:
			return 3
	return 2
