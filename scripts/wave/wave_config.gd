class_name WaveConfig
extends Resource
## Configuration for wave power scaling across 4 Eras.
## Create alternative .tres files for Hell/Zen modes.

const ERA_COUNT: int = 4

@export var base_power: float = 10.0
## Cycle thresholds for each Era. Configurable per scenario.
@export var era_boundaries: Array[int] = [1, 6, 11, 16]
@export var era_multipliers: Array[float] = [1.0, 1.8, 3.0, 5.0]
@export var damage_per_power: float = 0.02  ## Scar damage per unit of wave power
@export var damage_radius: int = 3  ## Hexes from Rift that take damage


## Return the Era index (0-3) for a given cycle number.
func get_era(cycle: int) -> int:
	var era: int = 0
	for i: int in range(ERA_COUNT):
		if i < era_boundaries.size() and cycle >= era_boundaries[i]:
			era = i
	return era


## Return the total wave power for a given cycle and region.
func get_wave_power(cycle: int, region: RegionType.Type = RegionType.Type.MID) -> float:
	var era: int = get_era(cycle)
	if era < 0 or era >= era_multipliers.size():
		return base_power
	return base_power * era_multipliers[era] * RegionType.get_density_modifier(region)


## Return the number of enemies for a given cycle and region.
func get_enemy_count(cycle: int, region: RegionType.Type = RegionType.Type.MID) -> int:
	return roundi(get_wave_power(cycle, region))
