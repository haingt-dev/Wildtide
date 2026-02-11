extends GutTest
## Tests for RuinType, RuinData, and RuinRegistry.

var registry: RuinRegistry


func before_each() -> void:
	registry = RuinRegistry.new()


# --- RuinType state constants ---


func test_state_none_is_zero() -> void:
	assert_eq(RuinType.STATE_NONE, 0)


func test_state_values_are_distinct() -> void:
	var states := [
		RuinType.STATE_NONE,
		RuinType.STATE_UNDISCOVERED,
		RuinType.STATE_DISCOVERED,
		RuinType.STATE_EXPLORING,
		RuinType.STATE_DEPLETED,
		RuinType.STATE_DAMAGED,
	]
	for i: int in range(states.size()):
		for j: int in range(i + 1, states.size()):
			assert_ne(states[i], states[j], "States %d and %d should differ" % [i, j])


func test_state_values_are_sequential() -> void:
	assert_eq(RuinType.STATE_UNDISCOVERED, RuinType.STATE_NONE + 1)
	assert_eq(RuinType.STATE_DISCOVERED, RuinType.STATE_UNDISCOVERED + 1)
	assert_eq(RuinType.STATE_EXPLORING, RuinType.STATE_DISCOVERED + 1)
	assert_eq(RuinType.STATE_DEPLETED, RuinType.STATE_EXPLORING + 1)
	assert_eq(RuinType.STATE_DAMAGED, RuinType.STATE_DEPLETED + 1)


# --- RuinRegistry loading ---


func test_all_ruins_loaded() -> void:
	assert_eq(registry.get_all().size(), 3)


func test_registry_lookup_observatory() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.OBSERVATORY)
	assert_not_null(data)
	assert_eq(data.ruin_type, RuinType.Type.OBSERVATORY)
	assert_eq(data.display_name, &"Observatory")
	assert_eq(data.tech_fragments, 3)
	assert_eq(data.rune_shards, 0)


func test_registry_lookup_energy_shrine() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.ENERGY_SHRINE)
	assert_not_null(data)
	assert_eq(data.ruin_type, RuinType.Type.ENERGY_SHRINE)
	assert_eq(data.display_name, &"Energy Shrine")
	assert_eq(data.tech_fragments, 0)
	assert_eq(data.rune_shards, 3)


func test_registry_lookup_archive_vault() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.ARCHIVE_VAULT)
	assert_not_null(data)
	assert_eq(data.ruin_type, RuinType.Type.ARCHIVE_VAULT)
	assert_eq(data.display_name, &"Archive Vault")
	assert_eq(data.tech_fragments, 1)
	assert_eq(data.rune_shards, 1)


# --- RuinData values ---


func test_observatory_exploration_duration() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.OBSERVATORY)
	assert_eq(data.exploration_duration, 2)


func test_energy_shrine_exploration_duration() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.ENERGY_SHRINE)
	assert_eq(data.exploration_duration, 2)


func test_archive_vault_exploration_duration() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.ARCHIVE_VAULT)
	assert_eq(data.exploration_duration, 3)


func test_observatory_rarity_weight() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.OBSERVATORY)
	assert_almost_eq(data.rarity_weight, 0.4, 0.001)


func test_archive_vault_rarity_weight() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.ARCHIVE_VAULT)
	assert_almost_eq(data.rarity_weight, 0.2, 0.001)


func test_damage_yield_penalty() -> void:
	var data: RuinData = registry.get_data(RuinType.Type.OBSERVATORY)
	assert_almost_eq(data.damage_yield_penalty, 0.5, 0.001)


# --- pick_random_type ---


func test_pick_random_type_returns_valid() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var valid_types := [
		RuinType.Type.OBSERVATORY,
		RuinType.Type.ENERGY_SHRINE,
		RuinType.Type.ARCHIVE_VAULT,
	]
	for i: int in range(100):
		var picked: RuinType.Type = registry.pick_random_type(rng)
		assert_has(valid_types, picked, "Picked type should be valid")
