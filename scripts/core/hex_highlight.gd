class_name HexHighlight
extends Node3D
## Renders a highlight overlay on a single hex.
## Repositioned dynamically — only one instance needed.

@export var highlight_color := Color(1.0, 1.0, 1.0, 0.3)

var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = HexMeshBuilder.create_flat_top_hex_mesh(HexMath.HEX_SIZE * 0.95)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = highlight_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	_mesh_instance.material_override = mat
	# Slight Y offset to avoid z-fighting with terrain.
	_mesh_instance.position.y = 0.02
	add_child(_mesh_instance)
	hide_highlight()


func show_at(coord: Vector3i) -> void:
	var world_pos := HexMath.hex_to_world(coord)
	global_position = world_pos
	visible = true


func hide_highlight() -> void:
	visible = false
