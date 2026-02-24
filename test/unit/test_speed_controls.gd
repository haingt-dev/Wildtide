extends GutTest
## Tests for SpeedControls — game speed buttons and pause toggle.

var panel: SpeedControls


func before_each() -> void:
	GameManager.game_speed = 1
	GameManager.is_paused = false
	GameManager.is_running = true
	panel = preload("res://scenes/ui/speed_controls.tscn").instantiate() as SpeedControls
	add_child(panel)


func after_each() -> void:
	panel.queue_free()
	GameManager.game_speed = 1
	GameManager.is_paused = false
	GameManager.is_running = false
	_disconnect_all(EventBus.game_speed_changed)
	_disconnect_all(EventBus.game_paused)
	_disconnect_all(EventBus.game_resumed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_speed_1_button_disabled_initially() -> void:
	assert_true(panel.speed_1_button.disabled, "1x should be disabled (active)")
	assert_false(panel.speed_2_button.disabled)
	assert_false(panel.speed_3_button.disabled)


func test_speed_highlight_updates_on_signal() -> void:
	EventBus.game_speed_changed.emit(2)
	assert_false(panel.speed_1_button.disabled)
	assert_true(panel.speed_2_button.disabled, "2x should be disabled (active)")
	assert_false(panel.speed_3_button.disabled)


func test_pause_label_shows_pause() -> void:
	assert_eq(panel.pause_button.text, "Pause")


func test_pause_label_updates_on_paused() -> void:
	GameManager.is_paused = true
	EventBus.game_paused.emit()
	assert_eq(panel.pause_button.text, "Play")


func test_pause_label_updates_on_resumed() -> void:
	EventBus.game_paused.emit()
	EventBus.game_resumed.emit()
	assert_eq(panel.pause_button.text, "Pause")


func test_speed_3_highlight() -> void:
	EventBus.game_speed_changed.emit(3)
	assert_true(panel.speed_3_button.disabled, "3x should be disabled (active)")
	assert_false(panel.speed_1_button.disabled)
	assert_false(panel.speed_2_button.disabled)


func test_speed_button_calls_game_manager() -> void:
	panel._on_speed_pressed(2)
	assert_eq(GameManager.game_speed, 2)


func test_pause_toggle_calls_game_manager() -> void:
	panel._on_pause_pressed()
	assert_true(GameManager.is_paused)
