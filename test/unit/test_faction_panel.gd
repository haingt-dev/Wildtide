extends GutTest
## Tests for FactionPanel — 4 faction morale bars.

var panel: FactionPanel


func before_each() -> void:
	panel = preload("res://scenes/ui/faction_panel.tscn").instantiate() as FactionPanel
	add_child(panel)


func after_each() -> void:
	panel.queue_free()
	_disconnect_all(EventBus.faction_morale_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_lens_morale_updates() -> void:
	EventBus.faction_morale_changed.emit(&"the_lens", 75, 50)
	assert_eq(panel.lens_bar.value, 75.0)


func test_veil_morale_updates() -> void:
	EventBus.faction_morale_changed.emit(&"the_veil", 30, 50)
	assert_eq(panel.veil_bar.value, 30.0)


func test_coin_morale_updates() -> void:
	EventBus.faction_morale_changed.emit(&"the_coin", 90, 50)
	assert_eq(panel.coin_bar.value, 90.0)


func test_wall_morale_updates() -> void:
	EventBus.faction_morale_changed.emit(&"the_wall", 10, 50)
	assert_eq(panel.wall_bar.value, 10.0)


func test_label_updates_with_display_name() -> void:
	EventBus.faction_morale_changed.emit(&"the_lens", 80, 50)
	assert_eq(panel.lens_label.text, "The Lens: 80")


func test_initial_morale_is_50() -> void:
	assert_eq(panel.lens_bar.value, 50.0)
	assert_eq(panel.veil_bar.value, 50.0)
	assert_eq(panel.coin_bar.value, 50.0)
	assert_eq(panel.wall_bar.value, 50.0)
