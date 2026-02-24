class_name ZoneType
extends RefCounted
## Soft zone types for the city footprint.
## Used by UtilityAI to score zone affinity when placing buildings.

enum Type { NONE, CORE, RESIDENTIAL, PRODUCTION, DEFENSE_PERIMETER }
