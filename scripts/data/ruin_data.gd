class_name RuinData
extends Resource
## Defines the properties of a single ruin type.
## Create one .tres instance per ruin type (e.g., ruin_observatory.tres).

@export var ruin_type: RuinType.Type = RuinType.Type.OBSERVATORY
@export var display_name: StringName = &"Observatory"
@export var description: String = ""

@export_group("Exploration")
@export_range(1, 5) var exploration_duration: int = 2  ## Cycles to fully explore

@export_group("Yields")
@export var tech_fragments: int = 0
@export var rune_shards: int = 0

@export_group("Rarity")
@export_range(0.0, 1.0) var rarity_weight: float = 0.4  ## Selection weight during type assignment

@export_group("Wave Damage")
@export_range(0.0, 1.0) var damage_yield_penalty: float = 0.5  ## Yield multiplier when damaged
