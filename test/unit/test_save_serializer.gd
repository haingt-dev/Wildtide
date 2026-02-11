extends GutTest
## Tests for SaveSerializer — pure data conversion between systems and Dicts.
## Uses global EventBus, MetricSystem, and GameManager autoloads.

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
	GameManager.cycle_number = 1
	GameManager.current_phase = CycleTimer.Phase.OBSERVE
	GameManager.game_speed = 1


func after_each() -> void:
	wave_mgr.queue_free()
	ruins_mgr.queue_free()
	building_mgr.queue_free()
	quest_mgr.queue_free()
	MetricSystem.reset_to_defaults()
	GameManager.cycle_number = 0
	GameManager.current_phase = CycleTimer.Phase.OBSERVE
	GameManager.game_speed = 1
	GameManager.is_running = false


# --- Utility ---


func test_vec3i_round_trip() -> void:
	var v := Vector3i(3, -2, -1)
	var arr: Array = SaveSerializer.vec3i_to_array(v)
	assert_eq(arr, [3, -2, -1])
	assert_eq(SaveSerializer.array_to_vec3i(arr), v)


func test_vec3i_key_round_trip() -> void:
	var v := Vector3i(-5, 3, 2)
	var key: String = SaveSerializer.vec3i_to_key(v)
	assert_eq(key, "-5,3,2")
	assert_eq(SaveSerializer.key_to_vec3i(key), v)


func test_empty_grid_serialize_deserialize() -> void:
	var empty_grid := HexGrid.new()
	empty_grid.initialize_hex_map(0)
	var empty_wave := WaveManager.new()
	add_child(empty_wave)
	var empty_ruins := RuinsManager.new()
	add_child(empty_ruins)
	empty_ruins.ruin_registry = RuinRegistry.new()
	var empty_buildings := BuildingManager.new()
	add_child(empty_buildings)
	empty_buildings.building_registry = BuildingRegistry.new()
	var data: Dictionary = SaveSerializer.serialize_world(
		empty_grid, empty_wave, empty_ruins, empty_buildings
	)
	assert_eq(data["cells"].size(), 1, "radius 0 = 1 hex")
	# Deserialize onto fresh grid
	var fresh_grid := HexGrid.new()
	var ok: bool = SaveSerializer.deserialize_world(
		data, fresh_grid, empty_wave, empty_ruins, empty_buildings
	)
	assert_true(ok)
	assert_eq(fresh_grid.get_cell_count(), 1)
	empty_wave.queue_free()
	empty_ruins.queue_free()
	empty_buildings.queue_free()


# --- Meta ---


func test_serialize_meta_has_correct_keys() -> void:
	GameManager.cycle_number = 5
	GameManager.current_phase = CycleTimer.Phase.INFLUENCE
	GameManager.game_speed = 2
	var data: Dictionary = SaveSerializer.serialize_meta(GameManager)
	assert_true(data.has("save_version"))
	assert_true(data.has("save_date"))
	assert_true(data.has("cycle_number"))
	assert_true(data.has("current_phase"))
	assert_true(data.has("game_speed"))


func test_serialize_meta_stores_values() -> void:
	GameManager.cycle_number = 7
	GameManager.current_phase = CycleTimer.Phase.WAVE
	GameManager.game_speed = 3
	var data: Dictionary = SaveSerializer.serialize_meta(GameManager)
	assert_eq(data["save_version"], SaveSerializer.SAVE_VERSION)
	assert_eq(data["cycle_number"], 7)
	assert_eq(data["current_phase"], int(CycleTimer.Phase.WAVE))
	assert_eq(data["game_speed"], 3)


func test_deserialize_meta_restores_state() -> void:
	var data: Dictionary = {
		"save_version": 1,
		"save_date": "2026-02-12T12:00:00",
		"cycle_number": 10,
		"current_phase": int(CycleTimer.Phase.EVOLVE),
		"game_speed": 2,
	}
	var ok: bool = SaveSerializer.deserialize_meta(data, GameManager)
	assert_true(ok)
	assert_eq(GameManager.cycle_number, 10)
	assert_eq(int(GameManager.current_phase), int(CycleTimer.Phase.EVOLVE))
	assert_eq(GameManager.game_speed, 2)
	assert_true(GameManager.is_running)


func test_deserialize_meta_missing_keys_returns_false() -> void:
	assert_false(SaveSerializer.deserialize_meta({}, GameManager))
	assert_false(SaveSerializer.deserialize_meta({"cycle_number": 1}, GameManager))


# --- World ---


func test_serialize_world_has_correct_keys() -> void:
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_true(data.has("map_radius"))
	assert_true(data.has("cells"))
	assert_true(data.has("rift_positions"))
	assert_true(data.has("ruin_types"))
	assert_true(data.has("active_explorations"))
	assert_true(data.has("constructions"))


func test_serialize_world_stores_map_radius() -> void:
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["map_radius"], 3)


func test_serialize_world_stores_correct_cell_count() -> void:
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["cells"].size(), grid.get_cell_count())


func test_serialize_world_cell_has_all_fields() -> void:
	# Set non-default values on a cell
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.biome = BiomeType.Type.FOREST
	cell.building_id = &"homestead"
	cell.scar_state = 0.3
	cell.exploration_state = 2
	cell.alignment_local = 0.5
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	var found := false
	for cd: Dictionary in data["cells"]:
		if cd["coord"] == [1, -1, 0]:
			assert_eq(cd["biome"], int(BiomeType.Type.FOREST))
			assert_eq(cd["building_id"], "homestead")
			assert_almost_eq(cd["scar_state"], 0.3, 0.001)
			assert_eq(cd["exploration_state"], 2)
			assert_almost_eq(cd["alignment_local"], 0.5, 0.001)
			found = true
			break
	assert_true(found, "Cell [1,-1,0] should be in serialized data")


func test_serialize_world_stores_rift_positions() -> void:
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["rift_positions"].size(), 3)
	assert_eq(data["rift_positions"][0], [1, -1, 0])


func test_serialize_world_stores_ruin_types() -> void:
	var coord := Vector3i(1, 0, -1)
	ruins_mgr._ruin_types[coord] = RuinType.Type.OBSERVATORY
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["ruin_types"]["1,0,-1"], int(RuinType.Type.OBSERVATORY))


func test_serialize_world_stores_active_explorations() -> void:
	var coord := Vector3i(1, 0, -1)
	var ruin_data: RuinData = ruins_mgr.ruin_registry.get_data(RuinType.Type.OBSERVATORY)
	var active := ActiveExploration.new(coord, ruin_data)
	active.remaining_cycles = 1
	active.is_damaged = true
	ruins_mgr._active_explorations[coord] = active
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["active_explorations"].size(), 1)
	var exp_data: Dictionary = data["active_explorations"][0]
	assert_eq(exp_data["coord"], [1, 0, -1])
	assert_eq(exp_data["ruin_type"], int(RuinType.Type.OBSERVATORY))
	assert_eq(exp_data["remaining_cycles"], 1)
	assert_true(exp_data["is_damaged"])


func test_serialize_world_stores_constructions() -> void:
	building_mgr.place_building(Vector3i(1, -1, 0), &"homestead")
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(data["constructions"].size(), 1)
	var con_data: Dictionary = data["constructions"][0]
	assert_eq(con_data["coord"], [1, -1, 0])
	assert_eq(con_data["building_id"], "homestead")


func test_deserialize_world_restores_cells() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.biome = BiomeType.Type.ROCKY
	cell.scar_state = 0.7
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	var fresh_grid := HexGrid.new()
	SaveSerializer.deserialize_world(data, fresh_grid, wave_mgr, ruins_mgr, building_mgr)
	var loaded_cell: HexCell = fresh_grid.get_cell(Vector3i(1, -1, 0))
	assert_not_null(loaded_cell)
	assert_eq(int(loaded_cell.biome), int(BiomeType.Type.ROCKY))
	assert_almost_eq(loaded_cell.scar_state, 0.7, 0.001)


func test_deserialize_world_restores_rift_positions() -> void:
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	wave_mgr.rift_positions.clear()
	SaveSerializer.deserialize_world(data, grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(wave_mgr.rift_positions.size(), 3)
	assert_eq(wave_mgr.rift_positions[0], Vector3i(1, -1, 0))


func test_deserialize_world_restores_ruin_types() -> void:
	var coord := Vector3i(1, 0, -1)
	ruins_mgr._ruin_types[coord] = RuinType.Type.ENERGY_SHRINE
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	ruins_mgr._ruin_types.clear()
	SaveSerializer.deserialize_world(data, grid, wave_mgr, ruins_mgr, building_mgr)
	assert_eq(int(ruins_mgr._ruin_types[coord]), int(RuinType.Type.ENERGY_SHRINE))


func test_deserialize_world_restores_explorations() -> void:
	var coord := Vector3i(1, 0, -1)
	var ruin_data: RuinData = ruins_mgr.ruin_registry.get_data(RuinType.Type.ARCHIVE_VAULT)
	var active := ActiveExploration.new(coord, ruin_data)
	active.remaining_cycles = 2
	active.is_damaged = true
	ruins_mgr._active_explorations[coord] = active
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	ruins_mgr._active_explorations.clear()
	SaveSerializer.deserialize_world(data, grid, wave_mgr, ruins_mgr, building_mgr)
	assert_true(ruins_mgr._active_explorations.has(coord))
	var loaded: ActiveExploration = ruins_mgr._active_explorations[coord]
	assert_eq(loaded.remaining_cycles, 2)
	assert_true(loaded.is_damaged)


func test_deserialize_world_restores_constructions() -> void:
	building_mgr.place_building(Vector3i(1, -1, 0), &"reactor")
	var construction: ActiveConstruction = building_mgr.get_construction(Vector3i(1, -1, 0))
	construction.progress = 1.5
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	building_mgr._constructions.clear()
	SaveSerializer.deserialize_world(data, grid, wave_mgr, ruins_mgr, building_mgr)
	assert_true(building_mgr._constructions.has(Vector3i(1, -1, 0)))
	var loaded: ActiveConstruction = building_mgr._constructions[Vector3i(1, -1, 0)]
	assert_almost_eq(loaded.progress, 1.5, 0.001)
	assert_eq(String(loaded.building_data.building_id), "reactor")


func test_deserialize_world_missing_keys_returns_false() -> void:
	assert_false(SaveSerializer.deserialize_world({}, grid, wave_mgr, ruins_mgr, building_mgr))
	assert_false(
		SaveSerializer.deserialize_world({"map_radius": 3}, grid, wave_mgr, ruins_mgr, building_mgr)
	)


# --- Metrics ---


func test_serialize_metrics_has_all_values() -> void:
	MetricSystem.pollution = 0.35
	MetricSystem.anxiety = 0.12
	MetricSystem.solidarity = 0.68
	MetricSystem.harmony = 0.41
	MetricSystem.science_value = 12.5
	MetricSystem.magic_value = 3.2
	var data: Dictionary = SaveSerializer.serialize_metrics()
	assert_almost_eq(data["pollution"], 0.35, 0.001)
	assert_almost_eq(data["anxiety"], 0.12, 0.001)
	assert_almost_eq(data["solidarity"], 0.68, 0.001)
	assert_almost_eq(data["harmony"], 0.41, 0.001)
	assert_almost_eq(data["science_value"], 12.5, 0.001)
	assert_almost_eq(data["magic_value"], 3.2, 0.001)


func test_deserialize_metrics_restores_values() -> void:
	var data: Dictionary = {
		"pollution": 0.5,
		"anxiety": 0.3,
		"solidarity": 0.7,
		"harmony": 0.2,
		"science_value": 8.0,
		"magic_value": 4.0,
	}
	var ok: bool = SaveSerializer.deserialize_metrics(data)
	assert_true(ok)
	assert_almost_eq(MetricSystem.pollution, 0.5, 0.001)
	assert_almost_eq(MetricSystem.anxiety, 0.3, 0.001)
	assert_almost_eq(MetricSystem.solidarity, 0.7, 0.001)
	assert_almost_eq(MetricSystem.harmony, 0.2, 0.001)
	assert_almost_eq(MetricSystem.science_value, 8.0, 0.001)
	assert_almost_eq(MetricSystem.magic_value, 4.0, 0.001)


func test_deserialize_metrics_missing_keys_returns_false() -> void:
	assert_false(SaveSerializer.deserialize_metrics({}))
	assert_false(SaveSerializer.deserialize_metrics({"pollution": 0.5}))


# --- Factions ---


func test_serialize_factions_stores_pending() -> void:
	var quests: Array[QuestData] = quest_mgr.quest_registry.get_all()
	if quests.size() >= 1:
		quest_mgr._pending_proposals[quests[0].quest_id] = quests[0]
	var data: Dictionary = SaveSerializer.serialize_factions(quest_mgr)
	assert_true(data.has("pending_proposals"))
	assert_eq(data["pending_proposals"].size(), quest_mgr._pending_proposals.size())


func test_serialize_factions_stores_active_quests() -> void:
	var quests: Array[QuestData] = quest_mgr.quest_registry.get_all()
	if quests.size() >= 1:
		var active := ActiveQuest.new(quests[0])
		active.remaining_cycles = 2
		quest_mgr._active_quests[quests[0].quest_id] = active
	var data: Dictionary = SaveSerializer.serialize_factions(quest_mgr)
	assert_true(data.has("active_quests"))
	if data["active_quests"].size() > 0:
		assert_true(data["active_quests"][0].has("quest_id"))
		assert_true(data["active_quests"][0].has("remaining_cycles"))


func test_serialize_factions_stores_last_proposed() -> void:
	quest_mgr._last_proposed[&"lens"] = &"quest_lens_research"
	var data: Dictionary = SaveSerializer.serialize_factions(quest_mgr)
	assert_true(data.has("last_proposed"))
	assert_eq(data["last_proposed"]["lens"], "quest_lens_research")


func test_deserialize_factions_restores_pending() -> void:
	var quests: Array[QuestData] = quest_mgr.quest_registry.get_all()
	if quests.is_empty():
		pass_test("No quest templates loaded, skipping")
		return
	var quest_id: String = String(quests[0].quest_id)
	var data: Dictionary = {
		"pending_proposals": [quest_id],
		"active_quests": [],
		"last_proposed": {},
	}
	var ok: bool = SaveSerializer.deserialize_factions(data, quest_mgr)
	assert_true(ok)
	assert_true(quest_mgr._pending_proposals.has(StringName(quest_id)))


func test_deserialize_factions_restores_active_quests() -> void:
	var quests: Array[QuestData] = quest_mgr.quest_registry.get_all()
	if quests.is_empty():
		pass_test("No quest templates loaded, skipping")
		return
	var quest_id: String = String(quests[0].quest_id)
	var data: Dictionary = {
		"pending_proposals": [],
		"active_quests": [{"quest_id": quest_id, "remaining_cycles": 3}],
		"last_proposed": {},
	}
	SaveSerializer.deserialize_factions(data, quest_mgr)
	assert_true(quest_mgr._active_quests.has(StringName(quest_id)))
	var active: ActiveQuest = quest_mgr._active_quests[StringName(quest_id)]
	assert_eq(active.remaining_cycles, 3)


func test_deserialize_factions_restores_last_proposed() -> void:
	var data: Dictionary = {
		"pending_proposals": [],
		"active_quests": [],
		"last_proposed": {"lens": "quest_lens_research", "coin": "quest_coin_market"},
	}
	SaveSerializer.deserialize_factions(data, quest_mgr)
	assert_eq(String(quest_mgr._last_proposed.get(&"lens", &"")), "quest_lens_research")
	assert_eq(String(quest_mgr._last_proposed.get(&"coin", &"")), "quest_coin_market")


func test_deserialize_factions_missing_keys_returns_false() -> void:
	assert_false(SaveSerializer.deserialize_factions({}, quest_mgr))
	assert_false(SaveSerializer.deserialize_factions({"pending_proposals": []}, quest_mgr))


# --- Full round-trip ---


func test_full_round_trip_all_four() -> void:
	# Set up non-default state across all systems
	GameManager.cycle_number = 5
	GameManager.current_phase = CycleTimer.Phase.INFLUENCE
	GameManager.game_speed = 2
	MetricSystem.pollution = 0.55
	MetricSystem.science_value = 10.0
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.biome = BiomeType.Type.SWAMP
	cell.scar_state = 0.25
	# Serialize all 4
	var meta: Dictionary = SaveSerializer.serialize_meta(GameManager)
	var world: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	var metrics: Dictionary = SaveSerializer.serialize_metrics()
	var factions: Dictionary = SaveSerializer.serialize_factions(quest_mgr)
	# Clear everything
	GameManager.cycle_number = 0
	GameManager.current_phase = CycleTimer.Phase.OBSERVE
	GameManager.game_speed = 1
	GameManager.is_running = false
	MetricSystem.reset_to_defaults()
	var fresh_grid := HexGrid.new()
	wave_mgr.rift_positions.clear()
	# Deserialize all 4
	assert_true(SaveSerializer.deserialize_meta(meta, GameManager))
	assert_true(
		SaveSerializer.deserialize_world(world, fresh_grid, wave_mgr, ruins_mgr, building_mgr)
	)
	assert_true(SaveSerializer.deserialize_metrics(metrics))
	assert_true(SaveSerializer.deserialize_factions(factions, quest_mgr))
	# Verify
	assert_eq(GameManager.cycle_number, 5)
	assert_almost_eq(MetricSystem.pollution, 0.55, 0.001)
	assert_almost_eq(MetricSystem.science_value, 10.0, 0.001)
	var loaded_cell: HexCell = fresh_grid.get_cell(Vector3i(1, -1, 0))
	assert_eq(int(loaded_cell.biome), int(BiomeType.Type.SWAMP))
	assert_eq(wave_mgr.rift_positions.size(), 3)
