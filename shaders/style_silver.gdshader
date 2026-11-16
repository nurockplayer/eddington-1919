shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
// Style audition: silver plate (scripts/styles/silver.gd). A full-screen pass:
// the lit frame through a plate's eyes. One channel mix makes the silver image,
// the lens is soft and loses the distance. The result stays HDR: the
// Environment's glow turns its highlights into halation, its colour correction
// tones the print, and scripts/look_post.gd adds grain and the plate's edge.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;

uniform float darkness = 0.0;        // 0 day … 1 totality
uniform float night = 0.0;

uniform float resp_r = 0.75;         // the plate's response: a channel mix, may be negative
uniform float resp_g = 0.40;
uniform float resp_b = -0.15;
uniform float gain = 1.0;            // exposure of the plate
uniform float totality_gain = 2.5;   // a longer exposure at totality
uniform float night_gain = 1.0;
uniform float black = 0.0;           // base fog of the plate, added before the tone curve
uniform float soft = 0.22;           // share of the blurred image everywhere (soft focus)
uniform float soft_lod = 3.0;        // mip level of the blurred image
uniform float focus_far = 22.0;      // metres where the lens starts to lose things
uniform float far_soft = 0.35;       // extra share of blur at four times that distance
uniform float tint = 0.0;            // 0 silver only … 1 hand-tinted with the scene's hue

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float raw = texture(depth_tex, uv).r;
	vec4 p4 = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, max(raw, 0.00001), 1.0);
	float z = raw < 0.00001 ? 4000.0 : -p4.z / p4.w;
	vec3 sharp = textureLod(screen_tex, uv, 0.0).rgb;
	vec3 blur = textureLod(screen_tex, uv, soft_lod).rgb;
	// The eclipsed sky stays sharper: its stars are the evidence.
	float s = soft + far_soft * smoothstep(focus_far, focus_far * 4.0, z);
	s = clamp(s * mix(1.0, 0.35, darkness), 0.0, 1.0);
	vec3 c = mix(sharp, blur, s);
	float ex = gain * mix(1.0, totality_gain, darkness) * mix(1.0, night_gain, night);
	float m = max(dot(c, vec3(resp_r, resp_g, resp_b)), 0.0) * ex + black;
	// Hand tinting: a thin dye of the scene's own hue over the silver image.
	vec3 hue = c / max(max(c.r, max(c.g, c.b)), 0.0001);
	hue /= max(dot(hue, vec3(0.2126, 0.7152, 0.0722)), 0.25);
	ALBEDO = m * mix(vec3(1.0), hue, tint);
}
