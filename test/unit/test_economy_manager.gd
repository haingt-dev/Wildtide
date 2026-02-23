extends GutTest
## Tests for EconomyManager Node.

var _manager: EconomyManager


func before_each() -> void:
	_manager = EconomyManager.new()
	_manager.economy_config = EconomyConfig.new()
	add_child(_manager)


func after_each() -> void:
	_manager.queue_free()


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
