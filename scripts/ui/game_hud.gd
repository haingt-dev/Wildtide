class_name GameHUD
extends CanvasLayer
## Root HUD controller. Manages phase-conditional panel visibility
## and distributes manager references to child panels.

@onready var quest_panel: QuestPanel = %QuestPanel
@onready var wave_warning_panel: WaveWarningPanel = %WaveWarningPanel
@onready var game_over_panel: GameOverPanel = %GameOverPanel


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.game_over.connect(_on_game_over)
	quest_panel.visible = false
	wave_warning_panel.visible = false
	game_over_panel.visible = false


func inject_managers(qmgr: QuestManager, emgr: EdictManager, econ: EconomyManager) -> void:
	quest_panel.quest_manager = qmgr
	var edict_panel: EdictPanel = %EdictPanel
	edict_panel.edict_manager = emgr
	var resource_panel: ResourcePanel = %ResourcePanel
	resource_panel.economy_manager = econ


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	quest_panel.visible = (new_phase == CycleTimer.Phase.INFLUENCE)
	wave_warning_panel.visible = (new_phase == CycleTimer.Phase.WAVE)


func _on_game_over() -> void:
	game_over_panel.visible = true
