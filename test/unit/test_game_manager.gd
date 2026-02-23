extends GutTest
## Tests for GameManager — phase state machine and cycle progression.
## Uses the global EventBus autoload (GameManager emits on it directly).

var gm: Node


func before_each() -> void:
	gm = load("res://scripts/core/game_manager.gd").new()
	add_child(gm)


func after_each() -> void:
	gm.queue_free()
	# Disconnect any test listeners from global EventBus.
	_disconnect_all(EventBus.cycle_started)
	_disconnect_all(EventBus.cycle_completed)
	_disconnect_all(EventBus.phase_changed)
	_disconnect_all(EventBus.game_speed_changed)
	_disconnect_all(EventBus.game_paused)
	_disconnect_all(EventBus.game_resumed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Initial state ---


func test_initial_state() -> void:
	assert_false(gm.is_running, "Should not be running initially")
	assert_eq(gm.current_phase, CycleTimer.Phase.OBSERVE)
	assert_eq(gm.cycle_number, 0)
	assert_eq(gm.game_speed, 1)
	assert_false(gm.is_paused)


# --- start_game ---


func test_start_game_sets_running() -> void:
	gm.start_game()
	assert_true(gm.is_running)
	assert_eq(gm.cycle_number, 1)
	assert_eq(gm.current_phase, CycleTimer.Phase.OBSERVE)


func test_start_game_emits_cycle_started() -> void:
	var received := []
	EventBus.cycle_started.connect(func(c: int) -> void: received.append(c))
	gm.start_game()
	assert_eq(received, [1])


func test_start_game_emits_phase_changed() -> void:
	var received := []
	EventBus.phase_changed.connect(func(p: int, n: StringName) -> void: received.append([p, n]))
	gm.start_game()
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], CycleTimer.Phase.OBSERVE)
	assert_eq(received[0][1], &"observe")


func test_start_game_idempotent() -> void:
	var received := []
	EventBus.cycle_started.connect(func(c: int) -> void: received.append(c))
	gm.start_game()
	gm.start_game()
	assert_eq(received.size(), 1, "Should not start twice")


# --- advance_phase ---


func test_advance_phase_observe_to_influence() -> void:
	gm.start_game()
	gm.advance_phase()
	assert_eq(gm.current_phase, CycleTimer.Phase.INFLUENCE)


func test_advance_phase_full_cycle() -> void:
	gm.start_game()
	assert_eq(gm.current_phase, CycleTimer.Phase.OBSERVE)
	gm.advance_phase()
	assert_eq(gm.current_phase, CycleTimer.Phase.INFLUENCE)
	gm.advance_phase()
	assert_eq(gm.current_phase, CycleTimer.Phase.WAVE)
	gm.advance_phase()
	assert_eq(gm.current_phase, CycleTimer.Phase.EVOLVE)
	gm.advance_phase()
	assert_eq(gm.current_phase, CycleTimer.Phase.OBSERVE, "Should wrap to OBSERVE")


func test_advance_past_evolve_increments_cycle() -> void:
	gm.start_game()
	assert_eq(gm.cycle_number, 1)
	gm.advance_phase()  # INFLUENCE
	gm.advance_phase()  # WAVE
	gm.advance_phase()  # EVOLVE
	gm.advance_phase()  # Back to OBSERVE
	assert_eq(gm.cycle_number, 2)


func test_advance_past_evolve_emits_cycle_completed_and_started() -> void:
	var completed := []
	var started := []
	EventBus.cycle_completed.connect(func(c: int) -> void: completed.append(c))
	EventBus.cycle_started.connect(func(c: int) -> void: started.append(c))
	gm.start_game()
	gm.advance_phase()
	gm.advance_phase()
	gm.advance_phase()
	gm.advance_phase()
	assert_eq(completed, [1], "Should complete cycle 1")
	assert_eq(started, [1, 2], "Should start cycle 1 and 2")


func test_advance_phase_emits_phase_changed() -> void:
	var received := []
	EventBus.phase_changed.connect(func(p: int, n: StringName) -> void: received.append([p, n]))
	gm.start_game()
	gm.advance_phase()
	assert_eq(received.size(), 2)
	assert_eq(received[1][0], CycleTimer.Phase.INFLUENCE)
	assert_eq(received[1][1], &"influence")


func test_advance_phase_does_nothing_if_not_running() -> void:
	gm.advance_phase()
	assert_eq(gm.current_phase, CycleTimer.Phase.OBSERVE)
	assert_eq(gm.cycle_number, 0)


# --- set_game_speed ---


func test_set_game_speed() -> void:
	gm.set_game_speed(2)
	assert_eq(gm.game_speed, 2)


func test_set_game_speed_emits_signal() -> void:
	var received := []
	EventBus.game_speed_changed.connect(func(s: int) -> void: received.append(s))
	gm.set_game_speed(3)
	assert_eq(received, [3])


func test_set_game_speed_clamps_high() -> void:
	gm.set_game_speed(10)
	assert_eq(gm.game_speed, 3)


func test_set_game_speed_clamps_low() -> void:
	gm.set_game_speed(0)
	assert_eq(gm.game_speed, 1)


func test_set_game_speed_no_emit_if_same() -> void:
	var received := []
	EventBus.game_speed_changed.connect(func(s: int) -> void: received.append(s))
	gm.set_game_speed(1)
	assert_eq(received.size(), 0, "No signal if speed unchanged")


# --- pause / resume ---


func test_pause_game() -> void:
	gm.start_game()
	gm.pause_game()
	assert_true(gm.is_paused)


func test_pause_emits_signal() -> void:
	var received := []
	EventBus.game_paused.connect(func() -> void: received.append(true))
	gm.start_game()
	gm.pause_game()
	assert_eq(received.size(), 1)


func test_resume_game() -> void:
	gm.start_game()
	gm.pause_game()
	gm.resume_game()
	assert_false(gm.is_paused)


func test_resume_emits_signal() -> void:
	var received := []
	EventBus.game_resumed.connect(func() -> void: received.append(true))
	gm.start_game()
	gm.pause_game()
	gm.resume_game()
	assert_eq(received.size(), 1)


func test_pause_idempotent() -> void:
	var received := []
	EventBus.game_paused.connect(func() -> void: received.append(true))
	gm.start_game()
	gm.pause_game()
	gm.pause_game()
	assert_eq(received.size(), 1, "Should not emit twice")


func test_resume_without_pause_does_nothing() -> void:
	var received := []
	EventBus.game_resumed.connect(func() -> void: received.append(true))
	gm.start_game()
	gm.resume_game()
	assert_eq(received.size(), 0)


# --- Progress and time remaining ---


func test_phase_progress_at_start() -> void:
	gm.start_game()
	assert_almost_eq(gm.get_phase_progress(), 0.0, 0.05)


func test_phase_time_remaining_at_start() -> void:
	gm.start_game()
	var expected: float = gm.cycle_timer.observe_duration / float(gm.game_speed)
	assert_almost_eq(gm.get_phase_time_remaining(), expected, 0.5)


func test_phase_progress_not_running() -> void:
	assert_almost_eq(gm.get_phase_progress(), 0.0, 0.001)


func test_phase_time_remaining_not_running() -> void:
	assert_almost_eq(gm.get_phase_time_remaining(), 0.0, 0.001)


# --- Era tracking ---


func test_default_era_thresholds() -> void:
	assert_eq(gm.era_cycle_thresholds, [1, 6, 11, 16])


func test_era_1_at_cycle_1() -> void:
	gm.cycle_number = 1
	assert_eq(gm.get_current_era(), 1)


func test_era_1_at_cycle_5() -> void:
	gm.cycle_number = 5
	assert_eq(gm.get_current_era(), 1)


func test_era_2_at_cycle_6() -> void:
	gm.cycle_number = 6
	assert_eq(gm.get_current_era(), 2)


func test_era_3_at_cycle_11() -> void:
	gm.cycle_number = 11
	assert_eq(gm.get_current_era(), 3)


func test_era_4_at_cycle_16() -> void:
	gm.cycle_number = 16
	assert_eq(gm.get_current_era(), 4)


func test_era_0_before_game_starts() -> void:
	gm.cycle_number = 0
	assert_eq(gm.get_current_era(), 1, "Era defaults to 1 even at cycle 0")


func test_scenario_id_default() -> void:
	assert_eq(gm.scenario_id, &"the_wildtide")
