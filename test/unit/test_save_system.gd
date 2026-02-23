extends GutTest
## Tests for SaveSystem — file I/O, save slots, and autosave.
## Uses global EventBus, MetricSystem, and GameManager autoloads.

const TEST_SLOT: String = "_gut_test_slot"
const TEST_SLOT_2: String = "_gut_test_slot_2"

var save_sys: SaveSystem
var grid: HexGrid
var wave_mgr: WaveManager
var ruins_mgr: RuinsManager
var building_mgr: BuildingManager
var quest_mgr: QuestManager


func before_each() -> void:
	grid = HexGrid.new()
	grid.initialize_hex_map(3)
	wave_mgr = WaveManager.new()
	add_child(wave_mgr)
	wave_mgr.hex_grid = grid
	wave_mgr.rift_positions = [Vector3i(1, -1, 0), Vector3i(-1, 0, 1), Vector3i(0, 1, -1)]
	ruins_mgr = RuinsManager.new()
	add_child(ruins_mgr)
	ruins_mgr.hex_grid = grid
	building_mgr = BuildingManager.new()
	add_child(building_mgr)
	building_mgr.hex_grid = grid
	quest_mgr = QuestManager.new()
	add_child(quest_mgr)
	save_sys = SaveSystem.new()
	add_child(save_sys)
	save_sys.hex_grid = grid
	save_sys.wave_manager = wave_mgr
	save_sys.ruins_manager = ruins_mgr
	save_sys.building_manager = building_mgr
	save_sys.quest_manager = quest_mgr
	save_sys.autosave_enabled = false
	MetricSystem.reset_to_defaults()
	GameManager.cycle_number = 3
	GameManager.current_phase = CycleTimer.Phase.INFLUENCE
	GameManager.game_speed = 2
	GameManager.is_running = true
	# Clean test slots
	_clean_slot(TEST_SLOT)
	_clean_slot(TEST_SLOT_2)


func after_each() -> void:
	_clean_slot(TEST_SLOT)
	_clean_slot(TEST_SLOT_2)
	save_sys.queue_free()
	wave_mgr.queue_free()
	ruins_mgr.queue_free()
	building_mgr.queue_free()
	quest_mgr.queue_free()
	MetricSystem.reset_to_defaults()
	GameManager.cycle_number = 0
	GameManager.current_phase = CycleTimer.Phase.OBSERVE
	GameManager.game_speed = 1
	GameManager.is_running = false


func _clean_slot(slot: String) -> void:
	var slot_path: String = SaveSystem.SAVE_DIR + slot + "/"
	if DirAccess.dir_exists_absolute(slot_path):
		var dir := DirAccess.open(slot_path)
		if dir:
			dir.list_dir_begin()
			var f: String = dir.get_next()
			while f != "":
				dir.remove(f)
				f = dir.get_next()
			DirAccess.remove_absolute(slot_path)


# --- Save ---


func test_save_creates_directory() -> void:
	var ok: bool = save_sys.save_game(TEST_SLOT)
	assert_true(ok)
	var slot_path: String = SaveSystem.SAVE_DIR + TEST_SLOT + "/"
	assert_true(DirAccess.dir_exists_absolute(slot_path))


func test_save_creates_core_json_files() -> void:
	save_sys.save_game(TEST_SLOT)
	var slot_path: String = SaveSystem.SAVE_DIR + TEST_SLOT + "/"
	for file_name: String in SaveSystem.CORE_FILE_NAMES:
		assert_true(FileAccess.file_exists(slot_path + file_name), file_name + " should exist")


func test_save_meta_is_valid_json() -> void:
	save_sys.save_game(TEST_SLOT)
	var path: String = SaveSystem.SAVE_DIR + TEST_SLOT + "/meta.json"
	var content: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(content)
	assert_not_null(parsed, "meta.json should be valid JSON")
	assert_true(parsed is Dictionary)
	assert_true((parsed as Dictionary).has("cycle_number"))


func test_save_world_is_valid_json() -> void:
	save_sys.save_game(TEST_SLOT)
	var path: String = SaveSystem.SAVE_DIR + TEST_SLOT + "/world.json"
	var content: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(content)
	assert_not_null(parsed, "world.json should be valid JSON")
	assert_true(parsed is Dictionary)
	assert_true((parsed as Dictionary).has("cells"))


# --- Load ---


func test_load_restores_game_state() -> void:
	MetricSystem.pollution = 0.65
	GameManager.cycle_number = 8
	save_sys.save_game(TEST_SLOT)
	# Reset state
	MetricSystem.reset_to_defaults()
	GameManager.cycle_number = 0
	GameManager.is_running = false
	# Load
	var ok: bool = save_sys.load_game(TEST_SLOT)
	assert_true(ok)
	assert_eq(GameManager.cycle_number, 8)
	assert_almost_eq(MetricSystem.pollution, 0.65, 0.001)
	assert_true(GameManager.is_running)


func test_load_missing_slot_returns_false() -> void:
	assert_false(save_sys.load_game("nonexistent_slot_xyz"))


func test_load_corrupt_file_returns_false() -> void:
	save_sys.save_game(TEST_SLOT)
	# Corrupt meta.json
	var path: String = SaveSystem.SAVE_DIR + TEST_SLOT + "/meta.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("not valid json {{{")
	file = null
	assert_false(save_sys.load_game(TEST_SLOT))


func test_load_partial_slot_returns_false() -> void:
	save_sys.save_game(TEST_SLOT)
	# Delete one file
	var path: String = SaveSystem.SAVE_DIR + TEST_SLOT + "/factions.json"
	DirAccess.remove_absolute(path)
	assert_false(save_sys.load_game(TEST_SLOT))


# --- Slots ---


func test_has_save_true_for_existing() -> void:
	save_sys.save_game(TEST_SLOT)
	assert_true(save_sys.has_save(TEST_SLOT))


func test_has_save_false_for_missing() -> void:
	assert_false(save_sys.has_save("nonexistent_slot_xyz"))


func test_delete_save_removes_slot() -> void:
	save_sys.save_game(TEST_SLOT)
	assert_true(save_sys.delete_save(TEST_SLOT))
	assert_false(save_sys.has_save(TEST_SLOT))


func test_delete_save_missing_returns_false() -> void:
	assert_false(save_sys.delete_save("nonexistent_slot_xyz"))


func test_get_save_slots_lists_all() -> void:
	save_sys.save_game(TEST_SLOT)
	save_sys.save_game(TEST_SLOT_2)
	var slots: Array[String] = save_sys.get_save_slots()
	assert_true(slots.has(TEST_SLOT))
	assert_true(slots.has(TEST_SLOT_2))


func test_get_save_slots_empty_when_no_saves() -> void:
	_clean_slot(TEST_SLOT)
	_clean_slot(TEST_SLOT_2)
	var slots: Array[String] = save_sys.get_save_slots()
	# Only check our test slots aren't present (other saves may exist)
	assert_false(slots.has(TEST_SLOT))
	assert_false(slots.has(TEST_SLOT_2))


func test_get_save_info_reads_meta() -> void:
	GameManager.cycle_number = 11
	save_sys.save_game(TEST_SLOT)
	var info: Dictionary = save_sys.get_save_info(TEST_SLOT)
	assert_eq(info.get("cycle_number", 0), 11)
	assert_true(info.has("save_version"))


# --- Autosave ---


func test_autosave_triggers_on_wave_phase() -> void:
	save_sys.autosave_enabled = true
	EventBus.phase_changed.emit(int(CycleTimer.Phase.WAVE), &"wave")
	assert_true(save_sys.has_save("autosave"))
	_clean_slot("autosave")


func test_autosave_does_not_trigger_on_other_phases() -> void:
	save_sys.autosave_enabled = true
	_clean_slot("autosave")
	EventBus.phase_changed.emit(int(CycleTimer.Phase.OBSERVE), &"observe")
	EventBus.phase_changed.emit(int(CycleTimer.Phase.INFLUENCE), &"influence")
	EventBus.phase_changed.emit(int(CycleTimer.Phase.EVOLVE), &"evolve")
	assert_false(save_sys.has_save("autosave"))


func test_autosave_saves_to_autosave_slot() -> void:
	save_sys.autosave_enabled = true
	GameManager.cycle_number = 7
	EventBus.phase_changed.emit(int(CycleTimer.Phase.WAVE), &"wave")
	var info: Dictionary = save_sys.get_save_info("autosave")
	assert_eq(info.get("cycle_number", 0), 7)
	_clean_slot("autosave")


# --- Round-trip ---


func test_round_trip_preserves_hex_cells() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.biome = BiomeType.Type.ROCKY
	cell.scar_state = 0.6
	save_sys.save_game(TEST_SLOT)
	# Reset grid
	grid.clear()
	grid.initialize_hex_map(3)
	save_sys.load_game(TEST_SLOT)
	var loaded: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	assert_eq(int(loaded.biome), int(BiomeType.Type.ROCKY))
	assert_almost_eq(loaded.scar_state, 0.6, 0.001)


func test_round_trip_preserves_metrics() -> void:
	MetricSystem.pollution = 0.45
	MetricSystem.solidarity = 0.78
	MetricSystem.science_value = 5.5
	save_sys.save_game(TEST_SLOT)
	MetricSystem.reset_to_defaults()
	save_sys.load_game(TEST_SLOT)
	assert_almost_eq(MetricSystem.pollution, 0.45, 0.001)
	assert_almost_eq(MetricSystem.solidarity, 0.78, 0.001)
	assert_almost_eq(MetricSystem.science_value, 5.5, 0.001)


# --- Edge ---


func test_save_without_grid_returns_false() -> void:
	save_sys.hex_grid = null
	assert_false(save_sys.save_game(TEST_SLOT))
