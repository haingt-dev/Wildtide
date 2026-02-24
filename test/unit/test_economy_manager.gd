extends GutTest
## Tests for EconomyManager Node.

var _manager: EconomyManager


func before_each() -> void:
	_manager = EconomyManager.new()
	_manager.economy_config = EconomyConfig.new()
	add_child(_manager)


func after_each() -> void:
	_manager.queue_free()
	_disconnect_all(EventBus.rift_shards_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func test_starting_gold() -> void:
	assert_eq(_manager.get_gold(), 100)


func test_starting_mana() -> void:
	assert_eq(_manager.get_mana(), 50)


func test_starting_capacity() -> void:
	assert_eq(_manager.get_gold_capacity(), 100)
	assert_eq(_manager.get_mana_capacity(), 100)


func test_can_afford_true() -> void:
	assert_true(_manager.can_afford(50, 25))


func test_can_afford_false_gold() -> void:
	assert_false(_manager.can_afford(200, 0))


func test_can_afford_false_mana() -> void:
	assert_false(_manager.can_afford(0, 100))


func test_spend_success() -> void:
	assert_true(_manager.spend(30, 20))
	assert_eq(_manager.get_gold(), 70)
	assert_eq(_manager.get_mana(), 30)


func test_spend_failure_no_change() -> void:
	assert_false(_manager.spend(200, 200))
	assert_eq(_manager.get_gold(), 100)
	assert_eq(_manager.get_mana(), 50)


func test_add_gold_clamped() -> void:
	_manager.add_gold(50)
	assert_eq(_manager.get_gold(), 100)  # Clamped to capacity


func test_add_mana_clamped() -> void:
	_manager.add_mana(100)
	assert_eq(_manager.get_mana(), 100)  # Clamped to capacity


func test_update_capacity() -> void:
	_manager.update_capacity(3)
	assert_eq(_manager.get_gold_capacity(), 160)
	assert_eq(_manager.get_mana_capacity(), 160)


func test_update_capacity_then_add() -> void:
	_manager.update_capacity(5)
	_manager.add_gold(200)
	assert_eq(_manager.get_gold(), 200)  # 100 + 5*20 = 200 capacity


func test_set_income_modifiers() -> void:
	_manager.set_income_modifiers(0.3, -0.2)
	assert_almost_eq(_manager._gold_income_modifier, 0.3, 0.001)
	assert_almost_eq(_manager._mana_income_modifier, -0.2, 0.001)


func test_set_transit() -> void:
	_manager.set_transit(true)
	assert_true(_manager._in_transit)
	_manager.set_transit(false)
	assert_false(_manager._in_transit)


func test_gold_changed_signal() -> void:
	var received: Array = []
	EventBus.gold_changed.connect(
		func(new_val: int, old_val: int) -> void: received.append([new_val, old_val])
	)
	_manager.spend(10, 0)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], 90)
	assert_eq(received[0][1], 100)


func test_mana_changed_signal() -> void:
	var received: Array = []
	EventBus.mana_changed.connect(
		func(new_val: int, old_val: int) -> void: received.append([new_val, old_val])
	)
	_manager.spend(0, 10)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], 40)
	assert_eq(received[0][1], 50)


# --- Edict → Economy integration ---


func test_edict_gold_modifier_applied_to_income() -> void:
	var emgr := EdictManager.new()
	add_child(emgr)
	_manager.edict_manager = emgr
	var e := EdictData.new()
	e.edict_id = &"boost"
	e.economy_effects = {&"gold_income": 0.5}
	emgr.edict_registry._data[&"boost"] = e
	emgr.enact_edict(&"boost")
	_manager._sync_edict_modifiers()
	assert_almost_eq(_manager._gold_income_modifier, 0.5, 0.001)
	emgr.queue_free()


func test_edict_mana_modifier_applied_to_income() -> void:
	var emgr := EdictManager.new()
	add_child(emgr)
	_manager.edict_manager = emgr
	var e := EdictData.new()
	e.edict_id = &"magic_boost"
	e.economy_effects = {&"mana_income": 0.3}
	emgr.edict_registry._data[&"magic_boost"] = e
	emgr.enact_edict(&"magic_boost")
	_manager._sync_edict_modifiers()
	assert_almost_eq(_manager._mana_income_modifier, 0.3, 0.001)
	emgr.queue_free()


func test_no_modifier_without_edict_manager() -> void:
	_manager._gold_income_modifier = 0.5
	_manager._sync_edict_modifiers()
	assert_almost_eq(_manager._gold_income_modifier, 0.5, 0.001, "No edict_manager = no change")


# --- Rift Shards ---


func test_rift_shards_initial_zero() -> void:
	assert_eq(_manager.get_rift_shards(), 0)


func test_add_rift_shards() -> void:
	_manager.add_rift_shards(10)
	assert_eq(_manager.get_rift_shards(), 10)


func test_rift_shards_accumulate() -> void:
	_manager.add_rift_shards(5)
	_manager.add_rift_shards(3)
	assert_eq(_manager.get_rift_shards(), 8)


func test_rift_shards_signal_emitted() -> void:
	var received := []
	EventBus.rift_shards_changed.connect(
		func(new_val: int, old_val: int) -> void: received.append([new_val, old_val])
	)
	_manager.add_rift_shards(7)
	assert_eq(received.size(), 1)
	assert_eq(received[0], [7, 0])


func test_add_zero_shards_no_signal() -> void:
	var received := []
	EventBus.rift_shards_changed.connect(
		func(new_val: int, old_val: int) -> void: received.append([new_val, old_val])
	)
	_manager.add_rift_shards(0)
	assert_eq(received.size(), 0, "Zero amount should not emit signal")
