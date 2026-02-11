class_name HexMeshBuilder
extends RefCounted
## Builds hex mesh geometry for rendering.
## Generates flat-top hexagon meshes as ArrayMesh.


## Create a flat-top hexagon ArrayMesh lying on the XZ plane (Y=0).
## The mesh is centered at the origin with the given outer radius (size).
## Uses 6 triangles (fan from center).
static func create_flat_top_hex_mesh(hex_size: float = HexMath.HEX_SIZE) -> ArrayMesh:
	var verts := get_hex_vertices(hex_size)
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# All normals point up (Y+) since the mesh lies flat on XZ.
	for i: int in range(verts.size()):
		normals.append(Vector3.UP)

	# 6 triangles: center (0) + two consecutive corners.
	for i: int in range(6):
		indices.append(0)  # center
		indices.append(i + 1)
		indices.append((i + 1) % 6 + 1)  # wrap around

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Return the 7 vertices for a flat-top hex: center + 6 corners.
## Corner i is at angle (60 * i) degrees from the +X axis.
## Index 0 is center, indices 1-6 are corners.
static func get_hex_vertices(hex_size: float = HexMath.HEX_SIZE) -> PackedVector3Array:
	var verts := PackedVector3Array()
	verts.append(Vector3.ZERO)  # center

	for i: int in range(6):
		var angle_rad: float = deg_to_rad(60.0 * i)
		var x: float = hex_size * cos(angle_rad)
		var z: float = hex_size * sin(angle_rad)
		verts.append(Vector3(x, 0.0, z))

	return verts
