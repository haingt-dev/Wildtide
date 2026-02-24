class_name StabilityTracker
extends Node
## Tracks city stability (0-100). Game over when stability reaches 0.
## Add as a child node in the main game scene (NOT an autoload).

var stability_config: StabilityConfig
var economy_manager: EconomyManager  ## Optional — auto-checks resource depletion.
var wave_manager: WaveManager  ## Optional — auto-checks wave damage.
var quest_manager: QuestManager  ## Optional — auto-checks faction morale.
var edict_manager: EdictManager  ## Optional — auto-checks festival bonus.

var _stability: int = 100
var _alert_level: StringName = &"normal"

## Consecutive cycles with a primary resource at 0.
var _depletion_cycles: int = 0


func _ready() -> void:
	if not stability_config:
		stability_config = StabilityConfig.new()
	_stability = stability_config.starting_stability
	_update_alert_level()
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.wave_ended.connect(_on_wave_ended)


## Get current stability.
func get_stability() -> int:
	return _stability


## Get current alert level (&"normal", &"yellow", &"red", &"final").
func get_alert_level() -> StringName:
	return _alert_level


## Push a raw stability delta (before multiplier).
func push_stability(raw_delta: int) -> void:
	var mult: float = (
		stability_config.gain_multiplier if raw_delta > 0 else stability_config.loss_multiplier
	)
	var actual: int = roundi(raw_delta * mult)
	_set_stability(_stability + actual)


## Called after a Wave: damage_fraction = damaged_buildings / total_buildings.
func on_wave_result(damage_fraction: float) -> void:
	if damage_fraction > stability_config.wave_damage_threshold:
		var severity: float = clampf(damage_fraction, 0.0, 1.0)
		var loss: int = roundi(
			lerpf(
				stability_config.wave_damage_loss_min,
				stability_config.wave_damage_loss_max,
				severity,
			)
		)
		push_stability(loss)
	elif damage_fraction < stability_config.wave_defense_threshold:
		push_stability(stability_config.wave_defense_gain)


## Called per cycle: check faction morale conditions.
func check_faction_morale(all_below_threshold: bool, high_morale_count: int) -> void:
	if all_below_threshold:
		push_stability(stability_config.low_morale_loss_per_cycle)
	if high_morale_count > 0:
		push_stability(stability_config.high_morale_gain_per_cycle * high_morale_count)


## Called per cycle: check resource depletion.
func check_resource_depletion(gold: int, mana: int) -> void:
	if gold == 0 or mana == 0:
		_depletion_cycles += 1
		if _depletion_cycles > 1:
			push_stability(stability_config.resource_depletion_loss)
	else:
		_depletion_cycles = 0


## Called per cycle: check solidarity metric.
func check_solidarity(solidarity_value: float) -> void:
	if solidarity_value > stability_config.solidarity_threshold:
		push_stability(stability_config.solidarity_gain_per_cycle)


## Called per cycle: festival edict bonus.
func apply_festival_bonus() -> void:
	push_stability(stability_config.festival_gain_per_cycle)


## Called when artifact construction fails.
func on_artifact_failed() -> void:
	push_stability(stability_config.failed_artifact_loss)


## Reset depletion counter (e.g., on save load).
func set_depletion_cycles(count: int) -> void:
	_depletion_cycles = count


## Get depletion counter for save/load.
func get_depletion_cycles() -> int:
	return _depletion_cycles


## Force set stability (for save loading).
func set_stability(value: int) -> void:
	_set_stability(value)


func _set_stability(value: int) -> void:
	var floor_val: int = stability_config.stability_floor
	var old: int = _stability
	_stability = clampi(value, floor_val, StabilityConfig.MAX_STABILITY)
	if _stability != old:
		EventBus.stability_changed.emit(_stability, old)
		_update_alert_level()
	if _stability <= 0 and stability_config.game_over_enabled:
		EventBus.game_over.emit()


func _on_phase_changed(new_phase: int, _phase_name: StringName) -> void:
	if new_phase != CycleTimer.Phase.EVOLVE:
		return
	if economy_manager:
		check_resource_depletion(economy_manager.get_gold(), economy_manager.get_mana())
	check_solidarity(MetricSystem.solidarity)
	_check_faction_morale()
	_check_festival()


func _on_wave_ended(_cycle: int) -> void:
	if not wave_manager or not wave_manager.hex_grid:
		return
	var total_cells: int = wave_manager.hex_grid.get_all_cells().size()
	if total_cells == 0:
		return
	var damage_fraction: float = wave_manager.get_last_total_damage() / float(total_cells)
	on_wave_result(damage_fraction)


func _check_faction_morale() -> void:
	if not quest_manager:
		return
	var all_low: bool = true
	var high_count: int = 0
	for fid: StringName in [&"the_lens", &"the_veil", &"the_coin", &"the_wall"]:
		var morale: int = quest_manager.get_faction_morale(fid)
		if morale >= stability_config.low_morale_threshold:
			all_low = false
		if morale >= stability_config.high_morale_threshold:
			high_count += 1
	check_faction_morale(all_low, high_count)


func _check_festival() -> void:
	if not edict_manager:
		return
	if edict_manager.get_active_edict(&"festival"):
		apply_festival_bonus()


func _update_alert_level() -> void:
	var new_level: StringName
	if _stability <= stability_config.warning_final:
		new_level = &"final"
	elif _stability <= stability_config.warning_red:
		new_level = &"red"
	elif _stability <= stability_config.warning_yellow:
		new_level = &"yellow"
	else:
		new_level = &"normal"
	if new_level != _alert_level:
		_alert_level = new_level
		EventBus.alert_level_changed.emit(_alert_level)
