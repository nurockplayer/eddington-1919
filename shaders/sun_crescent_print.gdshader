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
	float moon_dist = 1.0 - length(lp - moon_c);
	float dist = max(sun_dist, moon_dist);
	float px = max(length(vec2(dFdx(dist), dFdy(dist))), 0.00001);
	float coverage = 1.0 - smoothstep(-px * 0.5, px * 0.5, dist);
	float rim = 1.0 - smoothstep(px * 0.45, px * 1.05, abs(dist));
	ALBEDO = mix(print_paper.rgb, print_ink.rgb, rim);
	ALPHA = max(coverage, rim);
}
