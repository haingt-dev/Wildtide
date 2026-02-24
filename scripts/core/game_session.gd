class_name GameSession
extends Node3D
## Bootstrap script that wires all game systems together.
## Creates managers, injects dependencies, and starts the game loop.
## Attach to the root Node3D in game_session.tscn.

@export var map_radius: int = 9
@export var map_seed: int = -1
@export var scenario_id: StringName = &"the_wildtide"

var hex_grid: HexGrid
var economy_manager: EconomyManager
var edict_manager: EdictManager
var quest_manager: QuestManager
var building_manager: BuildingManager
var ruins_manager: RuinsManager
var wave_manager: WaveManager
var movement_manager: MovementManager
var stability_tracker: StabilityTracker
var utility_ai: UtilityAI
var ambient_threat_manager: AmbientThreatManager
var save_system: SaveSystem
var hud: GameHUD

var _rift_positions: Array[Vector3i] = []
var _scenario: ScenarioData


func _ready() -> void:
	load_scenario()
	create_hex_grid()
	create_managers()
	inject_dependencies()
	create_wave_intel()
	initialize_systems()
	setup_hud()
	setup_save_system()
	start_game()


# --- Bootstrap steps (public for testability) ---


## Step 1: Load scenario data from .tres.
func load_scenario() -> void:
	_scenario = ScenarioLoader.load_scenario(scenario_id)
	if _scenario:
		GameManager.scenario_id = scenario_id
		GameManager.scenario_data = _scenario


## Step 2: Generate hex grid and place rifts.
func create_hex_grid() -> void:
	var seed_val: int = map_seed
	if seed_val < 0:
		seed_val = randi()
	var generator := MapGenerator.new(seed_val)
	hex_grid = generator.generate(map_radius)
	_rift_positions = generator.get_rift_positions()
	_connect_renderer()
	EventBus.hex_grid_initialized.emit(hex_grid)


## Step 3: Instantiate all managers as child nodes.
func create_managers() -> void:
	economy_manager = EconomyManager.new()
	economy_manager.name = "EconomyManager"
	add_child(economy_manager)

	edict_manager = EdictManager.new()
	edict_manager.name = "EdictManager"
	add_child(edict_manager)

	quest_manager = QuestManager.new()
	quest_manager.name = "QuestManager"
	add_child(quest_manager)

	building_manager = BuildingManager.new()
	building_manager.name = "BuildingManager"
	add_child(building_manager)

	ruins_manager = RuinsManager.new()
	ruins_manager.name = "RuinsManager"
	add_child(ruins_manager)

	wave_manager = WaveManager.new()
	wave_manager.name = "WaveManager"
	add_child(wave_manager)

	movement_manager = MovementManager.new()
	movement_manager.name = "MovementManager"
	add_child(movement_manager)

	stability_tracker = StabilityTracker.new()
	stability_tracker.name = "StabilityTracker"
	add_child(stability_tracker)

	utility_ai = UtilityAI.new()
	utility_ai.name = "UtilityAI"
	add_child(utility_ai)

	ambient_threat_manager = AmbientThreatManager.new()
	ambient_threat_manager.name = "AmbientThreatManager"
	add_child(ambient_threat_manager)

	save_system = SaveSystem.new()
	save_system.name = "SaveSystem"
	add_child(save_system)


## Step 4: Inject cross-manager dependencies.
func inject_dependencies() -> void:
	# hex_grid on everyone who needs it
	building_manager.hex_grid = hex_grid
	wave_manager.hex_grid = hex_grid
	ruins_manager.hex_grid = hex_grid
	economy_manager.hex_grid = hex_grid
	movement_manager.hex_grid = hex_grid
	utility_ai.hex_grid = hex_grid

	# Rift positions
	wave_manager.rift_positions = _rift_positions

	# Cross-manager refs
	economy_manager.edict_manager = edict_manager
	edict_manager.quest_manager = quest_manager
	building_manager.economy_manager = economy_manager
	building_manager.movement_manager = movement_manager
	movement_manager.economy_manager = economy_manager
	movement_manager.building_manager = building_manager
	utility_ai.building_manager = building_manager
	utility_ai.economy_manager = economy_manager
	utility_ai.quest_manager = quest_manager
	utility_ai.movement_manager = movement_manager
	stability_tracker.economy_manager = economy_manager
	stability_tracker.wave_manager = wave_manager
	stability_tracker.quest_manager = quest_manager
	stability_tracker.edict_manager = edict_manager
	wave_manager.quest_manager = quest_manager
	wave_manager.edict_manager = edict_manager
	wave_manager.economy_manager = economy_manager
	ruins_manager.edict_manager = edict_manager
	movement_manager.edict_manager = edict_manager
	ambient_threat_manager.hex_grid = hex_grid
	ambient_threat_manager.building_manager = building_manager

	# GameManager refs for win condition checking
	GameManager.ruins_manager = ruins_manager
	GameManager.movement_manager = movement_manager
	GameManager.hex_grid = hex_grid


## Step 5: Create WaveIntel and inject into managers.
func create_wave_intel() -> void:
	var intel := WaveIntel.new(ruins_manager, quest_manager)
	quest_manager.wave_intel = intel
	wave_manager.wave_intel = intel


## Step 6: Initialize systems that need post-injection setup.
func initialize_systems() -> void:
	ruins_manager.initialize_ruins()
	if _scenario:
		ScenarioLoader.apply_scenario(_scenario, {"economy_manager": economy_manager})


## Step 7: Load HUD scene and inject manager refs.
func setup_hud() -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/game_hud.tscn")
	if not hud_scene:
		push_warning("GameSession: game_hud.tscn not found")
		return
	hud = hud_scene.instantiate() as GameHUD
	add_child(hud)
	hud.inject_managers(quest_manager, edict_manager, economy_manager)


## Step 8: Wire SaveSystem to all managers.
func setup_save_system() -> void:
	save_system.hex_grid = hex_grid
	save_system.wave_manager = wave_manager
	save_system.ruins_manager = ruins_manager
	save_system.building_manager = building_manager
	save_system.quest_manager = quest_manager
	save_system.economy_manager = economy_manager
	save_system.edict_manager = edict_manager
	save_system.stability_tracker = stability_tracker
	save_system.movement_manager = movement_manager


## Step 9: Start the game loop.
func start_game() -> void:
	GameManager.start_game()


# --- Helpers ---


func _connect_renderer() -> void:
	var renderer: HexGridRenderer = get_node_or_null("HexGridRenderer") as HexGridRenderer
	if renderer:
		renderer.hex_grid = hex_grid
