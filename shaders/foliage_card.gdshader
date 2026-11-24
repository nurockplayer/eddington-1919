shader_type spatial;
render_mode cull_disabled, fog_disabled;

uniform sampler2D tex_v1 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_v2 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_v3 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_custom_variant = false;
instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float pick = 0.0;
instance uniform bool print_card = true;
instance uniform float print_coverage = 1.0;
uniform float backlight = 0.3;
uniform float sway = 0.0;
varying flat float variant;

void vertex() {
	variant = use_custom_variant ? step(0.5, INSTANCE_CUSTOM.r) : pick;
	if (sway > 0.0) {
		vec3 w = MODEL_MATRIX[3].xyz;
		VERTEX.xz += sway * max(VERTEX.y, 0.0) * vec2(
			sin(TIME * 1.3 + w.x * 0.4 + w.z * 0.3),
			cos(TIME * 1.1 + w.z * 0.35));
	}
}

void fragment() {
	if (!print_card) {
		discard;
	}
	if (print_coverage < 1.0) {
		float grain = fract(52.9829189 * fract(dot(floor(FRAGCOORD.xy), vec2(0.06711056, 0.00583715))));
		if (grain >= print_coverage) {
			discard;
		}
	}
	vec4 c = variant > 1.5 ? texture(tex_v3, UV) : (variant > 0.5 ? texture(tex_v2, UV) : texture(tex_v1, UV));
	if (c.a < 0.5) {
		discard;
	}
	// Keep the painted leaf tone in the engraving's hatch range. Aerial fog
	// otherwise lifts the cutouts to bare paper before the distance ruling.
	ALBEDO = c.rgb * tint.rgb * 0.22;
	ROUGHNESS = 0.9;
	SPECULAR = 0.0;
	BACKLIGHT = vec3(0.0);
}
