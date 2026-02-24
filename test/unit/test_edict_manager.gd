extends GutTest
## Tests for EdictManager Node.

var _manager: EdictManager


func before_each() -> void:
	_manager = EdictManager.new()
	add_child(_manager)


func after_each() -> void:
	_manager.queue_free()


func _make_edict(
	eid: StringName,
	dur: int = -1,
	free: bool = false,
	metrics: Dictionary = {},
	econ: Dictionary = {},
	reactions: Dictionary = {},
) -> EdictData:
	var e := EdictData.new()
	e.edict_id = eid
	e.duration = dur
	e.is_free_action = free
	e.metric_effects = metrics
	e.economy_effects = econ
	e.faction_reactions = reactions
	return e


func _inject_edict(edata: EdictData) -> void:
	_manager.edict_registry._data[edata.edict_id] = edata


func test_enact_edict() -> void:
	_inject_edict(_make_edict(&"test_a"))
	assert_true(_manager.enact_edict(&"test_a"))
	assert_eq(_manager.get_active_edict_ids().size(), 1)


func test_enact_duplicate_fails() -> void:
	_inject_edict(_make_edict(&"test_a"))
	_manager.enact_edict(&"test_a")
	assert_false(_manager.enact_edict(&"test_a"))


func test_max_two_slots() -> void:
	_inject_edict(_make_edict(&"a"))
	_inject_edict(_make_edict(&"b"))
	_inject_edict(_make_edict(&"c"))
	_manager.enact_edict(&"a")
	_manager.enact_edict(&"b")
	assert_false(_manager.enact_edict(&"c"))


func test_free_action_bypasses_slots() -> void:
	_inject_edict(_make_edict(&"a"))
	_inject_edict(_make_edict(&"b"))
	_inject_edict(_make_edict(&"free", 1, true))
	_manager.enact_edict(&"a")
	_manager.enact_edict(&"b")
	assert_true(_manager.enact_edict(&"free"))
	assert_eq(_manager.get_active_edict_ids().size(), 3)


func test_revoke_edict() -> void:
	_inject_edict(_make_edict(&"a"))
	_manager.enact_edict(&"a")
	assert_true(_manager.revoke_edict(&"a"))
	assert_eq(_manager.get_active_edict_ids().size(), 0)


func test_revoke_nonexistent_fails() -> void:
	assert_false(_manager.revoke_edict(&"nope"))


func test_get_remaining_permanent() -> void:
	_inject_edict(_make_edict(&"perm"))
	_manager.enact_edict(&"perm")
	assert_eq(_manager.get_remaining(&"perm"), -1)


func test_timed_edict_expires() -> void:
	_inject_edict(_make_edict(&"timed", 2))
	_manager.enact_edict(&"timed")
	var expired_ids: Array = []
	EventBus.edict_expired.connect(func(eid: StringName) -> void: expired_ids.append(eid))
	# Tick 1
	_manager._tick_durations()
	assert_eq(_manager.get_remaining(&"timed"), 1)
	# Tick 2 — expires
	_manager._tick_durations()
	assert_eq(_manager.get_active_edict_ids().size(), 0)
	assert_eq(expired_ids.size(), 1)
	assert_eq(expired_ids[0], &"timed")


func test_get_economy_effects_aggregated() -> void:
	_inject_edict(_make_edict(&"a", -1, false, {}, {&"gold_income": 0.3}))
	_inject_edict(_make_edict(&"b", -1, false, {}, {&"gold_income": -0.2, &"defense": 0.25}))
	_manager.enact_edict(&"a")
	_manager.enact_edict(&"b")
	var effects: Dictionary = _manager.get_economy_effects()
	assert_almost_eq(effects[&"gold_income"] as float, 0.1, 0.001)
	assert_almost_eq(effects[&"defense"] as float, 0.25, 0.001)


func test_edict_enacted_signal() -> void:
	var received: Array = []
	EventBus.edict_enacted.connect(func(eid: StringName) -> void: received.append(eid))
	_inject_edict(_make_edict(&"sig_test"))
	_manager.enact_edict(&"sig_test")
	assert_eq(received.size(), 1)
	assert_eq(received[0], &"sig_test")


# --- Edict → QuestManager morale integration ---


func test_enact_pushes_positive_morale_to_quest_manager() -> void:
	var qmgr := QuestManager.new()
	add_child(qmgr)
	_manager.quest_manager = qmgr
	_inject_edict(_make_edict(&"popular", -1, false, {}, {}, {&"the_lens": 10}))
	var old_morale: int = qmgr.get_faction_morale(&"the_lens")
	_manager.enact_edict(&"popular")
	assert_eq(qmgr.get_faction_morale(&"the_lens"), old_morale + 10)
	qmgr.queue_free()


func test_dislike_pushes_negative_morale_per_cycle() -> void:
	var qmgr := QuestManager.new()
	add_child(qmgr)
	_manager.quest_manager = qmgr
	_inject_edict(_make_edict(&"unpop", -1, false, {}, {}, {&"the_coin": -5}))
	_manager.enact_edict(&"unpop")
	var before: int = qmgr.get_faction_morale(&"the_coin")
	_manager._apply_faction_dislike()
	assert_eq(qmgr.get_faction_morale(&"the_coin"), before - 5)
	qmgr.queue_free()


func test_faction_reactions_skip_without_quest_manager() -> void:
	_inject_edict(_make_edict(&"noop", -1, false, {}, {}, {&"the_wall": 10}))
	_manager.enact_edict(&"noop")
	# Should not crash — no quest_manager set
	assert_true(true, "No crash without quest_manager")


# --- Aggregation methods ---


func test_get_defense_modifier_empty() -> void:
	assert_almost_eq(_manager.get_defense_modifier(), 0.0, 0.001)


func test_get_defense_modifier_single() -> void:
	_inject_edict(_make_edict(&"fort", -1, false, {}, {&"defense": 0.15}))
	_manager.enact_edict(&"fort")
	assert_almost_eq(_manager.get_defense_modifier(), 0.15, 0.001)


func test_get_defense_modifier_stacks() -> void:
	_inject_edict(_make_edict(&"fort", -1, false, {}, {&"defense": 0.15}))
	_inject_edict(_make_edict(&"wall", -1, false, {}, {&"defense": 0.10}))
	_manager.enact_edict(&"fort")
	_manager.enact_edict(&"wall")
	assert_almost_eq(_manager.get_defense_modifier(), 0.25, 0.001)


func test_get_discovery_bonus_empty() -> void:
	assert_almost_eq(_manager.get_discovery_bonus(), 0.0, 0.001)


func test_get_discovery_bonus_from_edict() -> void:
	var e := _make_edict(&"research")
	e.discovery_bonus = 0.2
	_inject_edict(e)
	_manager.enact_edict(&"research")
	assert_almost_eq(_manager.get_discovery_bonus(), 0.2, 0.001)
