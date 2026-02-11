extends Node3D
## Debug scene for visualizing and testing the hex grid.
## Creates a HexGrid on _ready, assigns it to the renderer.

@export var map_radius: int = 9

var hex_grid: HexGrid

@onready var renderer: HexGridRenderer = $HexGridRenderer
@onready var hex_highlight: HexHighlight = $HexHighlight
@onready var debug_camera: Camera3D = $HexDebugCamera
@onready var debug_info: HexDebugInfo = $CanvasLayer/HexDebugInfo


func _ready() -> void:
	hex_grid = HexGrid.new()
	hex_grid.initialize_hex_map(map_radius)

	# Assign some varied biomes for visual testing.
	_assign_test_biomes()

	renderer.hex_grid = hex_grid
	debug_info.hex_grid = hex_grid
	debug_info.camera = debug_camera
	debug_info.highlight = hex_highlight


func _assign_test_biomes() -> void:
	# Simple pattern for visual testing: rings of different biomes.
	for cell: HexCell in hex_grid.get_all_cells():
		var dist: int = HexMath.distance(Vector3i.ZERO, cell.coord)
		if dist <= 2:
			cell.biome = BiomeType.Type.PLAINS
		elif dist <= 4:
			cell.biome = BiomeType.Type.FOREST
		elif dist <= 6:
			cell.biome = BiomeType.Type.ROCKY
		elif dist <= 8:
			cell.biome = BiomeType.Type.SWAMP
		else:
			cell.biome = BiomeType.Type.RUINS
