extends GutTest
## Tests for BuildingType, BuildingData, and BuildingRegistry.

var registry: BuildingRegistry


func before_each() -> void:
	registry = BuildingRegistry.new()


# --- BuildingData defaults ---


func test_building_data_defaults() -> void:
	var data := BuildingData.new()
	assert_eq(data.building_id, &"")
	assert_eq(data.building_type, BuildingType.Type.RESIDENTIAL)
	assert_eq(data.construction_duration, 2)


func test_building_data_metric_effects() -> void:
	var data := BuildingData.new()
	data.metric_effects = {&"pollution": 0.05}
	assert_almost_eq(data.metric_effects[&"pollution"] as float, 0.05, 0.001)


# --- BuildingRegistry loading ---


func test_registry_loads_all() -> void:
	assert_eq(registry.get_all().size(), 6)


func test_registry_lookup_homestead() -> void:
	var data: BuildingData = registry.get_data(&"homestead")
	assert_not_null(data)
	assert_eq(data.building_type, BuildingType.Type.RESIDENTIAL)
	assert_eq(data.display_name, "Homestead")
	assert_eq(data.construction_duration, 1)


func test_registry_lookup_reactor() -> void:
	var data: BuildingData = registry.get_data(&"reactor")
	assert_not_null(data)
	assert_eq(data.building_type, BuildingType.Type.SCIENCE)
	assert_almost_eq(data.alignment_push, 0.15, 0.001)
	assert_eq(data.construction_duration, 3)


func test_registry_lookup_shrine() -> void:
	var data: BuildingData = registry.get_data(&"shrine")
	assert_not_null(data)
	assert_eq(data.building_type, BuildingType.Type.MAGIC)
	assert_almost_eq(data.alignment_push, -0.15, 0.001)


func test_registry_lookup_watchtower() -> void:
	var data: BuildingData = registry.get_data(&"watchtower")
	assert_not_null(data)
	assert_eq(data.building_type, BuildingType.Type.DEFENSE)
	assert_eq(data.construction_duration, 1)


func test_registry_by_type_science() -> void:
	var science: Array[BuildingData] = registry.get_buildings_by_type(BuildingType.Type.SCIENCE)
	assert_eq(science.size(), 1)
	assert_eq(science[0].building_id, &"reactor")


func test_registry_by_type_residential() -> void:
	var res: Array[BuildingData] = registry.get_buildings_by_type(BuildingType.Type.RESIDENTIAL)
	assert_eq(res.size(), 1)
	assert_eq(res[0].building_id, &"homestead")


func test_registry_by_type_workshop() -> void:
	var ws: Array[BuildingData] = registry.get_buildings_by_type(BuildingType.Type.WORKSHOP)
	assert_eq(ws.size(), 1)
	assert_eq(ws[0].building_id, &"workshop")


func test_registry_unknown_returns_null() -> void:
	assert_null(registry.get_data(&"nonexistent"))


func test_biome_affinity_values() -> void:
	var reactor: BuildingData = registry.get_data(&"reactor")
	assert_eq(reactor.biome_affinity, BiomeType.Type.ROCKY)
	var shrine: BuildingData = registry.get_data(&"shrine")
	assert_eq(shrine.biome_affinity, BiomeType.Type.FOREST)
