extends GutTest
## Tests for StabilityTracker Node.

var _tracker: StabilityTracker


func before_each() -> void:
	_tracker = StabilityTracker.new()
	_tracker.stability_config = StabilityConfig.new()
	add_child(_tracker)


func after_each() -> void:
	_tracker.queue_free()


func test_starting_stability() -> void:
	assert_eq(_tracker.get_stability(), 100)


func test_starting_alert_normal() -> void:
	assert_eq(_tracker.get_alert_level(), &"normal")


func test_push_stability_loss() -> void:
	_tracker.push_stability(-20)
	assert_eq(_tracker.get_stability(), 80)


func test_push_stability_gain() -> void:
	_tracker.push_stability(-50)
	_tracker.push_stability(10)
	assert_eq(_tracker.get_stability(), 60)


func test_stability_clamped_to_max() -> void:
	_tracker.push_stability(50)
	assert_eq(_tracker.get_stability(), 100)


func test_alert_yellow() -> void:
	_tracker.push_stability(-55)
	assert_eq(_tracker.get_alert_level(), &"yellow")


func test_alert_red() -> void:
	_tracker.push_stability(-80)
	assert_eq(_tracker.get_alert_level(), &"red")


func test_alert_final() -> void:
	_tracker.push_stability(-92)
	assert_eq(_tracker.get_alert_level(), &"final")


func test_wave_heavy_damage_loss() -> void:
	_tracker.on_wave_result(0.8)
	assert_true(_tracker.get_stability() < 100)


func test_wave_good_defense_gain() -> void:
	_tracker.push_stability(-20)
	_tracker.on_wave_result(0.1)
	assert_eq(_tracker.get_stability(), 85)  # 80 + 5


func test_wave_moderate_no_change() -> void:
	_tracker.on_wave_result(0.3)
	assert_eq(_tracker.get_stability(), 100)


func test_faction_all_low_morale() -> void:
	_tracker.check_faction_morale(true, 0)
	assert_eq(_tracker.get_stability(), 95)


func test_faction_high_morale_gain() -> void:
	_tracker.push_stability(-20)
	_tracker.check_faction_morale(false, 3)
	assert_eq(_tracker.get_stability(), 83)  # 80 + 3*1


func test_resource_depletion_first_cycle_no_loss() -> void:
	_tracker.check_resource_depletion(0, 50)
	assert_eq(_tracker.get_stability(), 100)


func test_resource_depletion_second_cycle_loss() -> void:
	_tracker.check_resource_depletion(0, 50)
	_tracker.check_resource_depletion(0, 50)
	assert_eq(_tracker.get_stability(), 90)


func test_resource_depletion_resets() -> void:
	_tracker.check_resource_depletion(0, 50)
	_tracker.check_resource_depletion(100, 50)
	_tracker.check_resource_depletion(0, 50)
	assert_eq(_tracker.get_stability(), 100)  # Counter reset


func test_solidarity_gain() -> void:
	_tracker.push_stability(-20)
	_tracker.check_solidarity(0.8)
	assert_eq(_tracker.get_stability(), 82)


func test_solidarity_below_threshold_no_gain() -> void:
	_tracker.push_stability(-20)
	_tracker.check_solidarity(0.5)
	assert_eq(_tracker.get_stability(), 80)


func test_festival_bonus() -> void:
	_tracker.push_stability(-20)
	_tracker.apply_festival_bonus()
	assert_eq(_tracker.get_stability(), 83)


func test_artifact_failed() -> void:
	_tracker.on_artifact_failed()
	assert_eq(_tracker.get_stability(), 80)


func test_game_over_signal() -> void:
	var triggered: Array = []
	EventBus.game_over.connect(func() -> void: triggered.append(true))
	_tracker.push_stability(-100)
	assert_eq(triggered.size(), 1)


func test_zen_mode_floors_at_10() -> void:
	_tracker.stability_config.game_over_enabled = false
	_tracker.stability_config.stability_floor = 10
	_tracker.push_stability(-200)
	assert_eq(_tracker.get_stability(), 10)


func test_loss_multiplier() -> void:
	_tracker.stability_config.loss_multiplier = 1.5
	_tracker.push_stability(-10)
	assert_eq(_tracker.get_stability(), 85)  # 100 - round(10*1.5) = 85


func test_gain_multiplier() -> void:
	_tracker.push_stability(-50)
	_tracker.stability_config.gain_multiplier = 1.5
	_tracker.push_stability(10)
	assert_eq(_tracker.get_stability(), 65)  # 50 + round(10*1.5) = 65


func test_stability_changed_signal() -> void:
	var received: Array = []
	EventBus.stability_changed.connect(
		func(new_val: int, old_val: int) -> void: received.append([new_val, old_val])
	)
	_tracker.push_stability(-10)
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], 90)
	assert_eq(received[0][1], 100)


func test_alert_level_changed_signal() -> void:
	var received: Array = []
	EventBus.alert_level_changed.connect(func(level: StringName) -> void: received.append(level))
	_tracker.push_stability(-55)
	assert_eq(received.size(), 1)
	assert_eq(received[0], &"yellow")


# --- Phase hook: auto-checks on EVOLVE ---


func test_evolve_checks_resource_depletion() -> void:
	var econ := EconomyManager.new()
	var cfg := EconomyConfig.new()
	cfg.starting_gold = 0
	cfg.starting_mana = 0
	econ.economy_config = cfg
	add_child(econ)
	_tracker.economy_manager = econ
	# First EVOLVE: counter starts at 1, no loss yet
	_tracker._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(_tracker.get_stability(), 100)
	# Second EVOLVE: counter=2, loss applies
	_tracker._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(_tracker.get_stability(), 90)
	econ.queue_free()


func test_evolve_checks_solidarity() -> void:
	_tracker.push_stability(-20)
	MetricSystem.solidarity = 0.8
	_tracker._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(_tracker.get_stability(), 82)
	MetricSystem.reset_to_defaults()


func test_evolve_no_economy_skips_depletion() -> void:
	_tracker._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(_tracker.get_stability(), 100)


func test_non_evolve_no_auto_checks() -> void:
	MetricSystem.solidarity = 0.9
	_tracker.push_stability(-20)
	_tracker._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	_tracker._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	_tracker._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	assert_eq(_tracker.get_stability(), 80, "Non-EVOLVE phases should not trigger checks")
	MetricSystem.reset_to_defaults()


# --- Wave → Stability integration ---


func test_wave_ended_triggers_stability_loss() -> void:
	var wmgr := WaveManager.new()
	add_child(wmgr)
	wmgr.hex_grid = HexGrid.new()
	wmgr.hex_grid.initialize_hex_map(2)
	wmgr._last_total_damage = float(wmgr.hex_grid.get_all_cells().size())
	_tracker.wave_manager = wmgr
	_tracker._on_wave_ended(1)
	assert_true(_tracker.get_stability() < 100, "Heavy wave damage should reduce stability")
	wmgr.queue_free()


func test_wave_low_damage_triggers_stability_gain() -> void:
	_tracker.push_stability(-20)
	var wmgr := WaveManager.new()
	add_child(wmgr)
	wmgr.hex_grid = HexGrid.new()
	wmgr.hex_grid.initialize_hex_map(2)
	wmgr._last_total_damage = 0.01
	_tracker.wave_manager = wmgr
	_tracker._on_wave_ended(1)
	assert_eq(_tracker.get_stability(), 85, "Low damage should gain +5 stability")
	wmgr.queue_free()


func test_wave_stability_no_crash_without_wave_manager() -> void:
	_tracker._on_wave_ended(1)
	assert_eq(_tracker.get_stability(), 100, "Should not crash without wave_manager")


# --- Faction Morale → Stability integration ---


func test_all_factions_low_morale_drains_stability() -> void:
	var qmgr := QuestManager.new()
	add_child(qmgr)
	_tracker.quest_manager = qmgr
	for fid: StringName in [&"the_lens", &"the_veil", &"the_coin", &"the_wall"]:
		qmgr.push_faction_morale(fid, -40)
	_tracker._check_faction_morale()
	assert_eq(_tracker.get_stability(), 95, "All low morale = -5 stability")
	qmgr.queue_free()


func test_high_morale_factions_boost_stability() -> void:
	_tracker.push_stability(-20)
	var qmgr := QuestManager.new()
	add_child(qmgr)
	_tracker.quest_manager = qmgr
	qmgr.push_faction_morale(&"the_lens", 30)
	qmgr.push_faction_morale(&"the_veil", 30)
	_tracker._check_faction_morale()
	assert_eq(_tracker.get_stability(), 82, "2 factions at 80 morale = +2 stability")
	qmgr.queue_free()


# --- Festival → Stability integration ---


func test_festival_edict_gives_stability_bonus() -> void:
	_tracker.push_stability(-20)
	var emgr := EdictManager.new()
	add_child(emgr)
	_tracker.edict_manager = emgr
	var e := EdictData.new()
	e.edict_id = &"festival"
	e.duration = 3
	emgr.edict_registry._data[&"festival"] = e
	emgr.enact_edict(&"festival")
	_tracker._check_festival()
	assert_eq(_tracker.get_stability(), 83, "Festival edict = +3 stability")
	emgr.queue_free()
