extends GutTest
## Unit tests for hex cube coordinate math.
##
## These helper functions will be replaced by actual HexGrid class methods
## once the hex grid system is implemented. For now they validate the
## core math independently.

## Flat-top hex: 6 neighbor offsets in cube coordinates.
const NEIGHBOR_OFFSETS: Array[Vector3i] = [
	Vector3i(+1, -1, 0),
	Vector3i(+1, 0, -1),
	Vector3i(0, +1, -1),
	Vector3i(-1, +1, 0),
	Vector3i(-1, 0, +1),
	Vector3i(0, -1, +1),
]

# ---------------------------------------------------------------------------
# Helpers (inline until HexGrid exists)
# ---------------------------------------------------------------------------


func _hex_distance(a: Vector3i, b: Vector3i) -> int:
	return (absi(a.x - b.x) + absi(a.y - b.y) + absi(a.z - b.z)) / 2


func _hex_is_valid(coord: Vector3i) -> bool:
	return coord.x + coord.y + coord.z == 0


func _hex_neighbors(coord: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for offset in NEIGHBOR_OFFSETS:
		result.append(coord + offset)
	return result


# ---------------------------------------------------------------------------
# Coordinate validation
# ---------------------------------------------------------------------------


func test_origin_is_valid() -> void:
	assert_true(_hex_is_valid(Vector3i(0, 0, 0)), "Origin should be valid")


func test_valid_coord() -> void:
	# q + r + s must equal 0
	assert_true(_hex_is_valid(Vector3i(1, -1, 0)))
	assert_true(_hex_is_valid(Vector3i(2, -3, 1)))
	assert_true(_hex_is_valid(Vector3i(-5, 2, 3)))


func test_invalid_coord() -> void:
	assert_false(_hex_is_valid(Vector3i(1, 1, 1)), "q+r+s=3 is invalid")
	assert_false(_hex_is_valid(Vector3i(0, 0, 1)), "q+r+s=1 is invalid")


# ---------------------------------------------------------------------------
# Distance
# ---------------------------------------------------------------------------


func test_distance_to_self_is_zero() -> void:
	var coord := Vector3i(3, -2, -1)
	assert_eq(_hex_distance(coord, coord), 0)


func test_distance_to_neighbor_is_one() -> void:
	var origin := Vector3i(0, 0, 0)
	for offset in NEIGHBOR_OFFSETS:
		assert_eq(_hex_distance(origin, offset), 1, "Neighbor should be 1 step away")


func test_distance_symmetry() -> void:
	var a := Vector3i(2, -1, -1)
	var b := Vector3i(-1, 3, -2)
	assert_eq(_hex_distance(a, b), _hex_distance(b, a), "Distance should be symmetric")


func test_distance_known_value() -> void:
	# (0,0,0) to (3,-2,-1) should be 3
	assert_eq(_hex_distance(Vector3i(0, 0, 0), Vector3i(3, -2, -1)), 3)


# ---------------------------------------------------------------------------
# Neighbors
# ---------------------------------------------------------------------------


func test_neighbor_count() -> void:
	var neighbors := _hex_neighbors(Vector3i(0, 0, 0))
	assert_eq(neighbors.size(), 6, "Each hex should have exactly 6 neighbors")


func test_neighbors_are_valid() -> void:
	var neighbors := _hex_neighbors(Vector3i(1, -1, 0))
	for n in neighbors:
		assert_true(_hex_is_valid(n), "Neighbor %s should satisfy q+r+s=0" % str(n))


func test_neighbors_are_distance_one() -> void:
	var center := Vector3i(2, -3, 1)
	var neighbors := _hex_neighbors(center)
	for n in neighbors:
		assert_eq(_hex_distance(center, n), 1, "Neighbor should be 1 step from center")
