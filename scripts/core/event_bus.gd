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
signal wave_intel_updated(level: int, report: Dictionary)

# --- Buildings ---
signal building_placed(coord: Vector3i, building_id: StringName)
signal building_removed(coord: Vector3i, building_id: StringName)
signal building_tier_changed(coord: Vector3i, new_tier: int)

# --- AI ---
signal ai_buildings_placed(placements: Array)

# --- Quests ---
signal quest_proposed(faction: StringName, quest_id: StringName)
signal quest_approved(faction: StringName, quest_id: StringName)
signal quest_rejected(faction: StringName, quest_id: StringName)
signal quest_completed(faction: StringName, quest_id: StringName)

# --- Factions ---
signal faction_morale_changed(faction_id: StringName, new_morale: int, old_morale: int)

# --- Economy ---
signal gold_changed(new_amount: int, old_amount: int)
signal mana_changed(new_amount: int, old_amount: int)

# --- Edicts ---
signal edict_enacted(edict_id: StringName)
signal edict_revoked(edict_id: StringName)
signal edict_expired(edict_id: StringName)

# --- Stability ---
signal stability_changed(new_value: int, old_value: int)
signal alert_level_changed(new_level: StringName)
signal game_over
signal game_won(win_type: int)

# --- Movement ---
signal movement_proposed(direction: Vector3i)
signal city_moved(old_center: Vector3i, new_center: Vector3i)
signal transit_started
signal transit_ended
signal migration_requested
signal rift_shards_changed(new_amount: int, old_amount: int)
signal summon_tide_completed(shard_reward: int)

# --- Ruins ---
signal ruin_discovered(coord: Vector3i, ruin_type: StringName)
signal ruin_exploration_started(coord: Vector3i)
signal ruin_depleted(coord: Vector3i)

# --- Fragments & Artifact ---
signal fragments_changed(tech: int, rune: int)
signal artifact_started(coord: Vector3i)
signal artifact_progress(progress: int, required: int)
signal artifact_completed(win_type: int)
signal artifact_failed
