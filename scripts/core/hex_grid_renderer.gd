class_name HexGridRenderer
extends Node3D
## Renders a HexGrid Resource using MultiMeshInstance3D.
## Assign a HexGrid resource and call rebuild() to visualize.

const HEX_TERRAIN_SHADER = preload("res://scripts/shaders/hex_terrain.gdshader")

@export var hex_grid: HexGrid:
	set(value):
		hex_grid = value
		if is_inside_tree():
			rebuild()

var _multi_mesh_instance: MultiMeshInstance3D
var _hex_mesh: ArrayMesh
var _coord_to_index: Dictionary = {}  ## Vector3i -> int


func _ready() -> void:
	_hex_mesh = HexMeshBuilder.create_flat_top_hex_mesh(HexMath.HEX_SIZE)
	_setup_multi_mesh_instance()
	if hex_grid:
		rebuild()


func _setup_multi_mesh_instance() -> void:
	_multi_mesh_instance = MultiMeshInstance3D.new()
	var mat := ShaderMaterial.new()
	mat.shader = HEX_TERRAIN_SHADER
	_multi_mesh_instance.material_override = mat
	add_child(_multi_mesh_instance)


## Rebuild the entire MultiMesh from hex_grid data.
func rebuild() -> void:
	if not hex_grid or hex_grid.get_cell_count() == 0:
		return

	_coord_to_index.clear()
	var cells := hex_grid.get_all_cells()
	var count: int = cells.size()

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.instance_count = count
	mm.mesh = _hex_mesh

	for i: int in range(count):
		var cell: HexCell = cells[i]
		_coord_to_index[cell.coord] = i

		var world_pos := HexMath.hex_to_world(cell.coord)
		mm.set_instance_transform(i, Transform3D(Basis(), world_pos))

		# Encode biome type in custom data R channel.
		var biome_val: float = float(cell.biome) / 4.0
		mm.set_instance_custom_data(i, Color(biome_val, 0.0, 0.0, 1.0))

	_multi_mesh_instance.multimesh = mm


## Update a single hex instance (e.g., when biome changes).
func update_cell(coord: Vector3i) -> void:
	if not _coord_to_index.has(coord):
		return
	var idx: int = _coord_to_index[coord]
	var cell := hex_grid.get_cell(coord)
	if not cell:
		return
	var biome_val: float = float(cell.biome) / 4.0
	_multi_mesh_instance.multimesh.set_instance_custom_data(idx, Color(biome_val, 0.0, 0.0, 1.0))


## Map a hex coordinate to its MultiMesh instance index.
func get_instance_index(coord: Vector3i) -> int:
	return _coord_to_index.get(coord, -1)
