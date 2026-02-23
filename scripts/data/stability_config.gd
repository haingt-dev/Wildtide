class_name StabilityConfig
extends Resource
## Tuning knobs for the Stability meter (0-100). Game Over at 0.
## Create one .tres per difficulty mode (Normal, Hell, Zen).

const MIN_STABILITY: int = 0
const MAX_STABILITY: int = 100

@export_group("Starting")
@export var starting_stability: int = 100

@export_group("Multipliers")
@export var loss_multiplier: float = 1.0
@export var gain_multiplier: float = 1.0

@export_group("Loss — Wave Damage")
## If damaged buildings fraction > wave_damage_threshold, lose stability.
@export var wave_damage_threshold: float = 0.5
@export var wave_damage_loss_min: int = -10
@export var wave_damage_loss_max: int = -30

@export_group("Loss — Faction Morale")
## All factions below this morale → lose stability per cycle.
@export var low_morale_threshold: int = 25
@export var low_morale_loss_per_cycle: int = -5

@export_group("Loss — Resource Depletion")
## Gold or Mana at 0 for consecutive cycles.
@export var resource_depletion_loss: int = -10

@export_group("Loss — Artifact")
@export var failed_artifact_loss: int = -20

@export_group("Gain — Wave Defense")
## If damage fraction < wave_defense_threshold, gain stability.
@export var wave_defense_threshold: float = 0.2
@export var wave_defense_gain: int = 5

@export_group("Gain — Solidarity")
@export var solidarity_threshold: float = 0.7
@export var solidarity_gain_per_cycle: int = 2

@export_group("Gain — Faction Morale")
## Per faction above this threshold: gain per cycle.
@export var high_morale_threshold: int = 75
@export var high_morale_gain_per_cycle: int = 1

@export_group("Gain — Festival")
@export var festival_gain_per_cycle: int = 3

@export_group("Warning Thresholds")
@export var warning_yellow: int = 50
@export var warning_red: int = 25
@export var warning_final: int = 10

@export_group("Game Over")
## If false, stability floors at stability_floor instead of causing game over.
@export var game_over_enabled: bool = true
@export var stability_floor: int = 0  ## Zen mode: set to 10
