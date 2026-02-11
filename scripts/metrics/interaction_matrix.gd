class_name InteractionMatrix
extends Resource
## 4x4 interaction matrix: weight[source][target] applied per cycle.
## Row order: Pollution, Anxiety, Solidarity, Harmony.

const SIZE: int = 4

@export var weights: Array[PackedFloat64Array] = []


## Return the weight from source metric to target metric.
func get_weight(source: int, target: int) -> float:
	if source < 0 or source >= SIZE or target < 0 or target >= SIZE:
		return 0.0
	if source >= weights.size():
		return 0.0
	var row: PackedFloat64Array = weights[source]
	if target >= row.size():
		return 0.0
	return row[target]


## Calculate the total delta for a target metric from all sources.
## metric_values should be an Array of 4 floats (current metric levels).
func get_delta_for(target: int, metric_values: Array[float]) -> float:
	var delta: float = 0.0
	for source: int in range(SIZE):
		var w: float = get_weight(source, target)
		if w != 0.0 and source < metric_values.size():
			delta += w * metric_values[source]
	return delta
