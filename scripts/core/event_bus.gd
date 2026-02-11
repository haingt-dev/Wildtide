extends Node
## Global signal bus for cross-system communication.
## Register as autoload: Project Settings > Autoload > "EventBus".
##
## Usage:
##   EventBus.phase_changed.emit(1, &"influence")
##   EventBus.phase_changed.connect(_on_phase_changed)

# --- Cycle ---
signal phase_changed(new_phase: int, phase_name: StringName)
signal cycle_started(cycle_number: int)
signal cycle_completed(cycle_number: int)
signal game_speed_changed(new_speed: int)
signal game_paused
signal game_resumed

# --- Metrics ---
signal metric_changed(metric_name: StringName, new_value: float, old_value: float)
signal alignment_changed(new_alignment: float)

# --- HexGrid ---
signal hex_grid_initialized(grid: HexGrid)
signal hex_cell_changed(coord: Vector3i)
signal hex_selected(coord: Vector3i)
signal hex_deselected

# --- Wave ---
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal hex_scarred(coord: Vector3i, amount: float)

# --- Buildings ---
signal building_placed(coord: Vector3i, building_id: StringName)
signal building_removed(coord: Vector3i, building_id: StringName)

# --- Quests ---
signal quest_proposed(faction: StringName, quest_id: StringName)
signal quest_approved(faction: StringName, quest_id: StringName)
signal quest_rejected(faction: StringName, quest_id: StringName)
signal quest_completed(faction: StringName, quest_id: StringName)

# --- Ruins ---
signal ruin_discovered(coord: Vector3i, ruin_type: StringName)
signal ruin_exploration_started(coord: Vector3i)
signal ruin_depleted(coord: Vector3i)
