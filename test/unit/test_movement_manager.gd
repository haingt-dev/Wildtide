extends GutTest
## Tests for MovementManager — city footprint and transit state.

var manager: MovementManager


func before_each() -> void:
	manager = MovementManager.new()
	add_child(manager)


func after_each() -> void:
	manager.queue_free()
	_disconnect_all(EventBus.movement_proposed)
	_disconnect_all(EventBus.city_moved)
	_disconnect_all(EventBus.transit_started)
	_disconnect_all(EventBus.transit_ended)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Initial state ---


func test_initial_center_is_zero() -> void:
	assert_eq(manager.city_center, Vector3i.ZERO)


func test_initial_not_in_transit() -> void:
	assert_false(manager.is_in_transit)
	assert_eq(manager.transit_cycles_remaining, 0)


# --- Propose movement ---


func test_propose_movement_emits_signal() -> void:
	var received := []
	EventBus.movement_proposed.connect(func(d: Vector3i) -> void: received.append(d))
	var ok: bool = manager.propose_movement(Vector3i(1, -1, 0))
	assert_true(ok)
	assert_eq(received.size(), 1)
	assert_eq(received[0], Vector3i(1, -1, 0))


func test_propose_zero_direction_returns_false() -> void:
	assert_false(manager.propose_movement(Vector3i.ZERO))


func test_propose_during_transit_returns_false() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_false(manager.propose_movement(Vector3i(0, 1, -1)))


# --- Execute movement ---


func test_execute_shifts_center() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_eq(manager.city_center, Vector3i(1, -1, 0))


func test_execute_enters_transit() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_true(manager.is_in_transit)
	assert_eq(manager.transit_cycles_remaining, 1)


func test_execute_emits_city_moved_and_transit_started() -> void:
	var moved := []
	var started := []
	EventBus.city_moved.connect(
		func(old: Vector3i, new_c: Vector3i) -> void: moved.append([old, new_c])
	)
	EventBus.transit_started.connect(func() -> void: started.append(true))
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_eq(moved.size(), 1)
	assert_eq(moved[0][0], Vector3i.ZERO)
	assert_eq(moved[0][1], Vector3i(1, -1, 0))
	assert_eq(started.size(), 1)


func test_execute_zero_direction_returns_false() -> void:
	assert_false(manager.execute_movement(Vector3i.ZERO))


func test_execute_during_transit_returns_false() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_false(manager.execute_movement(Vector3i(0, 1, -1)))


func test_execute_sets_economy_transit() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	manager.economy_manager = econ
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_true(econ._in_transit)
	econ.queue_free()


# --- End transit ---


func test_end_transit_clears_state() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_false(manager.is_in_transit)
	assert_eq(manager.transit_cycles_remaining, 0)


func test_end_transit_emits_signal() -> void:
	var ended := []
	EventBus.transit_ended.connect(func() -> void: ended.append(true))
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_eq(ended.size(), 1)


func test_end_transit_clears_economy_transit() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	manager.economy_manager = econ
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_false(econ._in_transit)
	econ.queue_free()


func test_end_transit_noop_when_not_transiting() -> void:
	var ended := []
	EventBus.transit_ended.connect(func() -> void: ended.append(true))
	manager.end_transit()
	assert_eq(ended.size(), 0)


# --- Phase hook: auto-end transit ---


func test_evolve_ticks_transit_counter() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_eq(manager.transit_cycles_remaining, 1)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_false(manager.is_in_transit, "Transit should end after 1 EVOLVE tick")
	assert_eq(manager.transit_cycles_remaining, 0)


func test_non_evolve_phase_does_not_tick() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	assert_true(manager.is_in_transit)
	assert_eq(manager.transit_cycles_remaining, 1)


func test_evolve_noop_when_not_transiting() -> void:
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_false(manager.is_in_transit)


# --- Cumulative movement ---


func test_multiple_movements_accumulate_center() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	manager.execute_movement(Vector3i(0, 1, -1))
	assert_eq(manager.city_center, Vector3i(1, 0, -1))


# --- Settlement bonus ---


func test_settlement_inactive_after_creation() -> void:
	assert_eq(manager.get_settlement_cycles_remaining(), 0)
	assert_eq(manager.get_settlement_build_multiplier(), 1.0)
	assert_eq(manager.get_settlement_cost_discount(), 0.0)


func test_settlement_activates_after_transit_ends() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_eq(manager.get_settlement_cycles_remaining(), 2)


func test_settlement_build_multiplier_cycle_1() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_eq(manager.get_settlement_build_multiplier(), 2.0)


func test_settlement_build_multiplier_cycle_2() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_settlement_build_multiplier(), 1.5)


func test_settlement_build_multiplier_normal() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_settlement_build_multiplier(), 1.0)


func test_settlement_cost_discount_cycle_1() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_almost_eq(manager.get_settlement_cost_discount(), 0.3, 0.001)


func test_settlement_cost_discount_cycle_2() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_almost_eq(manager.get_settlement_cost_discount(), 0.15, 0.001)


func test_settlement_ticks_down_in_evolve() -> void:
	manager.execute_movement(Vector3i(1, -1, 0))
	manager.end_transit()
	assert_eq(manager.get_settlement_cycles_remaining(), 2)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_settlement_cycles_remaining(), 1)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_settlement_cycles_remaining(), 0)


# --- Salvage ---


func _setup_grid_with_buildings() -> void:
	var grid := HexGrid.new()
	grid.initialize_hex_map(3)
	manager.hex_grid = grid
	var bmgr := BuildingManager.new()
	add_child(bmgr)
	bmgr.hex_grid = grid
	manager.building_manager = bmgr
	# Place buildings manually (bypass economy)
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.building_id = &"homestead"
	var cell2: HexCell = grid.get_cell(Vector3i(0, 1, -1))
	cell2.building_id = &"reactor"


func test_salvage_yields_shards_for_buildings() -> void:
	_setup_grid_with_buildings()
	GameManager.cycle_number = 7  # Era 2 (cycle >= 6)
	manager._cycles_in_region = 6  # Full time factor (x1.0)
	manager._execute_salvage()
	# Era 2 = base 2, 2 buildings, no scar, time factor 1.0 => 2*2 = 4
	assert_eq(manager.get_last_salvage_yield(), 4)
	GameManager.cycle_number = 0


func test_salvage_scar_penalty() -> void:
	_setup_grid_with_buildings()
	GameManager.cycle_number = 1  # Era 1
	manager._cycles_in_region = 6
	# Scar one building above threshold
	var cell: HexCell = manager.hex_grid.get_cell(Vector3i(1, -1, 0))
	cell.scar_state = 0.6
	manager._execute_salvage()
	# Building 1: base 1 - 1 scar = 0. Building 2: base 1, no scar = 1. Total = 1
	assert_eq(manager.get_last_salvage_yield(), 1)
	GameManager.cycle_number = 0


func test_salvage_time_factor_short_stay() -> void:
	_setup_grid_with_buildings()
	GameManager.cycle_number = 1
	manager._cycles_in_region = 2  # <3 => x0.3
	manager._execute_salvage()
	# 2 buildings, base 1 each, x0.3 => 2 * 1 * 0.3 = 0.6 => round to 1
	assert_eq(manager.get_last_salvage_yield(), 1)
	GameManager.cycle_number = 0


func test_salvage_time_factor_long_stay() -> void:
	_setup_grid_with_buildings()
	GameManager.cycle_number = 1
	manager._cycles_in_region = 4  # 3-5 => x0.6
	manager._execute_salvage()
	# 2 buildings, base 1 each, x0.6 => 2 * 1 * 0.6 = 1.2 => round to 1
	assert_eq(manager.get_last_salvage_yield(), 1)
	GameManager.cycle_number = 0


func test_cycles_in_region_increments() -> void:
	assert_eq(manager.get_cycles_in_region(), 0)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_cycles_in_region(), 1)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_cycles_in_region(), 2)


func test_cycles_in_region_resets_on_movement() -> void:
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_cycles_in_region(), 2)
	manager.execute_movement(Vector3i(1, -1, 0))
	assert_eq(manager.get_cycles_in_region(), 0)


# --- Ghost footprint ---


func test_footprint_old_hexes_become_inactive() -> void:
	var grid := HexGrid.new()
	grid.initialize_hex_map(3)
	manager.hex_grid = grid
	# All cells start as ACTIVE (default)
	for cell: HexCell in grid.get_all_cells():
		cell.fog_state = FogState.ACTIVE
	manager._update_footprint(Vector3i.ZERO, Vector3i(10, -10, 0))
	# Old center cells should be INACTIVE
	var center_cell: HexCell = grid.get_cell(Vector3i.ZERO)
	assert_eq(center_cell.fog_state, FogState.INACTIVE)


func test_footprint_new_hexes_become_active() -> void:
	var grid := HexGrid.new()
	grid.initialize_hex_map(3)
	manager.hex_grid = grid
	# Mark all as HIDDEN first
	for cell: HexCell in grid.get_all_cells():
		cell.fog_state = FogState.HIDDEN
	manager._update_footprint(Vector3i(10, -10, 0), Vector3i.ZERO)
	# New center cells should be ACTIVE
	var center_cell: HexCell = grid.get_cell(Vector3i.ZERO)
	assert_eq(center_cell.fog_state, FogState.ACTIVE)
