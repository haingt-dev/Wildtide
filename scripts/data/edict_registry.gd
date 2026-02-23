class_name EdictRegistry
extends RefCounted
## Loads and caches all EdictData resources for lookup by edict_id.

const EDICT_DIR: String = "res://scripts/data/edicts/"

var _data: Dictionary = {}  ## StringName -> EdictData
var _by_category: Dictionary = {}  ## int (Category) -> Array[EdictData]


func _init() -> void:
	_load_all()


func _load_all() -> void:
	var dir := DirAccess.open(EDICT_DIR)
	if not dir:
		push_warning("EdictRegistry: cannot open %s" % EDICT_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = EDICT_DIR + file_name
			var res: EdictData = load(path) as EdictData
			if res and res.edict_id != &"":
				_data[res.edict_id] = res
				var cat: int = res.category
				if not _by_category.has(cat):
					_by_category[cat] = []
				_by_category[cat].append(res)
		file_name = dir.get_next()


func get_edict(edict_id: StringName) -> EdictData:
	return _data.get(edict_id, null) as EdictData


func get_edicts_by_category(category: EdictData.Category) -> Array[EdictData]:
	var arr: Array = _by_category.get(category, [])
	var result: Array[EdictData] = []
	for e: EdictData in arr:
		result.append(e)
	return result


func get_all() -> Array[EdictData]:
	var result: Array[EdictData] = []
	for val: EdictData in _data.values():
		result.append(val)
	return result
