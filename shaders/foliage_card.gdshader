shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex_v1 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_v2 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_custom_variant = false;
instance uniform vec4 tint : source_color = vec4(1.0);
uniform float backlight = 0.3;
uniform float sway = 0.0;
varying flat float variant;

void vertex() {
	variant = use_custom_variant && INSTANCE_CUSTOM.r > 0.5 ? 1.0 : 0.0;
	if (sway > 0.0) {
		vec3 w = MODEL_MATRIX[3].xyz;
		VERTEX.xz += sway * max(VERTEX.y, 0.0) * vec2(
			sin(TIME * 1.3 + w.x * 0.4 + w.z * 0.3),
			cos(TIME * 1.1 + w.z * 0.35));
	}
}

void fragment() {
	vec4 c = variant > 0.5 ? texture(tex_v2, UV) : texture(tex_v1, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	BACKLIGHT = ALBEDO * backlight;
}
