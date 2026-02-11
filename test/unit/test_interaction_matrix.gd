extends GutTest
## Tests for InteractionMatrix Resource — weight lookup and delta calculation.

var matrix: InteractionMatrix


func before_each() -> void:
	matrix = InteractionMatrix.new()
	# Normal mode weights from GDD:
	# Row order: Pollution, Anxiety, Solidarity, Harmony
	matrix.weights = [
		PackedFloat64Array([0, 0.3, 0, -0.5]),
		PackedFloat64Array([0, 0, -0.3, -0.2]),
		PackedFloat64Array([0, -0.2, 0, 0.3]),
		PackedFloat64Array([-0.4, -0.1, 0.2, 0]),
	]


# --- get_weight ---


func test_get_weight_pollution_to_anxiety() -> void:
	assert_almost_eq(matrix.get_weight(0, 1), 0.3, 0.001)


func test_get_weight_pollution_to_harmony() -> void:
	assert_almost_eq(matrix.get_weight(0, 3), -0.5, 0.001)


func test_get_weight_harmony_to_pollution() -> void:
	assert_almost_eq(matrix.get_weight(3, 0), -0.4, 0.001)


func test_get_weight_diagonal_is_zero() -> void:
	for i: int in range(InteractionMatrix.SIZE):
		assert_almost_eq(matrix.get_weight(i, i), 0.0, 0.001)


func test_get_weight_zero_entries() -> void:
	assert_almost_eq(matrix.get_weight(0, 0), 0.0, 0.001)
	assert_almost_eq(matrix.get_weight(0, 2), 0.0, 0.001)
	assert_almost_eq(matrix.get_weight(1, 0), 0.0, 0.001)


func test_get_weight_out_of_bounds() -> void:
	assert_almost_eq(matrix.get_weight(-1, 0), 0.0, 0.001)
	assert_almost_eq(matrix.get_weight(0, 4), 0.0, 0.001)
	assert_almost_eq(matrix.get_weight(5, 5), 0.0, 0.001)


func test_get_weight_empty_matrix() -> void:
	var empty := InteractionMatrix.new()
	assert_almost_eq(empty.get_weight(0, 0), 0.0, 0.001)


# --- get_delta_for ---


func test_get_delta_for_zero_metrics() -> void:
	var values: Array[float] = [0.0, 0.0, 0.0, 0.0]
	for target: int in range(InteractionMatrix.SIZE):
		assert_almost_eq(matrix.get_delta_for(target, values), 0.0, 0.001)


func test_get_delta_for_pollution_target() -> void:
	# Only Harmony→Pollution has weight -0.4
	var values: Array[float] = [0.0, 0.0, 0.0, 1.0]
	assert_almost_eq(matrix.get_delta_for(0, values), -0.4, 0.001)


func test_get_delta_for_anxiety_target() -> void:
	# Pollution→Anxiety +0.3, Solidarity→Anxiety -0.2, Harmony→Anxiety -0.1
	var values: Array[float] = [1.0, 0.0, 1.0, 1.0]
	# 0.3*1.0 + (-0.2)*1.0 + (-0.1)*1.0 = 0.0
	assert_almost_eq(matrix.get_delta_for(1, values), 0.0, 0.001)


func test_get_delta_for_solidarity_target() -> void:
	# Anxiety→Solidarity -0.3, Harmony→Solidarity +0.2
	var values: Array[float] = [0.0, 0.5, 0.0, 0.5]
	# (-0.3)*0.5 + 0.2*0.5 = -0.15 + 0.1 = -0.05
	assert_almost_eq(matrix.get_delta_for(2, values), -0.05, 0.001)


func test_get_delta_for_harmony_target() -> void:
	# Pollution→Harmony -0.5, Anxiety→Harmony -0.2, Solidarity→Harmony +0.3
	var values: Array[float] = [0.5, 0.5, 0.5, 0.0]
	# (-0.5)*0.5 + (-0.2)*0.5 + 0.3*0.5 = -0.25 + -0.1 + 0.15 = -0.2
	assert_almost_eq(matrix.get_delta_for(3, values), -0.2, 0.001)


func test_get_delta_for_all_ones() -> void:
	# All metrics at 1.0 — sum each column
	var values: Array[float] = [1.0, 1.0, 1.0, 1.0]
	# Pollution target: 0 + 0 + 0 + (-0.4) = -0.4
	assert_almost_eq(matrix.get_delta_for(0, values), -0.4, 0.001)
	# Anxiety target: 0.3 + 0 + (-0.2) + (-0.1) = 0.0
	assert_almost_eq(matrix.get_delta_for(1, values), 0.0, 0.001)
	# Solidarity target: 0 + (-0.3) + 0 + 0.2 = -0.1
	assert_almost_eq(matrix.get_delta_for(2, values), -0.1, 0.001)
	# Harmony target: (-0.5) + (-0.2) + 0.3 + 0 = -0.4
	assert_almost_eq(matrix.get_delta_for(3, values), -0.4, 0.001)
