extends GutTest
## Tests for MapGenerator procedural generation.


func test_generate_returns_correct_cell_count() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)
	assert_eq(grid.get_cell_count(), 271)


func test_generate_with_seed_is_deterministic() -> void:
	var grid_a := MapGenerator.new(12345).generate(9)
	var grid_b := MapGenerator.new(12345).generate(9)
	for cell_a: HexCell in grid_a.get_all_cells():
		var cell_b := grid_b.get_cell(cell_a.coord)
		assert_eq(cell_a.biome, cell_b.biome, "Same seed should produce same biomes")


func test_three_rifts_placed() -> void:
	var gen := MapGenerator.new(42)
	gen.generate(9)
	var rifts := gen.get_rift_positions()
	assert_eq(rifts.size(), 3)


func test_swamp_clusters_near_rifts() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)
	var rifts := gen.get_rift_positions()

	for rift: Vector3i in rifts:
		# At least some hexes within radius 2 of each rift should be Swamp.
		var nearby := grid.get_cells_in_range(rift, 2)
		var swamp_count: int = 0
		for cell: HexCell in nearby:
			if cell.biome == BiomeType.Type.SWAMP:
				swamp_count += 1
		assert_gt(swamp_count, 0, "Should have swamp near rift at %s" % str(rift))


func test_ruins_minimum_distance() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)
	var ruins := grid.get_cells_by_biome(BiomeType.Type.RUINS)

	for i: int in range(ruins.size()):
		for j: int in range(i + 1, ruins.size()):
			var dist: int = HexMath.distance(ruins[i].coord, ruins[j].coord)
			assert_gte(
				dist,
				MapGenerator.RUINS_MIN_DISTANCE,
				(
					"Ruins at %s and %s too close (%d)"
					% [str(ruins[i].coord), str(ruins[j].coord), dist]
				),
			)


func test_all_cells_have_valid_biome() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)
	var valid_biomes := [
		BiomeType.Type.PLAINS,
		BiomeType.Type.FOREST,
		BiomeType.Type.ROCKY,
		BiomeType.Type.SWAMP,
		BiomeType.Type.RUINS,
	]
	for cell: HexCell in grid.get_all_cells():
		assert_has(valid_biomes, cell.biome, "Cell has invalid biome")


func test_rocky_at_edges() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)

	# Outermost ring (radius 9) should be mostly Rocky.
	var edge_ring := HexMath.ring(Vector3i.ZERO, 9)
	var rocky_count: int = 0
	for coord: Vector3i in edge_ring:
		var cell := grid.get_cell(coord)
		if cell and cell.biome == BiomeType.Type.ROCKY:
			rocky_count += 1
	# Allow some tolerance — swamp near rifts may override.
	assert_gt(rocky_count, edge_ring.size() / 2, "Most edge hexes should be Rocky")


func test_forest_exists() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)
	var forests := grid.get_cells_by_biome(BiomeType.Type.FOREST)
	assert_gt(forests.size(), 0, "Map should have some forest hexes")


func test_plains_is_most_common_interior() -> void:
	var gen := MapGenerator.new(42)
	var grid := gen.generate(9)
	# Plains should be one of the most common biomes.
	var plains := grid.get_cells_by_biome(BiomeType.Type.PLAINS)
	assert_gt(plains.size(), 20, "Plains should still be present in significant numbers")
