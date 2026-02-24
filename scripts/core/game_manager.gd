extends Node
## Core game loop state machine. Manages phase transitions, cycle
## progression, game speed, and pause state.
## Register as autoload: Project Settings > Autoload > "GameManager".

const MAX_SPEED: int = 3
const MIN_SPEED: int = 1

var cycle_timer: CycleTimer = CycleTimer.new()
var current_phase: CycleTimer.Phase = CycleTimer.Phase.OBSERVE
var cycle_number: int = 0
var game_speed: int = 1
var is_paused: bool = false
var is_running: bool = false
var scenario_id: StringName = &"the_wildtide"
var scenario_data: ScenarioData

## Injected references for win condition checking.
var artifact_controller: ArtifactController
var ruins_manager: RuinsManager
var movement_manager: MovementManager
var hex_grid: HexGrid

## Cycle numbers where each era begins. Index 0 = Era 1, etc.
var era_cycle_thresholds: Array[int] = [1, 6, 11, 16]

var _phase_timer: Timer


func _ready() -> void:
	_phase_timer = Timer.new()
	_phase_timer.one_shot = true
	_phase_timer.timeout.connect(_on_phase_timer_timeout)
	add_child(_phase_timer)


## Start the game loop at cycle 1, Observe phase.
func start_game() -> void:
	if is_running:
		return
	is_running = true
	cycle_number = 1
	current_phase = CycleTimer.Phase.OBSERVE
	EventBus.cycle_started.emit(cycle_number)
	_start_phase(current_phase)


## Force-advance to next phase (debug / skip).
func advance_phase() -> void:
	if not is_running:
		return
	_phase_timer.stop()
	_transition_to_next_phase()


## Set game speed multiplier (1, 2, or 3).
func set_game_speed(speed: int) -> void:
	var clamped: int = clampi(speed, MIN_SPEED, MAX_SPEED)
	if clamped == game_speed:
		return
	game_speed = clamped
	EventBus.game_speed_changed.emit(game_speed)
	if is_running and not is_paused:
		_rescale_timer()


## Pause the game loop.
func pause_game() -> void:
	if is_paused or not is_running:
		return
	is_paused = true
	_phase_timer.paused = true
	EventBus.game_paused.emit()


## Resume the game loop.
func resume_game() -> void:
	if not is_paused or not is_running:
		return
	is_paused = false
	_phase_timer.paused = false
	EventBus.game_resumed.emit()


## Progress through current phase (0.0 to 1.0).
func get_phase_progress() -> float:
	if not is_running:
		return 0.0
	var total: float = _get_scaled_duration(current_phase)
	if total <= 0.0:
		return 1.0
	var elapsed: float = total - _phase_timer.time_left
	return clampf(elapsed / total, 0.0, 1.0)


## Get the current era (1-based) derived from cycle_number and thresholds.
func get_current_era() -> int:
	var era: int = 1
	for i: int in range(era_cycle_thresholds.size()):
		if cycle_number >= era_cycle_thresholds[i]:
			era = i + 1
	return era


## Seconds remaining in current phase.
func get_phase_time_remaining() -> float:
	if not is_running:
		return 0.0
	return _phase_timer.time_left


func _start_phase(phase: CycleTimer.Phase) -> void:
	current_phase = phase
	var duration: float = _get_scaled_duration(phase)
	_phase_timer.wait_time = maxf(duration, 0.01)
	_phase_timer.start()
	EventBus.phase_changed.emit(int(phase), cycle_timer.get_phase_name(phase))


func _transition_to_next_phase() -> void:
	if current_phase == CycleTimer.Phase.EVOLVE:
		_tick_artifact()
		_check_win_conditions()
		EventBus.cycle_completed.emit(cycle_number)
		cycle_number += 1
		EventBus.cycle_started.emit(cycle_number)
		_start_phase(CycleTimer.Phase.OBSERVE)
	else:
		var next_phase: int = int(current_phase) + 1
		_start_phase(next_phase as CycleTimer.Phase)


## Check all scenario win conditions at end of EVOLVE phase.
func _check_win_conditions() -> void:
	if not scenario_data or scenario_data.win_conditions.is_empty():
		return
	for wc: WinConditionData in scenario_data.win_conditions:
		if _is_condition_met(wc):
			EventBus.game_won.emit(wc.type)
			return


func _is_condition_met(wc: WinConditionData) -> bool:
	if get_current_era() < wc.required_era:
		return false
	var alignment: float = MetricSystem.get_alignment()
	match wc.type:
		WinConditionData.WinConditionType.SCIENCE_WIN:
			return alignment >= wc.required_alignment and _check_endgame(wc, true)
		WinConditionData.WinConditionType.MAGIC_WIN:
			return alignment <= -wc.required_alignment and _check_endgame(wc, false)
		WinConditionData.WinConditionType.SURVIVAL:
			return cycle_number >= wc.required_cycles
	return false


## Check fragment count, rift core location, and artifact completion.
func _check_endgame(wc: WinConditionData, is_science: bool) -> bool:
	if ruins_manager:
		var frags: int = (
			ruins_manager.get_tech_fragments() if is_science else ruins_manager.get_rune_shards()
		)
		if frags < wc.required_fragments:
			return false
	if wc.requires_rift_core and hex_grid and movement_manager:
		var cell: HexCell = hex_grid.get_cell(movement_manager.city_center)
		if not cell or cell.region != RegionType.Type.RIFT_CORE:
			return false
	if wc.artifact_construction_cycles > 0:
		if not artifact_controller or not artifact_controller.is_complete():
			return false
	return true


## Start artifact construction for the given win type.
## Validates all prerequisites before starting.
func start_artifact_construction(win_type: int) -> bool:
	if artifact_controller and artifact_controller.is_building():
		return false
	if not scenario_data:
		return false
	var wc: WinConditionData = _find_win_condition(win_type)
	if not wc or not _validate_artifact_prereqs(wc):
		return false
	artifact_controller = ArtifactController.new()
	var coord: Vector3i = movement_manager.city_center if movement_manager else Vector3i.ZERO
	artifact_controller.start_construction(coord, wc.artifact_construction_cycles)
	EventBus.artifact_started.emit(coord)
	return true


func _validate_artifact_prereqs(wc: WinConditionData) -> bool:
	if get_current_era() < wc.required_era:
		return false
	var alignment: float = MetricSystem.get_alignment()
	var is_science: bool = wc.type == WinConditionData.WinConditionType.SCIENCE_WIN
	if is_science and alignment < wc.required_alignment:
		return false
	if not is_science and alignment > -wc.required_alignment:
		return false
	if ruins_manager:
		var frags: int = (
			ruins_manager.get_tech_fragments() if is_science else ruins_manager.get_rune_shards()
		)
		if frags < wc.required_fragments:
			return false
	if wc.requires_rift_core and hex_grid and movement_manager:
		var cell: HexCell = hex_grid.get_cell(movement_manager.city_center)
		if not cell or cell.region != RegionType.Type.RIFT_CORE:
			return false
	return true


func _find_win_condition(win_type: int) -> WinConditionData:
	for wc: WinConditionData in scenario_data.win_conditions:
		if wc.type == win_type:
			return wc
	return null


func _tick_artifact() -> void:
	if not artifact_controller or not artifact_controller.is_building():
		return
	if artifact_controller.tick():
		EventBus.artifact_completed.emit(-1)
	else:
		EventBus.artifact_progress.emit(
			artifact_controller.progress_cycles, artifact_controller.required_cycles
		)


func _on_phase_timer_timeout() -> void:
	_transition_to_next_phase()


func _get_scaled_duration(phase: CycleTimer.Phase) -> float:
	return cycle_timer.get_phase_duration(phase) / float(game_speed)


func _rescale_timer() -> void:
	var remaining_ratio: float = get_phase_progress()
	var new_total: float = _get_scaled_duration(current_phase)
	var new_remaining: float = new_total * (1.0 - remaining_ratio)
	_phase_timer.stop()
	_phase_timer.wait_time = maxf(new_remaining, 0.01)
	_phase_timer.start()
