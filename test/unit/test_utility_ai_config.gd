extends GutTest
## Tests for UtilityAIConfig Resource.


func test_default_scoring_weights() -> void:
	var cfg := UtilityAIConfig.new()
	assert_almost_eq(cfg.need_weight, 1.0, 0.001)
	assert_almost_eq(cfg.affinity_weight, 0.5, 0.001)
	assert_almost_eq(cfg.adjacency_weight, 0.8, 0.001)
	assert_almost_eq(cfg.faction_weight, 0.6, 0.001)
	assert_almost_eq(cfg.penalty_weight, 0.7, 0.001)


func test_default_metric_thresholds() -> void:
	var cfg := UtilityAIConfig.new()
	assert_almost_eq(cfg.pollution_critical, 0.7, 0.001)
	assert_almost_eq(cfg.anxiety_critical, 0.7, 0.001)
	assert_almost_eq(cfg.harmony_critical_low, 0.3, 0.001)
	assert_almost_eq(cfg.solidarity_critical_low, 0.3, 0.001)
	assert_almost_eq(cfg.defense_critical_low, 0.3, 0.001)


func test_default_pollution_penalty_curve() -> void:
	var cfg := UtilityAIConfig.new()
	assert_almost_eq(cfg.pollution_low_threshold, 0.3, 0.001)
	assert_almost_eq(cfg.pollution_high_threshold, 0.7, 0.001)
	assert_almost_eq(cfg.pollution_mid_penalty, -0.15, 0.001)
	assert_almost_eq(cfg.pollution_max_penalty, -0.3, 0.001)


func test_default_era_placement_rates() -> void:
	var cfg := UtilityAIConfig.new()
	assert_eq(cfg.era_placement_rates.size(), 4)
	assert_eq(cfg.era_placement_rates[0], 1)
	assert_eq(cfg.era_placement_rates[1], 2)
	assert_eq(cfg.era_placement_rates[2], 3)
	assert_eq(cfg.era_placement_rates[3], 3)


func test_default_alignment_thresholds() -> void:
	var cfg := UtilityAIConfig.new()
	assert_almost_eq(cfg.science_dominant_threshold, 0.3, 0.001)
	assert_almost_eq(cfg.magic_dominant_threshold, -0.3, 0.001)


func test_default_faction_bonus() -> void:
	var cfg := UtilityAIConfig.new()
	assert_almost_eq(cfg.dominant_faction_bonus, 0.2, 0.001)


func test_default_performance_settings() -> void:
	var cfg := UtilityAIConfig.new()
	assert_eq(cfg.max_candidates_per_eval, 300)
	assert_eq(cfg.distance_falloff_radius, 5)


func test_custom_values() -> void:
	var cfg := UtilityAIConfig.new()
	cfg.need_weight = 2.0
	cfg.affinity_weight = 1.5
	cfg.era_placement_rates = [2, 3, 4, 5]
	cfg.max_candidates_per_eval = 500
	assert_almost_eq(cfg.need_weight, 2.0, 0.001)
	assert_almost_eq(cfg.affinity_weight, 1.5, 0.001)
	assert_eq(cfg.era_placement_rates[0], 2)
	assert_eq(cfg.max_candidates_per_eval, 500)


func test_is_resource() -> void:
	var cfg := UtilityAIConfig.new()
	assert_true(cfg is Resource)
