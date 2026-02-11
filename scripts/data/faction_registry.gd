class_name FactionRegistry
extends RefCounted
## Loads and caches all FactionData resources for O(1) lookup by type.

const FACTION_DIR: String = "res://scripts/data/factions/"

const _FACTION_FILES: Dictionary = {
	FactionType.Type.LENS: "faction_lens.tres",
	FactionType.Type.VEIL: "faction_veil.tres",
	FactionType.Type.COIN: "faction_coin.tres",
	FactionType.Type.WALL: "faction_wall.tres",
}

var _data: Dictionary = {}  ## FactionType.Type -> FactionData


func _init() -> void:
	_load_all()


func _load_all() -> void:
	for faction_type: FactionType.Type in _FACTION_FILES:
		var path: String = FACTION_DIR + _FACTION_FILES[faction_type]
		var res: FactionData = load(path) as FactionData
		if res:
			_data[faction_type] = res
		else:
			push_warning("FactionRegistry: failed to load %s" % path)


func get_data(faction: FactionType.Type) -> FactionData:
	return _data.get(faction, null) as FactionData


func get_all() -> Array[FactionData]:
	var result: Array[FactionData] = []
	for val: FactionData in _data.values():
		result.append(val)
	return result
