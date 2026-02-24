class_name SaveSerializer
extends RefCounted
## Pure data conversion between game systems and JSON-compatible Dictionaries.
## No file I/O — used by SaveSystem for the actual read/write.

const SAVE_VERSION: int = 3


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
		"scenario_id":
		game_mgr.get("scenario_id") if game_mgr.get("scenario_id") else "the_wildtide",
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
					"fog_state": cell.fog_state,
					"region": cell.region,
					"rift_density": cell.rift_density,
					"pollution_level": cell.pollution_level,
					"zone_type": cell.zone_type,
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
					"current_tier": active.current_tier,
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
		"last_intel_level": wave_mgr._last_intel_level,
		"last_intel_report": wave_mgr._last_intel_report,
		"tech_fragments": ruins_mgr._tech_fragments,
		"rune_shards": ruins_mgr._rune_shards,
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

	var offensive: Array = []
	for quest_id: StringName in quest_mgr._offensive_quests:
		var aq: ActiveQuest = quest_mgr._offensive_quests[quest_id]
		offensive.append({"quest_id": String(quest_id), "remaining_cycles": aq.remaining_cycles})

	var morale: Dictionary = {}
	for faction_id: StringName in quest_mgr._faction_morale:
		morale[String(faction_id)] = quest_mgr._faction_morale[faction_id]

	return {
		"pending_proposals": pending,
		"active_quests": active,
		"offensive_quests": offensive,
		"last_proposed": last,
		"faction_morale": morale,
	}


static func serialize_economy(economy_mgr: EconomyManager) -> Dictionary:
	return {
		"gold": economy_mgr.get_gold(),
		"mana": economy_mgr.get_mana(),
		"gold_capacity": economy_mgr.get_gold_capacity(),
		"mana_capacity": economy_mgr.get_mana_capacity(),
		"rift_shards": economy_mgr.get_rift_shards(),
	}


static func serialize_stability(tracker: StabilityTracker) -> Dictionary:
	return {
		"stability": tracker.get_stability(),
		"depletion_cycles": tracker.get_depletion_cycles(),
	}


static func serialize_movement(move_mgr: MovementManager) -> Dictionary:
	return {
		"city_center": vec3i_to_array(move_mgr.city_center),
		"is_in_transit": move_mgr.is_in_transit,
		"transit_cycles_remaining": move_mgr.transit_cycles_remaining,
		"settlement_cycles_remaining": move_mgr._settlement_cycles_remaining,
		"cycles_in_region": move_mgr._cycles_in_region,
		"last_salvage_yield": move_mgr._last_salvage_yield,
		"awaiting_direction": move_mgr.awaiting_direction,
	}


static func serialize_edicts(edict_mgr: EdictManager) -> Dictionary:
	var edicts: Array = []
	for eid: StringName in edict_mgr._active_edicts:
		var entry: Dictionary = edict_mgr._active_edicts[eid]
		(
			edicts
			. append(
				{
					"edict_id": String(eid),
					"remaining": entry["remaining"],
				}
			)
		)
	return {
		"active_edicts": edicts,
		"mandate_last_era": edict_mgr._mandate_last_era,
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
		cell.fog_state = int(cell_dict.get("fog_state", FogState.ACTIVE))
		cell.region = int(cell_dict.get("region", RegionType.Type.STARTING))
		cell.rift_density = float(cell_dict.get("rift_density", 0.0))
		cell.pollution_level = float(cell_dict.get("pollution_level", 0.0))
		cell.zone_type = int(cell_dict.get("zone_type", ZoneType.Type.NONE))
		grid._cell_array.append(cell)
	grid.rebuild_lookup()

	# WaveManager rift positions
	wave_mgr.rift_positions.clear()
	var rift_data: Array = data.get("rift_positions", [])
	for pos_arr: Array in rift_data:
		wave_mgr.rift_positions.append(array_to_vec3i(pos_arr))

	# WaveManager intel cache
	wave_mgr._last_intel_level = int(data.get("last_intel_level", 0))
	wave_mgr._last_intel_report = data.get("last_intel_report", {}) as Dictionary

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

	# Fragment counters
	ruins_mgr._tech_fragments = int(data.get("tech_fragments", 0))
	ruins_mgr._rune_shards = int(data.get("rune_shards", 0))

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
			active.current_tier = int(con_dict.get("current_tier", 1))
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

	# Offensive quests
	quest_mgr._offensive_quests.clear()
	var offensive_data: Array = data.get("offensive_quests", [])
	for oq_dict: Dictionary in offensive_data:
		var oq_id: StringName = StringName(oq_dict["quest_id"])
		var oq_data: QuestData = quest_mgr.quest_registry.get_quest(oq_id)
		if oq_data:
			var oq_active := ActiveQuest.new(oq_data)
			oq_active.remaining_cycles = int(oq_dict["remaining_cycles"])
			quest_mgr._offensive_quests[oq_id] = oq_active

	# Last proposed per faction
	quest_mgr._last_proposed.clear()
	var last_data: Dictionary = data.get("last_proposed", {})
	for faction_id_str: String in last_data:
		var faction_id: StringName = StringName(faction_id_str)
		quest_mgr._last_proposed[faction_id] = StringName(last_data[faction_id_str])

	# Faction morale (backward compat: defaults to initialized morale if absent)
	var morale_data: Dictionary = data.get("faction_morale", {})
	for faction_id_str: String in morale_data:
		quest_mgr._faction_morale[StringName(faction_id_str)] = int(morale_data[faction_id_str])

	return true


static func deserialize_economy(data: Dictionary, economy_mgr: EconomyManager) -> bool:
	if not data.has("gold"):
		return false
	economy_mgr._gold = int(data["gold"])
	economy_mgr._mana = int(data.get("mana", 0))
	economy_mgr._gold_capacity = int(data.get("gold_capacity", 100))
	economy_mgr._mana_capacity = int(data.get("mana_capacity", 100))
	economy_mgr._rift_shards = int(data.get("rift_shards", 0))
	return true


static func deserialize_stability(data: Dictionary, tracker: StabilityTracker) -> bool:
	if not data.has("stability"):
		return false
	tracker.set_stability(int(data["stability"]))
	tracker.set_depletion_cycles(int(data.get("depletion_cycles", 0)))
	return true


static func deserialize_movement(data: Dictionary, move_mgr: MovementManager) -> bool:
	move_mgr.city_center = array_to_vec3i(data.get("city_center", [0, 0, 0]))
	move_mgr.is_in_transit = bool(data.get("is_in_transit", false))
	move_mgr.transit_cycles_remaining = int(data.get("transit_cycles_remaining", 0))
	move_mgr._settlement_cycles_remaining = int(data.get("settlement_cycles_remaining", 0))
	move_mgr._cycles_in_region = int(data.get("cycles_in_region", 0))
	move_mgr._last_salvage_yield = int(data.get("last_salvage_yield", 0))
	move_mgr.awaiting_direction = bool(data.get("awaiting_direction", false))
	if move_mgr.is_in_transit and move_mgr.economy_manager:
		move_mgr.economy_manager.set_transit(true)
	return true


static func serialize_artifact(controller: ArtifactController) -> Dictionary:
	if not controller:
		return {}
	return {
		"state": controller.state,
		"progress_cycles": controller.progress_cycles,
		"required_cycles": controller.required_cycles,
		"construction_coord": vec3i_to_array(controller.construction_coord),
	}


static func deserialize_artifact(data: Dictionary) -> ArtifactController:
	if data.is_empty():
		return null
	var controller := ArtifactController.new()
	controller.state = int(data.get("state", 0)) as ArtifactController.State
	controller.progress_cycles = int(data.get("progress_cycles", 0))
	controller.required_cycles = int(data.get("required_cycles", 3))
	var coord_arr: Array = data.get("construction_coord", [0, 0, 0])
	controller.construction_coord = array_to_vec3i(coord_arr)
	return controller


static func deserialize_edicts(data: Dictionary, edict_mgr: EdictManager) -> bool:
	var edicts_data: Array = data.get("active_edicts", [])
	for entry: Dictionary in edicts_data:
		var eid: StringName = StringName(entry["edict_id"])
		var edata: EdictData = edict_mgr.edict_registry.get_edict(eid)
		if edata:
			edict_mgr._active_edicts[eid] = {
				"data": edata,
				"remaining": int(entry["remaining"]),
			}
	edict_mgr._mandate_last_era = int(data.get("mandate_last_era", 0))
	return true
