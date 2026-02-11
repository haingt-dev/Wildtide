class_name CycleTimer
extends Resource
## Defines phase durations for the 4-phase game cycle.
## Save as .tres for game mode presets (Normal, Hell, Zen).

enum Phase { OBSERVE, INFLUENCE, WAVE, EVOLVE }

const PHASE_NAMES: Array[StringName] = [&"observe", &"influence", &"wave", &"evolve"]
const PHASE_COUNT: int = 4

@export var observe_duration: float = 180.0  ## 3 minutes
@export var influence_duration: float = 180.0  ## 3 minutes
@export var wave_duration: float = 60.0  ## 1 minute
@export var evolve_duration: float = 60.0  ## 1 minute


func get_phase_duration(phase: Phase) -> float:
	match phase:
		Phase.OBSERVE:
			return observe_duration
		Phase.INFLUENCE:
			return influence_duration
		Phase.WAVE:
			return wave_duration
		Phase.EVOLVE:
			return evolve_duration
		_:
			return 0.0


func get_phase_name(phase: Phase) -> StringName:
	if phase >= 0 and phase < PHASE_COUNT:
		return PHASE_NAMES[phase]
	return &""


func get_total_cycle_duration() -> float:
	return observe_duration + influence_duration + wave_duration + evolve_duration
