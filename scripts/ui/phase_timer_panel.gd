class_name PhaseTimerPanel
extends PanelContainer
## Displays current phase, cycle number, era, and phase progress bar.

var _progress_timer: Timer

@onready var phase_label: Label = %PhaseLabel
@onready var cycle_label: Label = %CycleLabel
@onready var era_label: Label = %EraLabel
@onready var progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.cycle_started.connect(_on_cycle_started)
	_progress_timer = Timer.new()
	_progress_timer.wait_time = 0.1
	_progress_timer.timeout.connect(_on_progress_tick)
	add_child(_progress_timer)
	_init_from_current_state()


func _on_phase_changed(_new_phase: int, phase_name: StringName) -> void:
	phase_label.text = phase_name.capitalize()
	progress_bar.value = 0.0
	era_label.text = "Era %d" % GameManager.get_current_era()
	if GameManager.is_running and not GameManager.is_paused:
		_progress_timer.start()
	else:
		_progress_timer.stop()


func _on_cycle_started(cycle_number: int) -> void:
	cycle_label.text = "Cycle %d" % cycle_number
	era_label.text = "Era %d" % GameManager.get_current_era()


func _on_progress_tick() -> void:
	progress_bar.value = GameManager.get_phase_progress()


func _init_from_current_state() -> void:
	if GameManager.is_running:
		var phase_name: StringName = GameManager.cycle_timer.get_phase_name(
			GameManager.current_phase
		)
		phase_label.text = phase_name.capitalize()
		cycle_label.text = "Cycle %d" % GameManager.cycle_number
		era_label.text = "Era %d" % GameManager.get_current_era()
		progress_bar.value = GameManager.get_phase_progress()
		if not GameManager.is_paused:
			_progress_timer.start()
	else:
		phase_label.text = "---"
		cycle_label.text = "Cycle 0"
		era_label.text = "Era 1"
		progress_bar.value = 0.0
