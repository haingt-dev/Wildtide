class_name ScenarioData
extends Resource
## Top-level scenario configuration — single source of truth for a campaign.

@export var scenario_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""

@export_group("Map")
@export var map_config: MapPreset

@export_group("Factions")
@export var faction_config: FactionConfig

@export_group("Win Conditions")
@export var win_conditions: Array[WinConditionData] = []

@export_group("Starting Metrics")
## Keys: metric StringNames, Values: float initial values.
@export var starting_metrics: Dictionary = {
	&"pollution": 0.1,
	&"anxiety": 0.3,
	&"solidarity": 0.2,
	&"harmony": 0.3,
}

@export_group("Era")
## Cycle numbers where eras begin (index 0 = Era 1 start, etc.).
@export var era_cycle_thresholds: Array[int] = [1, 6, 11, 16]

@export_group("Wave Overrides")
## Optional overrides for wave scaling. Empty = use WaveConfig defaults.
@export var wave_config_overrides: Dictionary = {}

@export_group("Economy")
@export var starting_gold: int = 100
@export var starting_mana: int = 50
