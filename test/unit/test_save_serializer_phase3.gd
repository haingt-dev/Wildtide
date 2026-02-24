extends GutTest
## Tests for Phase 3 SaveSerializer additions: zone_type, offensive quests, wave intel.

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

	MetricSystem.reset_to_defaults()


func after_each() -> void:
	wave_mgr.queue_free()
	ruins_mgr.queue_free()
	building_mgr.queue_free()
	quest_mgr.queue_free()
	MetricSystem.reset_to_defaults()


# --- Zone type ---


func test_serialize_world_cell_has_zone_type() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.zone_type = ZoneType.Type.DEFENSE_PERIMETER
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	var found := false
	for cd: Dictionary in data["cells"]:
		if cd["coord"] == [1, -1, 0]:
			assert_eq(cd["zone_type"], int(ZoneType.Type.DEFENSE_PERIMETER))
			found = true
			break
	assert_true(found, "Cell [1,-1,0] should be in serialized data")


func test_deserialize_world_restores_zone_type() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(0, 0, 0))
	cell.zone_type = ZoneType.Type.RESIDENTIAL
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	var fresh_grid := HexGrid.new()
	SaveSerializer.deserialize_world(data, fresh_grid, wave_mgr, ruins_mgr, building_mgr)
	var loaded: HexCell = fresh_grid.get_cell(Vector3i(0, 0, 0))
	assert_not_null(loaded)
	assert_eq(loaded.zone_type, int(ZoneType.Type.RESIDENTIAL))


# --- Offensive quests ---


func test_serialize_factions_stores_offensive_quests() -> void:
	var quest_data: QuestData = quest_mgr.quest_registry.get_quest(&"wall_ambush")
	if not quest_data:
		pass_test("Offensive quest not found, skipping")
		return
	var active := ActiveQuest.new(quest_data)
	active.remaining_cycles = 1
	quest_mgr._offensive_quests[&"wall_ambush"] = active
	var data: Dictionary = SaveSerializer.serialize_factions(quest_mgr)
	assert_true(data.has("offensive_quests"))
	assert_eq(data["offensive_quests"].size(), 1)
	assert_eq(data["offensive_quests"][0]["quest_id"], "wall_ambush")
	assert_eq(data["offensive_quests"][0]["remaining_cycles"], 1)


func test_deserialize_factions_restores_offensive_quests() -> void:
	var quest_data: QuestData = quest_mgr.quest_registry.get_quest(&"wall_ambush")
	if not quest_data:
		pass_test("Offensive quest not found, skipping")
		return
	var data: Dictionary = {
		"pending_proposals": [],
		"active_quests": [],
		"offensive_quests": [{"quest_id": "wall_ambush", "remaining_cycles": 1}],
		"last_proposed": {},
	}
	SaveSerializer.deserialize_factions(data, quest_mgr)
	assert_true(quest_mgr._offensive_quests.has(&"wall_ambush"))
	var loaded: ActiveQuest = quest_mgr._offensive_quests[&"wall_ambush"]
	assert_eq(loaded.remaining_cycles, 1)
	assert_true(loaded.quest_data.is_offensive)


# --- Wave intel cache ---


func test_serialize_world_stores_intel_level() -> void:
	wave_mgr._last_intel_level = 3
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["last_intel_level"], 3)


func test_serialize_world_stores_intel_report() -> void:
	wave_mgr._last_intel_report = {&"level": 2, &"power_estimate": 50.0}
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["last_intel_report"][&"level"], 2)
	assert_almost_eq(float(data["last_intel_report"][&"power_estimate"]), 50.0, 0.001)


func test_deserialize_world_restores_intel_level() -> void:
	wave_mgr._last_intel_level = 2
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	wave_mgr._last_intel_level = 0
	SaveSerializer.deserialize_world(data, grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(wave_mgr._last_intel_level, 2)


func test_deserialize_world_restores_intel_report() -> void:
	wave_mgr._last_intel_report = {&"level": 3, &"direction": &"north"}
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	wave_mgr._last_intel_report = {}
	SaveSerializer.deserialize_world(data, grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(wave_mgr._last_intel_report.get("level", 0), 3)
	assert_eq(wave_mgr._last_intel_report.get("direction", ""), "north")
