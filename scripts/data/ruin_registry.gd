class_name RuinRegistry
extends RefCounted
## Loads and caches all RuinData resources for O(1) lookup by type.

const RUIN_DIR: String = "res://scripts/data/ruins/"

const _RUIN_FILES: Dictionary = {
	RuinType.Type.OBSERVATORY: "ruin_observatory.tres",
	RuinType.Type.ENERGY_SHRINE: "ruin_energy_shrine.tres",
	RuinType.Type.ARCHIVE_VAULT: "ruin_archive_vault.tres",
}

var _data: Dictionary = {}  ## RuinType.Type -> RuinData


func _init() -> void:
	_load_all()


func _load_all() -> void:
	for ruin_type: RuinType.Type in _RUIN_FILES:
		var path: String = RUIN_DIR + _RUIN_FILES[ruin_type]
		var res: RuinData = load(path) as RuinData
		if res:
			_data[ruin_type] = res
		else:
			push_warning("RuinRegistry: failed to load %s" % path)


func get_data(ruin: RuinType.Type) -> RuinData:
	return _data.get(ruin, null) as RuinData


func get_all() -> Array[RuinData]:
	var result: Array[RuinData] = []
	for val: RuinData in _data.values():
		result.append(val)
	return result


## Return a weighted-random ruin type based on rarity_weight.
func pick_random_type(rng: RandomNumberGenerator) -> RuinType.Type:
	var total: float = 0.0
	for rd: RuinData in _data.values():
		total += rd.rarity_weight
	var roll: float = rng.randf() * total
	var acc: float = 0.0
	for ruin_type: RuinType.Type in _data:
		acc += (_data[ruin_type] as RuinData).rarity_weight
		if roll <= acc:
			return ruin_type
	return RuinType.Type.OBSERVATORY
