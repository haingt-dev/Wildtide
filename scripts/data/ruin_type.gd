class_name RuinType
extends RefCounted
## Ruin type enum and exploration state constants.

enum Type { OBSERVATORY, ENERGY_SHRINE, ARCHIVE_VAULT }

## Maps to HexCell.exploration_state (int field).
const STATE_NONE: int = 0
const STATE_UNDISCOVERED: int = 1
const STATE_DISCOVERED: int = 2
const STATE_EXPLORING: int = 3
const STATE_DEPLETED: int = 4
const STATE_DAMAGED: int = 5
