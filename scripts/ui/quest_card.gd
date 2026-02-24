class_name QuestCard
extends PanelContainer
## Single quest proposal card with approve/reject buttons.

signal approved
signal rejected

var quest_id: StringName = &""

@onready var faction_label: Label = %FactionLabel
@onready var quest_name_label: Label = %QuestNameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var duration_label: Label = %DurationLabel
@onready var effects_label: Label = %EffectsLabel
@onready var approve_button: Button = %ApproveButton
@onready var reject_button: Button = %RejectButton


func _ready() -> void:
	approve_button.pressed.connect(func() -> void: approved.emit())
	reject_button.pressed.connect(func() -> void: rejected.emit())


func setup(quest_data: QuestData) -> void:
	quest_id = quest_data.quest_id
	faction_label.text = quest_data.faction_id.replace("_", " ").capitalize()
	quest_name_label.text = quest_data.display_name
	description_label.text = quest_data.description
	duration_label.text = "%d cycle(s)" % quest_data.duration
	effects_label.text = _format_effects(quest_data)


func _format_effects(quest_data: QuestData) -> String:
	var parts: Array[String] = []
	for metric_name: StringName in quest_data.metric_effects:
		var delta: float = quest_data.metric_effects[metric_name]
		var sign: String = "+" if delta > 0.0 else ""
		parts.append("%s %s%.2f/cycle" % [metric_name.capitalize(), sign, delta])
	if quest_data.alignment_push != 0.0:
		var dir: String = "Science" if quest_data.alignment_push > 0.0 else "Magic"
		parts.append("Alignment: %s" % dir)
	if parts.is_empty():
		return "No effects"
	return ", ".join(parts)
