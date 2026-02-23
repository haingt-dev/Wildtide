extends GutTest
## Tests for EdictData Resource and EdictRegistry.


func test_default_values() -> void:
	var edict := EdictData.new()
	assert_eq(edict.edict_id, &"")
	assert_eq(edict.duration, -1)
	assert_false(edict.is_free_action)
	assert_eq(edict.category, EdictData.Category.ECONOMY)


func test_category_enum() -> void:
	assert_eq(EdictData.Category.ECONOMY, 0)
	assert_eq(EdictData.Category.DEFENSE, 1)
	assert_eq(EdictData.Category.RESEARCH, 2)
	assert_eq(EdictData.Category.SOCIAL, 3)


func test_ration_resources_values() -> void:
	var edict := EdictData.new()
	edict.edict_id = &"ration_resources"
	edict.category = EdictData.Category.ECONOMY
	edict.metric_effects = {&"anxiety": -0.1}
	edict.economy_effects = {&"gold_income": -0.2}
	edict.duration = -1
	edict.faction_reactions = {&"coin": -3, &"wall": 5}

	assert_eq(edict.category, EdictData.Category.ECONOMY)
	assert_almost_eq(edict.metric_effects[&"anxiety"] as float, -0.1, 0.001)
	assert_almost_eq(edict.economy_effects[&"gold_income"] as float, -0.2, 0.001)
	assert_eq(edict.duration, -1)
	assert_eq(edict.faction_reactions[&"wall"], 5)
	assert_eq(edict.faction_reactions[&"coin"], -3)


func test_festival_has_duration() -> void:
	var edict := EdictData.new()
	edict.edict_id = &"festival"
	edict.category = EdictData.Category.SOCIAL
	edict.duration = 3
	assert_eq(edict.duration, 3)


func test_migration_is_free_action() -> void:
	var edict := EdictData.new()
	edict.edict_id = &"migration"
	edict.is_free_action = true
	edict.duration = 1
	assert_true(edict.is_free_action)
	assert_eq(edict.duration, 1)


func test_research_alignment_push() -> void:
	var edict := EdictData.new()
	edict.alignment_push = 0.1
	edict.discovery_bonus = 0.1
	assert_almost_eq(edict.alignment_push, 0.1, 0.001)
	assert_almost_eq(edict.discovery_bonus, 0.1, 0.001)


func test_magic_alignment_negative() -> void:
	var edict := EdictData.new()
	edict.alignment_push = -0.1
	assert_almost_eq(edict.alignment_push, -0.1, 0.001)


func test_martial_law_all_factions_react() -> void:
	var edict := EdictData.new()
	edict.faction_reactions = {&"wall": 5, &"lens": -3, &"veil": -3, &"coin": -3}
	assert_eq(edict.faction_reactions.size(), 4)
	assert_eq(edict.faction_reactions[&"wall"], 5)
	for fid: StringName in [&"lens", &"veil", &"coin"]:
		assert_eq(edict.faction_reactions[fid], -3)
