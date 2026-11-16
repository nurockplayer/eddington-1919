# Brief sa-engraving: the engraving look (style audition)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/sa-engraving`, branch `art/sa-engraving` (created from `art/style-audition` 8f09a21, after the plumbing task: `scripts/style.gd`, `tests/test_style.gd` and the stub `scripts/styles/engraving.gd` exist). Godot 4.7.2 Forward+ (MSAA 4× on), GDScript (tabs), Godot shading language.

## Goal

One of three looks for a style audition (`docs/design/SLICE_PRINCIPE.md`, top section): the game drawn as a period line engraving. Black ink on cream paper, tone carried by hatching whose lines sit **on the surfaces in world space** (so they do not swim when the camera moves), ink outlines, a ruled sky, and at totality the corona drawn as rays. It is one full-screen pass plus environment settings, switched on by `--style=engraving`. The art director wrote the shader and the script below and will tune them in a windowed session; your job is to install them, make them compile and run, and test what can be tested without a renderer.

You touch only: `shaders/style_engraving.gdshader` (new), `scripts/styles/engraving.gd` (replace the stub), `tests/test_style_engraving.gd` (new). Nothing else.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot bare: every run goes through `orb-test --host -- <command>` (one headless run at a time). **No windowed Godot runs at all.** No full-suite runs: only the tests named below.
- First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang).
- Before any `--script` test run, parse what you edited: `orb-test --host -- godot --headless --path . --check-only --script <file.gd>`; a script error in a `--script` run hangs instead of failing.
- Do not sleep or poll. Leave nothing behind (no scratch files).
- Every time you write down carries its zone (`2026-11-16 18:30 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`. Commit to `art/sa-engraving` and `git push -u origin art/sa-engraving`. No PR.

## The shader cannot be compiled here: read it as the compiler would

Headless Godot uses a dummy renderer that never compiles shaders, so a syntax or type error in the `.gdshader` shows up only in the art director's windowed session, where it costs render time. After installing the file, go through it line by line against the Godot 4.7 shading language and fix what would not compile, without changing what it computes. Check in particular: no implicit `int`→`float` conversion (every literal in float maths has a decimal point); built-ins (`SCREEN_UV`, `FRAGCOORD`, `VIEWPORT_SIZE`, `PROJECTION_MATRIX`, `INV_PROJECTION_MATRIX`, `VIEW_MATRIX`, `INV_VIEW_MATRIX`) are used only inside `fragment()` and passed to helper functions as arguments; every variable is declared before use and not redeclared in the same scope; ternaries have matching types on both sides; the render modes and uniform hints exist in 4.7 for `shader_type spatial`; a full-screen quad is written `POSITION = vec4(VERTEX.xy, 1.0, 1.0);` (reversed Z, Godot ≥ 4.3); in Forward+ the depth texture is 1 at the near plane and 0 at the far plane, and NDC is `vec3(SCREEN_UV * 2.0 - 1.0, depth)`. List in your report every line you changed and why. If the normal-roughness texture needs a different decode in 4.7 than `xyz * 2.0 - 1.0` (view space), say so with the source you checked (Godot docs or engine source), and fix it.

## 1. `shaders/style_engraving.gdshader`

```glsl
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
// Style audition: engraving (scripts/styles/engraving.gd). A full-screen pass:
// the lit frame becomes a tone, the tone becomes hatching. Line families are
// planes in world space cut by the surface, so lines stay on the surfaces; the
// spacing follows the pixel footprint in octaves, each second line tapering out.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, repeat_disable, filter_nearest;

uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);   // world, toward the Sun
uniform float sun_r = 0.02;                    // the Sun's angular radius in radians
uniform float darkness = 0.0;                  // 0 day … 1 totality
uniform float night = 0.0;

uniform vec3 paper : source_color = vec3(0.937, 0.902, 0.824);
uniform vec3 ink_col : source_color = vec3(0.133, 0.110, 0.094);

uniform float exposure = 2.2;
uniform float totality_gain = 14.0;   // exposure multiplier at totality
uniform float night_gain = 6.0;
uniform float resp_r = 0.60;          // channel mix of the tone (a "plate response")
uniform float resp_g = 0.55;
uniform float resp_b = -0.15;
uniform float tone_lo = 0.10;         // display tone that prints solid
uniform float tone_hi = 0.80;         // display tone that stays bare paper
uniform float sky_ink = 0.80;         // the sky never prints darker than this share
uniform float line_px = 5.0;          // line spacing in pixels
uniform float ray_px = 5.0;           // corona ray spacing in pixels
uniform float ray_inner = 3.0;        // rays hold to this many solar radii …
uniform float ray_outer = 8.0;        // … and hand over to the ruling by this many
uniform float cross_at = 0.34;        // darkness of tone where the second family starts
uniform float third_at = 0.62;
uniform float solid_lo = 0.92;
uniform float solid_hi = 0.99;
uniform float flat_at = 0.92;         // |normal.y| above this is hatched in plan
uniform float outline = 1.0;
uniform float outline_px = 1.3;
uniform float edge_depth = 0.02;
uniform float edge_normal = 0.18;
uniform float far_outline = 0.35;     // outline strength beyond 45 m
uniform float wobble = 1.0;           // hand wobble of the lines
uniform float wash = 0.0;             // 0 ink only … 1 hand-coloured
uniform float paper_grain = 0.05;
uniform float ink_strength = 0.94;
uniform float normal_from_depth = 0.0; // 1: normals from depth derivatives instead of the buffer

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Coverage of one line of half-width h at distance d from its centre, for a
// pixel footprint aa (all in line-coordinate units). Hairlines fade, never alias.
float line_cov(float d, float h, float aa) {
	return clamp((h - d) / (2.0 * aa) + 0.5, 0.0, 1.0) * clamp(h / aa, 0.0, 1.0);
}

// One family of parallel lines. u: line coordinate. g: |du| per pixel.
// cover: share of ink wanted, 0..1. px: spacing in pixels. max_lod: cap on
// log2(spacing) for periodic coordinates (99.0 for none).
float hatch(float u, float g, float cover, float px, float max_lod) {
	float lod = min(log2(max(g, 0.0000001) * px), max_lod + 0.999);
	float s0 = exp2(floor(lod));
	float f = lod - floor(lod);
	float w_odd = 1.0 - smoothstep(0.15, 0.85, f);   // every second line tapers out toward the next octave
	float v = u / (2.0 * s0);
	float aa = 0.6 * g / (2.0 * s0);
	float h_even = 0.5 * cover / (1.0 + w_odd);
	float h_odd = h_even * w_odd;
	float d_even = abs(fract(v + 0.5) - 0.5);
	float d_odd = abs(fract(v) - 0.5);
	return max(line_cov(d_even, h_even, aa), line_cov(d_odd, h_odd, aa));
}

// |d(dot(P, a))| per pixel on the surface through the view-space point z * q
// (q.z = -1) with view-space normal n. k: view units per pixel at depth 1.
float grad_px(vec3 a_v, vec3 n_v, vec3 q, float z, float k) {
	float nq = dot(n_v, q);
	nq = (nq < 0.0 ? -1.0 : 1.0) * max(abs(nq), 0.06);
	float aq = dot(a_v, q);
	vec2 d = vec2(a_v.x - aq * n_v.x / nq, a_v.y - aq * n_v.y / nq);
	return z * k * length(d);
}

vec3 view_pos(sampler2D depth, vec2 uv, mat4 inv_proj) {
	float raw = texture(depth, uv).r;
	if (raw < 0.00001) {
		// Sky: a point far along the ray, so differences against it read as an edge.
		vec4 far4 = inv_proj * vec4(uv * 2.0 - 1.0, 0.5, 1.0);
		return normalize(far4.xyz / far4.w) * 4000.0;
	}
	vec4 p = inv_proj * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return p.xyz / p.w;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	float raw = texture(depth_tex, uv).r;
	bool sky = raw < 0.00001;
	vec3 pv = view_pos(depth_tex, uv, INV_PROJECTION_MATRIX);
	float z = max(-pv.z, 0.01);
	vec3 ray_v = normalize(pv);
	vec3 ray_w = normalize((INV_VIEW_MATRIX * vec4(ray_v, 0.0)).xyz);
	float k = 2.0 / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);

	// Tone: 1 = bare paper, 0 = solid ink.
	float ex = exposure * mix(1.0, totality_gain, darkness) * mix(1.0, night_gain, night);
	float lum = max(dot(c, vec3(resp_r, resp_g, resp_b)), 0.0) * ex;
	float tone = pow(lum / (1.0 + lum), 0.4545);
	tone = clamp((tone - tone_lo) / max(tone_hi - tone_lo, 0.001), 0.0, 1.0);
	float dark = 1.0 - tone;

	// Outlines: second difference of depth (zero on any flat surface) and normal breaks.
	vec2 o = outline_px / VIEWPORT_SIZE;
	vec3 p_l = view_pos(depth_tex, uv - vec2(o.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 p_r = view_pos(depth_tex, uv + vec2(o.x, 0.0), INV_PROJECTION_MATRIX);
	vec3 p_d = view_pos(depth_tex, uv - vec2(0.0, o.y), INV_PROJECTION_MATRIX);
	vec3 p_u = view_pos(depth_tex, uv + vec2(0.0, o.y), INV_PROJECTION_MATRIX);
	float lap = abs(p_l.z + p_r.z - 2.0 * pv.z) + abs(p_d.z + p_u.z - 2.0 * pv.z);
	float edge = smoothstep(edge_depth, edge_depth * 2.5, lap / z);

	vec3 n_v = vec3(0.0, 0.0, 1.0);
	float ink = 0.0;
	if (sky) {
		dark *= sky_ink;
		// Ruling: lines of equal altitude, crossed by a tilted family where the sky is dark.
		float elev = asin(clamp(ray_w.y, -1.0, 1.0));
		float i1 = hatch(elev, k, clamp((dark - 0.06) * 1.7, 0.0, 0.55), line_px, 99.0);
		float tilt = asin(clamp(dot(ray_w, normalize(vec3(0.62, 0.48, 0.62))), -1.0, 1.0));
		float i2 = hatch(tilt, k, clamp((dark - cross_at) * 1.6, 0.0, 0.55), line_px, 99.0);
		ink = 1.0 - (1.0 - i1) * (1.0 - i2);
		// Corona: near the eclipsed Sun the ruling gives way to rays about its centre.
		vec3 t1 = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
		vec3 t2 = cross(t1, sun_dir);
		vec2 lp = vec2(dot(ray_w, t1), dot(ray_w, t2)) / sun_r;   // in solar radii
		float r = length(lp);
		float front = step(0.0, dot(ray_w, sun_dir));
		float w_rays = darkness * darkness * front * (1.0 - smoothstep(ray_inner, ray_outer, r));
		if (w_rays > 0.0) {
			float ang = atan(lp.y, lp.x) / 6.2831853;             // -0.5 … 0.5, periodic
			float g_ang = k / (6.2831853 * max(r * sun_r, 0.0001));
			float rays = hatch(ang, g_ang, clamp((dark - 0.04) * 1.5, 0.0, 0.8), ray_px, -3.0);
			rays = max(rays, 1.0 - smoothstep(0.96, 1.0, r));     // the Moon's disc prints solid
			ink = mix(ink, rays, w_rays);
		}
	} else {
		vec3 q = pv / z;
		vec3 n_buf = normalize(texture(normal_tex, uv).xyz * 2.0 - 1.0);
		vec3 n_dep = normalize(cross(dFdx(pv), dFdy(pv)));
		n_dep = dot(n_dep, pv) > 0.0 ? -n_dep : n_dep;
		n_v = normal_from_depth > 0.5 ? n_dep : n_buf;
		vec3 n_w = normalize((INV_VIEW_MATRIX * vec4(n_v, 0.0)).xyz);
		vec3 pw = (INV_VIEW_MATRIX * vec4(pv, 1.0)).xyz;

		if (normal_from_depth < 0.5) {
			vec3 n_l = normalize(texture(normal_tex, uv - vec2(o.x, 0.0)).xyz * 2.0 - 1.0);
			vec3 n_r = normalize(texture(normal_tex, uv + vec2(o.x, 0.0)).xyz * 2.0 - 1.0);
			vec3 n_d = normalize(texture(normal_tex, uv - vec2(0.0, o.y)).xyz * 2.0 - 1.0);
			vec3 n_u = normalize(texture(normal_tex, uv + vec2(0.0, o.y)).xyz * 2.0 - 1.0);
			float n_break = 1.0 - min(min(dot(n_v, n_l), dot(n_v, n_r)), min(dot(n_v, n_d), dot(n_v, n_u)));
			edge = max(edge, smoothstep(edge_normal, edge_normal * 2.0, n_break));
		}

		// Three line families per surface. Flat surfaces are hatched in plan; all
		// others carry level lines (constant height) crossed by two diagonals.
		vec3 a1;
		vec3 a2;
		vec3 a3;
		if (abs(n_w.y) > flat_at) {
			a1 = vec3(0.940, 0.0, 0.342);
			a2 = vec3(0.087, 0.0, 0.996);
			a3 = vec3(0.766, 0.0, -0.643);
		} else {
			vec3 t_h = abs(n_w.x) > abs(n_w.z) ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
			a1 = vec3(0.0, 1.0, 0.0);
			a2 = normalize(vec3(0.0, 0.8, 0.0) + t_h * 0.6);
			a3 = normalize(vec3(0.0, 0.8, 0.0) - t_h * 0.6);
		}
		float wob = (vnoise(pw.xz * 1.7 + vec2(pw.y * 0.9)) - 0.5) * 0.04 * wobble;
		float weight = 1.0 + (vnoise(pw.xz * 0.8 + vec2(pw.y * 1.3)) - 0.5) * 0.3 * wobble;
		vec3 a1_v = (VIEW_MATRIX * vec4(a1, 0.0)).xyz;
		vec3 a2_v = (VIEW_MATRIX * vec4(a2, 0.0)).xyz;
		vec3 a3_v = (VIEW_MATRIX * vec4(a3, 0.0)).xyz;
		float i1 = hatch(dot(pw, a1) + wob, grad_px(a1_v, n_v, q, z, k), clamp((dark - 0.06) * 1.7, 0.0, 0.55) * weight, line_px, 99.0);
		float i2 = hatch(dot(pw, a2) + wob, grad_px(a2_v, n_v, q, z, k), clamp((dark - cross_at) * 1.6, 0.0, 0.55) * weight, line_px, 99.0);
		float i3 = hatch(dot(pw, a3) - wob, grad_px(a3_v, n_v, q, z, k), clamp((dark - third_at) * 2.2, 0.0, 0.60) * weight, line_px, 99.0);
		ink = 1.0 - (1.0 - i1) * (1.0 - i2) * (1.0 - i3);
		ink = max(ink, smoothstep(solid_lo, solid_hi, dark));
		edge *= mix(1.0, far_outline, smoothstep(10.0, 45.0, z));
	}
	ink = max(ink, edge * outline);

	// Paper: fibre grain fixed to the page; an optional thin wash of the scene's hue.
	vec2 fp = FRAGCOORD.xy;
	float fibre = vnoise(fp * 0.35) * 0.6 + vnoise(fp * vec2(0.05, 0.9)) * 0.4;
	vec3 hue = c / max(max(c.r, max(c.g, c.b)), 0.0001);
	vec3 page = paper * (1.0 - paper_grain * fibre) * mix(vec3(1.0), hue, wash);
	ALBEDO = mix(page, ink_col, clamp(ink, 0.0, 1.0) * ink_strength);
}
```

## 2. `scripts/styles/engraving.gd` (replaces the stub)

```gdscript
extends RefCounted
## Style audition: engraving (docs/design/SLICE_PRINCIPE.md, 2026-11-16).
## Ink on paper. The pass in shaders/style_engraving.gdshader draws everything;
## this script gives it a frame with a clear key, hard shadows and no grade.

const SHADER := preload("res://shaders/style_engraving.gdshader")

## Every key is a float and can be overridden with --style-set. Keys listed in
## UNIFORMS are shader uniforms of the same name; the others are read here.
const PARAMS := {
	"exposure": 2.2, "totality_gain": 14.0, "night_gain": 6.0,
	"resp_r": 0.60, "resp_g": 0.55, "resp_b": -0.15,
	"tone_lo": 0.10, "tone_hi": 0.80, "sky_ink": 0.80,
	"line_px": 5.0, "ray_px": 5.0, "ray_inner": 3.0, "ray_outer": 8.0,
	"cross_at": 0.34, "third_at": 0.62, "solid_lo": 0.92, "solid_hi": 0.99, "flat_at": 0.92,
	"outline": 1.0, "outline_px": 1.3, "edge_depth": 0.02, "edge_normal": 0.18, "far_outline": 0.35,
	"wobble": 1.0, "wash": 0.0, "paper_grain": 0.05, "ink_strength": 0.94, "normal_from_depth": 0.0,
	"sun_floor": 0.9, "sun_gain": 1.8, "ambient": 0.45, "shadow_blur": 0.4, "sun_angle": 0.3,
	"ssao": 1.0, "fog_density": 0.006, "vignette": 0.12, "fov": 60.0,
}
const UNIFORMS := [
	"exposure", "totality_gain", "night_gain", "resp_r", "resp_g", "resp_b", "tone_lo", "tone_hi",
	"sky_ink", "line_px", "ray_px", "ray_inner", "ray_outer", "cross_at", "third_at", "solid_lo",
	"solid_hi", "flat_at", "outline", "outline_px", "edge_depth", "edge_normal", "far_outline",
	"wobble", "wash", "paper_grain", "ink_strength", "normal_from_depth",
]
const PAPER := Color("efe6d2")
const INK := Color("221c18")
const DIALOGUE := {
	"portrait": "res://assets/portraits/eddington_engraving.jpg",
	"panel": Color(0.937, 0.902, 0.824, 0.97), "border": INK,
	"speaker": INK, "text": INK,
	"mount": PAPER, "mount_border": INK,
}


func apply(main: Node, style: RefCounted) -> void:
	var p: Dictionary = style.params
	var env: Environment = main.env
	# The pass writes final colours: nothing may grade or bloom them afterwards.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = false
	env.glow_enabled = false
	env.sdfgi_enabled = false
	env.volumetric_fog_enabled = false
	env.ssao_enabled = p.ssao > 0.5
	env.fog_density = p.fog_density
	# Settings.apply_quality() restores these three from the node's metas.
	for we in main.get_tree().get_nodes_in_group("quality_env"):
		we.set_meta("standard_ssao", env.ssao_enabled)
		we.set_meta("standard_sdfgi", false)
		we.set_meta("standard_volumetric_fog", false)
	main.sun.light_angular_distance = p.sun_angle
	main.sun.shadow_blur = p.shadow_blur
	if not main._look.is_empty():
		main._look["sun_floor"] = p.sun_floor
	main._look_sun = p.sun_gain
	main._look_ambient = p.ambient
	main.player.camera.fov = p.fov
	style.add_quad(main, SHADER, {
		"sun_dir": main.sim.sun_dir, "sun_r": main.sim.SUN_R,
		"paper": PAPER, "ink_col": INK,
	})
	style.set_post(main, p.vignette, 0.0)


func light(_main: Node, style: RefCounted, _contact: float, darkness: float, night: float) -> void:
	if style.quad_material == null:
		return
	style.quad_material.set_shader_parameter("darkness", darkness)
	style.quad_material.set_shader_parameter("night", night)
```

`style.add_quad` already pushes every `params` key to the material (keys that are not uniforms are ignored by the shader). If the plumbing's `add_quad`, `set_post` or `quad_material` differ from what this script assumes, adapt this script, not `scripts/style.gd`, and say so.

## 3. `tests/test_style_engraving.gd` (SceneTree script, the `check()` pattern of `tests/test_style.gd`)

- Text checks on `res://shaders/style_engraving.gdshader` (read with `FileAccess`): for every name in `UNIFORMS` the file contains `uniform float <name> `; it contains `hint_screen_texture`, `hint_depth_texture`, `hint_normal_roughness_texture` and `POSITION = vec4(VERTEX.xy, 1.0, 1.0)`.
- Every `UNIFORMS` name is a `PARAMS` key; every `PARAMS` value is a float.
- With the main scene and this style applied (set up exactly as `tests/test_style.gd` does for its main-scene case): tonemap is linear, `adjustment_enabled`, `glow_enabled`, `sdfgi_enabled`, `volumetric_fog_enabled` are false; one node in group `style_quad` whose material uses this shader; `get_shader_parameter("line_px") == 5.0`; `get_shader_parameter("sun_r")` equals `main.sim.SUN_R`; `paper` equals `PAPER`; the camera FOV is 60; `main._look_sun == 1.8`.
- `main._apply_light(1.0, 1.0, 230.0, 0.0)` then `get_shader_parameter("darkness") == 1.0`; `main._apply_light(0.62, 0.0, -150.0, 0.0)` then `0.0`.
- After `Settings.apply_quality(get_tree())` at standard quality: `sdfgi_enabled` and `volumetric_fog_enabled` still false.
- An override: a `Style.from_args({"style": "engraving", "style-set": "wash=0.3,line_px=7"})` instance applied to a second main scene gives `wash` 0.3 and `line_px` 7.0 on the material.
- Last line `test_style_engraving: <n> checks, <f> failures`, exit code 1 on failures. Restore any `Settings` value the test changes.

## Report

The lines of the shader you changed and why; the normal-buffer decode you verified; the headless smoke `orb-test --host -- sh -c 'perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . -- --benchmark=/private/tmp/sa-engraving-smoke --seed=7 --style=engraving --bench-only=arrival,coelostat_still,totality_sky,dialogue > /private/tmp/sa-engraving-smoke.log 2>&1; echo exit=$?; grep -cE "SCRIPT ERROR|STYLE ERROR|SHADER ERROR" /private/tmp/sa-engraving-smoke.log; grep -c "\[BENCH\]" /private/tmp/sa-engraving-smoke.log; rm -rf /private/tmp/sa-engraving-smoke /private/tmp/sa-engraving-smoke.log'` → `exit=0`, `0`, `4`; the commit hash pushed.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; for t in test_style_engraving test_style test_look; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . --script res://tests/$t.gd || exit 1; done'

Acceptance cases:
- `--style=engraving`: the frame is produced by the pass (linear tonemap, no grade, no glow), with the quad present and every `PARAMS` value on its material; `--style-set=wash=0.3` reaches the shader.
- `darkness` and `night` on the material follow `_apply_light`.
- Without `--style`, or with another style, nothing of this file loads into the scene.
- The three suites in the `Test:` line pass; the smoke gives `exit=0`, `0`, `4`.
