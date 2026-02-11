extends GutTest
## Tests for HexGrid Resource.

var grid: HexGrid


func before_each() -> void:
	grid = HexGrid.new()
	grid.initialize_hex_map(9)


# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------


func test_initialize_creates_correct_count() -> void:
	# Radius 9 → 3*9*10+1 = 271 hexes.
	assert_eq(grid.get_cell_count(), 271)


func test_all_cells_are_valid_coords() -> void:
	for coord: Vector3i in grid.get_all_coords():
		assert_true(HexMath.is_valid(coord), "Coord %s should be valid" % str(coord))


func test_all_cells_default_to_plains() -> void:
	for cell: HexCell in grid.get_all_cells():
		assert_eq(cell.biome, BiomeType.Type.PLAINS)


func test_smaller_radius() -> void:
	var small := HexGrid.new()
	small.initialize_hex_map(2)
	# Radius 2 → 3*2*3+1 = 19 hexes.
	assert_eq(small.get_cell_count(), 19)


# ---------------------------------------------------------------------------
# Cell access
# ---------------------------------------------------------------------------


func test_get_cell_at_origin() -> void:
	var cell := grid.get_cell(Vector3i(0, 0, 0))
	assert_not_null(cell)
	assert_eq(cell.coord, Vector3i(0, 0, 0))


func test_get_cell_returns_null_for_missing() -> void:
	var cell := grid.get_cell(Vector3i(100, -100, 0))
	assert_null(cell)


func test_has_cell() -> void:
	assert_true(grid.has_cell(Vector3i(0, 0, 0)))
	assert_false(grid.has_cell(Vector3i(100, -100, 0)))


func test_set_cell_replaces() -> void:
	var new_cell := HexCell.new()
	new_cell.biome = BiomeType.Type.FOREST
	grid.set_cell(Vector3i(0, 0, 0), new_cell)
	var fetched := grid.get_cell(Vector3i(0, 0, 0))
	assert_eq(fetched.biome, BiomeType.Type.FOREST)


# ---------------------------------------------------------------------------
# Neighbors
# ---------------------------------------------------------------------------


func test_neighbors_of_center() -> void:
	var neighbors := grid.get_neighbors_of(Vector3i(0, 0, 0))
	assert_eq(neighbors.size(), 6, "Center should have 6 neighbors in radius-9 grid")


func test_neighbors_of_edge_has_fewer() -> void:
	# A hex at the edge of the grid should have fewer than 6 neighbors.
	# Hex at (9, -9, 0) is on the boundary — some neighbors are outside.
	var neighbors := grid.get_neighbors_of(Vector3i(9, -9, 0))
	assert_lt(neighbors.size(), 6, "Edge hex should have fewer than 6 neighbors")


# ---------------------------------------------------------------------------
# Query
# ---------------------------------------------------------------------------


func test_get_cells_by_biome() -> void:
	# All cells start as PLAINS.
	var plains := grid.get_cells_by_biome(BiomeType.Type.PLAINS)
	assert_eq(plains.size(), 271)
	var forest := grid.get_cells_by_biome(BiomeType.Type.FOREST)
	assert_eq(forest.size(), 0)


func test_get_cells_by_biome_after_change() -> void:
	var cell := grid.get_cell(Vector3i(0, 0, 0))
	cell.biome = BiomeType.Type.SWAMP
	var swamp := grid.get_cells_by_biome(BiomeType.Type.SWAMP)
	assert_eq(swamp.size(), 1)


func test_get_cells_in_range() -> void:
	var cells := grid.get_cells_in_range(Vector3i(0, 0, 0), 1)
	assert_eq(cells.size(), 7, "Range 1 from center = 1 + 6 = 7")


# ---------------------------------------------------------------------------
# Clear and serialization
# ---------------------------------------------------------------------------


func test_clear_empties_grid() -> void:
	grid.clear()
	assert_eq(grid.get_cell_count(), 0)
	assert_null(grid.get_cell(Vector3i(0, 0, 0)))


func test_rebuild_lookup_from_array() -> void:
	# Simulate loading: clear runtime dict, then rebuild from array.
	grid._cells.clear()
	assert_eq(grid.get_cell_count(), 0)
	grid.rebuild_lookup()
	assert_eq(grid.get_cell_count(), 271)


func test_sync_array_matches_dict() -> void:
	grid.sync_array()
	assert_eq(grid._cell_array.size(), grid.get_cell_count())
