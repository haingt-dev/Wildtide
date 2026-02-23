class_name FactionConfig
extends Resource
## Defines faction availability and starting state for a scenario.

## Which factions are present (e.g., [&"lens", &"veil", &"coin", &"wall"]).
@export var available_factions: Array[StringName] = [&"lens", &"veil", &"coin", &"wall"]

## Starting morale per faction. Key: faction_id, Value: int (0-100).
@export var starting_morale: Dictionary = {
	&"lens": 50,
	&"veil": 50,
	&"coin": 50,
	&"wall": 50,
}

## Optional quest pool overrides. Key: faction_id, Value: Array[StringName] of quest_ids.
@export var faction_quest_pools: Dictionary = {}

## Starting alignment (-1.0 Magic … +1.0 Science).
@export_range(-1.0, 1.0) var alignment_start: float = 0.0
