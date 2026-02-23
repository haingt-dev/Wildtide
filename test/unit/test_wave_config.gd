extends GutTest
## Tests for WaveConfig Resource — era scaling and wave power.

var config: WaveConfig


func before_each() -> void:
	config = WaveConfig.new()


# --- get_era ---


func test_era_cycle_1_is_era_0() -> void:
	assert_eq(config.get_era(1), 0)


func test_era_cycle_5_is_era_0() -> void:
	assert_eq(config.get_era(5), 0)


func test_era_cycle_6_is_era_1() -> void:
	assert_eq(config.get_era(6), 1)


func test_era_cycle_10_is_era_1() -> void:
	assert_eq(config.get_era(10), 1)


func test_era_cycle_11_is_era_2() -> void:
	assert_eq(config.get_era(11), 2)


func test_era_cycle_16_is_era_3() -> void:
	assert_eq(config.get_era(16), 3)


func test_era_cycle_0_is_era_0() -> void:
	assert_eq(config.get_era(0), 0)


# --- get_wave_power ---


func test_wave_power_era_1() -> void:
	assert_almost_eq(config.get_wave_power(1), 10.0, 0.001)


func test_wave_power_era_2() -> void:
	assert_almost_eq(config.get_wave_power(6), 18.0, 0.001)


func test_wave_power_era_3() -> void:
	assert_almost_eq(config.get_wave_power(11), 30.0, 0.001)


func test_wave_power_final() -> void:
	assert_almost_eq(config.get_wave_power(16), 50.0, 0.001)


# --- get_enemy_count ---


func test_enemy_count_era_1() -> void:
	assert_eq(config.get_enemy_count(1), 10)


func test_enemy_count_era_2() -> void:
	assert_eq(config.get_enemy_count(6), 18)


func test_enemy_count_final() -> void:
	assert_eq(config.get_enemy_count(16), 50)


# --- Custom config ---


func test_custom_base_power() -> void:
	config.base_power = 20.0
	assert_almost_eq(config.get_wave_power(1), 20.0, 0.001)
	assert_almost_eq(config.get_wave_power(6), 36.0, 0.001)


# --- Region modifier ---


func test_wave_power_region_starting() -> void:
	# Era 1 × Starting (0.8): 10 × 1.0 × 0.8 = 8.0
	assert_almost_eq(config.get_wave_power(1, RegionType.Type.STARTING), 8.0, 0.001)


func test_wave_power_region_late() -> void:
	# Era 1 × Late (1.5): 10 × 1.0 × 1.5 = 15.0
	assert_almost_eq(config.get_wave_power(1, RegionType.Type.LATE), 15.0, 0.001)


func test_wave_power_region_rift_core() -> void:
	# Era 3 × Rift Core (2.0): 10 × 3.0 × 2.0 = 60.0
	assert_almost_eq(config.get_wave_power(11, RegionType.Type.RIFT_CORE), 60.0, 0.001)


func test_enemy_count_with_region() -> void:
	# Era 1 × Starting (0.8): 10 × 1.0 × 0.8 = 8
	assert_eq(config.get_enemy_count(1, RegionType.Type.STARTING), 8)


# --- Custom era boundaries ---


func test_custom_era_boundaries() -> void:
	config.era_boundaries = [1, 4, 8, 12]
	assert_eq(config.get_era(3), 0)
	assert_eq(config.get_era(4), 1)
	assert_eq(config.get_era(8), 2)
	assert_eq(config.get_era(12), 3)
