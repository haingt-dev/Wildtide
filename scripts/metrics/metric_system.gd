extends Node
## Tracks 4 state metrics and Science/Magic alignment.
## Applies interaction matrix and biome pushes each EVOLVE phase.
## Register as autoload: Project Settings > Autoload > "MetricSystem".

const METRIC_NAMES: Array[StringName] = [&"pollution", &"anxiety", &"solidarity", &"harmony"]
const METRIC_COUNT: int = 4
const INDEX_POLLUTION: int = 0
const INDEX_ANXIETY: int = 1
const INDEX_SOLIDARITY: int = 2
const INDEX_HARMONY: int = 3

var pollution: float = 0.0
var anxiety: float = 0.0
var solidarity: float = 0.0
var harmony: float = 0.0

var science_value: float = 0.0
var magic_value: float = 0.0

var interaction_matrix: InteractionMatrix
var hex_grid: HexGrid
var biome_registry: BiomeRegistry


func _ready() -> void:
	interaction_matrix = (
		load("res://scripts/data/metrics/metric_matrix_normal.tres") as InteractionMatrix
	)
	biome_registry = BiomeRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)


## Get metric value by name. Returns 0.0 for unknown names.
func get_metric(metric_name: StringName) -> float:
	match metric_name:
		&"pollution":
			return pollution
		&"anxiety":
			return anxiety
		&"solidarity":
			return solidarity
		&"harmony":
			return harmony
	return 0.0


## Set metric by name, clamped to [0, 1]. Emits metric_changed.
func set_metric(metric_name: StringName, value: float) -> void:
	var clamped: float = clampf(value, 0.0, 1.0)
	var old: float = get_metric(metric_name)
	match metric_name:
		&"pollution":
			pollution = clamped
		&"anxiety":
			anxiety = clamped
		&"solidarity":
			solidarity = clamped
		&"harmony":
			harmony = clamped
		_:
			return
	if not is_equal_approx(old, clamped):
		EventBus.metric_changed.emit(metric_name, clamped, old)


## Add delta to a metric. Clamps result to [0, 1].
func push_metric(metric_name: StringName, delta: float) -> void:
	var current: float = get_metric(metric_name)
	set_metric(metric_name, current + delta)


## Shift alignment. Positive delta pushes toward Science.
func push_alignment(delta: float) -> void:
	if delta > 0.0:
		science_value += absf(delta)
	elif delta < 0.0:
		magic_value += absf(delta)
	var new_alignment: float = get_alignment()
	EventBus.alignment_changed.emit(new_alignment)


## Alignment axis: (S-M)/(S+M). Returns 0.0 if both are zero.
func get_alignment() -> float:
	var total: float = science_value + magic_value
	if total <= 0.0:
		return 0.0
	return (science_value - magic_value) / total


## Return all 4 metrics as a Dictionary.
func get_all_metrics() -> Dictionary:
	return {
		&"pollution": pollution,
		&"anxiety": anxiety,
		&"solidarity": solidarity,
		&"harmony": harmony,
	}


## Return metric values as an ordered Array[float].
func get_metric_values() -> Array[float]:
	return [pollution, anxiety, solidarity, harmony]


## Reset all metrics and alignment to defaults.
func reset_to_defaults() -> void:
	pollution = 0.0
	anxiety = 0.0
	solidarity = 0.0
	harmony = 0.0
	science_value = 0.0
	magic_value = 0.0


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_apply_interaction_matrix()
		_apply_biome_pushes()


func _apply_interaction_matrix() -> void:
	if not interaction_matrix:
		return
	var values: Array[float] = get_metric_values()
	var deltas: Array[float] = []
	for target: int in range(METRIC_COUNT):
		deltas.append(interaction_matrix.get_delta_for(target, values))
	for i: int in range(METRIC_COUNT):
		push_metric(METRIC_NAMES[i], deltas[i])


func _apply_biome_pushes() -> void:
	if not hex_grid or not biome_registry:
		return
	var cells: Array[HexCell] = hex_grid.get_all_cells()
	for cell: HexCell in cells:
		var bdata: BiomeData = biome_registry.get_data(cell.biome)
		if not bdata:
			continue
		if bdata.metric_push != &"" and bdata.metric_push_value != 0.0:
			push_metric(bdata.metric_push, bdata.metric_push_value)
		if bdata.alignment_affinity != 0.0:
			push_alignment(bdata.alignment_affinity)
