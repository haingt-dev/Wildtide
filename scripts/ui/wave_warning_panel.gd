class_name WaveWarningPanel
extends PanelContainer
## Overlay shown during WAVE phase with wave number.

var _hide_timer: Timer

@onready var warning_label: Label = %WarningLabel
@onready var wave_number_label: Label = %WaveNumberLabel


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_ended.connect(_on_wave_ended)
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = 2.0
	_hide_timer.timeout.connect(func() -> void: visible = false)
	add_child(_hide_timer)
	visible = false


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.WAVE:
		visible = true
		warning_label.text = "THE WAVE APPROACHES"
		wave_number_label.text = ""
		_hide_timer.stop()
	else:
		if _hide_timer.is_stopped():
			visible = false


func _on_wave_started(wave_number: int) -> void:
	visible = true
	warning_label.text = "WAVE IN PROGRESS"
	wave_number_label.text = "Wave %d" % wave_number
	_hide_timer.stop()


func _on_wave_ended(_wave_number: int) -> void:
	warning_label.text = "Wave Survived"
	_hide_timer.start()
