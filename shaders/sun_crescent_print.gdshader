shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// One pinhole image of the Sun on the ground; see scripts/sun_crescents.gd.
uniform vec4 ground_to_sun;      // row-major 2x2, per metre of gap height
uniform vec2 moon_c = vec2(2.1, 0.12);
uniform float brightness = 0.0;
uniform vec4 print_paper : source_color = vec4(1.0, 0.86, 0.62, 1.0);
uniform vec4 print_ink : source_color = vec4(0.133, 0.110, 0.094, 1.0);
uniform bool print_enabled = false;
varying vec2 local;

void vertex() {
	local = VERTEX.xz;
}

void fragment() {
	vec2 lp = vec2(dot(ground_to_sun.xy, local), dot(ground_to_sun.zw, local));
	float sun_dist = length(lp) - 1.0;
	float px = max(length(vec2(dFdx(sun_dist), dFdy(sun_dist))), 0.00001);
	if (dot(moon_c, moon_c) < 4.0) {
		// Looking down along the Sun's azimuth reverses the pinhole's horizontal
		// axis. Print the cut on the sky's side so the two views read the same.
		float moon_dist = length(vec2(-lp.x, lp.y) - moon_c) - 1.0;
		// Subtract the covered part of a pixel. A rim around both edges
		// would swallow the paper when the crescent is barely a pixel wide.
		float sun_coverage = clamp(0.5 - sun_dist / px, 0.0, 1.0);
		float moon_coverage = clamp(0.5 - moon_dist / px, 0.0, 1.0);
		ALBEDO = print_paper.rgb;
		ALPHA = max(0.0, sun_coverage - moon_coverage) * brightness;
	} else {
		float coverage = 1.0 - smoothstep(-px * 0.5, px * 0.5, sun_dist);
		float rim = 1.0 - smoothstep(px * 0.45, px * 1.05, abs(sun_dist));
		ALBEDO = mix(print_paper.rgb, print_ink.rgb, rim);
		ALPHA = max(coverage, rim);
	}
}
