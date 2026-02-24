class_name QuestManager
extends Node
## Manages faction quest proposal, approval, and execution lifecycle.
## Add as a child node in the main game scene (NOT an autoload).

const DEFAULT_MORALE: int = 50
const MIN_MORALE: int = 0
const MAX_MORALE: int = 100
const MORALE_ON_APPROVE: int = 5
const MORALE_ON_REJECT: int = -3
const MORALE_LOW_THRESHOLD: int = 25
const MORALE_HIGH_THRESHOLD: int = 75

var faction_registry: FactionRegistry
var quest_registry: QuestRegistry
var wave_intel: WaveIntel

## Quests proposed this cycle, awaiting player decision.
## Key: StringName (quest_id), Value: QuestData
var _pending_proposals: Dictionary = {}

## Currently running approved quests.
## Key: StringName (quest_id), Value: ActiveQuest
var _active_quests: Dictionary = {}

## Track last proposed quest per faction to avoid repeats.
## Key: StringName (faction_id), Value: StringName (quest_id)
var _last_proposed: Dictionary = {}

## Runtime morale per faction (0-100). Key: StringName (faction_id), Value: int.
var _faction_morale: Dictionary = {}

## Offensive quests approved this cycle, resolved after wave ends.
## Key: StringName (quest_id), Value: ActiveQuest
var _offensive_quests: Dictionary = {}

## Whether city migration is active (factions can propose movement directions).
var _migration_active: bool = false

var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func _ready() -> void:
	faction_registry = FactionRegistry.new()
	quest_registry = QuestRegistry.new()
	_initialize_morale()
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.migration_requested.connect(func() -> void: _migration_active = true)
	EventBus.city_moved.connect(func(_o: Vector3i, _n: Vector3i) -> void: _migration_active = false)


## Called by player UI to approve a pending quest.
func approve_quest(quest_id: StringName) -> bool:
	var quest_data: QuestData = _pending_proposals.get(quest_id, null) as QuestData
	if not quest_data:
		return false
	_pending_proposals.erase(quest_id)
	if quest_data.is_movement_proposal:
		push_faction_morale(quest_data.faction_id, MORALE_ON_APPROVE)
		EventBus.quest_approved.emit(quest_data.faction_id, quest_id)
		EventBus.movement_proposed.emit(quest_data.proposed_direction)
		return true
	var active := ActiveQuest.new(quest_data)
	if quest_data.is_offensive:
		_offensive_quests[quest_id] = active
	else:
		_apply_morale_duration_scaling(active)
		_active_quests[quest_id] = active
	push_faction_morale(quest_data.faction_id, MORALE_ON_APPROVE)
	EventBus.quest_approved.emit(quest_data.faction_id, quest_id)
	return true


## Called by player UI to reject a pending quest.
func reject_quest(quest_id: StringName) -> bool:
	var quest_data: QuestData = _pending_proposals.get(quest_id, null) as QuestData
	if not quest_data:
		return false
	_pending_proposals.erase(quest_id)
	push_faction_morale(quest_data.faction_id, MORALE_ON_REJECT)
	EventBus.quest_rejected.emit(quest_data.faction_id, quest_id)
	return true


## Get all currently pending proposals (read-only snapshot).
func get_pending_proposals() -> Array[QuestData]:
	var result: Array[QuestData] = []
	for val: QuestData in _pending_proposals.values():
		result.append(val)
	return result


## Get all currently active (running) quests.
func get_active_quests() -> Array[ActiveQuest]:
	var result: Array[ActiveQuest] = []
	for val: ActiveQuest in _active_quests.values():
		result.append(val)
	return result


## Get faction morale (0-100).
func get_faction_morale(faction_id: StringName) -> int:
	return _faction_morale.get(faction_id, DEFAULT_MORALE) as int


## Push morale delta for a faction, clamped to [0, 100].
func push_faction_morale(faction_id: StringName, delta: int) -> void:
	var old_value: int = get_faction_morale(faction_id)
	var new_value: int = clampi(old_value + delta, MIN_MORALE, MAX_MORALE)
	_faction_morale[faction_id] = new_value
	if new_value != old_value:
		EventBus.faction_morale_changed.emit(faction_id, new_value, old_value)


## Get count of active quests for a specific faction.
func get_active_count_for_faction(faction_id: StringName) -> int:
	var count: int = 0
	for active: ActiveQuest in _active_quests.values():
		if active.faction_id == faction_id:
			count += 1
	return count


func _initialize_morale() -> void:
	for faction_data: FactionData in faction_registry.get_all():
		_faction_morale[faction_data.faction_id] = DEFAULT_MORALE


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.INFLUENCE:
		_propose_quests()
	elif new_phase == CycleTimer.Phase.EVOLVE:
		_tick_active_quests()


func _propose_quests() -> void:
	_pending_proposals.clear()
	for faction_data: FactionData in faction_registry.get_all():
		var quest: QuestData = _pick_quest_for_faction(faction_data)
		if quest:
			_pending_proposals[quest.quest_id] = quest
			_last_proposed[faction_data.faction_id] = quest.quest_id
			EventBus.quest_proposed.emit(faction_data.faction_id, quest.quest_id)
	if wave_intel and wave_intel.compute_level() >= WaveIntel.Level.PARTIAL:
		_propose_offensive_quests()
	if _migration_active:
		_propose_movement_quests()


func _pick_quest_for_faction(faction_data: FactionData) -> QuestData:
	var pool: Array[QuestData] = quest_registry.get_quests_for_faction(faction_data.faction_id)
	if pool.is_empty():
		return null
	var last_id: StringName = _last_proposed.get(faction_data.faction_id, &"")
	var filtered: Array[QuestData] = []
	for q: QuestData in pool:
		if q.quest_id != last_id:
			filtered.append(q)
	if filtered.is_empty():
		filtered = pool
	var idx: int = _rng.randi_range(0, filtered.size() - 1)
	return filtered[idx]


func _tick_active_quests() -> void:
	var completed_ids: Array[StringName] = []
	for quest_id: StringName in _active_quests:
		var active: ActiveQuest = _active_quests[quest_id]
		_apply_quest_effects(active.quest_data)
		if active.tick():
			completed_ids.append(quest_id)
	for quest_id: StringName in completed_ids:
		var active: ActiveQuest = _active_quests[quest_id]
		_active_quests.erase(quest_id)
		EventBus.quest_completed.emit(active.faction_id, quest_id)


func _apply_quest_effects(quest_data: QuestData) -> void:
	for metric_name: StringName in quest_data.metric_effects:
		var delta: float = quest_data.metric_effects[metric_name]
		MetricSystem.push_metric(metric_name, delta)
	if quest_data.alignment_push != 0.0:
		MetricSystem.push_alignment(quest_data.alignment_push)


# --- Offensive quest lifecycle ---


func _propose_offensive_quests() -> void:
	for faction_data: FactionData in faction_registry.get_all():
		var offensives: Array[QuestData] = quest_registry.get_offensive_quests_for_faction(
			faction_data.faction_id
		)
		for quest: QuestData in offensives:
			if _meets_alignment_requirement(quest):
				_pending_proposals[quest.quest_id] = quest
				EventBus.quest_proposed.emit(faction_data.faction_id, quest.quest_id)


func _meets_alignment_requirement(quest: QuestData) -> bool:
	if quest.alignment_requirement == 0.0:
		return true
	var alignment: float = MetricSystem.get_alignment()
	if quest.alignment_requirement > 0.0:
		return alignment >= quest.alignment_requirement
	return alignment <= quest.alignment_requirement


## Return aggregated offensive quest effects for the current wave.
func get_active_offensive_effects() -> Dictionary:
	var effects: Dictionary = {}
	for active: ActiveQuest in _offensive_quests.values():
		var key: StringName = active.quest_data.offensive_effect_key
		var value: float = active.quest_data.offensive_effect_value
		if key == &"":
			continue
		if key == &"defense_bonus":
			effects[key] = (effects.get(key, 0.0) as float) + value
		else:
			effects[key] = (effects.get(key, 1.0) as float) * value
	return effects


func _on_wave_ended(_cycle: int) -> void:
	_resolve_offensive_quests()


func _resolve_offensive_quests() -> void:
	for quest_id: StringName in _offensive_quests:
		var active: ActiveQuest = _offensive_quests[quest_id]
		_apply_quest_effects(active.quest_data)
		EventBus.quest_completed.emit(active.faction_id, quest_id)
	_offensive_quests.clear()


# --- Movement quest proposals ---


func _propose_movement_quests() -> void:
	var directions: Array[Vector3i] = HexMath.NEIGHBOR_OFFSETS.duplicate()
	directions.shuffle()
	var idx: int = 0
	for faction_data: FactionData in faction_registry.get_all():
		if idx >= directions.size():
			break
		var qd := QuestData.new()
		qd.quest_id = StringName("move_%s" % faction_data.faction_id)
		qd.faction_id = faction_data.faction_id
		qd.display_name = "Move %s" % faction_data.display_name
		qd.is_movement_proposal = true
		qd.proposed_direction = directions[idx]
		qd.duration = 1
		_pending_proposals[qd.quest_id] = qd
		EventBus.quest_proposed.emit(faction_data.faction_id, qd.quest_id)
		idx += 1


# --- Morale-scaled duration ---


func _apply_morale_duration_scaling(active: ActiveQuest) -> void:
	var morale: int = get_faction_morale(active.faction_id)
	if morale < MORALE_LOW_THRESHOLD:
		active.remaining_cycles += 1
	elif morale > MORALE_HIGH_THRESHOLD:
		active.remaining_cycles = maxi(1, active.remaining_cycles - 1)
