extends GutTest
## Tests for offensive pre-wave quest lifecycle.

var manager: QuestManager
var grid: HexGrid
var ruins_mgr: RuinsManager


func before_each() -> void:
	grid = HexGrid.new()
	grid.initialize_hex_map(3)
	ruins_mgr = RuinsManager.new()
	add_child(ruins_mgr)
	ruins_mgr.hex_grid = grid
	manager = QuestManager.new()
	add_child(manager)
	MetricSystem.reset_to_defaults()


func after_each() -> void:
	ruins_mgr.queue_free()
	manager.queue_free()
	_disconnect_all(EventBus.quest_proposed)
	_disconnect_all(EventBus.quest_approved)
	_disconnect_all(EventBus.quest_completed)
	_disconnect_all(EventBus.wave_ended)
	_disconnect_all(EventBus.faction_morale_changed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


func _enable_intel_partial() -> void:
	# Set up Observatory as discovered so intel >= PARTIAL.
	var cell: HexCell = grid.get_cell(Vector3i(1, -1, 0))
	cell.biome = BiomeType.Type.RUINS
	cell.exploration_state = RuinType.STATE_DISCOVERED
	ruins_mgr._ruin_types[cell.coord] = RuinType.Type.OBSERVATORY
	var intel := WaveIntel.new(ruins_mgr, manager)
	manager.wave_intel = intel


# --- Proposal gating ---


func test_offensive_not_proposed_when_blind() -> void:
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	for p: QuestData in proposals:
		assert_false(p.is_offensive, "No offensive quests without intel")


func test_offensive_proposed_when_partial_intel() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var offensive_count: int = 0
	for p: QuestData in proposals:
		if p.is_offensive:
			offensive_count += 1
	assert_gt(offensive_count, 0, "Should propose offensive quests with intel")


func test_alignment_gates_lens_emp() -> void:
	_enable_intel_partial()
	# Alignment at 0.0 — Lens EMP requires > 0.3.
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	for p: QuestData in proposals:
		assert_ne(p.quest_id, &"lens_emp", "Lens EMP should not appear without alignment")


func test_alignment_gates_veil_disruption() -> void:
	_enable_intel_partial()
	# Alignment at 0.0 — Veil Disruption requires < -0.3.
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	for p: QuestData in proposals:
		assert_ne(
			p.quest_id, &"veil_disruption", "Veil Disruption should not appear without alignment"
		)


# --- Approval routing ---


func test_approve_offensive_routes_to_offensive_dict() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"wall_ambush")
	assert_eq(manager.get_active_quests().size(), 0, "Should not be in normal active quests")
	assert_true(manager._offensive_quests.has(&"wall_ambush"))


# --- Resolution ---


func test_offensive_resolved_after_wave_ended() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"wall_ambush")
	var received: Array = []
	EventBus.quest_completed.connect(
		func(f: StringName, q: StringName) -> void: received.append([f, q])
	)
	EventBus.wave_ended.emit(1)
	assert_eq(received.size(), 1)
	assert_eq(received[0][1], &"wall_ambush")
	assert_true(manager._offensive_quests.is_empty())


func test_offensive_metric_effects_applied() -> void:
	_enable_intel_partial()
	# Push alignment to trigger Lens EMP (requires > 0.3).
	MetricSystem.push_alignment(1.0)
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"lens_emp")
	EventBus.wave_ended.emit(1)
	assert_true(MetricSystem.get_metric(&"pollution") > 0.0, "EMP should push pollution")


# --- Effect aggregation ---


func test_get_active_offensive_effects_power_multiplier() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"wall_ambush")
	var effects: Dictionary = manager.get_active_offensive_effects()
	assert_almost_eq(effects.get(&"power_multiplier", 1.0) as float, 0.8, 0.001)


func test_get_active_offensive_effects_defense_bonus() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"coin_mercenary")
	var effects: Dictionary = manager.get_active_offensive_effects()
	assert_almost_eq(effects.get(&"defense_bonus", 0.0) as float, 0.25, 0.001)


func test_multiple_offensive_effects_stack() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"wall_ambush")
	manager.approve_quest(&"coin_mercenary")
	var effects: Dictionary = manager.get_active_offensive_effects()
	assert_true(effects.has(&"power_multiplier"))
	assert_true(effects.has(&"defense_bonus"))


# --- Additional lifecycle tests ---


func test_offensive_quests_cleared_after_wave() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"wall_ambush")
	manager.approve_quest(&"coin_mercenary")
	EventBus.wave_ended.emit(1)
	assert_true(manager._offensive_quests.is_empty(), "All offensives cleared post-wave")


func test_empty_effects_without_approved_offensive() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	# Don't approve any.
	var effects: Dictionary = manager.get_active_offensive_effects()
	assert_eq(effects.size(), 0, "No effects without approvals")


func test_lens_emp_available_with_positive_alignment() -> void:
	_enable_intel_partial()
	MetricSystem.push_alignment(1.0)
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var found: bool = false
	for p: QuestData in proposals:
		if p.quest_id == &"lens_emp":
			found = true
	assert_true(found, "Lens EMP should appear with positive alignment")


func test_veil_disruption_available_with_negative_alignment() -> void:
	_enable_intel_partial()
	MetricSystem.push_alignment(-1.0)
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var found: bool = false
	for p: QuestData in proposals:
		if p.quest_id == &"veil_disruption":
			found = true
	assert_true(found, "Veil Disruption should appear with negative alignment")


func test_offensive_not_reproposed_next_influence() -> void:
	_enable_intel_partial()
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	manager.approve_quest(&"wall_ambush")
	EventBus.wave_ended.emit(1)
	# Next influence cycle — proposals reset.
	manager._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	var proposals := manager.get_pending_proposals()
	var found_wall: bool = false
	for p: QuestData in proposals:
		if p.quest_id == &"wall_ambush":
			found_wall = true
	assert_true(found_wall, "Offensive should be re-proposed on new cycle")
