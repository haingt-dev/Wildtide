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
