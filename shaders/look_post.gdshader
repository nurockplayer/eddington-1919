shader_type canvas_item;
render_mode blend_mul, unshaded;
// Príncipe slice post (scripts/look_post.gd): gentle vignette and film grain,
// multiplied over the 3D image. Output stays in 0..1, so grain only darkens.
uniform float vignette = 0.22;
uniform float grain = 0.03;
uniform float grain_seed = 0.0;
uniform float dust = 0.0;   // plate specks, fixed to the plate (silver plate style)
uniform float edge = 0.0;   // uneven darkening where the emulsion ends

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 0.8);
	float v = 1.0 - vignette * smoothstep(0.30, 0.75, length(p));
	float n = hash(floor(FRAGCOORD.xy / 1.5) + vec2(grain_seed * 17.0, grain_seed * 31.0));
	// Silver plate (scripts/styles/silver.gd); both are 0 for every other look.
	float e = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y) * 0.5625);
	float rag = 0.004 * (sin(UV.x * 37.0) * sin(UV.y * 23.0 + 1.7) + 1.0);
	float emulsion = smoothstep(0.0, 0.035, e + rag - 0.004);
	v *= mix(1.0, 0.35 + 0.65 * emulsion, edge);
	float speck = step(0.9994, hash(floor(FRAGCOORD.xy / 2.0) + vec2(3.0, 11.0)));
	v *= 1.0 - dust * 0.5 * speck;
	COLOR = vec4(vec3(v * (1.0 - grain * n)), 1.0);
}
