extends GutTest
## Tests for StabilityPanel — stability meter + alert colors.

var panel: StabilityPanel


func before_each() -> void:
	panel = preload("res://scenes/ui/stability_panel.tscn").instantiate() as StabilityPanel
	add_child(panel)


func after_each() -> void:
	panel.queue_free()
	_disconnect_all(EventBus.stability_changed)
	_disconnect_all(EventBus.alert_level_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_stability_bar_updates_on_signal() -> void:
	EventBus.stability_changed.emit(75, 100)
	assert_eq(panel.stability_bar.value, 75.0)


func test_stability_label_updates() -> void:
	EventBus.stability_changed.emit(42, 100)
	assert_eq(panel.stability_label.text, "Stability: 42")


func test_alert_color_normal() -> void:
	EventBus.alert_level_changed.emit(&"normal")
	assert_eq(panel.alert_label.text, "Normal")


func test_alert_color_yellow() -> void:
	EventBus.alert_level_changed.emit(&"yellow")
	assert_eq(panel.alert_label.text, "Yellow")


func test_alert_color_red() -> void:
	EventBus.alert_level_changed.emit(&"red")
	assert_eq(panel.alert_label.text, "Red")


func test_alert_color_final() -> void:
	EventBus.alert_level_changed.emit(&"final")
	assert_eq(panel.alert_label.text, "Final")


func test_initial_state() -> void:
	assert_eq(panel.stability_bar.value, 100.0)
	assert_eq(panel.stability_label.text, "Stability: 100")


func test_low_stability() -> void:
	EventBus.stability_changed.emit(5, 100)
	assert_eq(panel.stability_bar.value, 5.0)
