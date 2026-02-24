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
	_disconnect_all(EventBus.fragments_changed)
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


# --- has_ruin_at_state ---


func test_has_ruin_at_state_true() -> void:
	manager.initialize_ruins_seeded(42)
	manager.discover_ruin(_ruins_coords[0])
	var ruin_type: Variant = manager.get_ruin_type(_ruins_coords[0])
	assert_true(manager.has_ruin_at_state(ruin_type as RuinType.Type, RuinType.STATE_DISCOVERED))


func test_has_ruin_at_state_false() -> void:
	manager.initialize_ruins_seeded(42)
	# No ruins discovered yet — all at UNDISCOVERED.
	var ruin_type: Variant = manager.get_ruin_type(_ruins_coords[0])
	assert_false(manager.has_ruin_at_state(ruin_type as RuinType.Type, RuinType.STATE_DISCOVERED))


# --- Fragment accumulation ---


func test_initial_fragment_counters_are_zero() -> void:
	manager.initialize_ruins_seeded(42)
	assert_eq(manager.get_tech_fragments(), 0)
	assert_eq(manager.get_rune_shards(), 0)


func test_completed_exploration_yields_fragments() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	manager.start_exploration(coord)
	var data: RuinData = manager.get_ruin_data(coord)
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var total: int = manager.get_tech_fragments() + manager.get_rune_shards()
	assert_gt(total, 0, "Should yield at least some fragments")


func test_fragment_counters_accumulate() -> void:
	manager.initialize_ruins_seeded(42)
	# Complete first ruin.
	var c0: Vector3i = _ruins_coords[0]
	manager.discover_ruin(c0)
	manager.start_exploration(c0)
	var d0: RuinData = manager.get_ruin_data(c0)
	for i: int in range(d0.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var tech_after_first: int = manager.get_tech_fragments()
	var rune_after_first: int = manager.get_rune_shards()
	# Complete second ruin.
	var c1: Vector3i = _ruins_coords[1]
	manager.discover_ruin(c1)
	manager.start_exploration(c1)
	var d1: RuinData = manager.get_ruin_data(c1)
	for i: int in range(d1.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var tech_total: int = manager.get_tech_fragments()
	var rune_total: int = manager.get_rune_shards()
	assert_true(
		tech_total >= tech_after_first and rune_total >= rune_after_first,
		"Counters should accumulate"
	)


func test_damaged_exploration_reduces_yield() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	manager.start_exploration(coord)
	var data: RuinData = manager.get_ruin_data(coord)
	# Damage the exploration mid-way.
	EventBus.hex_scarred.emit(coord, 0.2)
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var total: int = manager.get_tech_fragments() + manager.get_rune_shards()
	var undamaged_total: int = data.tech_fragments + data.rune_shards
	# Damaged yield should be <= undamaged full yield.
	assert_true(total <= undamaged_total, "Damaged yield should be reduced")


func test_fragments_changed_signal_emitted() -> void:
	manager.initialize_ruins_seeded(42)
	var received := []
	EventBus.fragments_changed.connect(func(t: int, r: int) -> void: received.append([t, r]))
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	manager.start_exploration(coord)
	var data: RuinData = manager.get_ruin_data(coord)
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(received.size(), 1, "Should emit fragments_changed on completion")


func test_initialize_resets_fragment_counters() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	manager.start_exploration(coord)
	var data: RuinData = manager.get_ruin_data(coord)
	for i: int in range(data.exploration_duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_gt(manager.get_tech_fragments() + manager.get_rune_shards(), 0)
	# Re-initialize should reset counters.
	manager.initialize_ruins_seeded(42)
	assert_eq(manager.get_tech_fragments(), 0)
	assert_eq(manager.get_rune_shards(), 0)


# --- Discovery bonus ---


func test_discovery_bonus_reduces_exploration_cycles() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	# Set up an edict manager with discovery bonus.
	var em := EdictManager.new()
	add_child(em)
	var edata := EdictData.new()
	edata.edict_id = &"research_grant"
	edata.discovery_bonus = 0.5
	edata.duration = -1
	em.edict_registry._data[&"research_grant"] = edata
	em.enact_edict(&"research_grant")
	manager.edict_manager = em
	manager.start_exploration(coord)
	var explorations := manager.get_active_explorations()
	var data: RuinData = manager.get_ruin_data(coord)
	assert_lt(
		explorations[0].remaining_cycles,
		data.exploration_duration,
		"Discovery bonus should reduce cycles"
	)
	em.queue_free()


func test_discovery_bonus_minimum_one_cycle() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	var em := EdictManager.new()
	add_child(em)
	var edata := EdictData.new()
	edata.edict_id = &"mega_research"
	edata.discovery_bonus = 0.99
	edata.duration = -1
	em.edict_registry._data[&"mega_research"] = edata
	em.enact_edict(&"mega_research")
	manager.edict_manager = em
	manager.start_exploration(coord)
	var explorations := manager.get_active_explorations()
	assert_gte(explorations[0].remaining_cycles, 1, "Should never go below 1 cycle")
	em.queue_free()


func test_no_discovery_bonus_without_edict_manager() -> void:
	manager.initialize_ruins_seeded(42)
	var coord: Vector3i = _ruins_coords[0]
	manager.discover_ruin(coord)
	manager.edict_manager = null
	manager.start_exploration(coord)
	var explorations := manager.get_active_explorations()
	var data: RuinData = manager.get_ruin_data(coord)
	assert_eq(explorations[0].remaining_cycles, data.exploration_duration)
