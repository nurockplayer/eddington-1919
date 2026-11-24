shader_type spatial;
render_mode ambient_light_disabled, specular_disabled, fog_disabled;

// Object-anchored ruling; ground and path share world coordinates.
uniform int swatch = 0;
uniform vec3 stock : source_color = vec3(0.937255, 0.901961, 0.823529);
uniform vec3 paper : source_color = vec3(0.937255, 0.901961, 0.823529);
uniform vec3 ink : source_color = vec3(0.133333, 0.109804, 0.094118);
uniform bool earth = false;

varying vec3 origin;
varying vec3 axis;
varying vec3 to_middle;
varying vec3 to_light;

void vertex() {
	origin = earth ? (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz : VERTEX;
	axis = NORMAL;
}

float line_mark(float phase, float along, float duty, float pixel) {
	float line_id = floor(phase + 0.5);
	float seed = fract(sin(line_id * 127.1) * 43758.5453);
	phase += 0.025 * sin(along * 0.17 + seed * 6.283185);
	float from_centre = abs(fract(phase + 0.5) - 0.5);
	return 1.0 - smoothstep(duty * 0.5 - pixel * 0.5, duty * 0.5 + pixel * 0.5, from_centre);
}

float stroke(float phase, float along, float duty, float viewport_height) {
	float pixel = max(length(vec2(dFdx(phase), dFdy(phase))), 0.0001);
	float pitch_px = 1080.0 / (pixel * viewport_height);
	// Blend anchored powers of two: visible near-camera pitches stay 6–16 px.
	float level = max(0.0, floor(log2(max(pitch_px / 8.0, 1.0))));
	float frequency = exp2(level);
	float blend = smoothstep(12.0, 16.0, pitch_px / frequency);
	float line = mix(line_mark(phase * frequency, along * frequency, duty, pixel * frequency),
		line_mark(phase * frequency * 2.0, along * frequency * 2.0, duty, pixel * frequency * 2.0), blend);
	float resolved = smoothstep(4.0, 6.0, pitch_px);
	return mix(duty, line, resolved);
}

void fragment() {
	// Tag this opaque print in the existing normal/roughness buffer (17/127).
	// The compositor uses its colour directly, adding the edge and paper grain.
	ROUGHNESS = 17.0 / 127.0;
	ALBEDO = vec3(1.0);
	vec3 n = normalize(axis);
	vec3 lit = stock;
	vec3 middle = stock;
	vec3 shadow = stock;
	if (swatch == 3 || swatch == 4) {
		float facing = abs(dot(normalize(NORMAL), VIEW));
		float rim = 1.0 - smoothstep(0.14, swatch == 4 ? 0.55 : 0.31, facing);
		float highlight = smoothstep(0.92, 0.99, facing);
		shadow = mix(ink, paper, rim);
		middle = shadow;
		lit = mix(shadow, paper, highlight);
	} else {
		vec2 across_along;
		float pitch;
		if (earth) {
			across_along = vec2(dot(origin.xz, vec2(0.94, 0.342)), origin.z);
			pitch = 0.20;
		} else if (swatch == 2) {
			across_along = origin.xz;
			pitch = 0.13;
		} else {
			float side = abs(n.x) > abs(n.z) ? origin.z : origin.x;
			across_along = abs(n.y) > 0.7 ? origin.zx : vec2(origin.y, side);
			pitch = swatch == 1 ? 0.026 : 0.045;
		}
		float across = across_along.x / pitch;
		float along = across_along.y / pitch;
		float first = stroke(across, along, 0.12, VIEWPORT_SIZE.y);
		float extra = 0.0;
		if (swatch == 1) {
			extra = stroke(across * 0.94 + along * 0.342, along, 0.10, VIEWPORT_SIZE.y);
		}
		middle = mix(stock, ink, 0.08 + 0.67 * first);
		shadow = mix(middle, ink, 0.52 + 0.22 * extra);
		if (swatch == 1) lit = mix(stock, ink, 0.18 * first);
	}
	EMISSION = shadow;
	to_middle = middle - shadow;
	to_light = lit - middle;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float key = ATTENUATION * max(0.0, dot(NORMAL, LIGHT));
		DIFFUSE_LIGHT += to_middle * smoothstep(0.01, 0.16, key)
			+ to_light * smoothstep(0.18, 0.44, key);
	}
}
