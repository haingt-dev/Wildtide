class_name EdictPanel
extends PanelContainer
## Display-only panel showing active edict slots (max 2).

var edict_manager: EdictManager
var _slot_labels: Array[Label] = []
var _slot_durations: Array[Label] = []

@onready var slot1_label: Label = %Slot1Label
@onready var slot1_duration: Label = %Slot1Duration
@onready var slot2_label: Label = %Slot2Label
@onready var slot2_duration: Label = %Slot2Duration


func _ready() -> void:
	_slot_labels = [slot1_label, slot2_label]
	_slot_durations = [slot1_duration, slot2_duration]
	EventBus.edict_enacted.connect(_on_edict_changed)
	EventBus.edict_revoked.connect(_on_edict_changed)
	EventBus.edict_expired.connect(_on_edict_changed)
	_refresh_slots()


func _on_edict_changed(_edict_id: StringName) -> void:
	_refresh_slots()


func _refresh_slots() -> void:
	if not edict_manager:
		for i: int in range(2):
			_slot_labels[i].text = "[Empty]"
			_slot_durations[i].text = ""
		return
	var active_ids: Array[StringName] = edict_manager.get_active_edict_ids()
	for i: int in range(2):
		if i < active_ids.size():
			var edata: EdictData = edict_manager.get_active_edict(active_ids[i])
			_slot_labels[i].text = edata.display_name if edata else "???"
			var remaining: int = edict_manager.get_remaining(active_ids[i])
			if remaining < 0:
				_slot_durations[i].text = "Permanent"
			else:
				_slot_durations[i].text = "%d cycle(s)" % remaining
		else:
			_slot_labels[i].text = "[Empty]"
			_slot_durations[i].text = ""
