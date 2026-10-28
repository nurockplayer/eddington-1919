shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// One pinhole image of the Sun on the ground; see scripts/sun_crescents.gd.
uniform vec4 ground_to_sun;      // row-major 2x2, per metre of gap height
uniform vec2 moon_c = vec2(2.1, 0.12);
uniform float brightness = 0.0;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	vec2 lp = vec2(dot(ground_to_sun.xy, local), dot(ground_to_sun.zw, local));
	// Frond gaps are not perfect pinholes: soft rims.
	float in_sun = 1.0 - smoothstep(0.8, 1.0, length(lp));
	float in_moon = 1.0 - smoothstep(0.95, 1.15, length(lp - moon_c));
	ALBEDO = vec3(1.0, 0.86, 0.62) * in_sun * (1.0 - in_moon) * brightness * 0.32;
}
