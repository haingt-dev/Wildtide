extends GutTest
## Tests for SaveSerializer — new systems (economy, stability, edicts, scenario, hex fields).

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
	wave_mgr.rift_positions = [Vector3i(1, -1, 0)]
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


# --- Meta: scenario_id ---


func test_serialize_meta_has_scenario_id() -> void:
	var data: Dictionary = SaveSerializer.serialize_meta(GameManager)
	assert_true(data.has("scenario_id"))
	assert_eq(data["scenario_id"], "the_wildtide")


# --- World: new HexCell fields ---


func test_serialize_world_cell_has_new_fields() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.fog_state = FogState.REVEALED
	cell.region = RegionType.Type.LATE
	cell.rift_density = 0.75
	cell.pollution_level = 0.4
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	for cd: Dictionary in data["cells"]:
		if cd["coord"] == [1, -1, 0]:
			assert_eq(cd["fog_state"], FogState.REVEALED)
			assert_eq(cd["region"], RegionType.Type.LATE)
			assert_almost_eq(cd["rift_density"] as float, 0.75, 0.001)
			assert_almost_eq(cd["pollution_level"] as float, 0.4, 0.001)
			return
	fail_test("Cell [1,-1,0] not found")


func test_deserialize_world_restores_new_fields() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.fog_state = FogState.INACTIVE
	cell.region = RegionType.Type.RIFT_CORE
	cell.rift_density = 0.9
	cell.pollution_level = 0.6
	var data: Dictionary = SaveSerializer.serialize_world(grid, wave_mgr, ruins_mgr, building_mgr)
	var fresh_grid := HexGrid.new()
	SaveSerializer.deserialize_world(data, fresh_grid, wave_mgr, ruins_mgr, building_mgr)
	var loaded: HexCell = fresh_grid.get_cell(Vector3i(1, -1, 0))
	assert_eq(loaded.fog_state, FogState.INACTIVE)
	assert_eq(loaded.region, RegionType.Type.RIFT_CORE)
	assert_almost_eq(loaded.rift_density, 0.9, 0.001)
	assert_almost_eq(loaded.pollution_level, 0.6, 0.001)


func test_deserialize_world_backward_compat_missing_new_fields() -> void:
	var data: Dictionary = {
		"map_radius": 0,
		"cells": [{"coord": [0, 0, 0], "biome": 0}],
		"rift_positions": [],
		"ruin_types": {},
		"active_explorations": [],
		"constructions": [],
	}
	var fresh_grid := HexGrid.new()
	var ok: bool = SaveSerializer.deserialize_world(
		data, fresh_grid, wave_mgr, ruins_mgr, building_mgr
	)
	assert_true(ok)
	var cell: HexCell = fresh_grid.get_cell(Vector3i(0, 0, 0))
	assert_eq(cell.fog_state, FogState.ACTIVE, "Should default to ACTIVE")
	assert_eq(cell.region, RegionType.Type.STARTING, "Should default to STARTING")


# --- Economy ---


func test_serialize_economy() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	econ.spend(10, 5)
	var data: Dictionary = SaveSerializer.serialize_economy(econ)
	assert_eq(data["gold"], 90)
	assert_eq(data["mana"], 45)
	assert_eq(data["gold_capacity"], 100)
	assert_eq(data["mana_capacity"], 100)
	econ.queue_free()


func test_deserialize_economy() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	var data: Dictionary = {
		"gold": 75,
		"mana": 30,
		"gold_capacity": 200,
		"mana_capacity": 150,
	}
	var ok: bool = SaveSerializer.deserialize_economy(data, econ)
	assert_true(ok)
	assert_eq(econ.get_gold(), 75)
	assert_eq(econ.get_mana(), 30)
	assert_eq(econ.get_gold_capacity(), 200)
	assert_eq(econ.get_mana_capacity(), 150)
	econ.queue_free()


func test_deserialize_economy_missing_key_returns_false() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	assert_false(SaveSerializer.deserialize_economy({}, econ))
	econ.queue_free()


# --- Stability ---


func test_serialize_stability() -> void:
	var tracker := StabilityTracker.new()
	tracker.stability_config = StabilityConfig.new()
	add_child(tracker)
	tracker.push_stability(-20)
	var data: Dictionary = SaveSerializer.serialize_stability(tracker)
	assert_eq(data["stability"], 80)
	assert_eq(data["depletion_cycles"], 0)
	tracker.queue_free()


func test_deserialize_stability() -> void:
	var tracker := StabilityTracker.new()
	tracker.stability_config = StabilityConfig.new()
	add_child(tracker)
	var data: Dictionary = {"stability": 65, "depletion_cycles": 2}
	var ok: bool = SaveSerializer.deserialize_stability(data, tracker)
	assert_true(ok)
	assert_eq(tracker.get_stability(), 65)
	assert_eq(tracker.get_depletion_cycles(), 2)
	tracker.queue_free()


func test_deserialize_stability_missing_key_returns_false() -> void:
	var tracker := StabilityTracker.new()
	tracker.stability_config = StabilityConfig.new()
	add_child(tracker)
	assert_false(SaveSerializer.deserialize_stability({}, tracker))
	tracker.queue_free()


# --- Edicts ---


func test_serialize_edicts() -> void:
	var emgr := EdictManager.new()
	add_child(emgr)
	var edata := EdictData.new()
	edata.edict_id = &"test_edict"
	edata.duration = 3
	emgr.edict_registry._data[&"test_edict"] = edata
	emgr.enact_edict(&"test_edict")
	var data: Dictionary = SaveSerializer.serialize_edicts(emgr)
	assert_eq(data["active_edicts"].size(), 1)
	assert_eq(data["active_edicts"][0]["edict_id"], "test_edict")
	assert_eq(data["active_edicts"][0]["remaining"], 3)
	emgr.queue_free()


func test_deserialize_edicts() -> void:
	var emgr := EdictManager.new()
	add_child(emgr)
	var edata := EdictData.new()
	edata.edict_id = &"restored"
	edata.duration = -1
	emgr.edict_registry._data[&"restored"] = edata
	var data: Dictionary = {
		"active_edicts": [{"edict_id": "restored", "remaining": -1}],
	}
	var ok: bool = SaveSerializer.deserialize_edicts(data, emgr)
	assert_true(ok)
	assert_eq(emgr.get_active_edict_ids().size(), 1)
	assert_eq(emgr.get_remaining(&"restored"), -1)
	emgr.queue_free()


func test_deserialize_edicts_empty() -> void:
	var emgr := EdictManager.new()
	add_child(emgr)
	var ok: bool = SaveSerializer.deserialize_edicts({}, emgr)
	assert_true(ok)
	assert_eq(emgr.get_active_edict_ids().size(), 0)
	emgr.queue_free()


# --- Movement ---


func test_serialize_movement() -> void:
	var mgr := MovementManager.new()
	add_child(mgr)
	mgr.city_center = Vector3i(3, -2, -1)
	mgr.is_in_transit = true
	mgr.transit_cycles_remaining = 1
	var data: Dictionary = SaveSerializer.serialize_movement(mgr)
	assert_eq(data["city_center"], [3, -2, -1])
	assert_true(data["is_in_transit"])
	assert_eq(data["transit_cycles_remaining"], 1)
	mgr.queue_free()


func test_deserialize_movement() -> void:
	var mgr := MovementManager.new()
	add_child(mgr)
	var data: Dictionary = {
		"city_center": [5, -3, -2],
		"is_in_transit": true,
		"transit_cycles_remaining": 1,
	}
	var ok: bool = SaveSerializer.deserialize_movement(data, mgr)
	assert_true(ok)
	assert_eq(mgr.city_center, Vector3i(5, -3, -2))
	assert_true(mgr.is_in_transit)
	assert_eq(mgr.transit_cycles_remaining, 1)
	mgr.queue_free()


func test_deserialize_movement_defaults() -> void:
	var mgr := MovementManager.new()
	add_child(mgr)
	var ok: bool = SaveSerializer.deserialize_movement({}, mgr)
	assert_true(ok)
	assert_eq(mgr.city_center, Vector3i.ZERO)
	assert_false(mgr.is_in_transit)
	mgr.queue_free()


func test_deserialize_movement_restores_economy_transit() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	var mgr := MovementManager.new()
	add_child(mgr)
	mgr.economy_manager = econ
	var data: Dictionary = {
		"city_center": [1, -1, 0],
		"is_in_transit": true,
		"transit_cycles_remaining": 1,
	}
	SaveSerializer.deserialize_movement(data, mgr)
	assert_true(econ._in_transit)
	mgr.queue_free()
	econ.queue_free()
