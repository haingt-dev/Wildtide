extends GutTest
## Tests for MetricsPanel — 4 metric bars + alignment slider.

const METRICS_PANEL_SCENE: PackedScene = preload("res://scenes/ui/metrics_panel.tscn")

var panel: MetricsPanel


func before_each() -> void:
	MetricSystem.reset_to_defaults()
	panel = METRICS_PANEL_SCENE.instantiate() as MetricsPanel
	add_child(panel)


func after_each() -> void:
	panel.queue_free()
	MetricSystem.reset_to_defaults()
	_disconnect_all(EventBus.metric_changed)
	_disconnect_all(EventBus.alignment_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_pollution_bar_updates_on_signal() -> void:
	EventBus.metric_changed.emit(&"pollution", 0.75, 0.0)
	assert_almost_eq(panel.pollution_bar.value, 0.75, 0.01)


func test_anxiety_bar_updates_on_signal() -> void:
	EventBus.metric_changed.emit(&"anxiety", 0.5, 0.0)
	assert_almost_eq(panel.anxiety_bar.value, 0.5, 0.01)


func test_solidarity_bar_updates_on_signal() -> void:
	EventBus.metric_changed.emit(&"solidarity", 0.3, 0.0)
	assert_almost_eq(panel.solidarity_bar.value, 0.3, 0.01)


func test_harmony_bar_updates_on_signal() -> void:
	EventBus.metric_changed.emit(&"harmony", 0.9, 0.0)
	assert_almost_eq(panel.harmony_bar.value, 0.9, 0.01)


func test_alignment_slider_updates() -> void:
	EventBus.alignment_changed.emit(0.6)
	assert_almost_eq(panel.alignment_slider.value, 0.6, 0.01)


func test_alignment_slider_negative() -> void:
	EventBus.alignment_changed.emit(-0.4)
	assert_almost_eq(panel.alignment_slider.value, -0.4, 0.01)


func test_pollution_label_shows_percentage() -> void:
	EventBus.metric_changed.emit(&"pollution", 0.75, 0.0)
	assert_eq(panel.pollution_label.text, "Pollution: 75%")


func test_init_from_current_state() -> void:
	MetricSystem.set_metric(&"harmony", 0.8)
	var p2: MetricsPanel = METRICS_PANEL_SCENE.instantiate()
	add_child(p2)
	assert_almost_eq(p2.harmony_bar.value, 0.8, 0.01)
	p2.queue_free()
