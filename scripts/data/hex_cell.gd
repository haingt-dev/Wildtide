class_name HexCell
extends Resource
## Data for a single hex tile in the grid.
## Stored inside HexGrid as an element of the serialized cell array.

@export var coord: Vector3i = Vector3i.ZERO
@export var biome: BiomeType.Type = BiomeType.Type.PLAINS
@export var building_id: StringName = &""
@export var scar_state: float = 0.0  ## 0.0 = pristine, 1.0 = fully scarred
@export var exploration_state: int = 0  ## 0=none, 1=undiscovered, 2=discovered, etc.
@export_range(-1.0, 1.0) var alignment_local: float = 0.0


func is_empty() -> bool:
	return building_id == &""


func is_buildable() -> bool:
	return is_empty() and scar_state < 1.0


func apply_scar(amount: float) -> void:
	scar_state = clampf(scar_state + amount, 0.0, 1.0)
