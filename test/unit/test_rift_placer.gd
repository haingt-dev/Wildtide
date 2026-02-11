extends GutTest
## Tests for RiftPlacer.


func test_three_positions_returned() -> void:
	var positions := RiftPlacer.get_rift_positions(9)
	assert_eq(positions.size(), 3)


func test_positions_are_valid_coords() -> void:
	for pos: Vector3i in RiftPlacer.get_rift_positions(9):
		assert_true(HexMath.is_valid(pos), "Rift at %s should be valid" % str(pos))


func test_positions_are_near_edge() -> void:
	var radius := 9
	for pos: Vector3i in RiftPlacer.get_rift_positions(radius):
		var dist: int = HexMath.distance(Vector3i.ZERO, pos)
		assert_gt(dist, radius / 2, "Rift should be in outer half of map")
		assert_lte(dist, radius, "Rift should be within map bounds")


func test_positions_are_spread_apart() -> void:
	var positions := RiftPlacer.get_rift_positions(9)
	# Each pair of rifts should be well separated.
	for i: int in range(3):
		for j: int in range(i + 1, 3):
			var dist: int = HexMath.distance(positions[i], positions[j])
			assert_gt(dist, 5, "Rifts %d and %d should be spread apart" % [i, j])


func test_offset_angle_changes_positions() -> void:
	var pos_a := RiftPlacer.get_rift_positions(9, 0.0)
	var pos_b := RiftPlacer.get_rift_positions(9, 60.0)
	# At least one position should differ.
	var any_different: bool = false
	for i: int in range(3):
		if pos_a[i] != pos_b[i]:
			any_different = true
			break
	assert_true(any_different, "Different offset angles should produce different positions")
