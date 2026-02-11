class_name RiftPlacer
extends RefCounted
## Calculates Rift positions for the triangular threat pattern.
## Rifts are placed at 3 evenly-spaced positions near the map edge.


## Return 3 hex coordinates near the map edge, 120 degrees apart.
## offset_angle adds rotation variance (in degrees).
static func get_rift_positions(
	map_radius: int,
	offset_angle: float = 0.0,
) -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var edge_radius: int = map_radius - 1

	for i: int in range(3):
		var angle := deg_to_rad(120.0 * i + offset_angle)
		# Convert polar to world coords, then snap to hex.
		var world_x: float = edge_radius * HexMath.HEX_SIZE * 1.5 * cos(angle)
		var world_z: float = edge_radius * HexMath.HEX_SIZE * 1.5 * sin(angle)
		var hex := HexMath.world_to_hex(Vector3(world_x, 0.0, world_z))

		# Clamp to within the map radius if needed.
		if HexMath.distance(Vector3i.ZERO, hex) > map_radius:
			hex = _clamp_to_radius(hex, map_radius)

		positions.append(hex)

	return positions


## Move a coordinate toward the origin until it's within the given radius.
static func _clamp_to_radius(coord: Vector3i, radius: int) -> Vector3i:
	var result := coord
	while HexMath.distance(Vector3i.ZERO, result) > radius:
		# Step toward origin along the axis with the largest magnitude.
		var ax: int = absi(result.x)
		var ay: int = absi(result.y)
		var az: int = absi(result.z)
		if ax >= ay and ax >= az:
			result.x -= signi(result.x)
		elif ay >= az:
			result.y -= signi(result.y)
		else:
			result.z -= signi(result.z)
		# Fix cube constraint.
		var diff: int = result.x + result.y + result.z
		if diff != 0:
			if ax >= ay and ax >= az:
				result.x -= diff
			elif ay >= az:
				result.y -= diff
			else:
				result.z -= diff
	return result
