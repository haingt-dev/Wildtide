extends GutTest
## Tests for ScenarioLoader — load and apply ScenarioData to subsystems.

# --- load_scenario ---


func test_load_the_wildtide() -> void:
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_not_null(scenario)
	assert_eq(scenario.scenario_id, &"the_wildtide")
	assert_eq(scenario.display_name, "The Wildtide")


func test_load_nonexistent_returns_null() -> void:
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"nonexistent_xyz")
	assert_null(scenario)


func test_load_has_map_config() -> void:
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_not_null(scenario.map_config)
	assert_eq(scenario.map_config.hex_count, 1750)
	assert_eq(scenario.map_config.rift_count, 3)


func test_load_has_faction_config() -> void:
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_not_null(scenario.faction_config)
	assert_eq(scenario.faction_config.available_factions.size(), 4)


func test_load_has_win_conditions() -> void:
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_eq(scenario.win_conditions.size(), 2)


func test_load_has_era_thresholds() -> void:
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_eq(scenario.era_cycle_thresholds, [1, 6, 11, 16])


# --- apply_scenario ---


func test_apply_null_returns_false() -> void:
	assert_false(ScenarioLoader.apply_scenario(null, {}))


func test_apply_sets_metrics() -> void:
	MetricSystem.reset_to_defaults()
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	ScenarioLoader.apply_scenario(scenario, {})
	assert_almost_eq(MetricSystem.pollution, 0.1, 0.001)
	assert_almost_eq(MetricSystem.anxiety, 0.3, 0.001)
	assert_almost_eq(MetricSystem.solidarity, 0.2, 0.001)
	assert_almost_eq(MetricSystem.harmony, 0.3, 0.001)
	MetricSystem.reset_to_defaults()


func test_apply_sets_economy() -> void:
	var econ := EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	econ._gold = 0
	econ._mana = 0
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	ScenarioLoader.apply_scenario(scenario, {"economy_manager": econ})
	assert_eq(econ._gold, 100)
	assert_eq(econ._mana, 50)
	econ.queue_free()


func test_apply_returns_true() -> void:
	MetricSystem.reset_to_defaults()
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_true(ScenarioLoader.apply_scenario(scenario, {}))
	MetricSystem.reset_to_defaults()


func test_apply_without_economy_succeeds() -> void:
	MetricSystem.reset_to_defaults()
	var scenario: ScenarioData = ScenarioLoader.load_scenario(&"the_wildtide")
	assert_true(ScenarioLoader.apply_scenario(scenario, {}))
	MetricSystem.reset_to_defaults()
