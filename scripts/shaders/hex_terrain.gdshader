shader_type spatial;

// Biome colors indexed by type: PLAINS=0, FOREST=1, ROCKY=2, SWAMP=3, RUINS=4.
// Biome index is encoded in INSTANCE_CUSTOM.r as float(biome) / 4.0.
// Colors set from GDScript (uniform arrays can't have default values).
uniform vec4 biome_colors[5] : source_color;

varying float biome_value;

void vertex() {
	// Read INSTANCE_CUSTOM in vertex shader and pass to fragment via varying.
	biome_value = INSTANCE_CUSTOM.r;
}

void fragment() {
	int biome_index = int(biome_value * 4.0 + 0.5);
	biome_index = clamp(biome_index, 0, 4);
	ALBEDO = biome_colors[biome_index].rgb;
}
