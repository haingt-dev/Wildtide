extends GutTest
## Integration tests for GameSession bootstrap and system wiring.
## Verifies all managers are created, injected, and can run a cycle.

var session: GameSession


func before_each() -> void:
	session = GameSession.new()
	add_child(session)
	# Run bootstrap steps manually (no .tscn children like renderer).
	session.load_scenario()
	session.create_hex_grid()
	session.create_managers()
	session.inject_dependencies()
	session.create_wave_intel()
	session.initialize_systems()
	session.setup_save_system()
	MetricSystem.reset_to_defaults()


func after_each() -> void:
	session.queue_free()
	GameManager.is_running = false
	GameManager.cycle_number = 0
	MetricSystem.reset_to_defaults()
	_disconnect_all(EventBus.phase_changed)
	_disconnect_all(EventBus.cycle_started)
	_disconnect_all(EventBus.cycle_completed)
	_disconnect_all(EventBus.wave_started)
	_disconnect_all(EventBus.wave_ended)
	_disconnect_all(EventBus.hex_grid_initialized)
	_disconnect_all(EventBus.quest_proposed)
	_disconnect_all(EventBus.quest_approved)
	_disconnect_all(EventBus.quest_completed)
	_disconnect_all(EventBus.building_placed)
	_disconnect_all(EventBus.ai_buildings_placed)
	_disconnect_all(EventBus.stability_changed)
	_disconnect_all(EventBus.gold_changed)
	_disconnect_all(EventBus.mana_changed)
	_disconnect_all(EventBus.game_over)
	_disconnect_all(EventBus.game_won)
	_disconnect_all(EventBus.faction_morale_changed)
	_disconnect_all(EventBus.wave_intel_updated)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Manager creation ---


func test_all_managers_created() -> void:
	assert_not_null(session.economy_manager, "EconomyManager")
	assert_not_null(session.edict_manager, "EdictManager")
	assert_not_null(session.quest_manager, "QuestManager")
	assert_not_null(session.building_manager, "BuildingManager")
	assert_not_null(session.ruins_manager, "RuinsManager")
	assert_not_null(session.wave_manager, "WaveManager")
	assert_not_null(session.movement_manager, "MovementManager")
	assert_not_null(session.stability_tracker, "StabilityTracker")
	assert_not_null(session.utility_ai, "UtilityAI")
	assert_not_null(session.save_system, "SaveSystem")


func test_managers_are_children() -> void:
	assert_not_null(session.get_node_or_null("EconomyManager"))
	assert_not_null(session.get_node_or_null("QuestManager"))
	assert_not_null(session.get_node_or_null("WaveManager"))
	assert_not_null(session.get_node_or_null("StabilityTracker"))
	assert_not_null(session.get_node_or_null("UtilityAI"))


# --- Hex grid ---


func test_hex_grid_initialized() -> void:
	assert_not_null(session.hex_grid)
	assert_gt(session.hex_grid.get_cell_count(), 0, "Grid should have cells")


func test_rift_positions_assigned() -> void:
	assert_eq(session.wave_manager.rift_positions.size(), 3, "Should have 3 Rifts")


# --- Dependency injection ---


func test_hex_grid_injected() -> void:
	assert_eq(session.building_manager.hex_grid, session.hex_grid)
	assert_eq(session.wave_manager.hex_grid, session.hex_grid)
	assert_eq(session.ruins_manager.hex_grid, session.hex_grid)
	assert_eq(session.economy_manager.hex_grid, session.hex_grid)
	assert_eq(session.movement_manager.hex_grid, session.hex_grid)
	assert_eq(session.utility_ai.hex_grid, session.hex_grid)


func test_cross_manager_refs() -> void:
	assert_eq(session.economy_manager.edict_manager, session.edict_manager)
	assert_eq(session.edict_manager.quest_manager, session.quest_manager)
	assert_eq(session.building_manager.economy_manager, session.economy_manager)
	assert_eq(session.stability_tracker.wave_manager, session.wave_manager)
	assert_eq(session.stability_tracker.quest_manager, session.quest_manager)
	assert_eq(session.utility_ai.building_manager, session.building_manager)
	assert_eq(session.movement_manager.building_manager, session.building_manager)
	assert_eq(session.building_manager.movement_manager, session.movement_manager)
	assert_eq(session.wave_manager.quest_manager, session.quest_manager)


func test_wave_intel_injected() -> void:
	assert_not_null(session.quest_manager.wave_intel)
	assert_not_null(session.wave_manager.wave_intel)
	assert_eq(session.quest_manager.wave_intel, session.wave_manager.wave_intel)


func test_save_system_has_all_refs() -> void:
	assert_eq(session.save_system.hex_grid, session.hex_grid)
	assert_eq(session.save_system.wave_manager, session.wave_manager)
	assert_eq(session.save_system.ruins_manager, session.ruins_manager)
	assert_eq(session.save_system.building_manager, session.building_manager)
	assert_eq(session.save_system.quest_manager, session.quest_manager)
	assert_eq(session.save_system.economy_manager, session.economy_manager)
	assert_eq(session.save_system.stability_tracker, session.stability_tracker)


# --- Scenario ---


func test_scenario_loaded() -> void:
	assert_not_null(GameManager.scenario_data)
	assert_eq(GameManager.scenario_id, &"the_wildtide")


func test_scenario_starting_resources() -> void:
	assert_eq(session.economy_manager.get_gold(), 100)
	assert_eq(session.economy_manager.get_mana(), 50)


# --- Ruins ---


func test_ruins_initialized() -> void:
	assert_gt(session.ruins_manager.get_ruin_count(), 0, "Ruins should be initialized")


# --- Full cycle ---


func test_one_full_cycle_completes() -> void:
	var cycle_completed := []
	EventBus.cycle_completed.connect(func(c: int) -> void: cycle_completed.append(c))
	session.start_game()
	# Advance through all 4 phases: OBSERVE → INFLUENCE → WAVE → EVOLVE
	GameManager.advance_phase()
	GameManager.advance_phase()
	GameManager.advance_phase()
	GameManager.advance_phase()
	assert_eq(cycle_completed.size(), 1, "Should complete 1 cycle")
	assert_eq(cycle_completed[0], 1)


func test_wave_runs_during_wave_phase() -> void:
	session.start_game()
	var wave_started := []
	EventBus.wave_started.connect(func(c: int) -> void: wave_started.append(c))
	# Advance: OBSERVE → INFLUENCE
	GameManager.advance_phase()
	assert_eq(wave_started.size(), 0, "No wave during INFLUENCE")
	# Advance: INFLUENCE → WAVE
	GameManager.advance_phase()
	assert_gt(wave_started.size(), 0, "Wave should run during WAVE phase")
