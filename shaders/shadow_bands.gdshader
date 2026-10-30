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
	// Bands ~22 cm apart, slightly wavy, drifting ~2 m/s; two layers beat so
	// the pattern shimmers instead of scrolling.
	float w = sin(v * 0.9 + TIME * 0.7) * 0.35;
	float a = sin((u + w) * 28.0 - TIME * 9.0);
	float b = sin((u * 0.83 - w) * 33.0 - TIME * 7.0);
	float band = a * 0.6 + b * 0.4;
	float edge = 1.0 - smoothstep(9.0, 13.0, length(local));
	// Real bands are a few percent of contrast: a soft light/dark ripple, not
	// stripes. 0.16 with a hard white/black split read as zebra on the ground
	// (windowed look 2026-10-30 09:07 JST).
	ALBEDO = vec3(1.0, 0.95, 0.85) * (0.5 + 0.5 * band);
	ALPHA = 0.07 * strength * edge;
}
