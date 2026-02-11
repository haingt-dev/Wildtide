class_name SaveSystem
extends Node
## Manages save/load file I/O and autosave. Wraps SaveSerializer.
## Add as a child node in the main game scene (NOT an autoload).

const SAVE_DIR: String = "user://saves/"
const FILE_NAMES: Array[String] = ["meta.json", "world.json", "metrics.json", "factions.json"]

var hex_grid: HexGrid
var wave_manager: WaveManager
var ruins_manager: RuinsManager
var building_manager: BuildingManager
var quest_manager: QuestManager
var autosave_enabled: bool = true


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)


## Save the full game state to a named slot. Returns true on success.
func save_game(slot: String) -> bool:
	if not _has_all_managers():
		return false
	var slot_path: String = SAVE_DIR + slot + "/"
	if not _ensure_dir(slot_path):
		return false
	var meta: Dictionary = SaveSerializer.serialize_meta(GameManager)
	var world: Dictionary = SaveSerializer.serialize_world(
		hex_grid, wave_manager, ruins_manager, building_manager
	)
	var metrics: Dictionary = SaveSerializer.serialize_metrics()
	var factions: Dictionary = SaveSerializer.serialize_factions(quest_manager)
	var dicts: Array[Dictionary] = [meta, world, metrics, factions]
	for i: int in range(FILE_NAMES.size()):
		if not _write_json(slot_path + FILE_NAMES[i], dicts[i]):
			return false
	return true


## Load game state from a named slot. Returns true on success.
## All 4 files must exist and parse before any state is modified.
func load_game(slot: String) -> bool:
	var slot_path: String = SAVE_DIR + slot + "/"
	# Read and parse all 4 files first (all-or-nothing)
	var parsed: Array[Dictionary] = []
	for file_name: String in FILE_NAMES:
		var data: Variant = _read_json(slot_path + file_name)
		if data == null or not data is Dictionary:
			return false
		parsed.append(data as Dictionary)
	if not _has_all_managers():
		return false
	# Apply deserialization — all 4 must succeed
	var ok: bool = SaveSerializer.deserialize_meta(parsed[0], GameManager)
	if ok:
		ok = SaveSerializer.deserialize_world(
			parsed[1], hex_grid, wave_manager, ruins_manager, building_manager
		)
	if ok:
		ok = SaveSerializer.deserialize_metrics(parsed[2])
	if ok:
		ok = SaveSerializer.deserialize_factions(parsed[3], quest_manager)
	return ok


## Check if a save slot exists with all 4 required files.
func has_save(slot: String) -> bool:
	var slot_path: String = SAVE_DIR + slot + "/"
	for file_name: String in FILE_NAMES:
		if not FileAccess.file_exists(slot_path + file_name):
			return false
	return true


## Delete a save slot and all its files. Returns true on success.
func delete_save(slot: String) -> bool:
	var slot_path: String = SAVE_DIR + slot + "/"
	if not DirAccess.dir_exists_absolute(slot_path):
		return false
	var dir := DirAccess.open(slot_path)
	if not dir:
		return false
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		dir.remove(file_name)
		file_name = dir.get_next()
	DirAccess.remove_absolute(slot_path)
	return true


## List all existing save slot names.
func get_save_slots() -> Array[String]:
	var result: Array[String] = []
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		return result
	var dir := DirAccess.open(SAVE_DIR)
	if not dir:
		return result
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry != "." and entry != "..":
			result.append(entry)
		entry = dir.get_next()
	return result


## Read only the meta.json from a slot (for save slot UI display).
func get_save_info(slot: String) -> Dictionary:
	var path: String = SAVE_DIR + slot + "/meta.json"
	var data: Variant = _read_json(path)
	if data != null and data is Dictionary:
		return data as Dictionary
	return {}


func _has_all_managers() -> bool:
	return hex_grid and wave_manager and ruins_manager and building_manager and quest_manager


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.WAVE and autosave_enabled:
		save_game("autosave")


func _ensure_dir(path: String) -> bool:
	if DirAccess.dir_exists_absolute(path):
		return true
	var err: Error = DirAccess.make_dir_recursive_absolute(path)
	return err == OK


func _write_json(path: String, data: Dictionary) -> bool:
	var json_str: String = JSON.stringify(data, "\t")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(json_str)
	return true


func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var content: String = FileAccess.get_file_as_string(path)
	if content.is_empty():
		return null
	return JSON.parse_string(content)
