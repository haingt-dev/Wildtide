extends GutTest
## Tests for HexMath static utility class.

# ---------------------------------------------------------------------------
# Coordinate validation
# ---------------------------------------------------------------------------


func test_origin_is_valid() -> void:
	assert_true(HexMath.is_valid(Vector3i(0, 0, 0)), "Origin should be valid")


func test_valid_coords() -> void:
	assert_true(HexMath.is_valid(Vector3i(1, -1, 0)))
	assert_true(HexMath.is_valid(Vector3i(2, -3, 1)))
	assert_true(HexMath.is_valid(Vector3i(-5, 2, 3)))


func test_invalid_coords() -> void:
	assert_false(HexMath.is_valid(Vector3i(1, 1, 1)), "q+r+s=3 is invalid")
	assert_false(HexMath.is_valid(Vector3i(0, 0, 1)), "q+r+s=1 is invalid")


# ---------------------------------------------------------------------------
# Distance
# ---------------------------------------------------------------------------


func test_distance_to_self() -> void:
	var coord := Vector3i(3, -2, -1)
	assert_eq(HexMath.distance(coord, coord), 0)


func test_distance_to_neighbor() -> void:
	var origin := Vector3i(0, 0, 0)
	for offset: Vector3i in HexMath.NEIGHBOR_OFFSETS:
		assert_eq(HexMath.distance(origin, offset), 1, "Neighbor should be 1 step away")


func test_distance_symmetry() -> void:
	var a := Vector3i(2, -1, -1)
	var b := Vector3i(-1, 3, -2)
	assert_eq(HexMath.distance(a, b), HexMath.distance(b, a))


func test_distance_known_values() -> void:
	assert_eq(HexMath.distance(Vector3i(0, 0, 0), Vector3i(3, -2, -1)), 3)
	assert_eq(HexMath.distance(Vector3i(1, -1, 0), Vector3i(-2, 3, -1)), 4)


# ---------------------------------------------------------------------------
# Neighbors
# ---------------------------------------------------------------------------


func test_neighbor_count() -> void:
	var result := HexMath.neighbors(Vector3i(0, 0, 0))
	assert_eq(result.size(), 6)


func test_neighbors_are_valid() -> void:
	for n: Vector3i in HexMath.neighbors(Vector3i(1, -1, 0)):
		assert_true(HexMath.is_valid(n), "Neighbor %s should satisfy q+r+s=0" % str(n))


func test_neighbors_are_distance_one() -> void:
	var center := Vector3i(2, -3, 1)
	for n: Vector3i in HexMath.neighbors(center):
		assert_eq(HexMath.distance(center, n), 1)


# ---------------------------------------------------------------------------
# Ring
# ---------------------------------------------------------------------------


func test_ring_zero_is_center() -> void:
	var result := HexMath.ring(Vector3i(0, 0, 0), 0)
	assert_eq(result.size(), 1)
	assert_eq(result[0], Vector3i(0, 0, 0))


func test_ring_one_has_six() -> void:
	var result := HexMath.ring(Vector3i(0, 0, 0), 1)
	assert_eq(result.size(), 6)


func test_ring_two_has_twelve() -> void:
	var result := HexMath.ring(Vector3i(0, 0, 0), 2)
	assert_eq(result.size(), 12)


func test_ring_elements_are_correct_distance() -> void:
	var center := Vector3i(1, -1, 0)
	var radius := 3
	for coord: Vector3i in HexMath.ring(center, radius):
		assert_eq(HexMath.distance(center, coord), radius)


# ---------------------------------------------------------------------------
# Spiral
# ---------------------------------------------------------------------------


func test_spiral_zero_is_one() -> void:
	var result := HexMath.spiral(Vector3i(0, 0, 0), 0)
	assert_eq(result.size(), 1)


func test_spiral_count_formula() -> void:
	# Hex spiral of radius n has 3*n*(n+1)+1 hexes.
	for n: int in [1, 2, 3, 5, 9]:
		var expected: int = 3 * n * (n + 1) + 1
		var result := HexMath.spiral(Vector3i(0, 0, 0), n)
		assert_eq(result.size(), expected, "Spiral radius %d should have %d hexes" % [n, expected])


func test_spiral_all_valid() -> void:
	for coord: Vector3i in HexMath.spiral(Vector3i(0, 0, 0), 4):
		assert_true(HexMath.is_valid(coord))


# ---------------------------------------------------------------------------
# hex_to_world
# ---------------------------------------------------------------------------


func test_origin_maps_to_world_origin() -> void:
	var world := HexMath.hex_to_world(Vector3i(0, 0, 0))
	assert_almost_eq(world.x, 0.0, 0.001)
	assert_almost_eq(world.y, 0.0, 0.001)
	assert_almost_eq(world.z, 0.0, 0.001)


func test_hex_to_world_y_is_zero() -> void:
	var world := HexMath.hex_to_world(Vector3i(3, -2, -1))
	assert_almost_eq(world.y, 0.0, 0.001)


func test_known_hex_to_world() -> void:
	# For flat-top with size 2.0:
	# q=1, r=0, s=-1 -> x = 2.0 * 1.5 * 1 = 3.0, z = 2.0 * sqrt(3)/2 * 1 = sqrt(3)
	var world := HexMath.hex_to_world(Vector3i(1, 0, -1))
	assert_almost_eq(world.x, 3.0, 0.001)
	assert_almost_eq(world.z, HexMath.SQRT_3, 0.001)


# ---------------------------------------------------------------------------
# world_to_hex (roundtrip)
# ---------------------------------------------------------------------------


func test_world_origin_maps_to_hex_origin() -> void:
	var hex := HexMath.world_to_hex(Vector3(0.0, 0.0, 0.0))
	assert_eq(hex, Vector3i(0, 0, 0))


func test_roundtrip_hex_to_world_to_hex() -> void:
	var test_coords: Array[Vector3i] = [
		Vector3i(0, 0, 0),
		Vector3i(1, -1, 0),
		Vector3i(3, -2, -1),
		Vector3i(-2, 5, -3),
		Vector3i(0, -4, 4),
	]
	for coord: Vector3i in test_coords:
		var world := HexMath.hex_to_world(coord)
		var back := HexMath.world_to_hex(world)
		assert_eq(back, coord, "Roundtrip failed for %s" % str(coord))


func test_world_to_hex_snapping() -> void:
	# A point slightly off-center should snap to the correct hex.
	var world := HexMath.hex_to_world(Vector3i(2, -1, -1))
	var nudged := world + Vector3(0.1, 0.0, -0.1)
	var hex := HexMath.world_to_hex(nudged)
	assert_eq(hex, Vector3i(2, -1, -1))


# ---------------------------------------------------------------------------
# Line
# ---------------------------------------------------------------------------


func test_line_to_self() -> void:
	var result := HexMath.line(Vector3i(0, 0, 0), Vector3i(0, 0, 0))
	assert_eq(result.size(), 1)
	assert_eq(result[0], Vector3i(0, 0, 0))


func test_line_to_neighbor() -> void:
	var a := Vector3i(0, 0, 0)
	var b := Vector3i(1, -1, 0)
	var result := HexMath.line(a, b)
	assert_eq(result.size(), 2)
	assert_eq(result[0], a)
	assert_eq(result[1], b)


func test_line_length() -> void:
	var a := Vector3i(0, 0, 0)
	var b := Vector3i(3, -2, -1)
	var result := HexMath.line(a, b)
	# Line length = distance + 1
	assert_eq(result.size(), HexMath.distance(a, b) + 1)


func test_line_all_valid() -> void:
	var a := Vector3i(-2, 3, -1)
	var b := Vector3i(4, -3, -1)
	for coord: Vector3i in HexMath.line(a, b):
		assert_true(HexMath.is_valid(coord))
