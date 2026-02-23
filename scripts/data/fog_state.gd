class_name FogState
extends RefCounted
## Fog of war state constants for hex visibility.
## Maps to HexCell.fog_state (int field).

const HIDDEN: int = 0  ## Unrevealed — dark/greyed out
const REVEALED: int = 1  ## Visible terrain/biome, not interactable
const ACTIVE: int = 2  ## Within city footprint, fully operational
const INACTIVE: int = 3  ## City left — desaturated, resource depleted
