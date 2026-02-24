class_name QuestPanel
extends PanelContainer
## Shows pending quest proposals during INFLUENCE phase.
## Player can approve or reject each quest.

const QUEST_CARD_SCENE_PATH: String = "res://scenes/ui/quest_card.tscn"

var quest_manager: QuestManager
var _quest_card_scene: PackedScene

@onready var title_label: Label = %TitleLabel
@onready var card_container: VBoxContainer = %CardContainer


func _ready() -> void:
	_quest_card_scene = load(QUEST_CARD_SCENE_PATH) as PackedScene
	EventBus.phase_changed.connect(_on_phase_changed)
	title_label.text = "Quest Proposals"


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.INFLUENCE:
		_populate_proposals()
	else:
		_clear_cards()


func _populate_proposals() -> void:
	_clear_cards()
	if not quest_manager:
		return
	var proposals: Array[QuestData] = quest_manager.get_pending_proposals()
	for quest_data: QuestData in proposals:
		var card: QuestCard
		if _quest_card_scene:
			card = _quest_card_scene.instantiate() as QuestCard
		else:
			card = QuestCard.new()
		card_container.add_child(card)
		card.setup(quest_data)
		card.approved.connect(_on_quest_approved.bind(quest_data.quest_id))
		card.rejected.connect(_on_quest_rejected.bind(quest_data.quest_id))


func _on_quest_approved(qid: StringName) -> void:
	if quest_manager:
		quest_manager.approve_quest(qid)
	_remove_card(qid)


func _on_quest_rejected(qid: StringName) -> void:
	if quest_manager:
		quest_manager.reject_quest(qid)
	_remove_card(qid)


func _remove_card(qid: StringName) -> void:
	for child: Node in card_container.get_children():
		var card := child as QuestCard
		if card and card.quest_id == qid:
			card.queue_free()
			break


func _clear_cards() -> void:
	for child: Node in card_container.get_children():
		child.queue_free()
