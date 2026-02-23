extends GutTest
## Tests for EconomyConfig Resource.


func test_default_starting_gold() -> void:
	var cfg := EconomyConfig.new()
	assert_eq(cfg.starting_gold, 100)


func test_default_starting_mana() -> void:
	var cfg := EconomyConfig.new()
	assert_eq(cfg.starting_mana, 50)


func test_default_capacities() -> void:
	var cfg := EconomyConfig.new()
	assert_eq(cfg.starting_gold_capacity, 100)
	assert_eq(cfg.starting_mana_capacity, 100)


func test_capacity_per_storage() -> void:
	var cfg := EconomyConfig.new()
	assert_eq(cfg.capacity_per_storage, 20)


func test_base_yields() -> void:
	var cfg := EconomyConfig.new()
	assert_almost_eq(cfg.base_gold_yield, 1.0, 0.001)
	assert_almost_eq(cfg.base_mana_yield, 1.0, 0.001)


func test_transit_modifier() -> void:
	var cfg := EconomyConfig.new()
	assert_almost_eq(cfg.transit_modifier, 0.5, 0.001)


func test_scar_modifier() -> void:
	var cfg := EconomyConfig.new()
	assert_almost_eq(cfg.scar_modifier, 0.8, 0.001)


func test_migration_cost_fraction() -> void:
	var cfg := EconomyConfig.new()
	assert_almost_eq(cfg.migration_cost_fraction, 0.7, 0.001)


func test_summon_tide_cost_fraction() -> void:
	var cfg := EconomyConfig.new()
	assert_almost_eq(cfg.summon_tide_cost_fraction, 0.5, 0.001)


func test_required_fragments() -> void:
	var cfg := EconomyConfig.new()
	assert_eq(cfg.required_fragments, 15)


func test_custom_values() -> void:
	var cfg := EconomyConfig.new()
	cfg.starting_gold = 200
	cfg.starting_mana = 100
	cfg.capacity_per_storage = 30
	cfg.transit_modifier = 0.3
	assert_eq(cfg.starting_gold, 200)
	assert_eq(cfg.starting_mana, 100)
	assert_eq(cfg.capacity_per_storage, 30)
	assert_almost_eq(cfg.transit_modifier, 0.3, 0.001)
