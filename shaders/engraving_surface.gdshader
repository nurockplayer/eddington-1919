shader_type spatial;
render_mode ambient_light_disabled, specular_disabled, fog_disabled;

// Paper, timber, canvas and dense ink. Coordinates are in mesh-local metres.
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
	origin = VERTEX;
	axis = NORMAL;
}

float stroke(float phase, float duty, float viewport_height) {
	float pixel = max(length(vec2(dFdx(phase), dFdy(phase))), 0.0001);
	// At a four-pixel pitch (1080p equivalent) all contrast has become tone.
	float resolved = 1.0 - smoothstep(1.0 / 6.0, 1.0 / 4.0, pixel * viewport_height / 1080.0);
	float from_centre = abs(fract(phase + 0.5) - 0.5);
	float line = 1.0 - smoothstep(duty * 0.5 - pixel * 0.5, duty * 0.5 + pixel * 0.5, from_centre);
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
	if (swatch == 3) {
		float facing = abs(dot(normalize(NORMAL), VIEW));
		float rim = 1.0 - smoothstep(0.14, 0.31, facing);
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
		float first = stroke(across + 0.08 * sin(along * 0.8), 0.18, VIEWPORT_SIZE.y);
		float extra = 0.0;
		if (swatch != 0) {
			extra = stroke(along * 0.73 + across * 0.44, 0.22, VIEWPORT_SIZE.y);
		}
		middle = mix(stock, ink, 0.12 + 0.47 * first);
		shadow = mix(middle, ink, 0.21 + 0.49 * extra);
		if (swatch == 1) lit = mix(stock, ink, 0.23 * first);
	}
	EMISSION = shadow;
	to_middle = middle - shadow;
	to_light = lit - middle;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		float key = ATTENUATION * max(0.0, dot(NORMAL, LIGHT));
		DIFFUSE_LIGHT += to_middle * smoothstep(0.02, 0.31, key)
			+ to_light * smoothstep(0.22, 0.58, key);
	}
}
