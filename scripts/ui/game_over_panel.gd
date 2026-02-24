class_name GameOverPanel
extends ColorRect
## Full-screen overlay shown when stability reaches zero.

@onready var title_label: Label = %TitleLabel
@onready var message_label: Label = %MessageLabel


func _ready() -> void:
	EventBus.game_over.connect(_on_game_over)
	color = Color(0.0, 0.0, 0.0, 0.7)
	visible = false


func _on_game_over() -> void:
	visible = true
	title_label.text = "CITY COLLAPSED"
	message_label.text = "Stability reached zero. The factions have abandoned the settlement."
	GameManager.pause_game()
