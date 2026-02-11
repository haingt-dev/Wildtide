extends GutTest
## Tests for FactionData, FactionRegistry, and FactionType.

var registry: FactionRegistry


func before_each() -> void:
	registry = FactionRegistry.new()


func test_all_factions_loaded() -> void:
	var all := registry.get_all()
	assert_eq(all.size(), 4, "Should load all 4 faction .tres files")


func test_registry_lookup_lens() -> void:
	var data := registry.get_data(FactionType.Type.LENS)
	assert_not_null(data)
	assert_eq(data.faction_type, FactionType.Type.LENS)
	assert_eq(data.faction_id, &"lens")
	assert_eq(data.display_name, "The Lens")


func test_lens_alignment_science() -> void:
	var data := registry.get_data(FactionType.Type.LENS)
	assert_almost_eq(data.alignment_bias, 1.0, 0.001)


func test_veil_alignment_magic() -> void:
	var data := registry.get_data(FactionType.Type.VEIL)
	assert_not_null(data)
	assert_eq(data.faction_id, &"veil")
	assert_almost_eq(data.alignment_bias, -1.0, 0.001)


func test_coin_is_neutral() -> void:
	var data := registry.get_data(FactionType.Type.COIN)
	assert_not_null(data)
	assert_eq(data.faction_id, &"coin")
	assert_almost_eq(data.alignment_bias, 0.0, 0.001)


func test_wall_is_neutral() -> void:
	var data := registry.get_data(FactionType.Type.WALL)
	assert_not_null(data)
	assert_eq(data.faction_id, &"wall")
	assert_almost_eq(data.alignment_bias, 0.0, 0.001)


func test_each_faction_has_quest_pool() -> void:
	for faction_data: FactionData in registry.get_all():
		assert_gt(
			faction_data.quest_pool.size(),
			0,
			"Faction %s should have non-empty quest pool" % faction_data.faction_id,
		)


func test_faction_enum_values() -> void:
	assert_eq(FactionType.Type.LENS, 0)
	assert_eq(FactionType.Type.VEIL, 1)
	assert_eq(FactionType.Type.COIN, 2)
	assert_eq(FactionType.Type.WALL, 3)


func test_unknown_faction_returns_null() -> void:
	var data := registry.get_data(99 as FactionType.Type)
	assert_null(data)
