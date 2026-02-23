class_name UtilityAI
extends Node
## Scoring-based AI that autonomously places buildings each cycle.
## Evaluates every (hex, building_type) pair using a 5-factor utility formula,
## then places the top N candidates via BuildingManager.
## Add as a child node in the main game scene (NOT an autoload).

## Era → allowed building IDs (GDD WT - Utility AI).
const ERA_BUILDINGS: Array[Array] = [
	[&"homestead", &"watchtower"],
	[&"homestead", &"watchtower", &"reactor", &"shrine", &"market"],
	[&"homestead", &"watchtower", &"reactor", &"shrine", &"market", &"workshop"],
]

## Faction → preferred building IDs for faction_influence scoring.
const FACTION_BUILDINGS: Dictionary = {
	&"the_lens": [&"reactor", &"workshop"],
	&"the_veil": [&"shrine"],
	&"the_coin": [&"market", &"homestead"],
	&"the_wall": [&"watchtower"],
}

## Alignment-favored building IDs.
const SCIENCE_BUILDINGS: Array[StringName] = [&"reactor", &"workshop"]
const MAGIC_BUILDINGS: Array[StringName] = [&"shrine"]

const ALIGNMENT_BOOST: float = 0.15
const DISTANCE_WEIGHT: float = 0.3

var ai_config: UtilityAIConfig
var hex_grid: HexGrid
var building_manager: BuildingManager
var building_registry: BuildingRegistry
var economy_manager: EconomyManager
var quest_manager: QuestManager
var movement_manager: MovementManager


func _ready() -> void:
	if not ai_config:
		ai_config = UtilityAIConfig.new()
	if not building_registry:
		building_registry = BuildingRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)


## Run a full evaluation cycle: score candidates, place top N buildings.
## Returns list of placements [{coord, building_id, score}].
func evaluate_and_place() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not hex_grid or not building_manager:
		return result
	var era: int = GameManager.get_current_era()
	var rate_idx: int = mini(era - 1, ai_config.era_placement_rates.size() - 1)
	var placement_count: int = ai_config.era_placement_rates[rate_idx]
	var allowed_ids: Array = _get_era_buildings(era)
	var candidates: Array[Vector3i] = _collect_candidates()

	for _i: int in range(placement_count):
		var best_score: float = -INF
		var best_coord: Vector3i = Vector3i.ZERO
		var best_id: StringName = &""
		for bid: StringName in allowed_ids:
			var bdata: BuildingData = building_registry.get_data(bid)
			if not bdata:
				continue
			if economy_manager and not economy_manager.can_afford(bdata.gold_cost, bdata.mana_cost):
				continue
			for coord: Vector3i in candidates:
				var cell: HexCell = hex_grid.get_cell(coord)
				if not cell or not cell.is_buildable():
					continue
				var score: float = _score_placement(coord, cell, bdata)
				if score > best_score:
					best_score = score
					best_coord = coord
					best_id = bid
		if best_id == &"" or best_score <= 0.0:
			break
		if building_manager.place_building(best_coord, best_id):
			result.append({&"coord": best_coord, &"building_id": best_id, &"score": best_score})
			candidates.erase(best_coord)

	if not result.is_empty():
		EventBus.ai_buildings_placed.emit(result)
	return result


## Get allowed building IDs for a given era.
func _get_era_buildings(era: int) -> Array:
	var idx: int = mini(era - 1, ERA_BUILDINGS.size() - 1)
	return ERA_BUILDINGS[maxi(idx, 0)]


## Collect buildable hex coordinates, sorted by distance to city center.
func _collect_candidates() -> Array[Vector3i]:
	var center: Vector3i = _get_city_center()
	var result: Array[Vector3i] = []
	for cell: HexCell in hex_grid.get_all_cells():
		if not cell.is_buildable():
			continue
		if cell.fog_state != FogState.ACTIVE:
			continue
		result.append(cell.coord)
	result.sort_custom(
		func(a: Vector3i, b: Vector3i) -> bool:
			return HexMath.distance(a, center) < HexMath.distance(b, center)
	)
	if result.size() > ai_config.max_candidates_per_eval:
		result.resize(ai_config.max_candidates_per_eval)
	return result


## Score a single (hex, building) pair using the 5-factor GDD formula.
func _score_placement(coord: Vector3i, cell: HexCell, bdata: BuildingData) -> float:
	var need: float = _calc_metric_need(bdata)
	var affinity: float = _calc_biome_affinity(cell, bdata)
	var adjacency: float = _calc_adjacency(coord, bdata)
	var faction: float = _calc_faction_influence(bdata)
	var penalty: float = _calc_pollution_penalty(cell)
	var score: float = (
		need * ai_config.need_weight
		+ affinity * ai_config.affinity_weight
		+ adjacency * ai_config.adjacency_weight
		+ faction * ai_config.faction_weight
		+ penalty * ai_config.penalty_weight
	)
	score += _calc_alignment_boost(bdata)
	score += _calc_distance_bonus(coord)
	return score


## Factor 1: Metric need — how much the city needs this building's effects.
func _calc_metric_need(bdata: BuildingData) -> float:
	if bdata.metric_effects.is_empty():
		return 0.0
	var total: float = 0.0
	var count: int = 0
	for metric_name: StringName in bdata.metric_effects:
		var delta: float = bdata.metric_effects[metric_name]
		var current: float = MetricSystem.get_metric(metric_name)
		var threshold: float = _get_critical_threshold(metric_name)
		if delta < 0.0:
			if current > threshold:
				total += clampf((current - threshold) / (1.0 - threshold), 0.0, 1.0)
			count += 1
		elif delta > 0.0:
			if current < threshold:
				total += clampf((threshold - current) / threshold, 0.0, 1.0)
			count += 1
	return total / maxf(count, 1.0)


## Factor 2: Biome affinity — binary match.
func _calc_biome_affinity(cell: HexCell, bdata: BuildingData) -> float:
	return 1.0 if bdata.biome_affinity == cell.biome else 0.0


## Factor 3: Adjacency bonus — sum of matching neighbor bonuses, capped at 1.0.
func _calc_adjacency(coord: Vector3i, bdata: BuildingData) -> float:
	if bdata.adjacency_targets.is_empty():
		return 0.0
	var total: float = 0.0
	for neighbor: HexCell in hex_grid.get_neighbors_of(coord):
		if bdata.adjacency_targets.has(neighbor.building_id):
			total += float(bdata.adjacency_targets[neighbor.building_id])
	return minf(total, 1.0)


## Factor 4: Faction influence — dominant faction boosts preferred buildings.
func _calc_faction_influence(bdata: BuildingData) -> float:
	if not quest_manager:
		return 0.0
	var best_faction: StringName = &""
	var best_morale: int = -1
	for faction_id: StringName in FACTION_BUILDINGS:
		var morale: int = quest_manager.get_faction_morale(faction_id)
		if morale > best_morale:
			best_morale = morale
			best_faction = faction_id
	if best_faction == &"":
		return 0.0
	var preferred: Array = FACTION_BUILDINGS.get(best_faction, [])
	if bdata.building_id in preferred:
		var morale_norm: float = float(best_morale) / float(QuestManager.MAX_MORALE)
		return morale_norm * ai_config.dominant_faction_bonus
	return 0.0


## Factor 5: Pollution penalty — 3-tier curve from UtilityAIConfig.
func _calc_pollution_penalty(cell: HexCell) -> float:
	var p: float = cell.pollution_level
	if p <= ai_config.pollution_low_threshold:
		return 0.0
	if p >= ai_config.pollution_high_threshold:
		return ai_config.pollution_max_penalty
	var t: float = (
		(p - ai_config.pollution_low_threshold)
		/ (ai_config.pollution_high_threshold - ai_config.pollution_low_threshold)
	)
	return lerpf(0.0, ai_config.pollution_mid_penalty, t)


## Alignment boost — Science/Magic axis favors certain building types.
func _calc_alignment_boost(bdata: BuildingData) -> float:
	var alignment: float = MetricSystem.get_alignment()
	if alignment > ai_config.science_dominant_threshold:
		if bdata.building_id in SCIENCE_BUILDINGS:
			return ALIGNMENT_BOOST
	elif alignment < ai_config.magic_dominant_threshold:
		if bdata.building_id in MAGIC_BUILDINGS:
			return ALIGNMENT_BOOST
	return 0.0


## Distance bonus — prefer hexes closer to city center.
func _calc_distance_bonus(coord: Vector3i) -> float:
	var center: Vector3i = _get_city_center()
	var dist: int = HexMath.distance(coord, center)
	var radius: int = ai_config.distance_falloff_radius
	if radius <= 0:
		return 0.0
	return maxf(0.0, 1.0 - float(dist) / float(radius)) * DISTANCE_WEIGHT


func _get_city_center() -> Vector3i:
	if movement_manager:
		return movement_manager.city_center
	return Vector3i.ZERO


func _get_critical_threshold(metric_name: StringName) -> float:
	match metric_name:
		&"pollution":
			return ai_config.pollution_critical
		&"anxiety":
			return ai_config.anxiety_critical
		&"harmony":
			return ai_config.harmony_critical_low
		&"solidarity":
			return ai_config.solidarity_critical_low
	return 0.5


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.OBSERVE:
		evaluate_and_place()
