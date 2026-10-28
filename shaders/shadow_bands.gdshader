shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Faint wavering bands on the ground; see scripts/shadow_bands.gd.
uniform vec2 band_dir = vec2(1.0, 0.0);
uniform float strength = 0.0;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	vec2 across = vec2(-band_dir.y, band_dir.x);
	float u = dot(local, band_dir);
	float v = dot(local, across);
	// Bands ~15 cm apart, slightly wavy, drifting ~2 m/s; two layers beat so
	// the pattern shimmers instead of scrolling.
	float w = sin(v * 0.9 + TIME * 0.7) * 0.35;
	float a = sin((u + w) * 40.0 - TIME * 13.0);
	float b = sin((u * 0.83 - w) * 47.0 - TIME * 10.0);
	float band = a * 0.6 + b * 0.4;
	float edge = 1.0 - smoothstep(9.0, 13.0, length(local));
	ALBEDO = band > 0.0 ? vec3(1.0, 0.95, 0.85) : vec3(0.0);
	ALPHA = abs(band) * 0.09 * strength * edge;
}
