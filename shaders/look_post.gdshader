shader_type canvas_item;
render_mode blend_mul, unshaded;
// Príncipe slice post (scripts/look_post.gd): gentle vignette and film grain,
// multiplied over the 3D image. Output stays in 0..1, so grain only darkens.
uniform float vignette = 0.22;
uniform float grain = 0.03;
uniform float grain_seed = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(1.0, 0.8);
	float v = 1.0 - vignette * smoothstep(0.30, 0.75, length(p));
	float n = hash(floor(FRAGCOORD.xy / 1.5) + vec2(grain_seed * 17.0, grain_seed * 31.0));
	COLOR = vec4(vec3(v * (1.0 - grain * n)), 1.0);
}
