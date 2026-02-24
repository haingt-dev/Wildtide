extends GutTest
## Tests for ArtifactController — artifact construction lifecycle.

var controller: ArtifactController


func before_each() -> void:
	controller = ArtifactController.new()


# --- Initial state ---


func test_initial_state_idle() -> void:
	assert_eq(controller.state, ArtifactController.State.IDLE)
	assert_eq(controller.progress_cycles, 0)
	assert_eq(controller.required_cycles, 3)
	assert_eq(controller.construction_coord, Vector3i.ZERO)


func test_is_not_complete_initially() -> void:
	assert_false(controller.is_complete())
	assert_false(controller.is_building())


# --- Start construction ---


func test_start_construction() -> void:
	var ok: bool = controller.start_construction(Vector3i(1, -1, 0), 3)
	assert_true(ok)
	assert_eq(controller.state, ArtifactController.State.BUILDING)
	assert_eq(controller.construction_coord, Vector3i(1, -1, 0))
	assert_eq(controller.required_cycles, 3)
	assert_true(controller.is_building())


func test_start_when_already_building_returns_false() -> void:
	controller.start_construction(Vector3i(1, -1, 0), 3)
	assert_false(controller.start_construction(Vector3i(0, 1, -1), 2))


# --- Tick ---


func test_tick_increments_progress() -> void:
	controller.start_construction(Vector3i.ZERO, 3)
	var completed: bool = controller.tick()
	assert_false(completed)
	assert_eq(controller.get_progress(), 1)


func test_tick_completes_after_required_cycles() -> void:
	controller.start_construction(Vector3i.ZERO, 3)
	controller.tick()
	controller.tick()
	var completed: bool = controller.tick()
	assert_true(completed)
	assert_true(controller.is_complete())
	assert_eq(controller.state, ArtifactController.State.COMPLETE)


func test_tick_noop_when_idle() -> void:
	assert_false(controller.tick())
	assert_eq(controller.get_progress(), 0)


func test_tick_noop_when_complete() -> void:
	controller.start_construction(Vector3i.ZERO, 1)
	controller.tick()
	assert_true(controller.is_complete())
	assert_false(controller.tick())
	assert_eq(controller.get_progress(), 1)


# --- Fail ---


func test_fail_sets_state() -> void:
	controller.start_construction(Vector3i.ZERO, 3)
	controller.fail()
	assert_eq(controller.state, ArtifactController.State.FAILED)
	assert_false(controller.is_building())
	assert_false(controller.is_complete())


func test_fail_noop_when_idle() -> void:
	controller.fail()
	assert_eq(controller.state, ArtifactController.State.IDLE)


# --- Reset ---


func test_reset() -> void:
	controller.start_construction(Vector3i(1, -1, 0), 3)
	controller.tick()
	controller.reset()
	assert_eq(controller.state, ArtifactController.State.IDLE)
	assert_eq(controller.get_progress(), 0)
	assert_eq(controller.construction_coord, Vector3i.ZERO)
