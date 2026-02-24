extends GutTest
## Tests for migration triggers, mandate migration, and salvage shard deposit.

var mm: MovementManager
var em: EdictManager
var eco: EconomyManager
var grid: HexGrid


func before_each() -> void:
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	eco = EconomyManager.new()
	add_child(eco)
	em = EdictManager.new()
	add_child(em)
	mm = MovementManager.new()
	add_child(mm)
	mm.hex_grid = grid
	mm.economy_manager = eco
	mm.edict_manager = em


func after_each() -> void:
	mm.queue_free()
	em.queue_free()
	eco.queue_free()
	_disconnect_all(EventBus.migration_requested)
	_disconnect_all(EventBus.transit_started)
	_disconnect_all(EventBus.transit_ended)
	_disconnect_all(EventBus.rift_shards_changed)
	_disconnect_all(EventBus.city_moved)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Migration edict trigger ---


func test_migration_edict_emits_signal() -> void:
	var received := []
	EventBus.migration_requested.connect(func() -> void: received.append(true))
	var edata := EdictData.new()
	edata.edict_id = &"migration"
	edata.duration = 1
	edata.is_free_action = true
	em.edict_registry._data[&"migration"] = edata
	em.enact_edict(&"migration")
	assert_eq(received.size(), 1)


func test_migration_signal_sets_awaiting() -> void:
	EventBus.migration_requested.emit()
	assert_true(mm.awaiting_direction)


# --- Mandate migration ---


func test_mandate_migration_costs_resources() -> void:
	EventBus.migration_requested.emit()
	var gold_before: int = eco.get_gold()
	var mana_before: int = eco.get_mana()
	mm.execute_mandate_migration(Vector3i(1, -1, 0))
	assert_lt(eco.get_gold(), gold_before, "Should spend gold")
	assert_lt(eco.get_mana(), mana_before, "Should spend mana")


func test_mandate_migration_moves_city() -> void:
	EventBus.migration_requested.emit()
	var old_center: Vector3i = mm.city_center
	mm.execute_mandate_migration(Vector3i(1, -1, 0))
	assert_ne(mm.city_center, old_center)
	assert_true(mm.is_in_transit)


func test_mandate_migration_fails_without_awaiting() -> void:
	assert_false(mm.execute_mandate_migration(Vector3i(1, -1, 0)))


func test_mandate_migration_clears_awaiting() -> void:
	EventBus.migration_requested.emit()
	mm.execute_mandate_migration(Vector3i(1, -1, 0))
	assert_false(mm.awaiting_direction)


# --- Mandate cooldown ---


func test_can_mandate_once_per_era() -> void:
	assert_true(em.can_mandate_migration())
	em.use_mandate_migration()
	assert_false(em.can_mandate_migration(), "Used this era")


func test_mandate_resets_on_new_era() -> void:
	GameManager.cycle_number = 1
	em.use_mandate_migration()
	assert_false(em.can_mandate_migration())
	GameManager.cycle_number = 6  # Era 2
	assert_true(em.can_mandate_migration(), "New era should allow mandate")
	GameManager.cycle_number = 0


# --- Salvage shard deposit ---


func test_end_transit_deposits_shards() -> void:
	mm._last_salvage_yield = 5
	mm.is_in_transit = true
	mm.transit_cycles_remaining = 1
	mm.end_transit()
	assert_eq(eco.get_rift_shards(), 5)
