class_name EconomyConfig
extends Resource
## Global economy tuning knobs — starting values, capacities, yields, modifiers.
## Create one .tres per game mode (normal, hell, zen).

@export_group("Starting Resources")
@export var starting_gold: int = 100
@export var starting_mana: int = 50

@export_group("Capacity")
@export var starting_gold_capacity: int = 100
@export var starting_mana_capacity: int = 100
@export var capacity_per_storage: int = 20  ## +capacity per Market/Storage building

@export_group("Base Yields")
@export var base_gold_yield: float = 1.0  ## Per hex before biome modifier
@export var base_mana_yield: float = 1.0

@export_group("Production Modifiers")
@export var transit_modifier: float = 0.5  ## During city transit phase
@export var scar_modifier: float = 0.8  ## History Scar hex penalty

@export_group("Special Action Costs")
## Fraction of current reserves (0.0 – 1.0).
@export_range(0.0, 1.0) var migration_cost_fraction: float = 0.7
@export_range(0.0, 1.0) var summon_tide_cost_fraction: float = 0.5

@export_group("Endgame")
@export var required_fragments: int = 15  ## Tech Fragments or Rune Shards to win
