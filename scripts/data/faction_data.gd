class_name FactionData
extends Resource
## Defines the properties of a single faction.
## Create one .tres instance per faction (e.g., faction_lens.tres).

@export var faction_type: FactionType.Type = FactionType.Type.LENS
@export var faction_id: StringName = &"lens"
@export var display_name: String = "The Lens"
@export var description: String = ""

@export_group("Alignment")
## -1.0 = Magic, 0.0 = Neutral, +1.0 = Science
@export_range(-1.0, 1.0) var alignment_bias: float = 0.0

@export_group("Quest Pool")
## Array of quest template IDs this faction can propose.
@export var quest_pool: Array[StringName] = []
