extends GutTest
## Tests for QuestManager quest lifecycle.
## Uses global EventBus and MetricSystem autoloads.

var manager: QuestManager


func before_each() -> void:
	manager = QuestManager.new()
	add_child(manager)
	MetricSystem.reset_to_defaults()


func after_each() -> void:
	manager.queue_free()
	_disconnect_all(EventBus.quest_proposed)
	_disconnect_all(EventBus.quest_approved)
	_disconnect_all(EventBus.quest_rejected)
	_disconnect_all(EventBus.quest_completed)
	_disconnect_all(EventBus.metric_changed)
	_disconnect_all(EventBus.alignment_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Proposal ---


func test_propose_quests_on_influence_phase() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	assert_eq(proposals.size(), 4, "Should propose 1 quest per faction")


func test_proposals_cleared_each_influence() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_eq(manager.get_pending_proposals().size(), 4)
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_eq(manager.get_pending_proposals().size(), 4, "Old proposals replaced")


func test_proposed_quest_emits_signal() -> void:
	var received := []
	EventBus.quest_proposed.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_eq(received.size(), 4, "Should emit 4 quest_proposed signals")


# --- Approval ---


func test_approve_quest_moves_to_active() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var first_id: StringName = proposals[0].quest_id
	var success: bool = manager.approve_quest(first_id)
	assert_true(success)
	assert_eq(manager.get_active_quests().size(), 1)
	assert_eq(manager.get_pending_proposals().size(), 3)


func test_approve_emits_signal() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var received := []
	EventBus.quest_approved.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	manager.approve_quest(proposals[0].quest_id)
	assert_eq(received.size(), 1)


func test_approve_nonexistent_returns_false() -> void:
	var success: bool = manager.approve_quest(&"nonexistent")
	assert_false(success)


# --- Rejection ---


func test_reject_quest_removes_from_pending() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var first_id: StringName = proposals[0].quest_id
	var success: bool = manager.reject_quest(first_id)
	assert_true(success)
	assert_eq(manager.get_pending_proposals().size(), 3)
	assert_eq(manager.get_active_quests().size(), 0)


func test_reject_emits_signal() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var received := []
	EventBus.quest_rejected.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	manager.reject_quest(proposals[0].quest_id)
	assert_eq(received.size(), 1)


# --- Execution (EVOLVE tick) ---


func test_evolve_applies_metric_effects() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var target: QuestData = null
	for p: QuestData in proposals:
		if not p.metric_effects.is_empty():
			target = p
			break
	assert_not_null(target, "Should have at least one quest with metric effects")
	manager.approve_quest(target.quest_id)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var any_changed: bool = false
	for metric_name: StringName in target.metric_effects:
		if MetricSystem.get_metric(metric_name) != 0.0:
			any_changed = true
			break
	assert_true(any_changed, "Metric effects should be applied on EVOLVE")


func test_quest_completes_after_duration() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var target: QuestData = proposals[0]
	manager.approve_quest(target.quest_id)
	for i: int in range(target.duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(manager.get_active_quests().size(), 0, "Quest should complete after duration")


func test_quest_completed_emits_signal() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var target: QuestData = null
	for p: QuestData in proposals:
		if p.duration == 1:
			target = p
			break
	if not target:
		target = proposals[0]
	manager.approve_quest(target.quest_id)
	var received := []
	EventBus.quest_completed.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	for i: int in range(target.duration):
		manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(received.size(), 1, "Should emit quest_completed")


func test_alignment_push_applied() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var target: QuestData = null
	for p: QuestData in proposals:
		if p.alignment_push != 0.0:
			target = p
			break
	assert_not_null(target, "Should have at least one quest with alignment push")
	manager.approve_quest(target.quest_id)
	manager._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	var alignment: float = MetricSystem.get_alignment()
	assert_ne(alignment, 0.0, "Alignment should shift after quest tick")


# --- Edge cases ---


func test_no_action_on_observe_phase() -> void:
	manager._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_eq(manager.get_pending_proposals().size(), 0)
	assert_eq(manager.get_active_quests().size(), 0)


func test_no_action_on_wave_phase() -> void:
	manager._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	assert_eq(manager.get_pending_proposals().size(), 0)
	assert_eq(manager.get_active_quests().size(), 0)


func test_reject_nonexistent_returns_false() -> void:
	var success: bool = manager.reject_quest(&"nonexistent")
	assert_false(success)


# --- Faction Morale ---


func test_morale_initialized_at_default() -> void:
	for faction: FactionData in manager.faction_registry.get_all():
		assert_eq(manager.get_faction_morale(faction.faction_id), 50)


func test_approve_increases_morale() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var target: QuestData = proposals[0]
	manager.approve_quest(target.quest_id)
	assert_eq(manager.get_faction_morale(target.faction_id), 55)


func test_reject_decreases_morale() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var target: QuestData = proposals[0]
	manager.reject_quest(target.quest_id)
	assert_eq(manager.get_faction_morale(target.faction_id), 47)


func test_morale_clamped_at_max() -> void:
	manager._faction_morale[&"lens"] = 98
	manager.push_faction_morale(&"lens", 10)
	assert_eq(manager.get_faction_morale(&"lens"), 100)


func test_morale_clamped_at_min() -> void:
	manager._faction_morale[&"lens"] = 2
	manager.push_faction_morale(&"lens", -10)
	assert_eq(manager.get_faction_morale(&"lens"), 0)


func test_morale_change_emits_signal() -> void:
	var received := []
	EventBus.faction_morale_changed.connect(
		func(f: StringName, nv: int, ov: int) -> void: received.append([f, nv, ov])
	)
	manager.push_faction_morale(&"lens", 10)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], &"lens")
	assert_eq(received[0][1], 60)
	assert_eq(received[0][2], 50)
