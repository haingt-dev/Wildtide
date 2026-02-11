shader_type spatial;

// Biome colors indexed by type: PLAINS=0, FOREST=1, ROCKY=2, SWAMP=3, RUINS=4.
// Biome index is encoded in INSTANCE_CUSTOM.r as float(biome) / 4.0.
uniform vec4 biome_colors[5] : source_color = {
	vec4(0.65, 0.78, 0.42, 1.0),  // Plains — yellow-green
	vec4(0.20, 0.55, 0.25, 1.0),  // Forest — dark green
	vec4(0.60, 0.55, 0.50, 1.0),  // Rocky  — gray-brown
	vec4(0.35, 0.45, 0.30, 1.0),  // Swamp  — murky green
	vec4(0.55, 0.50, 0.40, 1.0)   // Ruins  — sandy gray
};

void fragment() {
	int biome_index = int(INSTANCE_CUSTOM.r * 4.0 + 0.5);
	biome_index = clamp(biome_index, 0, 4);
	ALBEDO = biome_colors[biome_index].rgb;
}
