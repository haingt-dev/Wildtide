class_name HexDebugInfo
extends Control
## Shows hex coordinate and biome info on hover.
## Raycasts from camera to XZ plane to find hovered hex.

var hex_grid: HexGrid
var camera: Camera3D
var highlight: HexHighlight

var _label: Label
var _hovered_coord := Vector3i(0, 0, 0)
var _has_hover: bool = false


func _ready() -> void:
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	_label.position = Vector2(16, 16)
	add_child(_label)


func _process(_delta: float) -> void:
	if not camera or not hex_grid:
		return

	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var dir := camera.project_ray_normal(mouse_pos)

	# Intersect ray with the XZ plane (y = 0).
	if absf(dir.y) < 0.0001:
		_clear_hover()
		return

	var t: float = -from.y / dir.y
	if t < 0.0:
		_clear_hover()
		return

	var hit := from + dir * t
	var coord := HexMath.world_to_hex(hit)

	if hex_grid.has_cell(coord):
		_hovered_coord = coord
		_has_hover = true
		var cell := hex_grid.get_cell(coord)
		var biome_name := _get_biome_name(cell.biome)
		_label.text = "(%d, %d, %d) — %s" % [coord.x, coord.y, coord.z, biome_name]
		if highlight:
			highlight.show_at(coord)
	else:
		_clear_hover()


func _clear_hover() -> void:
	_has_hover = false
	_label.text = ""
	if highlight:
		highlight.hide_highlight()


func _get_biome_name(biome: BiomeType.Type) -> String:
	match biome:
		BiomeType.Type.PLAINS:
			return "Plains"
		BiomeType.Type.FOREST:
			return "Forest"
		BiomeType.Type.ROCKY:
			return "Rocky"
		BiomeType.Type.SWAMP:
			return "Swamp"
		BiomeType.Type.RUINS:
			return "Ruins"
		_:
			return "Unknown"
