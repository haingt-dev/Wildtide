class_name QuestManager
extends Node
## Manages faction quest proposal, approval, and execution lifecycle.
## Add as a child node in the main game scene (NOT an autoload).

const DEFAULT_MORALE: int = 50
const MIN_MORALE: int = 0
const MAX_MORALE: int = 100
const MORALE_ON_APPROVE: int = 5
const MORALE_ON_REJECT: int = -3

var faction_registry: FactionRegistry
var quest_registry: QuestRegistry

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

var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func _ready() -> void:
	faction_registry = FactionRegistry.new()
	quest_registry = QuestRegistry.new()
	_initialize_morale()
	EventBus.phase_changed.connect(_on_phase_changed)


## Called by player UI to approve a pending quest.
func approve_quest(quest_id: StringName) -> bool:
	var quest_data: QuestData = _pending_proposals.get(quest_id, null) as QuestData
	if not quest_data:
		return false
	_pending_proposals.erase(quest_id)
	var active := ActiveQuest.new(quest_data)
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
