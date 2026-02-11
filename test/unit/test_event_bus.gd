extends GutTest
## Tests for EventBus autoload signal bus.

var bus: Node


func before_each() -> void:
	bus = load("res://scripts/core/event_bus.gd").new()
	add_child(bus)


func after_each() -> void:
	bus.queue_free()


# --- Cycle signals ---


func test_phase_changed() -> void:
	var received := []
	bus.phase_changed.connect(func(p: int, n: StringName) -> void: received.append([p, n]))
	bus.phase_changed.emit(1, &"influence")
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], 1)
	assert_eq(received[0][1], &"influence")


func test_cycle_started() -> void:
	var received := []
	bus.cycle_started.connect(func(c: int) -> void: received.append(c))
	bus.cycle_started.emit(3)
	assert_eq(received, [3])


func test_cycle_completed() -> void:
	var received := []
	bus.cycle_completed.connect(func(c: int) -> void: received.append(c))
	bus.cycle_completed.emit(5)
	assert_eq(received, [5])


func test_game_speed_changed() -> void:
	var received := []
	bus.game_speed_changed.connect(func(s: int) -> void: received.append(s))
	bus.game_speed_changed.emit(2)
	assert_eq(received, [2])


func test_game_paused_resumed() -> void:
	var paused := []
	var resumed := []
	bus.game_paused.connect(func() -> void: paused.append(true))
	bus.game_resumed.connect(func() -> void: resumed.append(true))
	bus.game_paused.emit()
	bus.game_resumed.emit()
	assert_eq(paused.size(), 1)
	assert_eq(resumed.size(), 1)


# --- Metric signals ---


func test_metric_changed() -> void:
	var received := []
	bus.metric_changed.connect(
		func(name: StringName, nv: float, ov: float) -> void: received.append([name, nv, ov])
	)
	bus.metric_changed.emit(&"pollution", 0.7, 0.5)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], &"pollution")
	assert_almost_eq(received[0][1], 0.7, 0.001)
	assert_almost_eq(received[0][2], 0.5, 0.001)


func test_alignment_changed() -> void:
	var received := []
	bus.alignment_changed.connect(func(a: float) -> void: received.append(a))
	bus.alignment_changed.emit(-0.3)
	assert_almost_eq(received[0], -0.3, 0.001)


# --- HexGrid signals ---


func test_hex_grid_initialized() -> void:
	var received := []
	bus.hex_grid_initialized.connect(func(g: HexGrid) -> void: received.append(g))
	var grid := HexGrid.new()
	bus.hex_grid_initialized.emit(grid)
	assert_eq(received.size(), 1)
	assert_eq(received[0], grid)


func test_hex_cell_changed() -> void:
	var received := []
	bus.hex_cell_changed.connect(func(c: Vector3i) -> void: received.append(c))
	bus.hex_cell_changed.emit(Vector3i(1, -1, 0))
	assert_eq(received[0], Vector3i(1, -1, 0))


func test_hex_selected_deselected() -> void:
	var selected := []
	var deselected := []
	bus.hex_selected.connect(func(c: Vector3i) -> void: selected.append(c))
	bus.hex_deselected.connect(func() -> void: deselected.append(true))
	bus.hex_selected.emit(Vector3i(2, -3, 1))
	bus.hex_deselected.emit()
	assert_eq(selected[0], Vector3i(2, -3, 1))
	assert_eq(deselected.size(), 1)


# --- Wave signals ---


func test_wave_started_ended() -> void:
	var started := []
	var ended := []
	bus.wave_started.connect(func(w: int) -> void: started.append(w))
	bus.wave_ended.connect(func(w: int) -> void: ended.append(w))
	bus.wave_started.emit(1)
	bus.wave_ended.emit(1)
	assert_eq(started, [1])
	assert_eq(ended, [1])


func test_hex_scarred() -> void:
	var received := []
	bus.hex_scarred.connect(func(c: Vector3i, a: float) -> void: received.append([c, a]))
	bus.hex_scarred.emit(Vector3i(0, 0, 0), 0.5)
	assert_eq(received[0][0], Vector3i(0, 0, 0))
	assert_almost_eq(received[0][1], 0.5, 0.001)


# --- Building signals ---


func test_building_placed_removed() -> void:
	var placed := []
	var removed := []
	bus.building_placed.connect(func(c: Vector3i, b: StringName) -> void: placed.append([c, b]))
	bus.building_removed.connect(func(c: Vector3i, b: StringName) -> void: removed.append([c, b]))
	bus.building_placed.emit(Vector3i(1, 0, -1), &"farm")
	bus.building_removed.emit(Vector3i(1, 0, -1), &"farm")
	assert_eq(placed[0][1], &"farm")
	assert_eq(removed[0][1], &"farm")


# --- Quest signals ---


func test_quest_lifecycle() -> void:
	var proposed := []
	var approved := []
	var completed := []
	bus.quest_proposed.connect(func(f: StringName, q: StringName) -> void: proposed.append([f, q]))
	bus.quest_approved.connect(func(f: StringName, q: StringName) -> void: approved.append([f, q]))
	bus.quest_completed.connect(
		func(f: StringName, q: StringName) -> void: completed.append([f, q])
	)
	bus.quest_proposed.emit(&"lens", &"q01")
	bus.quest_approved.emit(&"lens", &"q01")
	bus.quest_completed.emit(&"lens", &"q01")
	assert_eq(proposed[0], [&"lens", &"q01"])
	assert_eq(approved[0], [&"lens", &"q01"])
	assert_eq(completed[0], [&"lens", &"q01"])


func test_quest_rejected() -> void:
	var rejected := []
	bus.quest_rejected.connect(func(f: StringName, q: StringName) -> void: rejected.append([f, q]))
	bus.quest_rejected.emit(&"veil", &"q02")
	assert_eq(rejected[0], [&"veil", &"q02"])


# --- Ruin signals ---


func test_ruin_discovered() -> void:
	var received := []
	bus.ruin_discovered.connect(func(c: Vector3i, t: StringName) -> void: received.append([c, t]))
	bus.ruin_discovered.emit(Vector3i(3, -5, 2), &"observatory")
	assert_eq(received[0][0], Vector3i(3, -5, 2))
	assert_eq(received[0][1], &"observatory")


func test_ruin_exploration_and_depletion() -> void:
	var explored := []
	var depleted := []
	bus.ruin_exploration_started.connect(func(c: Vector3i) -> void: explored.append(c))
	bus.ruin_depleted.connect(func(c: Vector3i) -> void: depleted.append(c))
	bus.ruin_exploration_started.emit(Vector3i(3, -5, 2))
	bus.ruin_depleted.emit(Vector3i(3, -5, 2))
	assert_eq(explored[0], Vector3i(3, -5, 2))
	assert_eq(depleted[0], Vector3i(3, -5, 2))


# --- Cross-cutting ---


func test_multiple_listeners() -> void:
	var a := []
	var b := []
	bus.phase_changed.connect(func(p: int, _n: StringName) -> void: a.append(p))
	bus.phase_changed.connect(func(p: int, _n: StringName) -> void: b.append(p))
	bus.phase_changed.emit(2, &"wave")
	assert_eq(a, [2], "First listener should receive signal")
	assert_eq(b, [2], "Second listener should receive signal")


func test_disconnect() -> void:
	var received := []
	var handler := func(c: int) -> void: received.append(c)
	bus.cycle_started.connect(handler)
	bus.cycle_started.emit(1)
	bus.cycle_started.disconnect(handler)
	bus.cycle_started.emit(2)
	assert_eq(received, [1], "Should not receive after disconnect")
