extends GutTest
## Tests for ActiveExploration runtime state.


func _make_ruin_data(dur: int = 2, tech: int = 3, rune: int = 0) -> RuinData:
	var data := RuinData.new()
	data.ruin_type = RuinType.Type.OBSERVATORY
	data.display_name = &"Observatory"
	data.exploration_duration = dur
	data.tech_fragments = tech
	data.rune_shards = rune
	data.damage_yield_penalty = 0.5
	return data


func test_initial_remaining_cycles() -> void:
	var active := ActiveExploration.new(Vector3i(1, -1, 0), _make_ruin_data(3))
	assert_eq(active.remaining_cycles, 3)


func test_tick_decrements() -> void:
	var active := ActiveExploration.new(Vector3i(1, -1, 0), _make_ruin_data(3))
	var completed: bool = active.tick()
	assert_false(completed)
	assert_eq(active.remaining_cycles, 2)


func test_tick_completes_at_zero() -> void:
	var active := ActiveExploration.new(Vector3i(1, -1, 0), _make_ruin_data(1))
	var completed: bool = active.tick()
	assert_true(completed)
	assert_eq(active.remaining_cycles, 0)


func test_is_completed() -> void:
	var active := ActiveExploration.new(Vector3i(1, -1, 0), _make_ruin_data(1))
	assert_false(active.is_completed())
	active.tick()
	assert_true(active.is_completed())


func test_coord_stored() -> void:
	var coord := Vector3i(2, -3, 1)
	var active := ActiveExploration.new(coord, _make_ruin_data())
	assert_eq(active.coord, coord)


func test_undamaged_yields_full() -> void:
	var active := ActiveExploration.new(Vector3i.ZERO, _make_ruin_data(2, 3, 0))
	assert_eq(active.get_effective_tech_fragments(), 3)
	assert_eq(active.get_effective_rune_shards(), 0)


func test_damaged_yields_reduced() -> void:
	var active := ActiveExploration.new(Vector3i.ZERO, _make_ruin_data(2, 3, 0))
	active.apply_damage()
	assert_eq(active.get_effective_tech_fragments(), 2)
	assert_eq(active.get_effective_rune_shards(), 0)


func test_damaged_mixed_yields() -> void:
	var active := ActiveExploration.new(Vector3i.ZERO, _make_ruin_data(3, 1, 1))
	active.apply_damage()
	assert_eq(active.get_effective_tech_fragments(), 1)
	assert_eq(active.get_effective_rune_shards(), 1)
