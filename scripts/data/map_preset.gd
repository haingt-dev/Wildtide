class_name MapPreset
extends Resource
## Defines the map generation parameters for a scenario.

enum SeedStrategy { FIXED, RANDOM }
enum RegionLayout { LINEAR, RADIAL }
enum RiftPlacement { TRIANGLE, RANDOM, FIXED_POSITIONS }

@export var seed_strategy: SeedStrategy = SeedStrategy.RANDOM
@export var fixed_seed: int = 0  ## Used when seed_strategy = FIXED

@export_group("Map Size")
@export var hex_count: int = 1750
@export var region_count: int = 4
@export var region_layout: RegionLayout = RegionLayout.LINEAR
@export var starting_region_index: int = 0

@export_group("Rifts")
@export var rift_count: int = 3
@export var rift_placement: RiftPlacement = RiftPlacement.TRIANGLE

@export_group("Biomes")
## Keys: biome name StringNames (&"plains", &"forest", etc.)
## Values: float fraction (must sum to ~1.0).
@export var biome_distribution: Dictionary = {
	&"plains": 0.35,
	&"forest": 0.25,
	&"rocky": 0.20,
	&"swamp": 0.15,
	&"ruins": 0.05,
}

@export_group("Ruins")
## Optional per-region ruin placement overrides.
@export var ruin_placements: Array[Dictionary] = []
