class_name BuildingRegistry
extends RefCounted
## Loads and caches all BuildingData resources for lookup by building_id.

const BUILDING_DIR: String = "res://scripts/data/buildings/"

var _data: Dictionary = {}  ## StringName -> BuildingData
var _by_type: Dictionary = {}  ## BuildingType.Type -> Array[BuildingData]


func _init() -> void:
	_load_all()


func _load_all() -> void:
	var dir := DirAccess.open(BUILDING_DIR)
	if not dir:
		push_warning("BuildingRegistry: cannot open %s" % BUILDING_DIR)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path: String = BUILDING_DIR + file_name
			var res: BuildingData = load(path) as BuildingData
			if res and res.building_id != &"":
				_data[res.building_id] = res
				if not _by_type.has(res.building_type):
					_by_type[res.building_type] = []
				_by_type[res.building_type].append(res)
		file_name = dir.get_next()


func get_data(building_id: StringName) -> BuildingData:
	return _data.get(building_id, null) as BuildingData


func get_buildings_by_type(btype: BuildingType.Type) -> Array[BuildingData]:
	var arr: Array = _by_type.get(btype, [])
	var result: Array[BuildingData] = []
	for b: BuildingData in arr:
		result.append(b)
	return result


func get_all() -> Array[BuildingData]:
	var result: Array[BuildingData] = []
	for val: BuildingData in _data.values():
		result.append(val)
	return result
