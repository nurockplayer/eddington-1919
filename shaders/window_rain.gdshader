shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Rain running down the study sash. Each streak slides RUN metres down from its
// rest point, fading in at the top and out at the bottom, then starts again.
// Per instance: INSTANCE_CUSTOM.x = phase (0..1), .y = runs per second.
uniform vec4 tint : source_color = vec4(0.53, 0.68, 0.78, 0.33);
uniform float run = 0.5;
varying float progress;

void vertex() {
	progress = fract(TIME * INSTANCE_CUSTOM.y + INSTANCE_CUSTOM.x);
	VERTEX.y -= progress * run;
}

void fragment() {
	ALBEDO = tint.rgb;
	ALPHA = tint.a * smoothstep(0.0, 0.08, progress) * (1.0 - smoothstep(0.75, 1.0, progress));
}
