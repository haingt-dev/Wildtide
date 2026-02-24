extends GutTest
## Tests for UtilityAI — scoring-based autonomous building placement.
## Uses global EventBus, MetricSystem, GameManager autoloads.

var ai: UtilityAI
var grid: HexGrid
var bmgr: BuildingManager
var econ: EconomyManager
var qmgr: QuestManager


func before_each() -> void:
	grid = HexGrid.new()
	grid.initialize_hex_map(3)
	bmgr = BuildingManager.new()
	add_child(bmgr)
	bmgr.hex_grid = grid
	econ = EconomyManager.new()
	econ.economy_config = EconomyConfig.new()
	add_child(econ)
	bmgr.economy_manager = econ
	qmgr = QuestManager.new()
	add_child(qmgr)
	ai = UtilityAI.new()
	add_child(ai)
	ai.hex_grid = grid
	ai.building_manager = bmgr
	ai.economy_manager = econ
	ai.quest_manager = qmgr
	# Set all cells to ACTIVE fog state for AI visibility.
	for cell: HexCell in grid.get_all_cells():
		cell.fog_state = FogState.ACTIVE
	MetricSystem.reset_to_defaults()
	GameManager.cycle_number = 1
	GameManager.is_running = true


func after_each() -> void:
	ai.queue_free()
	bmgr.queue_free()
	econ.queue_free()
	qmgr.queue_free()
	MetricSystem.reset_to_defaults()
	GameManager.cycle_number = 0
	GameManager.is_running = false
	_disconnect_all(EventBus.ai_buildings_placed)
	_disconnect_all(EventBus.building_placed)
	_disconnect_all(EventBus.phase_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Era gating ---


func test_era1_only_homestead_watchtower() -> void:
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 1, "Era 1 places 1 building")
	var bid: StringName = result[0][&"building_id"]
	assert_true(
		bid == &"homestead" or bid == &"watchtower",
		"Era 1 should only place homestead or watchtower",
	)


func test_era2_unlocks_more_buildings() -> void:
	GameManager.cycle_number = 6
	var allowed: Array = ai._get_era_buildings(2)
	assert_true(&"reactor" in allowed)
	assert_true(&"shrine" in allowed)
	assert_true(&"market" in allowed)
	assert_false(&"workshop" in allowed)


func test_era3_unlocks_workshop() -> void:
	var allowed: Array = ai._get_era_buildings(3)
	assert_true(&"workshop" in allowed)


# --- Placement count ---


func test_era1_places_1_building() -> void:
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 1)


func test_era2_places_2_buildings() -> void:
	GameManager.cycle_number = 6
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 2)


func test_era3_places_3_buildings() -> void:
	GameManager.cycle_number = 11
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 3)


# --- Biome affinity scoring ---


func test_reactor_scores_higher_on_rocky() -> void:
	var coord_rocky := Vector3i(1, -1, 0)
	var coord_plains := Vector3i(-1, 1, 0)
	grid.get_cell(coord_rocky).biome = BiomeType.Type.ROCKY
	grid.get_cell(coord_plains).biome = BiomeType.Type.PLAINS
	var bdata: BuildingData = ai.building_registry.get_data(&"reactor")
	var score_rocky: float = ai._score_placement(coord_rocky, grid.get_cell(coord_rocky), bdata)
	var score_plains: float = ai._score_placement(coord_plains, grid.get_cell(coord_plains), bdata)
	assert_gt(score_rocky, score_plains, "Reactor should prefer Rocky biome")


# --- Adjacency scoring ---


func test_market_scores_higher_next_to_homestead() -> void:
	var homestead_coord := Vector3i(1, -1, 0)
	var market_coord := Vector3i(0, -1, 1)
	var isolated_coord := Vector3i(-3, 3, 0)
	bmgr.place_building(homestead_coord, &"homestead")
	var bdata: BuildingData = ai.building_registry.get_data(&"market")
	var score_adjacent: float = ai._score_placement(
		market_coord, grid.get_cell(market_coord), bdata
	)
	var score_isolated: float = ai._score_placement(
		isolated_coord, grid.get_cell(isolated_coord), bdata
	)
	assert_gt(score_adjacent, score_isolated, "Market near Homestead should score higher")


# --- Metric need scoring ---


func test_high_pollution_favors_reducing_buildings() -> void:
	MetricSystem.push_metric(&"pollution", 0.9)
	# Homestead has anxiety: -0.01 but no pollution effect.
	# We need a building that reduces pollution.
	# Shrine has harmony push, no pollution effect in .tres.
	# Test the _calc_metric_need directly for a building that reduces pollution.
	var bdata := BuildingData.new()
	bdata.metric_effects = {&"pollution": -0.05}
	var need: float = ai._calc_metric_need(bdata)
	assert_gt(need, 0.0, "Should have positive need score when pollution is high")


func test_low_metric_no_need_for_reduction() -> void:
	MetricSystem.push_metric(&"pollution", 0.1)
	var bdata := BuildingData.new()
	bdata.metric_effects = {&"pollution": -0.05}
	var need: float = ai._calc_metric_need(bdata)
	assert_almost_eq(need, 0.0, 0.001, "Low pollution = no need to reduce it")


# --- Pollution penalty ---


func test_high_pollution_hex_penalizes_score() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.pollution_level = 0.9
	var penalty: float = ai._calc_pollution_penalty(cell)
	assert_lt(penalty, 0.0, "High pollution should give negative penalty")


func test_low_pollution_hex_no_penalty() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.pollution_level = 0.1
	var penalty: float = ai._calc_pollution_penalty(cell)
	assert_almost_eq(penalty, 0.0, 0.001, "Low pollution = no penalty")


func test_mid_pollution_interpolated_penalty() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.pollution_level = 0.5
	var penalty: float = ai._calc_pollution_penalty(cell)
	assert_lt(penalty, 0.0, "Mid pollution should have some penalty")
	assert_gt(penalty, ai.ai_config.pollution_max_penalty, "Should be less than max")


# --- Faction influence ---


func test_dominant_faction_boosts_preferred_buildings() -> void:
	qmgr.push_faction_morale(&"the_lens", 40)
	var bdata: BuildingData = ai.building_registry.get_data(&"reactor")
	var influence: float = ai._calc_faction_influence(bdata)
	assert_gt(influence, 0.0, "Lens faction should boost Reactor")


func test_non_preferred_building_no_faction_bonus() -> void:
	qmgr.push_faction_morale(&"the_lens", 40)
	var bdata: BuildingData = ai.building_registry.get_data(&"shrine")
	var influence: float = ai._calc_faction_influence(bdata)
	assert_almost_eq(influence, 0.0, 0.001, "Shrine not preferred by Lens")


# --- Alignment influence ---


func test_science_alignment_boosts_reactor() -> void:
	MetricSystem.push_alignment(0.5)
	var bdata: BuildingData = ai.building_registry.get_data(&"reactor")
	var boost: float = ai._calc_alignment_boost(bdata)
	assert_almost_eq(boost, UtilityAI.ALIGNMENT_BOOST, 0.001)


func test_magic_alignment_boosts_shrine() -> void:
	MetricSystem.push_alignment(-0.5)
	var bdata: BuildingData = ai.building_registry.get_data(&"shrine")
	var boost: float = ai._calc_alignment_boost(bdata)
	assert_almost_eq(boost, UtilityAI.ALIGNMENT_BOOST, 0.001)


func test_neutral_alignment_no_boost() -> void:
	var bdata: BuildingData = ai.building_registry.get_data(&"reactor")
	var boost: float = ai._calc_alignment_boost(bdata)
	assert_almost_eq(boost, 0.0, 0.001, "Neutral alignment gives no boost")


# --- Affordability ---


func test_cannot_place_unaffordable_building() -> void:
	var cfg := EconomyConfig.new()
	cfg.starting_gold = 1
	cfg.starting_mana = 0
	econ.economy_config = cfg
	econ._gold = 1
	econ._mana = 0
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 0, "Should place nothing if can't afford")


# --- Buildability filter ---


func test_skips_occupied_hexes() -> void:
	# Fill all hexes with buildings except one
	var empty_coord := Vector3i.ZERO
	for cell: HexCell in grid.get_all_cells():
		if cell.coord != empty_coord:
			cell.building_id = &"homestead"
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	if result.size() > 0:
		assert_eq(result[0][&"coord"], empty_coord)


func test_skips_fully_scarred_hexes() -> void:
	for cell: HexCell in grid.get_all_cells():
		cell.scar_state = 1.0
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 0, "No buildable hexes when all fully scarred")


# --- Empty grid ---


func test_no_placements_without_grid() -> void:
	ai.hex_grid = null
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 0)


func test_no_placements_without_building_manager() -> void:
	ai.building_manager = null
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 0)


# --- No economy manager ---


func test_works_without_economy_manager() -> void:
	ai.economy_manager = null
	bmgr.economy_manager = null
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_gt(result.size(), 0, "Should still place without economy check")


# --- Distance preference ---


func test_closer_hex_scores_higher_distance_bonus() -> void:
	var near: float = ai._calc_distance_bonus(Vector3i.ZERO)
	var far: float = ai._calc_distance_bonus(Vector3i(3, -3, 0))
	assert_gt(near, far, "Center hex should get higher distance bonus")


func test_beyond_radius_zero_distance_bonus() -> void:
	ai.ai_config.distance_falloff_radius = 2
	var far: float = ai._calc_distance_bonus(Vector3i(3, -3, 0))
	assert_almost_eq(far, 0.0, 0.001, "Beyond radius should get zero bonus")


# --- Multiple placements ---


func test_multiple_placements_use_different_hexes() -> void:
	GameManager.cycle_number = 6
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 2)
	assert_ne(result[0][&"coord"], result[1][&"coord"], "Should place on different hexes")


func test_resources_decrease_between_placements() -> void:
	var gold_before: int = econ.get_gold()
	GameManager.cycle_number = 6
	ai.evaluate_and_place()
	assert_lt(econ.get_gold(), gold_before, "Gold should decrease after placements")


# --- Phase hook ---


func test_only_triggers_on_observe_phase() -> void:
	var received := []
	EventBus.ai_buildings_placed.connect(func(p: Array) -> void: received.append(p))
	ai._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	ai._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	ai._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(received.size(), 0, "Should not trigger on non-OBSERVE phases")


func test_triggers_on_observe_phase() -> void:
	var received := []
	EventBus.ai_buildings_placed.connect(func(p: Array) -> void: received.append(p))
	ai._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_eq(received.size(), 1, "Should trigger on OBSERVE phase")


# --- Signal emission ---


func test_emits_ai_buildings_placed_signal() -> void:
	var received := []
	EventBus.ai_buildings_placed.connect(func(p: Array) -> void: received.append(p))
	GameManager.cycle_number = 1
	ai.evaluate_and_place()
	assert_eq(received.size(), 1)
	assert_gt(received[0].size(), 0)


func test_no_signal_when_nothing_placed() -> void:
	var received := []
	EventBus.ai_buildings_placed.connect(func(p: Array) -> void: received.append(p))
	for cell: HexCell in grid.get_all_cells():
		cell.scar_state = 1.0
	ai.evaluate_and_place()
	assert_eq(received.size(), 0, "No signal when nothing placed")


# --- Fog state filter ---


func test_skips_hidden_hexes() -> void:
	for cell: HexCell in grid.get_all_cells():
		cell.fog_state = FogState.HIDDEN
	GameManager.cycle_number = 1
	var result: Array[Dictionary] = ai.evaluate_and_place()
	assert_eq(result.size(), 0, "Should not place on hidden hexes")


# --- Zone affinity ---


func test_preferred_zone_boosts_score() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.zone_type = ZoneType.Type.RESIDENTIAL
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var zone: float = ai._calc_zone_affinity(cell, bdata)
	assert_almost_eq(zone, 0.3, 0.001, "Homestead in Residential = +0.3")


func test_conflicting_zone_penalizes_score() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.zone_type = ZoneType.Type.DEFENSE_PERIMETER
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var zone: float = ai._calc_zone_affinity(cell, bdata)
	assert_almost_eq(zone, -0.2, 0.001, "Homestead in Defense Perimeter = -0.2")


func test_no_zone_no_effect() -> void:
	var bdata := BuildingData.new()
	bdata.preferred_zone = ZoneType.Type.NONE
	bdata.conflicting_zone = ZoneType.Type.NONE
	var cell := HexCell.new()
	cell.zone_type = ZoneType.Type.CORE
	var zone: float = ai._calc_zone_affinity(cell, bdata)
	assert_almost_eq(zone, 0.0, 0.001, "No preference = no effect")


func test_none_zone_hex_neutral() -> void:
	var cell := HexCell.new()
	cell.zone_type = ZoneType.Type.NONE
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var zone: float = ai._calc_zone_affinity(cell, bdata)
	assert_almost_eq(zone, 0.0, 0.001, "NONE zone hex = neutral")


func test_zone_affinity_integrated_in_score() -> void:
	var coord_preferred := Vector3i(1, -1, 0)
	var coord_neutral := Vector3i(-1, 1, 0)
	grid.get_cell(coord_preferred).zone_type = ZoneType.Type.RESIDENTIAL
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var score_preferred: float = ai._score_placement(
		coord_preferred, grid.get_cell(coord_preferred), bdata
	)
	var score_neutral: float = ai._score_placement(
		coord_neutral, grid.get_cell(coord_neutral), bdata
	)
	assert_gt(score_preferred, score_neutral, "Preferred zone should boost total score")


# --- Cluster penalty ---


func test_cluster_penalty_with_3_same_neighbors() -> void:
	var center := Vector3i.ZERO
	var neighbors: Array[Vector3i] = HexMath.neighbors(center)
	for i: int in range(3):
		grid.get_cell(neighbors[i]).building_id = &"homestead"
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var penalty: float = ai._calc_cluster_penalty(center, bdata)
	assert_almost_eq(penalty, ai.ai_config.cluster_penalty, 0.001)


func test_no_penalty_with_2_same_neighbors() -> void:
	var center := Vector3i.ZERO
	var neighbors: Array[Vector3i] = HexMath.neighbors(center)
	for i: int in range(2):
		grid.get_cell(neighbors[i]).building_id = &"homestead"
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var penalty: float = ai._calc_cluster_penalty(center, bdata)
	assert_almost_eq(penalty, 0.0, 0.001, "Below threshold = no penalty")


func test_cluster_penalty_value_from_config() -> void:
	ai.ai_config.cluster_penalty = -0.5
	ai.ai_config.cluster_threshold = 2
	var center := Vector3i.ZERO
	var neighbors: Array[Vector3i] = HexMath.neighbors(center)
	for i: int in range(2):
		grid.get_cell(neighbors[i]).building_id = &"homestead"
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var penalty: float = ai._calc_cluster_penalty(center, bdata)
	assert_almost_eq(penalty, -0.5, 0.001, "Should use config penalty value")
