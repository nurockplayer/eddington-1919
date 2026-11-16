# Brief sa-silver: the silver plate look (style audition)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/sa-silver`, branch `art/sa-silver` (created from `art/style-audition` 8f09a21, after the plumbing task: `scripts/style.gd`, `tests/test_style.gd` and the stub `scripts/styles/silver.gd` exist). Godot 4.7.2 Forward+ (MSAA 4× on), GDScript (tabs), Godot shading language.

## Goal

One of three looks for a style audition (`docs/design/SLICE_PRINCIPE.md`, top section): the game seen as a 1919 glass plate and its toned print. One channel mix turns the lit frame into a silver image, the lens is soft and loses the distance, bright things bleed into the emulsion (halation, done by the Environment's glow on the HDR image), the print is warm-toned by the Environment's colour correction, and the plate has grain, specks and an uneven edge. Switched on by `--style=silver`. The art director wrote the shader and the script below and will tune them in a windowed session; your job is to install them, make them compile and run, and test what can be tested without a renderer.

You touch only: `shaders/style_silver.gdshader` (new), `scripts/styles/silver.gd` (replace the stub), `shaders/look_post.gdshader` (two new uniforms, section 3), `tests/test_style_silver.gd` (new). Nothing else.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot bare: every run goes through `orb-test --host -- <command>` (one headless run at a time). **No windowed Godot runs at all.** No full-suite runs: only the tests named below.
- First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang).
- Before any `--script` test run, parse what you edited: `orb-test --host -- godot --headless --path . --check-only --script <file.gd>`; a script error in a `--script` run hangs instead of failing.
- Do not sleep or poll. Leave nothing behind (no scratch files).
- Every time you write down carries its zone (`2026-11-16 18:30 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`. Commit to `art/sa-silver` and `git push -u origin art/sa-silver`. No PR.

## The shaders cannot be compiled here: read them as the compiler would

Headless Godot uses a dummy renderer that never compiles shaders, so a syntax or type error in a `.gdshader` shows up only in the art director's windowed session, where it costs render time. After installing the files, go through both shaders line by line against the Godot 4.7 shading language and fix what would not compile, without changing what they compute. Check in particular: no implicit `int`→`float` conversion (every literal in float maths has a decimal point); built-ins (`SCREEN_UV`, `FRAGCOORD`, `INV_PROJECTION_MATRIX`, `UV`) are used only inside `fragment()`; every variable is declared before use and not redeclared in the same scope; ternaries have matching types on both sides; the render modes and uniform hints exist in 4.7 (`filter_linear_mipmap` on a `hint_screen_texture` sampler is what makes `textureLod` return the blurred mip levels: confirm in the Godot docs or engine source that the Forward+ screen texture has mipmaps with this hint, and say what you found); a full-screen quad is written `POSITION = vec4(VERTEX.xy, 1.0, 1.0);` (reversed Z, Godot ≥ 4.3); in Forward+ the depth texture is 1 at the near plane and 0 at the far plane, and NDC is `vec3(SCREEN_UV * 2.0 - 1.0, depth)`. List in your report every line you changed and why.

## 1. `shaders/style_silver.gdshader`

```glsl
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
```

## 2. `scripts/styles/silver.gd` (replaces the stub)

```gdscript
extends RefCounted
## Style audition: silver plate (docs/design/SLICE_PRINCIPE.md, 2026-11-16).
## The pass in shaders/style_silver.gdshader makes the silver image; this script
## sets the lens, the halation, the toning and the plate's grain and edge.

const SHADER := preload("res://shaders/style_silver.gdshader")

## Every key is a float and can be overridden with --style-set. Keys listed in
## UNIFORMS are shader uniforms of the same name; the others are read here.
const PARAMS := {
	"resp_r": 0.75, "resp_g": 0.40, "resp_b": -0.15,
	"gain": 1.0, "totality_gain": 2.5, "night_gain": 1.0, "black": 0.0,
	"soft": 0.22, "soft_lod": 3.0, "focus_far": 22.0, "far_soft": 0.35, "tint": 0.0,
	"exposure": 1.0, "white": 4.0, "contrast": 1.08, "tone": 1.0,
	"glow": 0.9, "glow_threshold": 0.85, "glow_bloom": 0.06,
	"dof_far": 30.0, "dof_amount": 0.06,
	"sun_floor": 0.45, "sun_gain": 1.8, "ambient": 0.5, "sun_angle": 1.2,
	"ssao": 1.0, "volumetric_fog": 1.0, "fog_density": 0.008,
	"vignette": 0.5, "grain": 0.09, "dust": 0.6, "edge": 0.7, "fov": 60.0,
}
const UNIFORMS := [
	"resp_r", "resp_g", "resp_b", "gain", "totality_gain", "night_gain", "black",
	"soft", "soft_lod", "focus_far", "far_soft", "tint",
]
const DIALOGUE := {
	"portrait": "res://assets/portraits/eddington_neutral.jpg",
	"panel": Color(0.085, 0.07, 0.058, 0.94), "border": Color(0.56, 0.50, 0.41),
	"speaker": Color(0.86, 0.80, 0.68), "text": Color(0.93, 0.90, 0.82),
}
## The print's tone per channel: input value → output value. Black never prints
## pure black, the paper is cream. `tone` blends from a neutral curve to this.
const TONE_OFFSETS := [0.0, 0.12, 0.5, 0.88, 1.0]
const TONE_NEUTRAL := [Color(0.04, 0.04, 0.04), Color(0.14, 0.14, 0.14), Color(0.50, 0.50, 0.50), Color(0.88, 0.88, 0.88), Color(0.95, 0.95, 0.95)]
const TONE_WARM := [Color(0.045, 0.035, 0.030), Color(0.150, 0.120, 0.100), Color(0.520, 0.470, 0.410), Color(0.900, 0.865, 0.790), Color(0.965, 0.940, 0.880)]


static func tone_lut(tone: float) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(TONE_OFFSETS)
	var colors := PackedColorArray()
	for i in TONE_NEUTRAL.size():
		colors.append(TONE_NEUTRAL[i].lerp(TONE_WARM[i], tone))
	g.colors = colors
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	return tex


func apply(main: Node, style: RefCounted) -> void:
	var p: Dictionary = style.params
	var env: Environment = main.env
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = p.exposure
	env.tonemap_white = p.white
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.adjustment_contrast = p.contrast
	env.adjustment_color_correction = tone_lut(p.tone)
	# Halation: light bleeding sideways in the emulsion round every highlight.
	env.glow_enabled = p.glow > 0.0
	env.glow_intensity = p.glow
	env.glow_bloom = p.glow_bloom
	env.glow_hdr_threshold = p.glow_threshold
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for i in 7:
		env.set_glow_level(i, 1.0 if i >= 2 and i <= 5 else 0.0)
	env.sdfgi_enabled = false
	env.ssao_enabled = p.ssao > 0.5
	env.volumetric_fog_enabled = p.volumetric_fog > 0.5
	env.fog_density = p.fog_density
	# Settings.apply_quality() restores these three from the node's metas.
	for we in main.get_tree().get_nodes_in_group("quality_env"):
		we.set_meta("standard_ssao", env.ssao_enabled)
		we.set_meta("standard_sdfgi", false)
		we.set_meta("standard_volumetric_fog", env.volumetric_fog_enabled)
	main.sun.light_angular_distance = p.sun_angle
	if not main._look.is_empty():
		main._look["sun_floor"] = p.sun_floor
	main._look_sun = p.sun_gain
	main._look_ambient = p.ambient
	main.player.camera.fov = p.fov
	# A large-format lens: the distance goes soft.
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = p.dof_amount > 0.0
	lens.dof_blur_far_distance = p.dof_far
	lens.dof_blur_far_transition = p.dof_far
	lens.dof_blur_amount = p.dof_amount
	main.player.camera.attributes = lens
	style.add_quad(main, SHADER)
	style.set_post(main, p.vignette, p.grain)
	for post in main.get_tree().get_nodes_in_group("look_post"):
		post.material.set_shader_parameter("dust", p.dust)
		post.material.set_shader_parameter("edge", p.edge)


func light(_main: Node, style: RefCounted, _contact: float, darkness: float, night: float) -> void:
	if style.quad_material == null:
		return
	style.quad_material.set_shader_parameter("darkness", darkness)
	style.quad_material.set_shader_parameter("night", night)
```

Check while installing (read the code, then fix this script, not the others, and say what you changed):

- `style.add_quad` already pushes every `params` key to the material (keys that are not uniforms are ignored by the shader). If the plumbing's `add_quad`, `set_post` or `quad_material` differ from what this script assumes, adapt this script, not `scripts/style.gd`.
- Whether anything else writes `main.player.camera.attributes`, `env.glow_*`, the tonemap or the adjustments after `Style.apply()` runs in `main._ready()` (`scripts/main.gd` around lines 160–200 and `_apply_light`, `scripts/settings.gd` `apply_quality`, `scripts/player.gd`). If something does, report it; do not change those files.
- The Environment property and constant names against Godot 4.7 (`glow_blend_mode`, `set_glow_level`, `TONE_MAPPER_FILMIC`, `CameraAttributesPractical.dof_blur_*`): a wrong name is a script error in the headless run.
- The `look_post` layer is added to the tree by `set_post`; if the group lookup can run before the node is in the tree, find the layer the way `set_post` does.

## 3. `shaders/look_post.gdshader`: two uniforms, both 0 by default

Current file (18 lines): a `canvas_item` shader, `blend_mul`, that multiplies a vignette and a darkening grain over the frame. Add the plate's specks and its uneven edge. With `dust = 0` and `edge = 0` the output must be exactly what it is today.

```glsl
uniform float dust = 0.0;   // plate specks, fixed to the plate (silver plate style)
uniform float edge = 0.0;   // uneven darkening where the emulsion ends
```

and in `fragment()`, after `v` and `n` are computed and before `COLOR`:

```glsl
	// Silver plate (scripts/styles/silver.gd); both are 0 for every other look.
	float e = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y) * 0.5625);
	float rag = 0.004 * (sin(UV.x * 37.0) * sin(UV.y * 23.0 + 1.7) + 1.0);
	float emulsion = smoothstep(0.0, 0.035, e + rag - 0.004);
	v *= mix(1.0, 0.35 + 0.65 * emulsion, edge);
	float speck = step(0.9994, hash(floor(FRAGCOORD.xy / 2.0) + vec2(3.0, 11.0)));
	v *= 1.0 - dust * 0.5 * speck;
```

## 4. `tests/test_style_silver.gd` (SceneTree script, the `check()` pattern of `tests/test_style.gd`)

- Text checks (read with `FileAccess`): `res://shaders/style_silver.gdshader` contains `uniform float <name> ` for every name in `UNIFORMS`, and `hint_screen_texture`, `filter_linear_mipmap`, `hint_depth_texture`, `POSITION = vec4(VERTEX.xy, 1.0, 1.0)`; `res://shaders/look_post.gdshader` contains `uniform float dust = 0.0` and `uniform float edge = 0.0`.
- Every `UNIFORMS` name is a `PARAMS` key; every `PARAMS` value is a float.
- `tone_lut(1.0)`: the gradient's first colour is `Color(0.045, 0.035, 0.030)` and its last `Color(0.965, 0.940, 0.880)`; `tone_lut(0.0)`: every colour has r == g == b.
- With the main scene and this style applied (set up exactly as `tests/test_style.gd` does for its main-scene case): tonemap is filmic; `adjustment_enabled` and `glow_enabled` true; `glow_hdr_threshold == 0.85`; `sdfgi_enabled` false; one node in group `style_quad` whose material uses this shader; `get_shader_parameter("resp_b") == -0.15`; the `look_post` material has `vignette` 0.5, `grain` 0.09, `dust` 0.6, `edge` 0.7; the camera has `CameraAttributesPractical` with far blur on at 30 m; the camera FOV is 60; `main._look_sun == 1.8`.
- `main._apply_light(1.0, 1.0, 215.0, 0.0)` then `get_shader_parameter("darkness") == 1.0`; `main._apply_light(0.62, 0.0, -150.0, 0.0)` then `0.0`.
- After `Settings.apply_quality(get_tree())` at standard quality: `sdfgi_enabled` still false, `volumetric_fog_enabled` still true.
- An override: a `Style.from_args({"style": "silver", "style-set": "tint=0.3,glow=0"})` instance applied to a second main scene gives `tint` 0.3 on the material and `glow_enabled` false.
- Last line `test_style_silver: <n> checks, <f> failures`, exit code 1 on failures. Restore any `Settings` value the test changes.

## Report

The shader lines you changed and why; what you found about the screen texture's mipmaps; anything that overwrites this style's settings after `apply`; the headless smoke `orb-test --host -- sh -c 'perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . -- --benchmark=/private/tmp/sa-silver-smoke --seed=7 --style=silver --bench-only=arrival,coelostat_still,totality_sky,dialogue > /private/tmp/sa-silver-smoke.log 2>&1; echo exit=$?; grep -cE "SCRIPT ERROR|STYLE ERROR|SHADER ERROR" /private/tmp/sa-silver-smoke.log; grep -c "\[BENCH\]" /private/tmp/sa-silver-smoke.log; rm -rf /private/tmp/sa-silver-smoke /private/tmp/sa-silver-smoke.log'` → `exit=0`, `0`, `4`; the commit hash pushed.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; for t in test_style_silver test_style test_look; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . --script res://tests/$t.gd || exit 1; done'

Acceptance cases:
- `--style=silver`: filmic tonemap, glow on, the toning curve installed, the quad present with every `PARAMS` value on its material, grain, vignette, dust and edge on the `look_post` layer; `--style-set=tint=0.3` reaches the shader.
- `darkness` and `night` on the material follow `_apply_light`.
- Without `--style`, or with another style: nothing of `style_silver` loads into the scene, and `look_post` draws exactly as before (`dust` and `edge` are 0).
- The three suites in the `Test:` line pass; the smoke gives `exit=0`, `0`, `4`.
