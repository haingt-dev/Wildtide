extends GutTest
## Tests for StabilityConfig Resource.


func test_constants() -> void:
	assert_eq(StabilityConfig.MIN_STABILITY, 0)
	assert_eq(StabilityConfig.MAX_STABILITY, 100)


func test_default_starting() -> void:
	var cfg := StabilityConfig.new()
	assert_eq(cfg.starting_stability, 100)


func test_default_multipliers() -> void:
	var cfg := StabilityConfig.new()
	assert_almost_eq(cfg.loss_multiplier, 1.0, 0.001)
	assert_almost_eq(cfg.gain_multiplier, 1.0, 0.001)


func test_wave_damage_loss() -> void:
	var cfg := StabilityConfig.new()
	assert_almost_eq(cfg.wave_damage_threshold, 0.5, 0.001)
	assert_eq(cfg.wave_damage_loss_min, -10)
	assert_eq(cfg.wave_damage_loss_max, -30)


func test_morale_thresholds() -> void:
	var cfg := StabilityConfig.new()
	assert_eq(cfg.low_morale_threshold, 25)
	assert_eq(cfg.low_morale_loss_per_cycle, -5)
	assert_eq(cfg.high_morale_threshold, 75)
	assert_eq(cfg.high_morale_gain_per_cycle, 1)


func test_solidarity_gain() -> void:
	var cfg := StabilityConfig.new()
	assert_almost_eq(cfg.solidarity_threshold, 0.7, 0.001)
	assert_eq(cfg.solidarity_gain_per_cycle, 2)


func test_warning_thresholds() -> void:
	var cfg := StabilityConfig.new()
	assert_eq(cfg.warning_yellow, 50)
	assert_eq(cfg.warning_red, 25)
	assert_eq(cfg.warning_final, 10)


func test_game_over_enabled_by_default() -> void:
	var cfg := StabilityConfig.new()
	assert_true(cfg.game_over_enabled)
	assert_eq(cfg.stability_floor, 0)


func test_zen_mode_config() -> void:
	var cfg := StabilityConfig.new()
	cfg.game_over_enabled = false
	cfg.stability_floor = 10
	cfg.loss_multiplier = 0.5
	cfg.gain_multiplier = 1.5
	assert_false(cfg.game_over_enabled)
	assert_eq(cfg.stability_floor, 10)
	assert_almost_eq(cfg.loss_multiplier, 0.5, 0.001)
	assert_almost_eq(cfg.gain_multiplier, 1.5, 0.001)


func test_hell_mode_config() -> void:
	var cfg := StabilityConfig.new()
	cfg.starting_stability = 75
	cfg.loss_multiplier = 1.5
	cfg.gain_multiplier = 0.7
	cfg.warning_yellow = 60
	assert_eq(cfg.starting_stability, 75)
	assert_almost_eq(cfg.loss_multiplier, 1.5, 0.001)
	assert_almost_eq(cfg.gain_multiplier, 0.7, 0.001)
	assert_eq(cfg.warning_yellow, 60)
