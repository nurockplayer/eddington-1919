shader_type spatial;
render_mode cull_disabled;

uniform sampler2D tex_v1 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_v2 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_v3 : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool use_custom_variant = false;
instance uniform vec4 tint : source_color = vec4(1.0);
instance uniform float pick = 0.0;
uniform float backlight = 0.3;
uniform float sway = 0.0;
uniform float flatten = 0.0;   // poster style: 1 = the cut-out's broad colour only, no brushwork
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
	vec4 c = variant > 1.5 ? texture(tex_v3, UV) : (variant > 0.5 ? texture(tex_v2, UV) : texture(tex_v1, UV));
	vec3 broad = variant > 1.5 ? textureLod(tex_v3, UV, 5.0).rgb : (variant > 0.5 ? textureLod(tex_v2, UV, 5.0).rgb : textureLod(tex_v1, UV, 5.0).rgb);
	c.rgb = mix(c.rgb, broad, flatten);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 0.9;
	SPECULAR = 0.2;
	BACKLIGHT = ALBEDO * backlight;
}
