class_name SpeedControls
extends HBoxContainer
## Game speed buttons (1x/2x/3x) and pause toggle.

var _speed_buttons: Array[Button] = []

@onready var speed_1_button: Button = %Speed1Button
@onready var speed_2_button: Button = %Speed2Button
@onready var speed_3_button: Button = %Speed3Button
@onready var pause_button: Button = %PauseButton


func _ready() -> void:
	_speed_buttons = [speed_1_button, speed_2_button, speed_3_button]
	speed_1_button.pressed.connect(_on_speed_pressed.bind(1))
	speed_2_button.pressed.connect(_on_speed_pressed.bind(2))
	speed_3_button.pressed.connect(_on_speed_pressed.bind(3))
	pause_button.pressed.connect(_on_pause_pressed)
	EventBus.game_speed_changed.connect(_on_speed_changed)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	_update_speed_highlight(GameManager.game_speed)
	_update_pause_label()


func _on_speed_pressed(speed: int) -> void:
	GameManager.set_game_speed(speed)


func _on_pause_pressed() -> void:
	if GameManager.is_paused:
		GameManager.resume_game()
	else:
		GameManager.pause_game()


func _on_speed_changed(new_speed: int) -> void:
	_update_speed_highlight(new_speed)


func _on_game_paused() -> void:
	_update_pause_label()


func _on_game_resumed() -> void:
	_update_pause_label()


func _update_speed_highlight(speed: int) -> void:
	for i: int in range(_speed_buttons.size()):
		var btn: Button = _speed_buttons[i]
		btn.disabled = (i + 1 == speed)


func _update_pause_label() -> void:
	pause_button.text = "Play" if GameManager.is_paused else "Pause"
