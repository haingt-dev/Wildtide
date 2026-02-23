class_name WinConditionData
extends Resource
## Defines a single win condition for a scenario.

enum WinConditionType {
	SCIENCE_WIN,
	MAGIC_WIN,
	RIFT_SEAL,
	SURVIVAL,
	CUSTOM,
}

@export var type: WinConditionType = WinConditionType.SCIENCE_WIN

@export_group("Thresholds")
@export var required_alignment: float = 0.8
@export var required_fragments: int = 15
@export var required_era: int = 3
@export var required_cycles: int = 0
@export var requires_rift_core: bool = true
@export var artifact_construction_cycles: int = 3

@export_group("Display")
@export var custom_description: String = ""
