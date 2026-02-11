extends GutTest
## Tests for BiomeData and BiomeRegistry.

var registry: BiomeRegistry


func before_each() -> void:
	registry = BiomeRegistry.new()


func test_all_biomes_loaded() -> void:
	var all := registry.get_all()
	assert_eq(all.size(), 5, "Should load all 5 biome .tres files")


func test_registry_lookup_plains() -> void:
	var data := registry.get_data(BiomeType.Type.PLAINS)
	assert_not_null(data)
	assert_eq(data.biome_type, BiomeType.Type.PLAINS)
	assert_eq(data.display_name, &"Plains")


func test_plains_defaults() -> void:
	var data := registry.get_data(BiomeType.Type.PLAINS)
	assert_almost_eq(data.construction_speed, 1.0, 0.001)
	assert_almost_eq(data.gold_yield, 1.0, 0.001)
	assert_almost_eq(data.mana_yield, 1.0, 0.001)
	assert_almost_eq(data.defense_bonus, 0.0, 0.001)
	assert_almost_eq(data.alignment_affinity, 0.0, 0.001)


func test_forest_construction_speed() -> void:
	var data := registry.get_data(BiomeType.Type.FOREST)
	assert_not_null(data)
	assert_almost_eq(data.construction_speed, 0.7, 0.001)
	assert_almost_eq(data.mana_yield, 1.5, 0.001)
	assert_eq(data.metric_push, &"harmony")


func test_rocky_defense_bonus() -> void:
	var data := registry.get_data(BiomeType.Type.ROCKY)
	assert_not_null(data)
	assert_almost_eq(data.defense_bonus, 0.2, 0.001)
	assert_almost_eq(data.alignment_affinity, 0.3, 0.001)


func test_swamp_pollution_push() -> void:
	var data := registry.get_data(BiomeType.Type.SWAMP)
	assert_not_null(data)
	assert_eq(data.metric_push, &"pollution")
	assert_almost_eq(data.defense_bonus, -0.1, 0.001)


func test_ruins_anxiety_push() -> void:
	var data := registry.get_data(BiomeType.Type.RUINS)
	assert_not_null(data)
	assert_eq(data.metric_push, &"anxiety")
	assert_almost_eq(data.construction_speed, 0.6, 0.001)


func test_unknown_biome_returns_null() -> void:
	# BiomeType.Type only has 5 values (0-4). Casting 99 is invalid.
	var data := registry.get_data(99 as BiomeType.Type)
	assert_null(data)
