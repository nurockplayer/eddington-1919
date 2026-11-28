shader_type spatial;
render_mode unshaded, fog_disabled, skip_vertex_transform, cull_disabled;

uniform float age = 0.0;
varying flat float blink;
varying flat float tilt;

void vertex() {
	vec3 centre = MODELVIEW_MATRIX[3].xyz;
	float phase = INSTANCE_CUSTOM.x;
	if (age >= 0.0) {
		float drift = TAU * (age / 5.0 + phase);
		centre.x += 0.025 * sin(drift);
		centre.y += 0.025 * cos(drift);
	}
	blink = age < 0.0 ? 0.0 : fract(age / (2.0 + INSTANCE_CUSTOM.y) + phase);
	tilt = INSTANCE_CUSTOM.y < 0.5 ? -1.0 : 1.0;

	// Keep the whole stamp under seven pixels at 1080p, even at the near plane.
	float view_per_pixel = 2.0 * max(-centre.z, 0.0) / (VIEWPORT_SIZE.y * PROJECTION_MATRIX[1][1]);
	float scale = VIEWPORT_SIZE.y / 1080.0;
	float size = clamp(0.045, 2.7 * scale * view_per_pixel, 7.0 * scale * view_per_pixel);
	VERTEX = centre + vec3(VERTEX.xy * size, 0.0);
}

void fragment() {
	if (blink >= 0.44) {
		discard;
	}
	vec2 p = UV;
	p.y = (p.y - 0.5) * tilt + 0.5;
	bool paper = p.x >= 0.49 && p.x <= 0.85
		&& abs(p.y - 0.38 + 0.35 * (p.x - 0.65)) < 0.16;
	bool ink = p.x >= 0.06 && p.x <= 0.58
		&& abs(p.y - mix(0.78, 0.40, (p.x - 0.06) / 0.52)) < mix(0.045, 0.13, p.x);
	if (!paper && !ink) {
		discard;
	}
	ALBEDO = paper ? vec3(0.94, 0.85, 0.61) : vec3(0.018, 0.012, 0.009);
	ALPHA = 1.0;
}
