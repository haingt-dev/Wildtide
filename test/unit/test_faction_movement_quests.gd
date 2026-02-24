extends GutTest
## Tests for faction movement quest proposals in QuestManager.

var qm: QuestManager


func before_each() -> void:
	qm = QuestManager.new()
	add_child(qm)


func after_each() -> void:
	qm.queue_free()
	_disconnect_all(EventBus.quest_proposed)
	_disconnect_all(EventBus.quest_approved)
	_disconnect_all(EventBus.quest_rejected)
	_disconnect_all(EventBus.movement_proposed)
	_disconnect_all(EventBus.faction_morale_changed)
	_disconnect_all(EventBus.migration_requested)
	_disconnect_all(EventBus.city_moved)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Movement quest proposals ---


func test_no_movement_quests_when_migration_inactive() -> void:
	qm._propose_quests()
	for quest_id: StringName in qm._pending_proposals:
		var qdata: QuestData = qm._pending_proposals[quest_id]
		assert_false(qdata.is_movement_proposal, "No movement proposals without migration")


func test_movement_quests_proposed_when_migration_active() -> void:
	qm._migration_active = true
	qm._propose_quests()
	var move_count: int = 0
	for quest_id: StringName in qm._pending_proposals:
		var qdata: QuestData = qm._pending_proposals[quest_id]
		if qdata.is_movement_proposal:
			move_count += 1
	assert_gt(move_count, 0, "Should propose movement quests during migration")


func test_approve_movement_quest_emits_movement_proposed() -> void:
	var received := []
	EventBus.movement_proposed.connect(func(dir: Vector3i) -> void: received.append(dir))
	# Create a movement proposal manually
	var qd := QuestData.new()
	qd.quest_id = &"move_lens"
	qd.faction_id = &"lens"
	qd.is_movement_proposal = true
	qd.proposed_direction = Vector3i(1, -1, 0)
	qd.duration = 1
	qm._pending_proposals[&"move_lens"] = qd
	var success: bool = qm.approve_quest(&"move_lens")
	assert_true(success)
	assert_eq(received.size(), 1)
	assert_eq(received[0], Vector3i(1, -1, 0))


func test_approve_movement_quest_gives_morale() -> void:
	var qd := QuestData.new()
	qd.quest_id = &"move_wall"
	qd.faction_id = &"wall"
	qd.is_movement_proposal = true
	qd.proposed_direction = Vector3i(0, 1, -1)
	qd.duration = 1
	qm._pending_proposals[&"move_wall"] = qd
	var before: int = qm.get_faction_morale(&"wall")
	qm.approve_quest(&"move_wall")
	var after: int = qm.get_faction_morale(&"wall")
	assert_eq(after - before, QuestManager.MORALE_ON_APPROVE)


func test_migration_flag_reset_on_city_moved() -> void:
	qm._migration_active = true
	EventBus.city_moved.emit(Vector3i.ZERO, Vector3i(1, -1, 0))
	assert_false(qm._migration_active, "Should deactivate after city moves")


func test_migration_flag_set_on_migration_requested() -> void:
	assert_false(qm._migration_active)
	EventBus.migration_requested.emit()
	assert_true(qm._migration_active, "Should activate on migration request")
