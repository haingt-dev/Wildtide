class_name BiomeRegistry
extends RefCounted
## Loads and caches all BiomeData resources for O(1) lookup by type.

const BIOME_DIR: String = "res://scripts/data/biomes/"

const _BIOME_FILES: Dictionary = {
	BiomeType.Type.PLAINS: "biome_plains.tres",
	BiomeType.Type.FOREST: "biome_forest.tres",
	BiomeType.Type.ROCKY: "biome_rocky.tres",
	BiomeType.Type.SWAMP: "biome_swamp.tres",
	BiomeType.Type.RUINS: "biome_ruins.tres",
}

var _data: Dictionary = {}  ## BiomeType.Type -> BiomeData


func _init() -> void:
	_load_all()


func _load_all() -> void:
	for biome_type: BiomeType.Type in _BIOME_FILES:
		var path: String = BIOME_DIR + _BIOME_FILES[biome_type]
		var res: BiomeData = load(path) as BiomeData
		if res:
			_data[biome_type] = res
		else:
			push_warning("BiomeRegistry: failed to load %s" % path)


func get_data(biome: BiomeType.Type) -> BiomeData:
	return _data.get(biome, null) as BiomeData


func get_all() -> Array[BiomeData]:
	var result: Array[BiomeData] = []
	for val: BiomeData in _data.values():
		result.append(val)
	return result
