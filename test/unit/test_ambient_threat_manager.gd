extends GutTest
## Tests for AmbientThreatManager — ambient threat level calculation per hex.

var mgr: AmbientThreatManager
var grid: HexGrid
var bmgr: BuildingManager


func before_each() -> void:
	mgr = AmbientThreatManager.new()
	add_child(mgr)
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	mgr.hex_grid = grid
	bmgr = BuildingManager.new()
	add_child(bmgr)
	bmgr.hex_grid = grid
	mgr.building_manager = bmgr


func after_each() -> void:
	mgr.queue_free()
	bmgr.queue_free()
	_disconnect_all(EventBus.phase_changed)
	_disconnect_all(EventBus.wave_ended)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Basic calculation ---


func test_clean_hex_has_low_threat() -> void:
	mgr._recalculate_all()
	var cell: HexCell = grid.get_cell(Vector3i.ZERO)
	assert_lt(cell.ambient_threat_level, 0.3, "Clean hex should have low threat")


func test_high_rift_density_increases_threat() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.rift_density = 0.8
	mgr._recalculate_all()
	assert_gt(cell.ambient_threat_level, 0.0, "High rift density should increase threat")


func test_high_pollution_increases_threat() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.pollution_level = 0.9
	mgr._recalculate_all()
	assert_gt(
		cell.ambient_threat_level, 0.3, "High pollution should push threat above low threshold"
	)


func test_ruins_biome_increases_nearby_threat() -> void:
	var ruin_coord := Vector3i(2, -2, 0)
	var ruin_cell: HexCell = grid.get_cell(ruin_coord)
	ruin_cell.biome = BiomeType.Type.RUINS
	mgr._recalculate_all()
	# Adjacent hex should have ruin proximity contribution
	var neighbor: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	assert_gt(
		neighbor.ambient_threat_level,
		grid.get_cell(Vector3i(-2, 2, 0)).ambient_threat_level,
		"Hex near ruins should have higher threat",
	)


func test_swamp_biome_has_higher_base_threat() -> void:
	var swamp_cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	swamp_cell.biome = BiomeType.Type.SWAMP
	mgr._recalculate_all()
	var plains_cell: HexCell = grid.get_cell(Vector3i(-1, 1, 0))
	assert_gt(
		swamp_cell.ambient_threat_level,
		plains_cell.ambient_threat_level,
		"Swamp should have higher base threat than Plains",
	)


# --- Post-wave clear ---


func test_post_wave_reduces_threat() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.rift_density = 0.5
	cell.pollution_level = 0.5
	mgr._recalculate_all()
	var normal_threat: float = cell.ambient_threat_level
	# Simulate wave end
	mgr._on_wave_ended(1)
	mgr._recalculate_all()
	assert_lt(cell.ambient_threat_level, normal_threat, "Threat should be lower right after wave")


func test_post_wave_timer_recovers() -> void:
	mgr._on_wave_ended(1)
	assert_eq(mgr._post_wave_timer, 2)
	mgr._tick_post_wave_timer()
	assert_eq(mgr._post_wave_timer, 1)
	mgr._tick_post_wave_timer()
	assert_eq(mgr._post_wave_timer, 0)


# --- Watchtower suppression ---


func test_watchtower_suppresses_rift_threat() -> void:
	var coord := Vector3i(1, -1, 0)
	var cell: HexCell = grid.get_cell(coord)
	cell.rift_density = 0.8
	mgr._recalculate_all()
	var unsuppressed: float = cell.ambient_threat_level
	# Place a watchtower nearby
	bmgr.place_building(Vector3i(0, 0, 0), &"watchtower")
	# Force completion
	bmgr._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	mgr._recalculate_all()
	assert_lt(
		cell.ambient_threat_level,
		unsuppressed,
		"Watchtower should reduce nearby threat",
	)


# --- Construction modifier ---


func test_construction_modifier_normal() -> void:
	var mod: float = AmbientThreatManager.get_construction_modifier(0.1)
	assert_almost_eq(mod, 1.0, 0.001)


func test_construction_modifier_low_threat() -> void:
	var mod: float = AmbientThreatManager.get_construction_modifier(0.4)
	assert_almost_eq(mod, 0.9, 0.001)


func test_construction_modifier_medium_threat() -> void:
	var mod: float = AmbientThreatManager.get_construction_modifier(0.7)
	assert_almost_eq(mod, 0.75, 0.001)


func test_construction_modifier_high_threat() -> void:
	var mod: float = AmbientThreatManager.get_construction_modifier(0.9)
	assert_almost_eq(mod, 0.0, 0.001)


# --- Yield modifier ---


func test_yield_modifier_normal() -> void:
	assert_almost_eq(AmbientThreatManager.get_yield_modifier(0.2), 1.0, 0.001)


func test_yield_modifier_medium() -> void:
	assert_almost_eq(AmbientThreatManager.get_yield_modifier(0.5), 0.9, 0.001)


func test_yield_modifier_high() -> void:
	assert_almost_eq(AmbientThreatManager.get_yield_modifier(0.7), 0.8, 0.001)


func test_yield_modifier_blocked() -> void:
	assert_almost_eq(AmbientThreatManager.get_yield_modifier(0.9), 0.0, 0.001)


# --- Phase triggers ---


func test_recalculate_on_evolve_phase() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.rift_density = 0.6
	mgr._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_gt(cell.ambient_threat_level, 0.0, "Should recalculate on EVOLVE")


func test_no_recalculate_on_observe() -> void:
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.rift_density = 0.6
	mgr._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_almost_eq(cell.ambient_threat_level, 0.0, 0.001, "Should not recalculate on OBSERVE")
