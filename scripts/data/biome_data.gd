class_name BiomeData
extends Resource
## Defines the gameplay properties of a single biome type.
## Create one .tres instance per biome (e.g., biome_plains.tres).

@export var biome_type: BiomeType.Type = BiomeType.Type.PLAINS
@export var display_name: StringName = &"Plains"

@export_group("Construction")
@export var construction_speed: float = 1.0  ## Multiplier (0.5 = half speed)

@export_group("Resources")
@export var gold_yield: float = 1.0  ## Multiplier
@export var mana_yield: float = 1.0  ## Multiplier

@export_group("Defense")
@export var defense_bonus: float = 0.0  ## Additive (0.2 = +20%)

@export_group("Metrics")
@export var metric_push: StringName = &""  ## Which metric this biome pushes
@export var metric_push_value: float = 0.0  ## Push amount per cycle

@export_group("Alignment")
## -1.0 = Magic, 0.0 = Neutral, +1.0 = Science
@export_range(-1.0, 1.0) var alignment_affinity: float = 0.0

@export_group("Ambient Threats")
## Base threat contribution from this biome (0.0-1.0). Swamp=0.4, Ruins=0.35.
@export_range(0.0, 1.0) var base_threat: float = 0.0
