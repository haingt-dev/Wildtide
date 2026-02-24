class_name QuestData
extends Resource
## Template for a single quest that a faction can propose.
## Create one .tres instance per quest template.

@export var quest_id: StringName = &""
@export var faction_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Duration")
@export_range(1, 5) var duration: int = 1  ## Cycles to complete

@export_group("Metric Effects")
## Keys: metric StringNames (&"pollution", &"anxiety", etc.)
## Values: float delta applied per cycle while active.
@export var metric_effects: Dictionary = {}

@export_group("Alignment")
## Per-cycle push toward Science (+) or Magic (-).
@export var alignment_push: float = 0.0

@export_group("Offensive")
@export var is_offensive: bool = false
## Effect key applied to wave (e.g., &"power_multiplier", &"defense_bonus").
@export var offensive_effect_key: StringName = &""
## Effect magnitude (e.g., 0.8 = -20% power, 0.25 = +25% defense).
@export var offensive_effect_value: float = 0.0
## Alignment requirement to propose. 0.0 = none. Positive = Science, negative = Magic.
@export var alignment_requirement: float = 0.0

@export_group("Movement")
@export var is_movement_proposal: bool = false
@export var proposed_direction: Vector3i = Vector3i.ZERO
