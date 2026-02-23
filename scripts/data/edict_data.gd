class_name EdictData
extends Resource
## Template for a single edict (city-wide policy).
## Create one .tres instance per edict definition.

enum Category { ECONOMY, DEFENSE, RESEARCH, SOCIAL }

@export var edict_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var category: Category = Category.ECONOMY

@export_group("Effects")
## Keys: metric StringNames (&"pollution", &"anxiety", etc.)
## Values: float delta applied per cycle while active.
@export var metric_effects: Dictionary = {}

## Keys: economy stat names (&"gold_income", &"mana_income", &"defense")
## Values: float modifier (e.g., -0.2 = -20%, +0.3 = +30%).
@export var economy_effects: Dictionary = {}

## Per-cycle alignment push: positive = Science, negative = Magic.
@export var alignment_push: float = 0.0

## Bonus fraction for fragment discovery in ruins (0.1 = +10%).
@export var discovery_bonus: float = 0.0

@export_group("Duration")
## -1 = permanent (until replaced). Positive = auto-expires after N cycles.
@export var duration: int = -1

## If true, this edict does NOT consume an edict slot.
@export var is_free_action: bool = false

@export_group("Faction Reactions")
## Keys: faction_id StringNames (&"lens", &"coin", etc.)
## Values: int morale delta applied when edict enacted (positive=approve)
## and per cycle while active (negative=dislike).
@export var faction_reactions: Dictionary = {}
