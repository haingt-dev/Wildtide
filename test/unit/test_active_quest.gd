extends GutTest
## Tests for ActiveQuest runtime state.


func _make_quest_data(dur: int = 2) -> QuestData:
	var data := QuestData.new()
	data.quest_id = &"test_quest"
	data.faction_id = &"lens"
	data.duration = dur
	data.metric_effects = {&"pollution": 0.05}
	data.alignment_push = 0.1
	return data


func test_initial_remaining_cycles() -> void:
	var active := ActiveQuest.new(_make_quest_data(3))
	assert_eq(active.remaining_cycles, 3)


func test_tick_decrements() -> void:
	var active := ActiveQuest.new(_make_quest_data(3))
	var completed: bool = active.tick()
	assert_false(completed)
	assert_eq(active.remaining_cycles, 2)


func test_tick_completes_at_zero() -> void:
	var active := ActiveQuest.new(_make_quest_data(1))
	var completed: bool = active.tick()
	assert_true(completed)
	assert_eq(active.remaining_cycles, 0)


func test_is_completed() -> void:
	var active := ActiveQuest.new(_make_quest_data(1))
	assert_false(active.is_completed())
	active.tick()
	assert_true(active.is_completed())


func test_faction_id_from_quest_data() -> void:
	var active := ActiveQuest.new(_make_quest_data())
	assert_eq(active.faction_id, &"lens")
