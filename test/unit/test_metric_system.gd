extends GutTest
## Tests for MetricSystem — metric tracking, interaction matrix, alignment.
## Uses the global EventBus autoload (MetricSystem emits on it directly).

var ms: Node


func before_each() -> void:
	ms = load("res://scripts/metrics/metric_system.gd").new()
	add_child(ms)


func after_each() -> void:
	ms.queue_free()
	_disconnect_all(EventBus.metric_changed)
	_disconnect_all(EventBus.alignment_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Initial state ---


func test_initial_metrics_zero() -> void:
	assert_almost_eq(ms.pollution, 0.0, 0.001)
	assert_almost_eq(ms.anxiety, 0.0, 0.001)
	assert_almost_eq(ms.solidarity, 0.0, 0.001)
	assert_almost_eq(ms.harmony, 0.0, 0.001)


func test_initial_alignment_values_zero() -> void:
	assert_almost_eq(ms.science_value, 0.0, 0.001)
	assert_almost_eq(ms.magic_value, 0.0, 0.001)


func test_initial_alignment_zero() -> void:
	assert_almost_eq(ms.get_alignment(), 0.0, 0.001)


# --- get_metric / set_metric ---


func test_set_metric_pollution() -> void:
	ms.set_metric(&"pollution", 0.5)
	assert_almost_eq(ms.pollution, 0.5, 0.001)
	assert_almost_eq(ms.get_metric(&"pollution"), 0.5, 0.001)


func test_set_metric_clamps_high() -> void:
	ms.set_metric(&"anxiety", 1.5)
	assert_almost_eq(ms.anxiety, 1.0, 0.001)


func test_set_metric_clamps_low() -> void:
	ms.set_metric(&"solidarity", -0.5)
	assert_almost_eq(ms.solidarity, 0.0, 0.001)


func test_set_metric_emits_signal() -> void:
	var received := []
	EventBus.metric_changed.connect(
		func(n: StringName, nv: float, ov: float) -> void: received.append([n, nv, ov])
	)
	ms.set_metric(&"harmony", 0.7)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], &"harmony")
	assert_almost_eq(received[0][1], 0.7, 0.001)
	assert_almost_eq(received[0][2], 0.0, 0.001)


func test_set_metric_no_emit_if_same() -> void:
	var received := []
	EventBus.metric_changed.connect(
		func(n: StringName, nv: float, ov: float) -> void: received.append([n, nv, ov])
	)
	ms.set_metric(&"pollution", 0.0)
	assert_eq(received.size(), 0, "No signal if value unchanged")


func test_set_metric_unknown_name() -> void:
	ms.set_metric(&"unknown", 0.5)
	assert_almost_eq(ms.get_metric(&"unknown"), 0.0, 0.001)


func test_get_metric_all_names() -> void:
	ms.set_metric(&"pollution", 0.1)
	ms.set_metric(&"anxiety", 0.2)
	ms.set_metric(&"solidarity", 0.3)
	ms.set_metric(&"harmony", 0.4)
	assert_almost_eq(ms.get_metric(&"pollution"), 0.1, 0.001)
	assert_almost_eq(ms.get_metric(&"anxiety"), 0.2, 0.001)
	assert_almost_eq(ms.get_metric(&"solidarity"), 0.3, 0.001)
	assert_almost_eq(ms.get_metric(&"harmony"), 0.4, 0.001)


# --- push_metric ---


func test_push_metric_adds_delta() -> void:
	ms.set_metric(&"pollution", 0.3)
	ms.push_metric(&"pollution", 0.2)
	assert_almost_eq(ms.pollution, 0.5, 0.001)


func test_push_metric_clamps() -> void:
	ms.set_metric(&"anxiety", 0.9)
	ms.push_metric(&"anxiety", 0.5)
	assert_almost_eq(ms.anxiety, 1.0, 0.001)


func test_push_metric_negative() -> void:
	ms.set_metric(&"harmony", 0.5)
	ms.push_metric(&"harmony", -0.3)
	assert_almost_eq(ms.harmony, 0.2, 0.001)


# --- Alignment ---


func test_alignment_zero_when_both_zero() -> void:
	assert_almost_eq(ms.get_alignment(), 0.0, 0.001)


func test_alignment_science_only() -> void:
	ms.science_value = 10.0
	ms.magic_value = 0.0
	assert_almost_eq(ms.get_alignment(), 1.0, 0.001)


func test_alignment_magic_only() -> void:
	ms.science_value = 0.0
	ms.magic_value = 10.0
	assert_almost_eq(ms.get_alignment(), -1.0, 0.001)


func test_alignment_balanced() -> void:
	ms.science_value = 5.0
	ms.magic_value = 5.0
	assert_almost_eq(ms.get_alignment(), 0.0, 0.001)


func test_alignment_ratio() -> void:
	ms.science_value = 3.0
	ms.magic_value = 1.0
	# (3-1)/(3+1) = 0.5
	assert_almost_eq(ms.get_alignment(), 0.5, 0.001)


func test_push_alignment_positive() -> void:
	ms.push_alignment(2.0)
	assert_almost_eq(ms.science_value, 2.0, 0.001)
	assert_almost_eq(ms.magic_value, 0.0, 0.001)


func test_push_alignment_negative() -> void:
	ms.push_alignment(-3.0)
	assert_almost_eq(ms.science_value, 0.0, 0.001)
	assert_almost_eq(ms.magic_value, 3.0, 0.001)


func test_push_alignment_emits_signal() -> void:
	var received := []
	EventBus.alignment_changed.connect(func(a: float) -> void: received.append(a))
	ms.push_alignment(1.0)
	assert_eq(received.size(), 1)
	assert_almost_eq(received[0], 1.0, 0.001)


# --- get_all_metrics ---


func test_get_all_metrics() -> void:
	ms.set_metric(&"pollution", 0.1)
	ms.set_metric(&"anxiety", 0.2)
	ms.set_metric(&"solidarity", 0.3)
	ms.set_metric(&"harmony", 0.4)
	var all: Dictionary = ms.get_all_metrics()
	assert_almost_eq(all[&"pollution"], 0.1, 0.001)
	assert_almost_eq(all[&"anxiety"], 0.2, 0.001)
	assert_almost_eq(all[&"solidarity"], 0.3, 0.001)
	assert_almost_eq(all[&"harmony"], 0.4, 0.001)


# --- get_metric_values ---


func test_get_metric_values_order() -> void:
	ms.set_metric(&"pollution", 0.1)
	ms.set_metric(&"anxiety", 0.2)
	ms.set_metric(&"solidarity", 0.3)
	ms.set_metric(&"harmony", 0.4)
	var values: Array[float] = ms.get_metric_values()
	assert_eq(values.size(), 4)
	assert_almost_eq(values[0], 0.1, 0.001)
	assert_almost_eq(values[1], 0.2, 0.001)
	assert_almost_eq(values[2], 0.3, 0.001)
	assert_almost_eq(values[3], 0.4, 0.001)


# --- reset_to_defaults ---


func test_reset_to_defaults() -> void:
	ms.set_metric(&"pollution", 0.8)
	ms.set_metric(&"anxiety", 0.7)
	ms.science_value = 5.0
	ms.magic_value = 3.0
	ms.reset_to_defaults()
	assert_almost_eq(ms.pollution, 0.0, 0.001)
	assert_almost_eq(ms.anxiety, 0.0, 0.001)
	assert_almost_eq(ms.solidarity, 0.0, 0.001)
	assert_almost_eq(ms.harmony, 0.0, 0.001)
	assert_almost_eq(ms.science_value, 0.0, 0.001)
	assert_almost_eq(ms.magic_value, 0.0, 0.001)


# --- Interaction matrix application ---


func test_interaction_matrix_applied() -> void:
	# Set all metrics to 1.0 and trigger EVOLVE
	ms.set_metric(&"pollution", 1.0)
	ms.set_metric(&"anxiety", 1.0)
	ms.set_metric(&"solidarity", 1.0)
	ms.set_metric(&"harmony", 1.0)
	# Manually call the internal method
	ms._apply_interaction_matrix()
	# Column sums with all 1.0:
	# Pollution: 0 + 0 + 0 + (-0.4) = -0.4 -> 1.0 + (-0.4) = 0.6
	assert_almost_eq(ms.pollution, 0.6, 0.001)
	# Anxiety: 0.3 + 0 + (-0.2) + (-0.1) = 0.0 -> 1.0 + 0.0 = 1.0
	assert_almost_eq(ms.anxiety, 1.0, 0.001)
	# Solidarity: 0 + (-0.3) + 0 + 0.2 = -0.1 -> 1.0 + (-0.1) = 0.9
	assert_almost_eq(ms.solidarity, 0.9, 0.001)
	# Harmony: (-0.5) + (-0.2) + 0.3 + 0 = -0.4 -> 1.0 + (-0.4) = 0.6
	assert_almost_eq(ms.harmony, 0.6, 0.001)


func test_interaction_matrix_zero_metrics() -> void:
	ms._apply_interaction_matrix()
	assert_almost_eq(ms.pollution, 0.0, 0.001)
	assert_almost_eq(ms.anxiety, 0.0, 0.001)
	assert_almost_eq(ms.solidarity, 0.0, 0.001)
	assert_almost_eq(ms.harmony, 0.0, 0.001)


func test_interaction_matrix_clamps_result() -> void:
	# Pollution at 1.0, Harmony at 0.0 — Pollution→Harmony = -0.5
	# Harmony should not go below 0.0
	ms.set_metric(&"pollution", 1.0)
	ms._apply_interaction_matrix()
	assert_almost_eq(ms.harmony, 0.0, 0.001)


# --- Biome pushes ---


func test_biome_pushes_with_hex_grid() -> void:
	var grid := HexGrid.new()
	grid.initialize_hex_map(1)  # Small grid: 7 hexes
	# Set all cells to FOREST biome (pushes harmony)
	for cell: HexCell in grid.get_all_cells():
		cell.biome = BiomeType.Type.FOREST
	ms.hex_grid = grid
	ms._apply_biome_pushes()
	# Forest biome has metric_push = "harmony" with some push value
	# Check that harmony increased (exact value depends on biome data)
	assert_gt(ms.harmony, 0.0, "Forest biome should push harmony")


func test_biome_pushes_no_grid() -> void:
	# Should not crash with no hex_grid
	ms._apply_biome_pushes()
	assert_almost_eq(ms.pollution, 0.0, 0.001)


# --- EVOLVE phase trigger ---


func test_evolve_phase_triggers_matrix() -> void:
	ms.set_metric(&"pollution", 1.0)
	ms.set_metric(&"harmony", 1.0)
	# Simulate EVOLVE phase signal
	ms._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	# Should have applied interaction matrix
	# Harmony→Pollution = -0.4 -> pollution = 1.0 + (-0.4) = 0.6
	assert_almost_eq(ms.pollution, 0.6, 0.01)


func test_non_evolve_phase_does_nothing() -> void:
	ms.set_metric(&"pollution", 0.5)
	ms._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_almost_eq(ms.pollution, 0.5, 0.001)
