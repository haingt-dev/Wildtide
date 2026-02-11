extends GutTest
## Tests for WaveManager — wave damage simulation.
## Uses global EventBus and GameManager autoloads.

var wm: WaveManager
var grid: HexGrid


func before_each() -> void:
	wm = WaveManager.new()
	add_child(wm)
	# Create a small hex grid with known Rift positions.
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	wm.rift_positions = [Vector3i(4, -4, 0), Vector3i(-4, 0, 4), Vector3i(0, 4, -4)]


func after_each() -> void:
	wm.queue_free()
	_disconnect_all(EventBus.wave_started)
	_disconnect_all(EventBus.wave_ended)
	_disconnect_all(EventBus.hex_scarred)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Phase triggers ---


func test_wave_triggers_on_wave_phase() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	GameManager.cycle_number = 1
	wm._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	assert_eq(started.size(), 1)


func test_no_trigger_on_observe() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	wm._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_eq(started.size(), 0)


func test_no_trigger_on_influence() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	wm._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_eq(started.size(), 0)


func test_no_trigger_on_evolve() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	wm._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(started.size(), 0)


# --- Signals ---


func test_emits_wave_started_and_ended() -> void:
	var started := []
	var ended := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	EventBus.wave_ended.connect(func(c: int) -> void: ended.append(c))
	wm._run_wave(1)
	assert_eq(started, [1])
	assert_eq(ended, [1])


func test_emits_hex_scarred() -> void:
	var scarred := []
	EventBus.hex_scarred.connect(
		func(coord: Vector3i, amount: float) -> void: scarred.append([coord, amount])
	)
	wm._run_wave(1)
	assert_gt(scarred.size(), 0, "Should emit hex_scarred for damaged hexes")


# --- Damage ---


func test_applies_scar_damage_near_rifts() -> void:
	wm._run_wave(1)
	# Check a hex at a Rift position took damage.
	var rift := wm.rift_positions[0]
	var cell: HexCell = grid.get_cell(rift)
	if cell:
		assert_gt(cell.scar_state, 0.0, "Rift hex should be scarred")


func test_damage_falls_off_with_distance() -> void:
	wm._run_wave(1)
	var rift := wm.rift_positions[0]
	var rift_cell: HexCell = grid.get_cell(rift)
	if not rift_cell:
		pass_test("Rift coord outside grid")
		return
	# Find a neighbor 1 hex away.
	var neighbors := grid.get_neighbors_of(rift)
	if neighbors.is_empty():
		pass_test("No neighbors")
		return
	var near_cell: HexCell = neighbors[0]
	assert_gt(rift_cell.scar_state, near_cell.scar_state, "Closer = more damage")


func test_no_damage_beyond_radius() -> void:
	wm._run_wave(1)
	# Center hex (0,0,0) is far from all Rifts (dist=4), radius=3.
	var center: HexCell = grid.get_cell(Vector3i.ZERO)
	assert_almost_eq(center.scar_state, 0.0, 0.001, "Center should be undamaged")


func test_wave_power_scales_with_era() -> void:
	wm._run_wave(1)
	var power_era1: float = wm.get_last_wave_power()
	# Reset grid for clean second run.
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	wm._run_wave(6)
	var power_era2: float = wm.get_last_wave_power()
	assert_gt(power_era2, power_era1, "Era 2 should have higher power")


func test_total_damage_tracked() -> void:
	wm._run_wave(1)
	assert_gt(wm.get_last_total_damage(), 0.0, "Should track total damage")


# --- Edge cases ---


func test_no_crash_without_grid() -> void:
	wm.hex_grid = null
	wm._run_wave(1)
	assert_almost_eq(wm.get_last_wave_power(), 0.0, 0.001)


func test_no_crash_without_rifts() -> void:
	wm.rift_positions = []
	wm._run_wave(1)
	assert_almost_eq(wm.get_last_total_damage(), 0.0, 0.001)
