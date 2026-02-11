class_name BuildingData
extends Resource
## Template for a building type that can be placed on the hex grid.
## Create one .tres instance per building type.

@export var building_id: StringName = &""
@export var building_type: BuildingType.Type = BuildingType.Type.RESIDENTIAL
@export var display_name: String = ""
@export var description: String = ""

@export_group("Construction")
@export_range(1, 8) var construction_duration: int = 2  ## Cycles to complete

@export_group("Metric Effects")
## Keys: metric StringNames (&"pollution", &"anxiety", etc.)
## Values: float delta applied per EVOLVE cycle when completed.
@export var metric_effects: Dictionary = {}

@export_group("Alignment")
## Per-cycle push toward Science (+) or Magic (-) when completed.
@export var alignment_push: float = 0.0

@export_group("Biome Affinity")
## Preferred biome type. Construction on this biome gets speed bonus.
@export var biome_affinity: BiomeType.Type = BiomeType.Type.PLAINS
@export var affinity_bonus: float = 0.2  ## Speed multiplier bonus on preferred biome
