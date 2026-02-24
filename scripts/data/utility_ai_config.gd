class_name UtilityAIConfig
extends Resource
## Tuning knobs for the Utility AI building-placement scorer.
## Create one .tres per game mode (normal, hell, zen).
## No AI logic here — just weights and thresholds.

@export_group("Utility Scoring Weights")
@export_range(0.0, 3.0) var need_weight: float = 1.0
@export_range(0.0, 3.0) var affinity_weight: float = 0.5
@export_range(0.0, 3.0) var adjacency_weight: float = 0.8
@export_range(0.0, 3.0) var faction_weight: float = 0.6
@export_range(0.0, 3.0) var penalty_weight: float = 0.7
@export_range(0.0, 3.0) var zone_weight: float = 0.6

@export_group("Metric Need Thresholds")
## When a metric exceeds its threshold, AI prioritizes remedial buildings.
@export_range(0.0, 1.0) var pollution_critical: float = 0.7
@export_range(0.0, 1.0) var anxiety_critical: float = 0.7
@export_range(0.0, 1.0) var harmony_critical_low: float = 0.3
@export_range(0.0, 1.0) var solidarity_critical_low: float = 0.3
@export_range(0.0, 1.0) var defense_critical_low: float = 0.3

@export_group("Pollution Penalty Curve")
## Below low_threshold: no penalty. Above high_threshold: max penalty.
## Linear interpolation in between.
@export_range(0.0, 1.0) var pollution_low_threshold: float = 0.3
@export_range(0.0, 1.0) var pollution_high_threshold: float = 0.7
@export var pollution_mid_penalty: float = -0.15
@export var pollution_max_penalty: float = -0.3

@export_group("Placement Rate per Era")
## Buildings the AI places per EVOLVE cycle, indexed by Era (0-based).
## Era 1 = cycles 1-5, Era 2 = 6-10, Era 3 = 11-15, Final = 16.
@export var era_placement_rates: Array[int] = [1, 2, 3, 3]

@export_group("Alignment Thresholds")
## When alignment exceeds these, AI shifts building preferences.
## Science > science_threshold: prefer Reactor/Workshop.
## Science < magic_threshold: prefer Shrine.
@export_range(-1.0, 1.0) var science_dominant_threshold: float = 0.3
@export_range(-1.0, 1.0) var magic_dominant_threshold: float = -0.3

@export_group("Faction Influence")
## Bonus applied when placing a building preferred by the dominant faction.
@export_range(0.0, 1.0) var dominant_faction_bonus: float = 0.2

@export_group("Skyline Rules")
@export var cluster_penalty: float = -0.15  ## Applied when 3+ adjacent same type
@export var cluster_threshold: int = 3  ## How many same-type neighbors trigger penalty

@export_group("Weapon Buildings")
@export var weapon_diversity_penalty: float = -0.5  ## Penalty when too many same weapons
@export var weapon_diversity_max: int = 2  ## Max same weapon type in Defense Perimeter

@export_group("Performance")
## Max hex candidates to evaluate per cycle (limits CPU cost).
@export var max_candidates_per_eval: int = 300
## How far from city center to still prefer placement.
@export var distance_falloff_radius: int = 5
