extends GutTest
## Tests for WaveIntel intelligence level computation.

var intel: WaveIntel
var ruins_mgr: RuinsManager
var quest_mgr: QuestManager
var grid: HexGrid


func before_each() -> void:
	grid = HexGrid.new()
	grid.initialize_hex_map(3)
	ruins_mgr = RuinsManager.new()
	add_child(ruins_mgr)
	ruins_mgr.hex_grid = grid
	quest_mgr = QuestManager.new()
	add_child(quest_mgr)
	intel = WaveIntel.new(ruins_mgr, quest_mgr)


func after_each() -> void:
	ruins_mgr.queue_free()
	quest_mgr.queue_free()
	_disconnect_all(EventBus.quest_proposed)
	_disconnect_all(EventBus.quest_approved)
	_disconnect_all(EventBus.quest_completed)
	_disconnect_all(EventBus.ruin_discovered)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func _setup_observatory_discovered() -> void:
	# Find a RUINS biome hex and set it up as a discovered Observatory.
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.biome = BiomeType.Type.RUINS
	cell.exploration_state = RuinType.STATE_UNDISCOVERED
	ruins_mgr._ruin_types[cell.coord] = RuinType.Type.OBSERVATORY
	cell.exploration_state = RuinType.STATE_DISCOVERED


# --- Level computation ---


func test_blind_by_default() -> void:
	assert_eq(intel.compute_level(), WaveIntel.Level.BLIND)


func test_partial_when_observatory_discovered() -> void:
	_setup_observatory_discovered()
	assert_eq(intel.compute_level(), WaveIntel.Level.PARTIAL)


func test_good_when_lens_morale_above_75() -> void:
	_setup_observatory_discovered()
	quest_mgr._faction_morale[&"lens"] = 80
	assert_eq(intel.compute_level(), WaveIntel.Level.GOOD)


func test_full_when_scout_quest_active() -> void:
	_setup_observatory_discovered()
	var scout_data := QuestData.new()
	scout_data.quest_id = &"wall_patrol"
	scout_data.faction_id = &"wall"
	scout_data.duration = 1
	var active := ActiveQuest.new(scout_data)
	quest_mgr._active_quests[&"wall_patrol"] = active
	assert_eq(intel.compute_level(), WaveIntel.Level.FULL)


func test_highest_level_wins() -> void:
	# Set up all conditions: observatory + high Lens morale + scout active.
	_setup_observatory_discovered()
	quest_mgr._faction_morale[&"lens"] = 80
	var scout_data := QuestData.new()
	scout_data.quest_id = &"wall_patrol"
	scout_data.faction_id = &"wall"
	scout_data.duration = 1
	quest_mgr._active_quests[&"wall_patrol"] = ActiveQuest.new(scout_data)
	assert_eq(intel.compute_level(), WaveIntel.Level.FULL)


func test_blind_without_managers() -> void:
	var empty_intel := WaveIntel.new(null, null)
	assert_eq(empty_intel.compute_level(), WaveIntel.Level.BLIND)


# --- Report ---


func test_report_blind_has_level_only() -> void:
	var wc := WaveConfig.new()
	var report: Dictionary = intel.get_report(1, wc, RegionType.Type.MID)
	assert_eq(report[&"level"], WaveIntel.Level.BLIND)
	assert_false(report.has(&"enemy_count"))


func test_report_partial_has_enemy_count() -> void:
	_setup_observatory_discovered()
	var wc := WaveConfig.new()
	var report: Dictionary = intel.get_report(1, wc, RegionType.Type.MID)
	assert_eq(report[&"level"], WaveIntel.Level.PARTIAL)
	assert_true(report.has(&"enemy_count"))
	assert_true(report.has(&"power"))


func test_report_good_has_spawn_directions() -> void:
	_setup_observatory_discovered()
	quest_mgr._faction_morale[&"lens"] = 80
	var wc := WaveConfig.new()
	var report: Dictionary = intel.get_report(1, wc, RegionType.Type.MID)
	assert_eq(report[&"level"], WaveIntel.Level.GOOD)
	assert_true(report.has(&"spawn_directions"))
	assert_eq(report[&"spawn_directions"], 2)
