extends GutTest
## Tests for HexCell Resource.


func test_default_values() -> void:
	var cell := HexCell.new()
	assert_eq(cell.coord, Vector3i.ZERO)
	assert_eq(cell.biome, BiomeType.Type.PLAINS)
	assert_eq(cell.building_id, &"")
	assert_eq(cell.scar_state, 0.0)
	assert_eq(cell.exploration_state, 0)
	assert_eq(cell.alignment_local, 0.0)


func test_is_empty_when_no_building() -> void:
	var cell := HexCell.new()
	assert_true(cell.is_empty())


func test_is_not_empty_with_building() -> void:
	var cell := HexCell.new()
	cell.building_id = &"barracks"
	assert_false(cell.is_empty())


func test_is_buildable_when_empty_and_pristine() -> void:
	var cell := HexCell.new()
	assert_true(cell.is_buildable())


func test_is_not_buildable_when_fully_scarred() -> void:
	var cell := HexCell.new()
	cell.scar_state = 1.0
	assert_false(cell.is_buildable())


func test_is_not_buildable_with_building() -> void:
	var cell := HexCell.new()
	cell.building_id = &"tower"
	assert_false(cell.is_buildable())


func test_apply_scar_adds() -> void:
	var cell := HexCell.new()
	cell.apply_scar(0.3)
	assert_almost_eq(cell.scar_state, 0.3, 0.001)
	cell.apply_scar(0.5)
	assert_almost_eq(cell.scar_state, 0.8, 0.001)


func test_apply_scar_clamps_at_one() -> void:
	var cell := HexCell.new()
	cell.apply_scar(1.5)
	assert_almost_eq(cell.scar_state, 1.0, 0.001)


func test_apply_scar_clamps_at_zero() -> void:
	var cell := HexCell.new()
	cell.scar_state = 0.5
	cell.apply_scar(-1.0)
	assert_almost_eq(cell.scar_state, 0.0, 0.001)


func test_biome_assignment() -> void:
	var cell := HexCell.new()
	cell.biome = BiomeType.Type.FOREST
	assert_eq(cell.biome, BiomeType.Type.FOREST)


func test_default_fog_state_is_active() -> void:
	var cell := HexCell.new()
	assert_eq(cell.fog_state, FogState.ACTIVE)


func test_default_region_is_starting() -> void:
	var cell := HexCell.new()
	assert_eq(cell.region, RegionType.Type.STARTING)


func test_default_rift_density() -> void:
	var cell := HexCell.new()
	assert_eq(cell.rift_density, 0.0)


func test_default_pollution_level() -> void:
	var cell := HexCell.new()
	assert_eq(cell.pollution_level, 0.0)
