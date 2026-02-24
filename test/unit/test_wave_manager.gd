extends GutTest
## Tests for WaveManager — wave damage simulation.
## Uses global EventBus and GameManager autoloads.

var wm: WaveManager
var grid: HexGrid


func before_each() -> void:
	wm = WaveManager.new()
	add_child(wm)
	# Create a small hex grid with known Rift positions.
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	wm.rift_positions = [Vector3i(4, -4, 0), Vector3i(-4, 0, 4), Vector3i(0, 4, -4)]


func after_each() -> void:
	wm.queue_free()
	_disconnect_all(EventBus.wave_started)
	_disconnect_all(EventBus.wave_ended)
	_disconnect_all(EventBus.hex_scarred)
	_disconnect_all(EventBus.wave_intel_updated)
	_disconnect_all(EventBus.summon_tide_completed)


func _disconnect_all(sig: Signal) -> void:
	for conn: Dictionary in sig.get_connections():
		sig.disconnect(conn["callable"])


# --- Phase triggers ---


func test_wave_triggers_on_wave_phase() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	GameManager.cycle_number = 1
	wm._on_phase_changed(CycleTimer.Phase.WAVE, &"wave")
	assert_eq(started.size(), 1)


func test_no_trigger_on_observe() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	wm._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_eq(started.size(), 0)


func test_no_trigger_on_influence() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	wm._on_phase_changed(CycleTimer.Phase.INFLUENCE, &"influence")
	assert_eq(started.size(), 0)


func test_no_trigger_on_evolve() -> void:
	var started := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	wm._on_phase_changed(CycleTimer.Phase.EVOLVE, &"evolve")
	assert_eq(started.size(), 0)


# --- Signals ---


func test_emits_wave_started_and_ended() -> void:
	var started := []
	var ended := []
	EventBus.wave_started.connect(func(c: int) -> void: started.append(c))
	EventBus.wave_ended.connect(func(c: int) -> void: ended.append(c))
	wm._run_wave(1)
	assert_eq(started, [1])
	assert_eq(ended, [1])


func test_emits_hex_scarred() -> void:
	var scarred := []
	EventBus.hex_scarred.connect(
		func(coord: Vector3i, amount: float) -> void: scarred.append([coord, amount])
	)
	wm._run_wave(1)
	assert_gt(scarred.size(), 0, "Should emit hex_scarred for damaged hexes")


# --- Damage ---


func test_applies_scar_damage_near_rifts() -> void:
	wm._run_wave(1)
	# Check a hex at a Rift position took damage.
	var rift := wm.rift_positions[0]
	var cell: HexCell = grid.get_cell(rift)
	if cell:
		assert_gt(cell.scar_state, 0.0, "Rift hex should be scarred")


func test_damage_falls_off_with_distance() -> void:
	wm._run_wave(1)
	var rift := wm.rift_positions[0]
	var rift_cell: HexCell = grid.get_cell(rift)
	if not rift_cell:
		pass_test("Rift coord outside grid")
		return
	# Find a neighbor 1 hex away.
	var neighbors := grid.get_neighbors_of(rift)
	if neighbors.is_empty():
		pass_test("No neighbors")
		return
	var near_cell: HexCell = neighbors[0]
	assert_gt(rift_cell.scar_state, near_cell.scar_state, "Closer = more damage")


func test_no_damage_beyond_radius() -> void:
	wm._run_wave(1)
	# Center hex (0,0,0) is far from all Rifts (dist=4), radius=3.
	var center: HexCell = grid.get_cell(Vector3i.ZERO)
	assert_almost_eq(center.scar_state, 0.0, 0.001, "Center should be undamaged")


func test_wave_power_scales_with_era() -> void:
	wm._run_wave(1)
	var power_era1: float = wm.get_last_wave_power()
	# Reset grid for clean second run.
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	wm._run_wave(6)
	var power_era2: float = wm.get_last_wave_power()
	assert_gt(power_era2, power_era1, "Era 2 should have higher power")


func test_total_damage_tracked() -> void:
	wm._run_wave(1)
	assert_gt(wm.get_last_total_damage(), 0.0, "Should track total damage")


# --- Edge cases ---


func test_no_crash_without_grid() -> void:
	wm.hex_grid = null
	wm._run_wave(1)
	assert_almost_eq(wm.get_last_wave_power(), 0.0, 0.001)


func test_no_crash_without_rifts() -> void:
	wm.rift_positions = []
	wm._run_wave(1)
	assert_almost_eq(wm.get_last_total_damage(), 0.0, 0.001)


# --- Offensive quest effects ---


func test_power_multiplier_reduces_damage() -> void:
	wm._run_wave(1)
	var damage_normal: float = wm.get_last_total_damage()
	# Reset grid.
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	# Set up a mock quest_manager with power_multiplier effect.
	var qmgr := QuestManager.new()
	add_child(qmgr)
	var qdata := QuestData.new()
	qdata.quest_id = &"wall_ambush"
	qdata.faction_id = &"wall"
	qdata.duration = 1
	qdata.is_offensive = true
	qdata.offensive_effect_key = &"power_multiplier"
	qdata.offensive_effect_value = 0.8
	qmgr._offensive_quests[&"wall_ambush"] = ActiveQuest.new(qdata)
	wm.quest_manager = qmgr
	wm._run_wave(1)
	assert_lt(wm.get_last_total_damage(), damage_normal, "Power mult should reduce damage")
	qmgr.queue_free()


func test_defense_bonus_reduces_damage() -> void:
	wm._run_wave(1)
	var damage_normal: float = wm.get_last_total_damage()
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	var qmgr := QuestManager.new()
	add_child(qmgr)
	var qdata := QuestData.new()
	qdata.quest_id = &"coin_mercenary"
	qdata.faction_id = &"coin"
	qdata.duration = 1
	qdata.is_offensive = true
	qdata.offensive_effect_key = &"defense_bonus"
	qdata.offensive_effect_value = 0.25
	qmgr._offensive_quests[&"coin_mercenary"] = ActiveQuest.new(qdata)
	wm.quest_manager = qmgr
	wm._run_wave(1)
	assert_lt(wm.get_last_total_damage(), damage_normal, "Defense bonus should reduce damage")
	qmgr.queue_free()


func test_no_offensive_effects_without_quest_manager() -> void:
	wm.quest_manager = null
	wm._run_wave(1)
	assert_gt(wm.get_last_total_damage(), 0.0, "Should still run without quest_manager")


func test_full_intel_adds_defense_bonus() -> void:
	# Run baseline.
	wm._run_wave(1)
	var damage_blind: float = wm.get_last_total_damage()
	# Reset grid.
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	# Set _last_intel_level to FULL.
	wm._last_intel_level = WaveIntel.Level.FULL
	wm._run_wave(1)
	assert_lt(wm.get_last_total_damage(), damage_blind, "Full intel should reduce damage")


func test_edict_defense_modifier_reduces_damage() -> void:
	wm._run_wave(1)
	var damage_base: float = wm.get_last_total_damage()
	grid = HexGrid.new()
	grid.initialize_hex_map(5)
	wm.hex_grid = grid
	var em := EdictManager.new()
	add_child(em)
	var edata := EdictData.new()
	edata.edict_id = &"fortify"
	edata.economy_effects = {&"defense": 0.2}
	edata.duration = -1
	em.edict_registry._data[&"fortify"] = edata
	em.enact_edict(&"fortify")
	wm.edict_manager = em
	wm._run_wave(1)
	assert_lt(wm.get_last_total_damage(), damage_base, "Edict defense should reduce damage")
	em.queue_free()


func test_intel_updated_on_observe_phase() -> void:
	var received: Array = []
	EventBus.wave_intel_updated.connect(
		func(level: int, report: Dictionary) -> void: received.append([level, report])
	)
	GameManager.cycle_number = 1
	wm._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	assert_eq(received.size(), 1)
	assert_eq(received[0][0], 0, "Should be BLIND without wave_intel")


# --- Summon the Tide ---


func test_summon_the_tide_returns_shards() -> void:
	GameManager.cycle_number = 1
	var reward: int = wm.summon_the_tide()
	assert_gt(reward, 0, "Should return shard reward")


func test_summon_the_tide_max_once_per_cycle() -> void:
	GameManager.cycle_number = 1
	wm.summon_the_tide()
	var second: int = wm.summon_the_tide()
	assert_eq(second, 0, "Should not allow second summon")


func test_summon_resets_on_observe() -> void:
	GameManager.cycle_number = 1
	wm.summon_the_tide()
	wm._on_phase_changed(CycleTimer.Phase.OBSERVE, &"observe")
	var reward: int = wm.summon_the_tide()
	assert_gt(reward, 0, "Should allow summon after observe reset")


func test_summon_costs_resources() -> void:
	var eco := EconomyManager.new()
	add_child(eco)
	wm.economy_manager = eco
	GameManager.cycle_number = 1
	var gold_before: int = eco.get_gold()
	wm.summon_the_tide()
	assert_lt(eco.get_gold(), gold_before, "Should spend gold")
	eco.queue_free()


func test_summon_emits_signal() -> void:
	var received := []
	EventBus.summon_tide_completed.connect(func(r: int) -> void: received.append(r))
	GameManager.cycle_number = 1
	wm.summon_the_tide()
	assert_eq(received.size(), 1)
	_disconnect_all(EventBus.summon_tide_completed)
