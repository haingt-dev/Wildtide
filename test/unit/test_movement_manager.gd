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
