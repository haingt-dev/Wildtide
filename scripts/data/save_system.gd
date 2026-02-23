class_name SaveSystem
extends Node
## Manages save/load file I/O and autosave. Wraps SaveSerializer.
## Add as a child node in the main game scene (NOT an autoload).

const SAVE_DIR: String = "user://saves/"

## Core files required for any valid save.
const CORE_FILE_NAMES: Array[String] = ["meta.json", "world.json", "metrics.json", "factions.json"]

## Extra files written by new systems (optional on load for backward compat).
const EXTRA_FILE_NAMES: Array[String] = ["economy.json", "stability.json", "edicts.json"]

## Core system refs (required).
var hex_grid: HexGrid
var wave_manager: WaveManager
var ruins_manager: RuinsManager
var building_manager: BuildingManager
var quest_manager: QuestManager
var autosave_enabled: bool = true

## New system refs (optional — skip save/load for null refs).
var economy_manager: EconomyManager
var edict_manager: EdictManager
var stability_tracker: StabilityTracker
var movement_manager: MovementManager


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)


## Save the full game state to a named slot. Returns true on success.
func save_game(slot: String) -> bool:
	if not _has_core_managers():
		return false
	var slot_path: String = SAVE_DIR + slot + "/"
	if not _ensure_dir(slot_path):
		return false
	# Core files
	var core_dicts: Array[Dictionary] = [
		SaveSerializer.serialize_meta(GameManager),
		SaveSerializer.serialize_world(hex_grid, wave_manager, ruins_manager, building_manager),
		SaveSerializer.serialize_metrics(),
		SaveSerializer.serialize_factions(quest_manager),
	]
	for i: int in range(CORE_FILE_NAMES.size()):
		if not _write_json(slot_path + CORE_FILE_NAMES[i], core_dicts[i]):
			return false
	# Extra files (skip if manager is null)
	if economy_manager:
		_write_json(
			slot_path + "economy.json",
			SaveSerializer.serialize_economy(economy_manager),
		)
	if stability_tracker:
		_write_json(
			slot_path + "stability.json",
			SaveSerializer.serialize_stability(stability_tracker),
		)
	if edict_manager:
		var edict_data: Dictionary = SaveSerializer.serialize_edicts(edict_manager)
		if movement_manager:
			edict_data["movement"] = SaveSerializer.serialize_movement(movement_manager)
		_write_json(slot_path + "edicts.json", edict_data)
	return true


## Load game state from a named slot. Returns true on success.
## Core 4 files must exist. Extra files are optional (backward compat).
func load_game(slot: String) -> bool:
	var slot_path: String = SAVE_DIR + slot + "/"
	# Read and parse core files first (all-or-nothing)
	var parsed: Array[Dictionary] = []
	for file_name: String in CORE_FILE_NAMES:
		var data: Variant = _read_json(slot_path + file_name)
		if data == null or not data is Dictionary:
			return false
		parsed.append(data as Dictionary)
	if not _has_core_managers():
		return false
	# Apply core deserialization — all 4 must succeed
	var ok: bool = SaveSerializer.deserialize_meta(parsed[0], GameManager)
	if ok:
		ok = SaveSerializer.deserialize_world(
			parsed[1], hex_grid, wave_manager, ruins_manager, building_manager
		)
	if ok:
		ok = SaveSerializer.deserialize_metrics(parsed[2])
	if ok:
		ok = SaveSerializer.deserialize_factions(parsed[3], quest_manager)
	if not ok:
		return false
	# Extra files — load if file exists and manager is set
	_load_extra(slot_path)
	return true


## Check if a save slot exists (checks core files only for backward compat).
func has_save(slot: String) -> bool:
	var slot_path: String = SAVE_DIR + slot + "/"
	for file_name: String in CORE_FILE_NAMES:
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


func _has_core_managers() -> bool:
	return hex_grid and wave_manager and ruins_manager and building_manager and quest_manager


func _load_extra(slot_path: String) -> void:
	if economy_manager:
		var econ_data: Variant = _read_json(slot_path + "economy.json")
		if econ_data is Dictionary:
			SaveSerializer.deserialize_economy(econ_data as Dictionary, economy_manager)
	if stability_tracker:
		var stab_data: Variant = _read_json(slot_path + "stability.json")
		if stab_data is Dictionary:
			SaveSerializer.deserialize_stability(stab_data as Dictionary, stability_tracker)
	var edicts_data: Variant = _read_json(slot_path + "edicts.json")
	if edicts_data is Dictionary:
		var ed: Dictionary = edicts_data as Dictionary
		if edict_manager:
			SaveSerializer.deserialize_edicts(ed, edict_manager)
		if movement_manager and ed.has("movement"):
			SaveSerializer.deserialize_movement(ed["movement"] as Dictionary, movement_manager)


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
	var json := JSON.new()
	if json.parse(content) != OK:
		return null
	return json.data
