class_name MapGenerator
extends RefCounted
## Procedurally generates a HexGrid with biome assignments
## following the GDD placement rules.

const DEFAULT_MAP_RADIUS: int = 9
const RIFT_COUNT: int = 3
const SWAMP_RIFT_RADIUS: int = 4
const RUINS_MIN_DISTANCE: int = 5
const RUINS_TARGET_COUNT: int = 8
const FOREST_NOISE_THRESHOLD: float = 0.35
const ROCKY_EDGE_RINGS: int = 2

var _rng: RandomNumberGenerator
var _rift_positions: Array[Vector3i] = []


func _init(seed_value: int = -1) -> void:
	_rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()


## Main entry point. Returns a fully populated HexGrid.
func generate(radius: int = DEFAULT_MAP_RADIUS) -> HexGrid:
	var grid := HexGrid.new()
	grid.initialize_hex_map(radius)

	_rift_positions = RiftPlacer.get_rift_positions(radius, _rng.randf_range(0.0, 120.0))

	# Generation order matters — later steps only override PLAINS.
	_place_swamps(grid)
	_place_ruins(grid)
	_place_rocky(grid, radius)
	_place_forests(grid)
	# Remaining hexes stay PLAINS (the default).

	return grid


## Get the generated rift positions (available after generate()).
func get_rift_positions() -> Array[Vector3i]:
	return _rift_positions


func _place_swamps(grid: HexGrid) -> void:
	for rift: Vector3i in _rift_positions:
		var nearby := HexMath.spiral(rift, SWAMP_RIFT_RADIUS)
		for coord: Vector3i in nearby:
			var cell := grid.get_cell(coord)
			if not cell:
				continue
			# Probability decreases with distance from Rift.
			var dist: int = HexMath.distance(rift, coord)
			var probability: float = 1.0 - float(dist) / float(SWAMP_RIFT_RADIUS + 1)
			if _rng.randf() < probability:
				cell.biome = BiomeType.Type.SWAMP


func _place_ruins(grid: HexGrid) -> void:
	var placed: Array[Vector3i] = []
	var candidates: Array[Vector3i] = []

	# Collect eligible hexes (still PLAINS, not near rifts).
	for cell: HexCell in grid.get_all_cells():
		if cell.biome != BiomeType.Type.PLAINS:
			continue
		var too_close_to_rift: bool = false
		for rift: Vector3i in _rift_positions:
			if HexMath.distance(cell.coord, rift) <= 2:
				too_close_to_rift = true
				break
		if not too_close_to_rift:
			candidates.append(cell.coord)

	# Shuffle and pick with minimum distance constraint.
	_shuffle_array(candidates)
	for coord: Vector3i in candidates:
		if placed.size() >= RUINS_TARGET_COUNT:
			break
		var too_close: bool = false
		for existing: Vector3i in placed:
			if HexMath.distance(coord, existing) < RUINS_MIN_DISTANCE:
				too_close = true
				break
		if not too_close:
			placed.append(coord)
			var cell := grid.get_cell(coord)
			if cell:
				cell.biome = BiomeType.Type.RUINS


func _place_rocky(grid: HexGrid, radius: int) -> void:
	for cell: HexCell in grid.get_all_cells():
		if cell.biome != BiomeType.Type.PLAINS:
			continue
		var dist: int = HexMath.distance(Vector3i.ZERO, cell.coord)
		if dist > radius - ROCKY_EDGE_RINGS:
			cell.biome = BiomeType.Type.ROCKY


func _place_forests(grid: HexGrid) -> void:
	var noise := FastNoiseLite.new()
	noise.seed = _rng.randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08

	for cell: HexCell in grid.get_all_cells():
		if cell.biome != BiomeType.Type.PLAINS:
			continue
		var world := HexMath.hex_to_world(cell.coord)
		var val: float = noise.get_noise_2d(world.x, world.z)
		# FastNoiseLite returns [-1, 1]; normalize to [0, 1].
		var normalized: float = (val + 1.0) * 0.5
		if normalized > FOREST_NOISE_THRESHOLD:
			cell.biome = BiomeType.Type.FOREST


func _shuffle_array(arr: Array[Vector3i]) -> void:
	for i: int in range(arr.size() - 1, 0, -1):
		var j: int = _rng.randi_range(0, i)
		var tmp: Vector3i = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
