class_name RegionType
extends RefCounted
## Region type enum and wave density modifiers.
## Regions define map progression from safe starting zones to the dangerous Rift Core.

enum Type { STARTING, MID, LATE, RIFT_CORE }

## Wave power multiplier per region. Applied on top of Era scaling.
const DENSITY_MODIFIERS: Dictionary = {
	Type.STARTING: 0.8,
	Type.MID: 1.0,
	Type.LATE: 1.5,
	Type.RIFT_CORE: 2.0,
}


## Return the wave density modifier for a given region type.
static func get_density_modifier(region: Type) -> float:
	return DENSITY_MODIFIERS.get(region, 1.0)
