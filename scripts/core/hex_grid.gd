class_name HexGrid
extends Resource
## The authoritative data store for the hex map.
## Contains all hex cells indexed by cube coordinates.
## This is a pure data Resource — no rendering logic.

signal cell_changed(coord: Vector3i)
signal grid_initialized

@export var map_radius: int = 9

## Serialized form — Godot can save/load Array[HexCell] in .tres.
## The runtime Dictionary is rebuilt from this after loading.
@export var _cell_array: Array[HexCell] = []

## Runtime lookup: Vector3i -> HexCell. Not exported.
var _cells: Dictionary = {}


## Create an empty hex grid of the given radius centered at origin.
## Radius 9 produces 3*9*10+1 = 271 hexes.
func initialize_hex_map(radius: int = -1) -> void:
	if radius >= 0:
		map_radius = radius
	_cells.clear()
	_cell_array.clear()
	var coords: Array[Vector3i] = HexMath.spiral(Vector3i.ZERO, map_radius)
	for coord: Vector3i in coords:
		var cell := HexCell.new()
		cell.coord = coord
		_cells[coord] = cell
		_cell_array.append(cell)
	grid_initialized.emit()


func get_cell(coord: Vector3i) -> HexCell:
	return _cells.get(coord, null) as HexCell


func set_cell(coord: Vector3i, cell: HexCell) -> void:
	cell.coord = coord
	var existing: HexCell = _cells.get(coord, null) as HexCell
	if existing:
		var idx: int = _cell_array.find(existing)
		if idx >= 0:
			_cell_array[idx] = cell
	else:
		_cell_array.append(cell)
	_cells[coord] = cell
	cell_changed.emit(coord)


func has_cell(coord: Vector3i) -> bool:
	return _cells.has(coord)


func get_all_cells() -> Array[HexCell]:
	var result: Array[HexCell] = []
	result.assign(_cell_array)
	return result


func get_all_coords() -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for coord: Vector3i in _cells.keys():
		result.append(coord)
	return result


func get_cell_count() -> int:
	return _cells.size()


## Return neighboring cells that exist within the grid.
## Edge hexes will return fewer than 6 neighbors.
func get_neighbors_of(coord: Vector3i) -> Array[HexCell]:
	var result: Array[HexCell] = []
	for neighbor_coord: Vector3i in HexMath.neighbors(coord):
		var cell: HexCell = _cells.get(neighbor_coord, null) as HexCell
		if cell:
			result.append(cell)
	return result


## Return all cells within the given range (inclusive) of center.
func get_cells_in_range(center: Vector3i, radius: int) -> Array[HexCell]:
	var result: Array[HexCell] = []
	var coords: Array[Vector3i] = HexMath.spiral(center, radius)
	for coord: Vector3i in coords:
		var cell: HexCell = _cells.get(coord, null) as HexCell
		if cell:
			result.append(cell)
	return result


## Return all cells matching the given biome type.
func get_cells_by_biome(biome: BiomeType.Type) -> Array[HexCell]:
	var result: Array[HexCell] = []
	for cell: HexCell in _cell_array:
		if cell.biome == biome:
			result.append(cell)
	return result


func clear() -> void:
	_cells.clear()
	_cell_array.clear()


## Rebuild the runtime Dictionary from the serialized Array.
## Call this after loading a HexGrid from .tres or JSON.
func rebuild_lookup() -> void:
	_cells.clear()
	for cell: HexCell in _cell_array:
		_cells[cell.coord] = cell


## Sync the serialized Array from the runtime Dictionary.
## Call this before saving to .tres or JSON.
func sync_array() -> void:
	_cell_array.clear()
	_cell_array.assign(_cells.values())
