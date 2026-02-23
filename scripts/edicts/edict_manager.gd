class_name EdictManager
extends Node
## Manages active edicts: enact, revoke, tick durations, apply effects.
## Add as a child node in the main game scene (NOT an autoload).

const MAX_ACTIVE_EDICTS: int = 2

var edict_registry: EdictRegistry

## Currently active edicts. Key: edict_id, Value: Dictionary {data, remaining}.
## remaining = -1 for permanent, positive int for timed edicts.
var _active_edicts: Dictionary = {}


func _ready() -> void:
	edict_registry = EdictRegistry.new()
	EventBus.phase_changed.connect(_on_phase_changed)


## Enact an edict by id. Returns true if successful.
## If slots are full, caller must revoke one first (unless is_free_action).
func enact_edict(edict_id: StringName) -> bool:
	if _active_edicts.has(edict_id):
		return false
	var edata: EdictData = edict_registry.get_edict(edict_id)
	if not edata:
		return false
	if not edata.is_free_action and _get_slot_count() >= MAX_ACTIVE_EDICTS:
		return false
	_active_edicts[edict_id] = {
		"data": edata,
		"remaining": edata.duration,
	}
	_apply_faction_enact_reactions(edata)
	EventBus.edict_enacted.emit(edict_id)
	return true


## Revoke an active edict. Returns true if it was active.
func revoke_edict(edict_id: StringName) -> bool:
	if not _active_edicts.has(edict_id):
		return false
	_active_edicts.erase(edict_id)
	EventBus.edict_revoked.emit(edict_id)
	return true


## Get all active edict ids.
func get_active_edict_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for eid: StringName in _active_edicts:
		result.append(eid)
	return result


## Get the EdictData for an active edict, or null.
func get_active_edict(edict_id: StringName) -> EdictData:
	var entry: Dictionary = _active_edicts.get(edict_id, {})
	return entry.get("data", null) as EdictData


## Get remaining duration for an active edict (-1 = permanent).
func get_remaining(edict_id: StringName) -> int:
	var entry: Dictionary = _active_edicts.get(edict_id, {})
	return entry.get("remaining", 0) as int


## Get number of occupied edict slots (excludes free actions).
func _get_slot_count() -> int:
	var count: int = 0
	for entry: Dictionary in _active_edicts.values():
		var edata: EdictData = entry["data"]
		if not edata.is_free_action:
			count += 1
	return count


## Aggregate economy effects from all active edicts.
func get_economy_effects() -> Dictionary:
	var result: Dictionary = {}
	for entry: Dictionary in _active_edicts.values():
		var edata: EdictData = entry["data"]
		for key: StringName in edata.economy_effects:
			var val: float = edata.economy_effects[key]
			result[key] = (result.get(key, 0.0) as float) + val
	return result


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase == CycleTimer.Phase.EVOLVE:
		_apply_metric_effects()
		_apply_faction_dislike()
		_tick_durations()


func _apply_metric_effects() -> void:
	for entry: Dictionary in _active_edicts.values():
		var edata: EdictData = entry["data"]
		for metric_name: StringName in edata.metric_effects:
			var delta: float = edata.metric_effects[metric_name]
			MetricSystem.push_metric(metric_name, delta)
		if edata.alignment_push != 0.0:
			MetricSystem.push_alignment(edata.alignment_push)


func _apply_faction_enact_reactions(edata: EdictData) -> void:
	for fid: StringName in edata.faction_reactions:
		var reaction: int = edata.faction_reactions[fid]
		if reaction > 0:
			EventBus.faction_morale_changed.emit(fid, reaction, 0)


func _apply_faction_dislike() -> void:
	for entry: Dictionary in _active_edicts.values():
		var edata: EdictData = entry["data"]
		for fid: StringName in edata.faction_reactions:
			var reaction: int = edata.faction_reactions[fid]
			if reaction < 0:
				EventBus.faction_morale_changed.emit(fid, reaction, 0)


func _tick_durations() -> void:
	var expired_ids: Array[StringName] = []
	for eid: StringName in _active_edicts:
		var entry: Dictionary = _active_edicts[eid]
		var remaining: int = entry["remaining"]
		if remaining > 0:
			remaining -= 1
			entry["remaining"] = remaining
			if remaining == 0:
				expired_ids.append(eid)
	for eid: StringName in expired_ids:
		_active_edicts.erase(eid)
		EventBus.edict_expired.emit(eid)
