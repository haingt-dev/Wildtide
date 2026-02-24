extends GutTest
## Tests for GameHUD — root HUD controller and phase visibility.

const GAME_HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")

var hud: GameHUD


func before_each() -> void:
	hud = GAME_HUD_SCENE.instantiate() as GameHUD
	add_child(hud)


func after_each() -> void:
	hud.queue_free()
	_disconnect_all(EventBus.phase_changed)
	_disconnect_all(EventBus.game_over)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_quest_panel_hidden_on_observe() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.OBSERVE, &"observe")
	assert_false(hud.quest_panel.visible)


func test_quest_panel_visible_on_influence() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_true(hud.quest_panel.visible)


func test_wave_panel_visible_on_wave() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.WAVE, &"wave")
	assert_true(hud.wave_warning_panel.visible)


func test_wave_panel_hidden_on_evolve() -> void:
	EventBus.phase_changed.emit(CycleTimer.Phase.WAVE, &"wave")
	EventBus.phase_changed.emit(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_false(hud.wave_warning_panel.visible)


func test_game_over_visible_on_signal() -> void:
	EventBus.game_over.emit()
	assert_true(hud.game_over_panel.visible)


func test_game_over_hidden_initially() -> void:
	assert_false(hud.game_over_panel.visible)
