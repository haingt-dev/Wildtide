extends GutTest
## Tests for UtilityAI weapon buildings — era gating, threat direction,
## weapon diversity, defense need, negative space, and alignment.

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


# --- Weapon era gating ---


func test_era1_no_weapon_buildings() -> void:
	var allowed: Array = ai._get_era_buildings(1)
	for wid: StringName in UtilityAI.WEAPON_BUILDINGS:
		assert_false(wid in allowed, "%s should NOT be in Era 1" % wid)


func test_era2_unlocks_weapon_buildings() -> void:
	var allowed: Array = ai._get_era_buildings(2)
	assert_true(&"tesla_coil" in allowed, "Tesla Coil unlocks in Era 2")
	assert_true(&"rift_ward" in allowed, "Rift Ward unlocks in Era 2")
	assert_false(&"siege_ballista" in allowed, "Siege Ballista NOT in Era 2")
	assert_false(&"entropy_spire" in allowed, "Entropy Spire NOT in Era 2")


func test_era3_unlocks_all_weapons() -> void:
	var allowed: Array = ai._get_era_buildings(3)
	for wid: StringName in UtilityAI.WEAPON_BUILDINGS:
		assert_true(wid in allowed, "%s should be in Era 3" % wid)


# --- Weapon zone scoring ---


func test_weapon_scores_higher_in_defense_perimeter() -> void:
	var coord_def := Vector3i(1, -1, 0)
	var coord_none := Vector3i(-1, 1, 0)
	grid.get_cell(coord_def).zone_type = ZoneType.Type.DEFENSE_PERIMETER
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var zone_def: float = ai._calc_zone_affinity(grid.get_cell(coord_def), bdata)
	var zone_none: float = ai._calc_zone_affinity(grid.get_cell(coord_none), bdata)
	assert_gt(zone_def, zone_none, "Weapon should score higher in Defense Perimeter")


func test_weapon_penalized_in_conflicting_zone() -> void:
	var coord := Vector3i(1, -1, 0)
	grid.get_cell(coord).zone_type = ZoneType.Type.RESIDENTIAL
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var zone: float = ai._calc_zone_affinity(grid.get_cell(coord), bdata)
	assert_lt(zone, 0.0, "Tesla Coil in Residential = penalty")


# --- Threat direction ---


func test_threat_bonus_for_weapon_on_high_rift_density() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.rift_density = 0.8
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var bonus: float = ai._calc_threat_bonus(cell, bdata)
	assert_almost_eq(bonus, 0.8 * UtilityAI.THREAT_DIRECTION_BONUS, 0.001)


func test_no_threat_bonus_for_non_weapon() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.rift_density = 0.8
	var bdata: BuildingData = ai.building_registry.get_data(&"homestead")
	var bonus: float = ai._calc_threat_bonus(cell, bdata)
	assert_almost_eq(bonus, 0.0, 0.001, "Non-weapon gets no threat bonus")


func test_threat_bonus_zero_on_low_density() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.rift_density = 0.0
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var bonus: float = ai._calc_threat_bonus(cell, bdata)
	assert_almost_eq(bonus, 0.0, 0.001, "Zero rift density = zero bonus")


# --- Weapon diversity ---


func test_weapon_diversity_penalty_after_max() -> void:
	var cells: Array[HexCell] = grid.get_all_cells()
	var placed: int = 0
	for cell: HexCell in cells:
		if placed >= 2:
			break
		cell.building_id = &"tesla_coil"
		cell.zone_type = ZoneType.Type.DEFENSE_PERIMETER
		placed += 1
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var penalty: float = ai._calc_weapon_diversity_penalty(bdata)
	assert_almost_eq(penalty, ai.ai_config.weapon_diversity_penalty, 0.001)


func test_no_diversity_penalty_below_max() -> void:
	var cells: Array[HexCell] = grid.get_all_cells()
	cells[0].building_id = &"tesla_coil"
	cells[0].zone_type = ZoneType.Type.DEFENSE_PERIMETER
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var penalty: float = ai._calc_weapon_diversity_penalty(bdata)
	assert_almost_eq(penalty, 0.0, 0.001, "1 < max = no penalty")


# --- Defense need ---


func test_defense_need_boosts_weapon_when_defense_low() -> void:
	ai.ai_config.defense_critical_low = 0.3
	var bdata: BuildingData = ai.building_registry.get_data(&"watchtower")
	var bonus: float = ai._calc_defense_need_bonus(bdata)
	assert_gt(bonus, 0.0, "Defense building should get bonus when defense is low")


func test_no_defense_bonus_when_defense_adequate() -> void:
	for cell: HexCell in grid.get_all_cells():
		cell.building_id = &"watchtower"
	ai.ai_config.defense_critical_low = 0.1
	var bdata: BuildingData = ai.building_registry.get_data(&"watchtower")
	var bonus: float = ai._calc_defense_need_bonus(bdata)
	assert_almost_eq(bonus, 0.0, 0.001, "Adequate defense = no bonus")


# --- Negative space ---


func test_zone_fill_cap_excludes_full_zones() -> void:
	var residential_count: int = 0
	for cell: HexCell in grid.get_all_cells():
		cell.zone_type = ZoneType.Type.RESIDENTIAL
		residential_count += 1
	# Fill 80% with buildings (over 70% cap).
	var fill_target: int = int(residential_count * 0.8)
	var filled: int = 0
	for cell: HexCell in grid.get_all_cells():
		if filled >= fill_target:
			break
		cell.building_id = &"homestead"
		filled += 1
	var candidates: Array[Vector3i] = ai._collect_candidates()
	assert_eq(candidates.size(), 0, "Over-filled zone should yield no candidates")


func test_scar_avoidance_skips_heavy_scars() -> void:
	for cell: HexCell in grid.get_all_cells():
		cell.scar_state = 0.9
	var candidates: Array[Vector3i] = ai._collect_candidates()
	assert_eq(candidates.size(), 0, "Heavy scar hexes should be excluded")


# --- Alignment gating for weapons ---


func test_science_alignment_boosts_tesla_coil() -> void:
	MetricSystem.push_alignment(0.5)
	var bdata: BuildingData = ai.building_registry.get_data(&"tesla_coil")
	var boost: float = ai._calc_alignment_boost(bdata)
	assert_almost_eq(boost, UtilityAI.ALIGNMENT_BOOST, 0.001)


func test_magic_alignment_boosts_rift_ward() -> void:
	MetricSystem.push_alignment(-0.5)
	var bdata: BuildingData = ai.building_registry.get_data(&"rift_ward")
	var boost: float = ai._calc_alignment_boost(bdata)
	assert_almost_eq(boost, UtilityAI.ALIGNMENT_BOOST, 0.001)
