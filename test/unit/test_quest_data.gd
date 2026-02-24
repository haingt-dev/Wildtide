extends GutTest
## Tests for QuestData and QuestRegistry.

var registry: QuestRegistry


func before_each() -> void:
	registry = QuestRegistry.new()


func test_all_quests_loaded() -> void:
	var all := registry.get_all()
	assert_eq(all.size(), 16, "Should load all 16 quest .tres files (12 normal + 4 offensive)")


func test_lookup_by_quest_id() -> void:
	var quest := registry.get_quest(&"lens_reactor")
	assert_not_null(quest)
	assert_eq(quest.quest_id, &"lens_reactor")
	assert_eq(quest.faction_id, &"lens")


func test_quests_for_each_faction_has_three() -> void:
	for faction_id: StringName in [&"lens", &"veil", &"coin", &"wall"]:
		var quests := registry.get_quests_for_faction(faction_id)
		assert_eq(quests.size(), 3, "Faction %s should have 3 quests" % faction_id)


func test_quest_has_valid_duration() -> void:
	for quest: QuestData in registry.get_all():
		assert_gt(quest.duration, 0, "Quest %s duration must be > 0" % quest.quest_id)
		assert_lte(quest.duration, 5, "Quest %s duration must be <= 5" % quest.quest_id)


func test_quest_metric_effects_valid_keys() -> void:
	var valid_metrics: Array[StringName] = [&"pollution", &"anxiety", &"solidarity", &"harmony"]
	for quest: QuestData in registry.get_all():
		for key: StringName in quest.metric_effects:
			assert_has(
				valid_metrics,
				key,
				"Quest %s has invalid metric key: %s" % [quest.quest_id, key],
			)


func test_unknown_quest_returns_null() -> void:
	var quest := registry.get_quest(&"nonexistent")
	assert_null(quest)


func test_quest_has_display_name() -> void:
	for quest: QuestData in registry.get_all():
		assert_ne(quest.display_name, "", "Quest %s must have display_name" % quest.quest_id)


func test_offensive_quests_have_effect_key() -> void:
	for quest: QuestData in registry.get_all():
		if quest.is_offensive:
			assert_ne(
				quest.offensive_effect_key,
				&"",
				"Offensive quest %s must have effect key" % quest.quest_id,
			)


func test_each_faction_has_one_offensive_quest() -> void:
	for faction_id: StringName in [&"lens", &"veil", &"coin", &"wall"]:
		var offensives := registry.get_offensive_quests_for_faction(faction_id)
		assert_eq(offensives.size(), 1, "Faction %s should have 1 offensive quest" % faction_id)
