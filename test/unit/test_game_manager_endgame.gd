extends GutTest
## Tests for GameManager endgame win conditions — fragments, rift core, artifact.

var gm: Node
var _nodes_to_free: Array[Node] = []


func before_each() -> void:
	gm = load("res://scripts/core/game_manager.gd").new()
	add_child(gm)
	_nodes_to_free.clear()


func after_each() -> void:
	for n: Node in _nodes_to_free:
		n.free()
	_nodes_to_free.clear()
	gm.queue_free()
	MetricSystem.reset_to_defaults()
	_disconnect_all(EventBus.game_won)
	_disconnect_all(EventBus.artifact_progress)
	_disconnect_all(EventBus.artifact_completed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func _make_scenario(
	wc_type: int, alignment: float, era: int, frags: int, rift: bool, artifact_cycles: int
) -> ScenarioData:
	var sd := ScenarioData.new()
	var wc := WinConditionData.new()
	wc.type = wc_type as WinConditionData.WinConditionType
	wc.required_alignment = alignment
	wc.required_era = era
	wc.required_cycles = 0
	wc.required_fragments = frags
	wc.requires_rift_core = rift
	wc.artifact_construction_cycles = artifact_cycles
	sd.win_conditions = [wc]
	return sd


func _make_ruins_manager(tech: int, rune: int) -> RuinsManager:
	var rm := RuinsManager.new()
	rm._tech_fragments = tech
	rm._rune_shards = rune
	_nodes_to_free.append(rm)
	return rm


# --- Fragment requirements ---


func test_science_win_requires_fragments() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.SCIENCE_WIN, 0.8, 3, 5, false, 0
	)
	gm.ruins_manager = _make_ruins_manager(3, 0)
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 0, "Not enough tech fragments")


func test_science_win_with_enough_fragments() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.SCIENCE_WIN, 0.8, 3, 5, false, 0
	)
	gm.ruins_manager = _make_ruins_manager(5, 0)
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 1)


func test_magic_win_requires_rune_shards() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(-1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.MAGIC_WIN, 0.8, 3, 4, false, 0
	)
	gm.ruins_manager = _make_ruins_manager(0, 2)
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 0, "Not enough rune shards")


# --- Rift core requirement ---


func test_win_requires_rift_core() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.SCIENCE_WIN, 0.8, 3, 0, true, 0
	)
	var grid := HexGrid.new()
	grid.initialize_hex_map(3)
	gm.hex_grid = grid
	var mm := MovementManager.new()
	mm.city_center = Vector3i.ZERO
	gm.movement_manager = mm
	_nodes_to_free.append(mm)
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 0, "Should not win without rift core")


func test_win_with_rift_core() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.SCIENCE_WIN, 0.8, 3, 0, true, 0
	)
	var grid := HexGrid.new()
	grid.initialize_hex_map(3)
	gm.hex_grid = grid
	var mm := MovementManager.new()
	mm.city_center = Vector3i.ZERO
	gm.movement_manager = mm
	_nodes_to_free.append(mm)
	var cell: HexCell = grid.get_cell(Vector3i.ZERO)
	cell.region = RegionType.Type.RIFT_CORE
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 1)


# --- Artifact requirement ---


func test_win_requires_artifact_complete() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.SCIENCE_WIN, 0.8, 3, 0, false, 3
	)
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 0, "No artifact = no win when cycles > 0")


func test_win_with_artifact_complete() -> void:
	gm.cycle_number = 11
	MetricSystem.push_alignment(1.0)
	gm.scenario_data = _make_scenario(
		WinConditionData.WinConditionType.SCIENCE_WIN, 0.8, 3, 0, false, 2
	)
	var ac := ArtifactController.new()
	ac.start_construction(Vector3i.ZERO, 2)
	ac.tick()
	ac.tick()
	assert_true(ac.is_complete())
	gm.artifact_controller = ac
	var received: Array = []
	EventBus.game_won.connect(func(wt: int) -> void: received.append(wt))
	gm._check_win_conditions()
	assert_eq(received.size(), 1)


# --- Artifact lifecycle in game loop ---


func test_artifact_ticks_during_evolve_transition() -> void:
	gm.start_game()
	var ac := ArtifactController.new()
	ac.start_construction(Vector3i.ZERO, 2)
	gm.artifact_controller = ac
	var progress_received: Array = []
	EventBus.artifact_progress.connect(
		func(p: int, r: int) -> void: progress_received.append([p, r])
	)
	gm.advance_phase()  # INFLUENCE
	gm.advance_phase()  # WAVE
	gm.advance_phase()  # EVOLVE
	gm.advance_phase()  # Back to OBSERVE (triggers _transition from EVOLVE)
	assert_eq(ac.progress_cycles, 1, "Artifact should tick once per EVOLVE")


func test_artifact_completion_emits_signal() -> void:
	gm.start_game()
	var ac := ArtifactController.new()
	ac.start_construction(Vector3i.ZERO, 1)
	gm.artifact_controller = ac
	var completed: Array = []
	EventBus.artifact_completed.connect(func(wt: int) -> void: completed.append(wt))
	gm.advance_phase()  # INFLUENCE
	gm.advance_phase()  # WAVE
	gm.advance_phase()  # EVOLVE
	gm.advance_phase()  # Triggers EVOLVE transition -> tick completes artifact
	assert_eq(completed.size(), 1, "Should emit artifact_completed")
