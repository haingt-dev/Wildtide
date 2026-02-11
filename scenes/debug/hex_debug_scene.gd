extends Node3D
## Debug scene for visualizing and testing the hex grid.
## Uses MapGenerator for procedural biome placement.

@export var map_radius: int = 9
@export var map_seed: int = 12345

var hex_grid: HexGrid

@onready var renderer: HexGridRenderer = $HexGridRenderer
@onready var hex_highlight: HexHighlight = $HexHighlight
@onready var debug_camera: Camera3D = $HexDebugCamera
@onready var debug_info: HexDebugInfo = $CanvasLayer/HexDebugInfo


func _ready() -> void:
	var generator := MapGenerator.new(map_seed)
	hex_grid = generator.generate(map_radius)

	renderer.hex_grid = hex_grid
	debug_info.hex_grid = hex_grid
	debug_info.camera = debug_camera
	debug_info.highlight = hex_highlight
