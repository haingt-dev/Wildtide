extends GutTest
## Tests for CycleTimer Resource — phase durations and helpers.

var timer: CycleTimer


func before_each() -> void:
	timer = CycleTimer.new()


# --- Default durations ---


func test_default_observe_duration() -> void:
	assert_almost_eq(timer.observe_duration, 180.0, 0.001, "Observe = 3 min")


func test_default_influence_duration() -> void:
	assert_almost_eq(timer.influence_duration, 180.0, 0.001, "Influence = 3 min")


func test_default_wave_duration() -> void:
	assert_almost_eq(timer.wave_duration, 60.0, 0.001, "Wave = 1 min")


func test_default_evolve_duration() -> void:
	assert_almost_eq(timer.evolve_duration, 60.0, 0.001, "Evolve = 1 min")


# --- get_phase_duration ---


func test_get_phase_duration_observe() -> void:
	assert_almost_eq(timer.get_phase_duration(CycleTimer.Phase.OBSERVE), 180.0, 0.001)


func test_get_phase_duration_influence() -> void:
	assert_almost_eq(timer.get_phase_duration(CycleTimer.Phase.INFLUENCE), 180.0, 0.001)


func test_get_phase_duration_wave() -> void:
	assert_almost_eq(timer.get_phase_duration(CycleTimer.Phase.WAVE), 60.0, 0.001)


func test_get_phase_duration_evolve() -> void:
	assert_almost_eq(timer.get_phase_duration(CycleTimer.Phase.EVOLVE), 60.0, 0.001)


func test_get_phase_duration_custom() -> void:
	timer.observe_duration = 90.0
	assert_almost_eq(timer.get_phase_duration(CycleTimer.Phase.OBSERVE), 90.0, 0.001)


# --- get_phase_name ---


func test_get_phase_name_all() -> void:
	assert_eq(timer.get_phase_name(CycleTimer.Phase.OBSERVE), &"observe")
	assert_eq(timer.get_phase_name(CycleTimer.Phase.INFLUENCE), &"influence")
	assert_eq(timer.get_phase_name(CycleTimer.Phase.WAVE), &"wave")
	assert_eq(timer.get_phase_name(CycleTimer.Phase.EVOLVE), &"evolve")


# --- get_total_cycle_duration ---


func test_total_cycle_duration_default() -> void:
	assert_almost_eq(timer.get_total_cycle_duration(), 480.0, 0.001, "Total = 8 min")


func test_total_cycle_duration_custom() -> void:
	timer.observe_duration = 60.0
	timer.influence_duration = 60.0
	assert_almost_eq(timer.get_total_cycle_duration(), 240.0, 0.001)


# --- Phase enum ---


func test_phase_enum_values() -> void:
	assert_eq(CycleTimer.Phase.OBSERVE, 0)
	assert_eq(CycleTimer.Phase.INFLUENCE, 1)
	assert_eq(CycleTimer.Phase.WAVE, 2)
	assert_eq(CycleTimer.Phase.EVOLVE, 3)


func test_phase_count() -> void:
	assert_eq(CycleTimer.PHASE_COUNT, 4)


func test_phase_names_count() -> void:
	assert_eq(CycleTimer.PHASE_NAMES.size(), 4)
