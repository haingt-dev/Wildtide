class_name QuestRegistry
extends RefCounted
## Loads and caches all QuestData resources for lookup by quest_id.

const QUEST_DIR: String = "res://scripts/data/quests/"

var _data: Dictionary = {}  ## StringName -> QuestData
var _by_faction: Dictionary = {}  ## StringName -> Array[QuestData] (non-offensive only)
var _offensive_by_faction: Dictionary = {}  ## StringName -> Array[QuestData]


func _init() -> void:
	_load_all()


func _load_all() -> void:
	var dir := DirAccess.open(QUEST_DIR)
	if not dir:
		push_warning("QuestRegistry: cannot open %s" % QUEST_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = QUEST_DIR + file_name
			var res: QuestData = load(path) as QuestData
			if res and res.quest_id != &"":
				_data[res.quest_id] = res
				if res.is_offensive:
					if not _offensive_by_faction.has(res.faction_id):
						_offensive_by_faction[res.faction_id] = []
					_offensive_by_faction[res.faction_id].append(res)
				else:
					if not _by_faction.has(res.faction_id):
						_by_faction[res.faction_id] = []
					_by_faction[res.faction_id].append(res)
		file_name = dir.get_next()


func get_quest(quest_id: StringName) -> QuestData:
	return _data.get(quest_id, null) as QuestData


func get_quests_for_faction(faction_id: StringName) -> Array[QuestData]:
	var arr: Array = _by_faction.get(faction_id, [])
	var result: Array[QuestData] = []
	for q: QuestData in arr:
		result.append(q)
	return result


## Get offensive quests for a faction.
func get_offensive_quests_for_faction(faction_id: StringName) -> Array[QuestData]:
	var arr: Array = _offensive_by_faction.get(faction_id, [])
	var result: Array[QuestData] = []
	for q: QuestData in arr:
		result.append(q)
	return result


func get_all() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for val: QuestData in _data.values():
		result.append(val)
	return result
