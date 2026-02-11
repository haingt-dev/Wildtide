class_name SaveSerializer
extends RefCounted
## Pure data conversion between game systems and JSON-compatible Dictionaries.
## No file I/O — used by SaveSystem for the actual read/write.

const SAVE_VERSION: int = 1


static func vec3i_to_array(v: Vector3i) -> Array:
	return [v.x, v.y, v.z]


static func array_to_vec3i(a: Array) -> Vector3i:
	return Vector3i(int(a[0]), int(a[1]), int(a[2]))


static func vec3i_to_key(v: Vector3i) -> String:
	return "%d,%d,%d" % [v.x, v.y, v.z]


static func key_to_vec3i(k: String) -> Vector3i:
	var parts: PackedStringArray = k.split(",")
	return Vector3i(parts[0].to_int(), parts[1].to_int(), parts[2].to_int())


# --- Serialize ---


static func serialize_meta(game_mgr: Node) -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"save_date": Time.get_datetime_string_from_system(true),
		"cycle_number": game_mgr.cycle_number,
		"current_phase": int(game_mgr.current_phase),
		"game_speed": game_mgr.game_speed,
	}


static func serialize_world(
	grid: HexGrid,
	wave_mgr: WaveManager,
	ruins_mgr: RuinsManager,
	building_mgr: BuildingManager,
) -> Dictionary:
	var cells: Array = []
	for cell: HexCell in grid.get_all_cells():
		(
			cells
			. append(
				{
					"coord": vec3i_to_array(cell.coord),
					"biome": int(cell.biome),
					"building_id": String(cell.building_id),
					"scar_state": cell.scar_state,
					"exploration_state": cell.exploration_state,
					"alignment_local": cell.alignment_local,
				}
			)
		)

	var rift_arr: Array = []
	for pos: Vector3i in wave_mgr.rift_positions:
		rift_arr.append(vec3i_to_array(pos))

	var ruin_dict: Dictionary = {}
	for coord: Vector3i in ruins_mgr._ruin_types:
		ruin_dict[vec3i_to_key(coord)] = int(ruins_mgr._ruin_types[coord])

	var explorations: Array = []
	for coord: Vector3i in ruins_mgr._active_explorations:
		var active: ActiveExploration = ruins_mgr._active_explorations[coord]
		(
			explorations
			. append(
				{
					"coord": vec3i_to_array(active.coord),
					"ruin_type": int(active.ruin_data.ruin_type),
					"remaining_cycles": active.remaining_cycles,
					"is_damaged": active.is_damaged,
				}
			)
		)

	var constructions: Array = []
	for coord: Vector3i in building_mgr._constructions:
		var active: ActiveConstruction = building_mgr._constructions[coord]
		(
			constructions
			. append(
				{
					"coord": vec3i_to_array(active.coord),
					"building_id": String(active.building_data.building_id),
					"progress": active.progress,
					"is_complete": active.is_complete,
				}
			)
		)

	return {
		"map_radius": grid.map_radius,
		"cells": cells,
		"rift_positions": rift_arr,
		"ruin_types": ruin_dict,
		"active_explorations": explorations,
		"constructions": constructions,
	}


static func serialize_metrics() -> Dictionary:
	return {
		"pollution": MetricSystem.pollution,
		"anxiety": MetricSystem.anxiety,
		"solidarity": MetricSystem.solidarity,
		"harmony": MetricSystem.harmony,
		"science_value": MetricSystem.science_value,
		"magic_value": MetricSystem.magic_value,
	}


static func serialize_factions(quest_mgr: QuestManager) -> Dictionary:
	var pending: Array = []
	for quest_id: StringName in quest_mgr._pending_proposals:
		pending.append(String(quest_id))

	var active: Array = []
	for quest_id: StringName in quest_mgr._active_quests:
		var aq: ActiveQuest = quest_mgr._active_quests[quest_id]
		(
			active
			. append(
				{
					"quest_id": String(quest_id),
					"remaining_cycles": aq.remaining_cycles,
				}
			)
		)

	var last: Dictionary = {}
	for faction_id: StringName in quest_mgr._last_proposed:
		last[String(faction_id)] = String(quest_mgr._last_proposed[faction_id])

	return {
		"pending_proposals": pending,
		"active_quests": active,
		"last_proposed": last,
	}


# --- Deserialize ---


static func deserialize_meta(data: Dictionary, game_mgr: Node) -> bool:
	if not data.has("cycle_number") or not data.has("current_phase"):
		return false
	game_mgr.cycle_number = int(data["cycle_number"])
	game_mgr.current_phase = int(data["current_phase"])
	game_mgr.game_speed = int(data.get("game_speed", 1))
	game_mgr.is_running = true
	game_mgr.is_paused = false
	return true


static func deserialize_world(
	data: Dictionary,
	grid: HexGrid,
	wave_mgr: WaveManager,
	ruins_mgr: RuinsManager,
	building_mgr: BuildingManager,
) -> bool:
	if not data.has("map_radius") or not data.has("cells"):
		return false

	# Rebuild HexGrid from cell data
	grid.clear()
	grid.map_radius = int(data["map_radius"])
	var cells_data: Array = data["cells"]
	for cell_dict: Dictionary in cells_data:
		var cell := HexCell.new()
		cell.coord = array_to_vec3i(cell_dict["coord"])
		cell.biome = int(cell_dict["biome"])
		cell.building_id = StringName(cell_dict.get("building_id", ""))
		cell.scar_state = float(cell_dict.get("scar_state", 0.0))
		cell.exploration_state = int(cell_dict.get("exploration_state", 0))
		cell.alignment_local = float(cell_dict.get("alignment_local", 0.0))
		grid._cell_array.append(cell)
	grid.rebuild_lookup()

	# WaveManager rift positions
	wave_mgr.rift_positions.clear()
	var rift_data: Array = data.get("rift_positions", [])
	for pos_arr: Array in rift_data:
		wave_mgr.rift_positions.append(array_to_vec3i(pos_arr))

	# RuinsManager ruin types
	ruins_mgr._ruin_types.clear()
	ruins_mgr._active_explorations.clear()
	var ruin_types_data: Dictionary = data.get("ruin_types", {})
	for key: String in ruin_types_data:
		ruins_mgr._ruin_types[key_to_vec3i(key)] = int(ruin_types_data[key])

	# Active explorations
	var explorations_data: Array = data.get("active_explorations", [])
	for exp_dict: Dictionary in explorations_data:
		var coord: Vector3i = array_to_vec3i(exp_dict["coord"])
		var ruin_type: int = int(exp_dict["ruin_type"])
		var ruin_data: RuinData = ruins_mgr.ruin_registry.get_data(ruin_type)
		if ruin_data:
			var active := ActiveExploration.new(coord, ruin_data)
			active.remaining_cycles = int(exp_dict["remaining_cycles"])
			active.is_damaged = bool(exp_dict.get("is_damaged", false))
			ruins_mgr._active_explorations[coord] = active

	# BuildingManager constructions
	building_mgr._constructions.clear()
	var constructions_data: Array = data.get("constructions", [])
	for con_dict: Dictionary in constructions_data:
		var coord: Vector3i = array_to_vec3i(con_dict["coord"])
		var building_id: StringName = StringName(con_dict["building_id"])
		var bdata: BuildingData = building_mgr.building_registry.get_data(building_id)
		if bdata:
			var active := ActiveConstruction.new(coord, bdata)
			active.progress = float(con_dict["progress"])
			active.is_complete = bool(con_dict.get("is_complete", false))
			building_mgr._constructions[coord] = active

	return true


static func deserialize_metrics(data: Dictionary) -> bool:
	if not data.has("pollution") or not data.has("anxiety"):
		return false
	MetricSystem.pollution = float(data["pollution"])
	MetricSystem.anxiety = float(data["anxiety"])
	MetricSystem.solidarity = float(data.get("solidarity", 0.0))
	MetricSystem.harmony = float(data.get("harmony", 0.0))
	MetricSystem.science_value = float(data.get("science_value", 0.0))
	MetricSystem.magic_value = float(data.get("magic_value", 0.0))
	return true


static func deserialize_factions(data: Dictionary, quest_mgr: QuestManager) -> bool:
	if not data.has("pending_proposals") or not data.has("active_quests"):
		return false

	# Pending proposals — look up QuestData by quest_id
	quest_mgr._pending_proposals.clear()
	var pending_data: Array = data["pending_proposals"]
	for quest_id_str: String in pending_data:
		var quest_id: StringName = StringName(quest_id_str)
		var quest_data: QuestData = quest_mgr.quest_registry.get_quest(quest_id)
		if quest_data:
			quest_mgr._pending_proposals[quest_id] = quest_data

	# Active quests — recreate ActiveQuest, override remaining_cycles
	quest_mgr._active_quests.clear()
	var active_data: Array = data["active_quests"]
	for aq_dict: Dictionary in active_data:
		var quest_id: StringName = StringName(aq_dict["quest_id"])
		var quest_data: QuestData = quest_mgr.quest_registry.get_quest(quest_id)
		if quest_data:
			var active := ActiveQuest.new(quest_data)
			active.remaining_cycles = int(aq_dict["remaining_cycles"])
			quest_mgr._active_quests[quest_id] = active

	# Last proposed per faction
	quest_mgr._last_proposed.clear()
	var last_data: Dictionary = data.get("last_proposed", {})
	for faction_id_str: String in last_data:
		var faction_id: StringName = StringName(faction_id_str)
		quest_mgr._last_proposed[faction_id] = StringName(last_data[faction_id_str])

	return true
