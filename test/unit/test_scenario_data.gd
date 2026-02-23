extends GutTest
## Tests for ScenarioData and its sub-resources.

# --- MapPreset ---


func test_map_preset_defaults() -> void:
	var mp := MapPreset.new()
	assert_eq(mp.seed_strategy, MapPreset.SeedStrategy.RANDOM)
	assert_eq(mp.hex_count, 1750)
	assert_eq(mp.region_count, 4)
	assert_eq(mp.rift_count, 3)
	assert_eq(mp.rift_placement, MapPreset.RiftPlacement.TRIANGLE)


func test_map_preset_biome_distribution() -> void:
	var mp := MapPreset.new()
	assert_eq(mp.biome_distribution.size(), 5)
	assert_almost_eq(mp.biome_distribution[&"plains"] as float, 0.35, 0.001)


func test_map_preset_enums() -> void:
	assert_eq(MapPreset.SeedStrategy.FIXED, 0)
	assert_eq(MapPreset.SeedStrategy.RANDOM, 1)
	assert_eq(MapPreset.RegionLayout.LINEAR, 0)
	assert_eq(MapPreset.RegionLayout.RADIAL, 1)
	assert_eq(MapPreset.RiftPlacement.TRIANGLE, 0)
	assert_eq(MapPreset.RiftPlacement.RANDOM, 1)
	assert_eq(MapPreset.RiftPlacement.FIXED_POSITIONS, 2)


# --- FactionConfig ---


func test_faction_config_defaults() -> void:
	var fc := FactionConfig.new()
	assert_eq(fc.available_factions.size(), 4)
	assert_has(fc.available_factions, &"lens")
	assert_has(fc.available_factions, &"wall")
	assert_almost_eq(fc.alignment_start, 0.0, 0.001)


func test_faction_config_morale() -> void:
	var fc := FactionConfig.new()
	assert_eq(fc.starting_morale[&"lens"], 50)
	assert_eq(fc.starting_morale[&"coin"], 50)


func test_faction_config_custom() -> void:
	var fc := FactionConfig.new()
	fc.available_factions = [&"wall", &"coin"]
	fc.alignment_start = 0.5
	assert_eq(fc.available_factions.size(), 2)
	assert_almost_eq(fc.alignment_start, 0.5, 0.001)


# --- WinConditionData ---


func test_win_condition_defaults() -> void:
	var wc := WinConditionData.new()
	assert_eq(wc.type, WinConditionData.WinConditionType.SCIENCE_WIN)
	assert_almost_eq(wc.required_alignment, 0.8, 0.001)
	assert_eq(wc.required_fragments, 15)
	assert_eq(wc.required_era, 3)
	assert_true(wc.requires_rift_core)
	assert_eq(wc.artifact_construction_cycles, 3)


func test_win_condition_type_enum() -> void:
	assert_eq(WinConditionData.WinConditionType.SCIENCE_WIN, 0)
	assert_eq(WinConditionData.WinConditionType.MAGIC_WIN, 1)
	assert_eq(WinConditionData.WinConditionType.RIFT_SEAL, 2)
	assert_eq(WinConditionData.WinConditionType.SURVIVAL, 3)
	assert_eq(WinConditionData.WinConditionType.CUSTOM, 4)


func test_magic_win_condition() -> void:
	var wc := WinConditionData.new()
	wc.type = WinConditionData.WinConditionType.MAGIC_WIN
	wc.required_alignment = 0.8
	wc.required_fragments = 15
	assert_eq(wc.type, WinConditionData.WinConditionType.MAGIC_WIN)


# --- ScenarioData ---


func test_scenario_data_defaults() -> void:
	var sd := ScenarioData.new()
	assert_eq(sd.starting_gold, 100)
	assert_eq(sd.starting_mana, 50)
	assert_eq(sd.era_cycle_thresholds.size(), 4)


func test_scenario_data_starting_metrics() -> void:
	var sd := ScenarioData.new()
	assert_almost_eq(sd.starting_metrics[&"pollution"] as float, 0.1, 0.001)
	assert_almost_eq(sd.starting_metrics[&"anxiety"] as float, 0.3, 0.001)


func test_scenario_data_with_sub_resources() -> void:
	var sd := ScenarioData.new()
	sd.scenario_id = &"test_scenario"
	sd.map_config = MapPreset.new()
	sd.faction_config = FactionConfig.new()
	var wc := WinConditionData.new()
	sd.win_conditions = [wc]
	assert_eq(sd.map_config.hex_count, 1750)
	assert_eq(sd.faction_config.available_factions.size(), 4)
	assert_eq(sd.win_conditions.size(), 1)


# --- ScenarioModifier ---


func test_scenario_modifier_defaults() -> void:
	var sm := ScenarioModifier.new()
	assert_almost_eq(sm.wave_multiplier, 1.0, 0.001)
	assert_almost_eq(sm.income_multiplier, 1.0, 0.001)
	assert_eq(sm.metric_weight_preset_path, "")


func test_scenario_modifier_hell_mode() -> void:
	var sm := ScenarioModifier.new()
	sm.modifier_id = &"hell"
	sm.wave_multiplier = 2.0
	sm.income_multiplier = 0.5
	assert_almost_eq(sm.wave_multiplier, 2.0, 0.001)
	assert_almost_eq(sm.income_multiplier, 0.5, 0.001)
