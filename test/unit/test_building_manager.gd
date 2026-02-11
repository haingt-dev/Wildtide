extends GutTest
## Tests for BuildingManager — building lifecycle management.
## Uses global EventBus and MetricSystem autoloads.

var manager: BuildingManager
var grid: HexGrid


func before_each() -> void:
	manager = BuildingManager.new()
	add_child(manager)
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	manager.hex_grid = grid
	MetricSystem.reset_to_defaults()


func after_each() -> void:
	manager.queue_free()
	_disconnect_all(EventBus.building_placed)
	_disconnect_all(EventBus.building_removed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Placement ---


func test_place_building_on_empty_hex() -> void:
	var coord := Vector3i(1, -1, 0)
	var success: bool = manager.place_building(coord, &"homestead")
	assert_true(success)
	var cell: HexCell = grid.get_cell(coord)
	assert_eq(cell.building_id, &"homestead")


func test_place_emits_building_placed_signal() -> void:
	var received := []
	EventBus.building_placed.connect(
		func(c: Vector3i, b: StringName) -> void: received.append([c, b])
	)
	manager.place_building(Vector3i(1, -1, 0), &"homestead")
	assert_eq(received.size(), 1)


func test_place_on_occupied_hex_returns_false() -> void:
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"homestead")
	assert_false(manager.place_building(coord, &"reactor"))


func test_place_on_fully_scarred_hex_returns_false() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.scar_state = 1.0
	assert_false(manager.place_building(coord, &"homestead"))


func test_place_unknown_building_id_returns_false() -> void:
	assert_false(manager.place_building(Vector3i(1, -1, 0), &"nonexistent"))


func test_place_on_invalid_coord_returns_false() -> void:
	assert_false(manager.place_building(Vector3i(99, -99, 0), &"homestead"))


func test_place_without_grid_returns_false() -> void:
	manager.hex_grid = null
	assert_false(manager.place_building(Vector3i(1, -1, 0), &"homestead"))


# --- Removal ---


func test_remove_building_clears_cell() -> void:
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"homestead")
	var success: bool = manager.remove_building(coord)
	assert_true(success)
	var cell: HexCell = grid.get_cell(coord)
	assert_eq(cell.building_id, &"")


func test_remove_emits_building_removed_signal() -> void:
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"homestead")
	var received := []
	EventBus.building_removed.connect(
		func(c: Vector3i, b: StringName) -> void: received.append([c, b])
	)
	manager.remove_building(coord)
	assert_eq(received.size(), 1)


func test_remove_from_empty_returns_false() -> void:
	assert_false(manager.remove_building(Vector3i(1, -1, 0)))


func test_remove_nonexistent_coord_returns_false() -> void:
	assert_false(manager.remove_building(Vector3i(99, -99, 0)))


# --- Construction tick (EVOLVE) ---


func test_evolve_ticks_construction() -> void:
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"homestead")
	var construction: ActiveConstruction = manager.get_construction(coord)
	assert_almost_eq(construction.progress, 0.0, 0.001)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_gt(construction.progress, 0.0, "Progress should advance")


func test_construction_completes_after_duration() -> void:
	var coord := Vector3i(1, -1, 0)
	# Homestead has duration=1, Plains biome speed=1.0 + affinity=0.2 = 1.2 per tick
	manager.place_building(coord, &"homestead")
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var construction: ActiveConstruction = manager.get_construction(coord)
	assert_true(construction.is_complete, "Should complete in 1 EVOLVE tick")


func test_biome_speed_affects_construction() -> void:
	# Place on Swamp biome (0.5 speed) — reactor has Rocky affinity, no bonus
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.biome = BiomeType.Type.SWAMP
	manager.place_building(coord, &"reactor")
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var construction: ActiveConstruction = manager.get_construction(coord)
	assert_almost_eq(construction.progress, 0.5, 0.001)


func test_scar_penalty_slows_construction() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.scar_state = 0.5  # Partially scarred
	# Plains speed=1.0 + homestead affinity=0.2 = 1.2, then *0.8 scar = 0.96
	manager.place_building(coord, &"homestead")
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var construction: ActiveConstruction = manager.get_construction(coord)
	assert_almost_eq(construction.progress, 0.96, 0.01)


func test_biome_affinity_bonus() -> void:
	# Reactor on Rocky biome: speed=0.8 + affinity=0.2 = 1.0
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.biome = BiomeType.Type.ROCKY
	manager.place_building(coord, &"reactor")
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var construction: ActiveConstruction = manager.get_construction(coord)
	assert_almost_eq(construction.progress, 1.0, 0.001)


# --- Completed effects ---


func test_completed_building_pushes_metrics() -> void:
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"homestead")
	# Force completion
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	MetricSystem.reset_to_defaults()
	# Now trigger another EVOLVE to apply effects
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_gt(MetricSystem.get_metric(&"solidarity"), 0.0, "Should push solidarity")


func test_completed_building_pushes_alignment() -> void:
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"reactor")
	# Force completion by ticking enough
	for i: int in range(5):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	MetricSystem.reset_to_defaults()
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_gt(MetricSystem.science_value, 0.0, "Should push science alignment")


func test_under_construction_no_effects() -> void:
	# Reactor takes 3 cycles on Plains (speed=1.0, no affinity bonus)
	var coord := Vector3i(1, -1, 0)
	manager.place_building(coord, &"reactor")
	MetricSystem.reset_to_defaults()
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	# Reactor not yet complete (1/3 progress), effects should not apply
	var construction: ActiveConstruction = manager.get_construction(coord)
	assert_false(construction.is_complete)
	assert_almost_eq(MetricSystem.get_metric(&"pollution"), 0.0, 0.001)


# --- Query ---


func test_get_under_construction_count() -> void:
	manager.place_building(Vector3i(1, -1, 0), &"reactor")
	manager.place_building(Vector3i(-1, 1, 0), &"homestead")
	# Homestead completes in 1 tick, reactor does not
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_under_construction().size(), 1)
	assert_eq(manager.get_completed_buildings().size(), 1)


func test_get_count_by_type() -> void:
	manager.place_building(Vector3i(1, -1, 0), &"homestead")
	manager.place_building(Vector3i(-1, 1, 0), &"reactor")
	assert_eq(manager.get_count_by_type(BuildingType.Type.RESIDENTIAL), 1)
	assert_eq(manager.get_count_by_type(BuildingType.Type.SCIENCE), 1)
	assert_eq(manager.get_count_by_type(BuildingType.Type.MAGIC), 0)


# --- Edge cases ---


func test_no_action_on_non_evolve_phase() -> void:
	manager.place_building(Vector3i(1, -1, 0), &"reactor")
	manager._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	var construction: ActiveConstruction = manager.get_construction(Vector3i(1, -1, 0))
	assert_almost_eq(construction.progress, 0.0, 0.001)
