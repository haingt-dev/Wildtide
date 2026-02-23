class_name ScenarioModifier
extends Resource
## Difficulty modifier layer that stacks on top of ScenarioData.
## Application order: ScenarioData -> ScenarioModifier -> Edicts.

@export var modifier_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Multipliers")
@export var wave_multiplier: float = 1.0
@export var income_multiplier: float = 1.0

@export_group("Metric Weights")
## Optional alternative interaction matrix .tres path.
## Empty string = use default matrix from MetricSystem.
@export var metric_weight_preset_path: String = ""
