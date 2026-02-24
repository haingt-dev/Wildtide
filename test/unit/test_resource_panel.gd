extends GutTest
## Tests for ResourcePanel — gold/mana counters with capacity.

const RESOURCE_PANEL_SCENE: PackedScene = preload("res://scenes/ui/resource_panel.tscn")

var panel: ResourcePanel
var econ: EconomyManager


func before_each() -> void:
	econ = EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	panel = RESOURCE_PANEL_SCENE.instantiate() as ResourcePanel
	panel.economy_manager = econ
	add_child(panel)


func after_each() -> void:
	panel.queue_free()
	econ.queue_free()
	_disconnect_all(EventBus.gold_changed)
	_disconnect_all(EventBus.mana_changed)
	_disconnect_all(EventBus.phase_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_gold_updates_on_signal() -> void:
	EventBus.gold_changed.emit(75, 100)
	assert_eq(panel.gold_label.text, "Gold: 75 / 100")


func test_mana_updates_on_signal() -> void:
	EventBus.mana_changed.emit(30, 50)
	assert_eq(panel.mana_label.text, "Mana: 30 / 100")


func test_gold_bar_value_matches() -> void:
	EventBus.gold_changed.emit(50, 100)
	assert_almost_eq(panel.gold_bar.value, 50.0, 0.1)


func test_init_with_economy_manager() -> void:
	var p2: ResourcePanel = RESOURCE_PANEL_SCENE.instantiate()
	p2.economy_manager = econ
	add_child(p2)
	assert_eq(p2.gold_label.text, "Gold: %d / %d" % [econ.get_gold(), econ.get_gold_capacity()])
	p2.queue_free()


func test_works_without_economy_manager() -> void:
	var p2: ResourcePanel = RESOURCE_PANEL_SCENE.instantiate()
	add_child(p2)
	assert_eq(p2.gold_label.text, "Gold: 0 / 100")
	p2.queue_free()


func test_mana_bar_max_matches_capacity() -> void:
	EventBus.mana_changed.emit(30, 50)
	assert_almost_eq(panel.mana_bar.max_value, float(econ.get_mana_capacity()), 0.1)
