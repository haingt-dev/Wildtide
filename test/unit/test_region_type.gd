extends GutTest


func test_enum_values() -> void:
	assert_eq(RegionType.Type.STARTING, 0)
	assert_eq(RegionType.Type.MID, 1)
	assert_eq(RegionType.Type.LATE, 2)
	assert_eq(RegionType.Type.RIFT_CORE, 3)


func test_density_modifier_starting() -> void:
	assert_almost_eq(RegionType.get_density_modifier(RegionType.Type.STARTING), 0.8, 0.001)


func test_density_modifier_mid() -> void:
	assert_almost_eq(RegionType.get_density_modifier(RegionType.Type.MID), 1.0, 0.001)


func test_density_modifier_late() -> void:
	assert_almost_eq(RegionType.get_density_modifier(RegionType.Type.LATE), 1.5, 0.001)


func test_density_modifier_rift_core() -> void:
	assert_almost_eq(RegionType.get_density_modifier(RegionType.Type.RIFT_CORE), 2.0, 0.001)


func test_density_modifier_all_regions_covered() -> void:
	for region_type: int in RegionType.DENSITY_MODIFIERS:
		var modifier: float = RegionType.get_density_modifier(region_type as RegionType.Type)
		assert_gt(modifier, 0.0, "Region %d should have positive modifier" % region_type)
