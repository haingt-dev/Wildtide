class_name HexMath
extends RefCounted
## Pure static utility class for flat-top hexagonal grid math.
## All functions are static — do not instantiate this class.
## Coordinate system: cube coordinates (q, r, s) where q + r + s = 0.
## World space: hexes lie on the XZ plane, Y is up.

## Distance from hex center to vertex (outer radius).
const HEX_SIZE: float = 2.0

## Precomputed sqrt(3) for hex geometry.
const SQRT_3: float = 1.7320508075688772

## Flat-top hex: 6 neighbor offsets in cube coordinates.
## Ordered clockwise starting from East.
const NEIGHBOR_OFFSETS: Array[Vector3i] = [
	Vector3i(+1, -1, 0),  # 0: E
	Vector3i(+1, 0, -1),  # 1: NE
	Vector3i(0, +1, -1),  # 2: NW
	Vector3i(-1, +1, 0),  # 3: W
	Vector3i(-1, 0, +1),  # 4: SW
	Vector3i(0, -1, +1),  # 5: SE
]


static func is_valid(coord: Vector3i) -> bool:
	return coord.x + coord.y + coord.z == 0


static func distance(a: Vector3i, b: Vector3i) -> int:
	return (absi(a.x - b.x) + absi(a.y - b.y) + absi(a.z - b.z)) / 2


static func neighbors(coord: Vector3i) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for offset in NEIGHBOR_OFFSETS:
		result.append(coord + offset)
	return result


static func ring(center: Vector3i, radius: int) -> Array[Vector3i]:
	if radius <= 0:
		return [center]
	var results: Array[Vector3i] = []
	# Start at the hex reached by going radius steps in direction 4 (SW).
	var current: Vector3i = center + NEIGHBOR_OFFSETS[4] * radius
	# Walk 6 edges of the ring, each edge has `radius` steps.
	for edge_dir: int in range(6):
		for _step: int in range(radius):
			results.append(current)
			current = current + NEIGHBOR_OFFSETS[edge_dir]
	return results


static func spiral(center: Vector3i, radius: int) -> Array[Vector3i]:
	var results: Array[Vector3i] = [center]
	for r: int in range(1, radius + 1):
		results.append_array(ring(center, r))
	return results


## Convert cube coordinates to 3D world position (flat-top).
## Returns a Vector3 on the XZ plane (y = 0).
static func hex_to_world(coord: Vector3i) -> Vector3:
	var x: float = HEX_SIZE * 1.5 * coord.x
	var z: float = HEX_SIZE * (SQRT_3 * 0.5 * coord.x + SQRT_3 * coord.y)
	return Vector3(x, 0.0, z)


## Convert 3D world position to the nearest cube coordinate (flat-top).
## Only uses the x and z components; y is ignored.
static func world_to_hex(world_pos: Vector3) -> Vector3i:
	var q_frac: float = world_pos.x / (HEX_SIZE * 1.5)
	var r_frac: float = (-world_pos.x / 3.0 + SQRT_3 / 3.0 * world_pos.z) / HEX_SIZE
	var s_frac: float = -q_frac - r_frac
	return _cube_round(q_frac, r_frac, s_frac)


## Round fractional cube coordinates to the nearest valid integer cube coord.
static func _cube_round(fq: float, fr: float, fs: float) -> Vector3i:
	var qi: int = roundi(fq)
	var ri: int = roundi(fr)
	var si: int = roundi(fs)

	var q_diff: float = absf(qi - fq)
	var r_diff: float = absf(ri - fr)
	var s_diff: float = absf(si - fs)

	if q_diff > r_diff and q_diff > s_diff:
		qi = -ri - si
	elif r_diff > s_diff:
		ri = -qi - si
	else:
		si = -qi - ri

	return Vector3i(qi, ri, si)


## Linearly interpolate between two hex coordinates and return the hex at t.
static func hex_lerp(a: Vector3i, b: Vector3i, t: float) -> Vector3i:
	# Add small nudge to avoid ambiguous midpoints on hex edges.
	var nudge: float = 1e-6
	var fq: float = lerpf(float(a.x) + nudge, float(b.x) + nudge, t)
	var fr: float = lerpf(float(a.y) + nudge, float(b.y) + nudge, t)
	var fs: float = lerpf(float(a.z) - 2.0 * nudge, float(b.z) - 2.0 * nudge, t)
	return _cube_round(fq, fr, fs)


## Return all hexes along the straight line from a to b (inclusive).
static func line(a: Vector3i, b: Vector3i) -> Array[Vector3i]:
	var dist: int = distance(a, b)
	if dist == 0:
		return [a]
	var results: Array[Vector3i] = []
	for i: int in range(dist + 1):
		var t: float = float(i) / float(dist)
		results.append(hex_lerp(a, b, t))
	return results
