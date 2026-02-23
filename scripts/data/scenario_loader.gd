class_name ScenarioLoader
extends RefCounted
## Static helpers to load a ScenarioData resource and apply it to subsystems.
## No file I/O state — pure utility class.

const SCENARIO_DIR: String = "res://scripts/data/scenarios/"


## Load a ScenarioData .tres by scenario_id. Returns null if not found.
static func load_scenario(scenario_id: StringName) -> ScenarioData:
	var path: String = SCENARIO_DIR + String(scenario_id) + ".tres"
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = ResourceLoader.load(path)
	if res is ScenarioData:
		return res as ScenarioData
	return null


## Apply scenario starting state to game systems.
## systems dict keys: "economy_manager" (EconomyManager), etc.
## Returns false if scenario is null.
static func apply_scenario(scenario: ScenarioData, systems: Dictionary) -> bool:
	if not scenario:
		return false
	_apply_metrics(scenario)
	_apply_economy(scenario, systems)
	_apply_game_manager(scenario)
	return true


static func _apply_metrics(scenario: ScenarioData) -> void:
	for metric_name: StringName in scenario.starting_metrics:
		MetricSystem.set_metric(metric_name, float(scenario.starting_metrics[metric_name]))
	if scenario.faction_config:
		MetricSystem.push_alignment(scenario.faction_config.alignment_start)


static func _apply_economy(scenario: ScenarioData, systems: Dictionary) -> void:
	var econ: EconomyManager = systems.get("economy_manager") as EconomyManager
	if not econ:
		return
	econ._gold = scenario.starting_gold
	econ._mana = scenario.starting_mana


static func _apply_game_manager(scenario: ScenarioData) -> void:
	if scenario.era_cycle_thresholds.size() > 0:
		GameManager.set(&"era_cycle_thresholds", scenario.era_cycle_thresholds)
