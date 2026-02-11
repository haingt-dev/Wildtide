extends GutTest
## Tests for RuinsManager — ruin lifecycle management.
## Uses global EventBus and MetricSystem autoloads.

var manager: RuinsManager
var grid: HexGrid

## Known coords that will be set to RUINS biome.
var _ruins_coords: Array[Vector3i] = [
	Vector3i(1, -1, 0),
	Vector3i(-2, 2, 0),
	Vector3i(0, -3, 3),
]


func before_each() -> void:
	manager = RuinsManager.new()
	add_child(manager)
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	_set_ruins_hexes()
	manager.hex_grid = grid
	MetricSystem.reset_to_defaults()


func after_each() -> void:
	manager.queue_free()
	_disconnect_all(EventBus.ruin_discovered)
	_disconnect_all(EventBus.ruin_exploration_started)
	_disconnect_all(EventBus.ruin_depleted)
	_disconnect_all(EventBus.hex_scarred)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func _set_ruins_hexes() -> void:
	for coord: Vector3i in _ruins_coords:
		var cell: HexCell = grid.get_cell(coord)
		if cell:
			cell.biome = BiomeType.Type.RUINS


# --- Initialization ---


func test_initialize_assigns_types_to_all_ruins() -> void:
	manager.initialize_ruins_seeded(42)
	assert_eq(manager.get_ruin_count(), 3)


func test_initialize_sets_undiscovered_state() -> void:
	manager.initialize_ruins_seeded(42)
	for coord: Vector3i in _ruins_coords:
		var cell: HexCell = grid.get_cell(coord)
		assert_eq(cell.exploration_state, RuinType.STATE_UNDISCOVERED)


func test_initialize_seeded_is_deterministic() -> void:
	manager.initialize_ruins_seeded(99)
	var types_a := []
	for coord: Vector3i in _ruins_coords:
		types_a.append(manager.get_ruin_type(coord))
	# Reset and re-initialize with same seed.
	for coord: Vector3i in _ruins_coords:
		var cell: HexCell = grid.get_cell(coord)
		cell.exploration_state = RuinType.STATE_NONE
	manager.initialize_ruins_seeded(99)
	var types_b := []
	for coord: Vector3i in _ruins_coords:
		types_b.append(manager.get_ruin_type(coord))
	assert_eq(types_a, types_b, "Same seed should produce same types")


func test_get_ruin_type_non_ruin_returns_null() -> void:
	manager.initialize_ruins_seeded(42)
	assert_null(manager.get_ruin_type(Vector3i.ZERO))


# --- Discovery ---


func test_discover_ruin_changes_state() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	var cell: HexCell = grid.get_cell(coord)
	assert_eq(cell.exploration_state, RuinType.STATE_DISCOVERED)


func test_discover_ruin_emits_signal() -> void:
	manager.initialize_ruins_seeded(42)
	var received := []
	EventBus.ruin_discovered.connect(
		func(c: Vector3i, t: StringName) -> void: received.append([c, t])
	)
	manager.discover_ruin(_ruins_coords[0])
	assert_eq(received.size(), 1)


func test_discover_ruin_returns_true() -> void:
	manager.initialize_ruins_seeded(42)
	assert_true(manager.discover_ruin(_ruins_coords[0]))


func test_discover_already_discovered_returns_false() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	assert_false(manager.discover_ruin(_ruins_coords[0]))


func test_discover_non_ruin_returns_false() -> void:
	manager.initialize_ruins_seeded(42)
	assert_false(manager.discover_ruin(Vector3i.ZERO))


func test_discover_pushes_metrics() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	assert_gt(MetricSystem.get_metric(&"anxiety"), 0.0, "Should push anxiety")
	assert_gt(MetricSystem.get_metric(&"solidarity"), 0.0, "Should push solidarity")


# --- Exploration ---


func test_start_exploration_changes_state() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	manager.start_exploration(_ruins_coords[0])
	var cell: HexCell = grid.get_cell(_ruins_coords[0])
	assert_eq(cell.exploration_state, RuinType.STATE_EXPLORING)


func test_start_exploration_emits_signal() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	var received := []
	EventBus.ruin_exploration_started.connect(func(c: Vector3i) -> void: received.append(c))
	manager.start_exploration(_ruins_coords[0])
	assert_eq(received.size(), 1)


func test_start_exploration_returns_true() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	assert_true(manager.start_exploration(_ruins_coords[0]))


func test_start_undiscovered_returns_false() -> void:
	manager.initialize_ruins_seeded(42)
	assert_false(manager.start_exploration(_ruins_coords[0]))


func test_start_already_exploring_returns_false() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	manager.start_exploration(_ruins_coords[0])
	assert_false(manager.start_exploration(_ruins_coords[0]))


# --- EVOLVE tick ---


func test_evolve_ticks_exploration() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	manager.start_exploration(_ruins_coords[0])
	var data: RuinData = manager.get_ruin_data(_ruins_coords[0])
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_active_explorations().size(), 0, "Should complete after duration")


func test_completed_exploration_sets_depleted() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	manager.start_exploration(_ruins_coords[0])
	var data: RuinData = manager.get_ruin_data(_ruins_coords[0])
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var cell: HexCell = grid.get_cell(_ruins_coords[0])
	assert_eq(cell.exploration_state, RuinType.STATE_DEPLETED)


func test_completed_emits_ruin_depleted() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	manager.start_exploration(_ruins_coords[0])
	var received := []
	EventBus.ruin_depleted.connect(func(c: Vector3i) -> void: received.append(c))
	var data: RuinData = manager.get_ruin_data(_ruins_coords[0])
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(received.size(), 1, "Should emit ruin_depleted")


# --- Wave damage ---


func test_wave_damage_marks_exploration_damaged() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	manager.start_exploration(coord)
	EventBus.hex_scarred.emit(coord, 0.1)
	var explorations: Array[ActiveExploration] = manager.get_active_explorations()
	assert_eq(explorations.size(), 1)
	assert_true(explorations[0].is_damaged, "Should be marked damaged")


func test_wave_damage_on_non_exploring_no_effect() -> void:
	manager.initialize_ruins_seeded(42)
	# Emit scarred on a ruin that is undiscovered — should not crash.
	EventBus.hex_scarred.emit(_ruins_coords[0], 0.1)
	var cell: HexCell = grid.get_cell(_ruins_coords[0])
	assert_eq(cell.exploration_state, RuinType.STATE_UNDISCOVERED)


# --- Edge cases ---


func test_no_crash_without_grid() -> void:
	manager.hex_grid = null
	manager.initialize_ruins()
	assert_eq(manager.get_ruin_count(), 0)


func test_get_count_by_state() -> void:
	manager.initialize_ruins_seeded(42)
	assert_eq(manager.get_count_by_state(RuinType.STATE_UNDISCOVERED), 3)
	manager.discover_ruin(_ruins_coords[0])
	assert_eq(manager.get_count_by_state(RuinType.STATE_UNDISCOVERED), 2)
	assert_eq(manager.get_count_by_state(RuinType.STATE_DISCOVERED), 1)
