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
		EventBus.cycle_completed.emit(cycle_number)
		cycle_number += 1
		EventBus.cycle_started.emit(cycle_number)
		_start_phase(CycleTimer.Phase.OBSERVE)
	else:
		var next_phase: int = int(current_phase) + 1
		_start_phase(next_phase as CycleTimer.Phase)


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
