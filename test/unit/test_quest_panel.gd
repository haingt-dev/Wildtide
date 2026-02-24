extends GutTest
## Tests for QuestPanel — quest proposal display and approve/reject.

const QUEST_PANEL_SCENE: PackedScene = preload("res://scenes/ui/quest_panel.tscn")

var panel: QuestPanel
var qmgr: QuestManager


func before_each() -> void:
	qmgr = QuestManager.new()
	add_child(qmgr)
	panel = QUEST_PANEL_SCENE.instantiate() as QuestPanel
	panel.quest_manager = qmgr
	add_child(panel)


func after_each() -> void:
	panel.queue_free()
	qmgr.queue_free()
	_disconnect_all(EventBus.phase_changed)
	_disconnect_all(EventBus.quest_proposed)
	_disconnect_all(EventBus.quest_approved)
	_disconnect_all(EventBus.quest_rejected)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_populates_on_influence_phase() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals: Array[QuestData] = qmgr.get_pending_proposals()
	var card_count: int = panel.card_container.get_child_count()
	assert_eq(card_count, proposals.size(), "Should create one card per proposal")


func test_clears_on_observe_phase() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.INFLUENCE, &"influence")
	EventBus.phase_changed.emit(CycleTimer.Phase.OBSERVE, &"observe")
	await get_tree().process_frame
	assert_eq(panel.card_container.get_child_count(), 0, "Cards cleared on phase change")


func test_approve_calls_quest_manager() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals: Array[QuestData] = qmgr.get_pending_proposals()
	if proposals.is_empty():
		pass_test("No proposals to test")
		return
	var qid: StringName = proposals[0].quest_id
	var received := []
	EventBus.quest_approved.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	panel._on_quest_approved(qid)
	assert_eq(received.size(), 1, "Quest should be approved via manager")


func test_reject_calls_quest_manager() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals: Array[QuestData] = qmgr.get_pending_proposals()
	if proposals.is_empty():
		pass_test("No proposals to test")
		return
	var qid: StringName = proposals[0].quest_id
	var received := []
	EventBus.quest_rejected.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	panel._on_quest_rejected(qid)
	assert_eq(received.size(), 1, "Quest should be rejected via manager")


func test_works_without_quest_manager() -> void:
	panel.quest_manager = null
	EventBus.phase_changed.emit(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_eq(panel.card_container.get_child_count(), 0)
