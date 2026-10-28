shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Distant stars seen through the departure-night sash. Per instance:
// COLOR = tint and brightness, INSTANCE_CUSTOM.x = twinkle phase, .y = twinkle rate.
varying vec4 tint;
varying vec2 twinkle;

void vertex() {
	tint = COLOR;
	twinkle = INSTANCE_CUSTOM.xy;
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float core = exp(-r * r * 18.0);
	float glow = exp(-r * r * 4.0) * 0.25;
	float flicker = 0.72 + 0.28 * sin(TIME * twinkle.y + twinkle.x);
	ALBEDO = tint.rgb * (core + glow) * flicker * tint.a;
}
