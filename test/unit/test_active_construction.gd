extends GutTest
## Tests for ActiveConstruction runtime state.


func _make_building_data(dur: int = 2) -> BuildingData:
	var data := BuildingData.new()
	data.building_id = &"test_building"
	data.building_type = BuildingType.Type.RESIDENTIAL
	data.construction_duration = dur
	data.metric_effects = {&"solidarity": 0.02}
	data.alignment_push = 0.0
	return data


func test_initial_state() -> void:
	var active := ActiveConstruction.new(Vector3i(1, -1, 0), _make_building_data())
	assert_almost_eq(active.progress, 0.0, 0.001)
	assert_false(active.is_complete)


func test_tick_advances_progress() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(2))
	var completed: bool = active.tick(1.0)
	assert_false(completed)
	assert_almost_eq(active.progress, 1.0, 0.001)


func test_tick_completes_at_duration() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(2))
	active.tick(1.0)
	var completed: bool = active.tick(1.0)
	assert_true(completed)
	assert_true(active.is_complete)


func test_tick_returns_true_on_completion() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(1))
	assert_true(active.tick(1.0))


func test_tick_with_slow_speed() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(2))
	active.tick(0.5)
	assert_false(active.is_complete)
	active.tick(0.5)
	assert_false(active.is_complete)
	active.tick(0.5)
	assert_false(active.is_complete)
	active.tick(0.5)
	assert_true(active.is_complete)


func test_tick_after_complete_returns_false() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(1))
	active.tick(1.0)
	assert_false(active.tick(1.0))


func test_progress_ratio() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(2))
	assert_almost_eq(active.get_progress_ratio(), 0.0, 0.001)
	active.tick(1.0)
	assert_almost_eq(active.get_progress_ratio(), 0.5, 0.001)
	active.tick(1.0)
	assert_almost_eq(active.get_progress_ratio(), 1.0, 0.001)


func test_remaining_estimate() -> void:
	var active := ActiveConstruction.new(Vector3i.ZERO, _make_building_data(4))
	assert_eq(active.get_remaining_cycles_estimate(1.0), 4)
	active.tick(1.0)
	assert_eq(active.get_remaining_cycles_estimate(1.0), 3)
	assert_eq(active.get_remaining_cycles_estimate(0.5), 6)


func test_coord_stored() -> void:
	var coord := Vector3i(3, -2, -1)
	var active := ActiveConstruction.new(coord, _make_building_data())
	assert_eq(active.coord, coord)


func test_building_data_stored() -> void:
	var data := _make_building_data(3)
	var active := ActiveConstruction.new(Vector3i.ZERO, data)
	assert_eq(active.building_data.building_id, &"test_building")
	assert_eq(active.building_data.construction_duration, 3)
