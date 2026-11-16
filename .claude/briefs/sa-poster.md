# Brief sa-poster: the poster look, flat colour and light (style audition)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/sa-poster`, branch `art/sa-poster` (created from `art/style-audition` 8f09a21, after the plumbing task: `scripts/style.gd`, `tests/test_style.gd` and the stub `scripts/styles/poster.gd` exist). Godot 4.7.2 Forward+ (MSAA 4× on), GDScript (tabs), Godot shading language.

## Goal

One of three looks for a style audition (`docs/design/SLICE_PRINCIPE.md`, top section): the game as a 1920s travel-poster lithograph. Every surface is one flat colour with one hard-edged shadow tone (toon diffuse, a warm key, a violet ambient, crisp cast shadows, no texture noise); the distance steps back through a warm-then-cool haze; the sky is drawn by the pass itself as flat bands with cut-paper clouds, and at totality as a flat corona in three tones on indigo with a salmon horizon. Switched on by `--style=poster`. The art director wrote the shader and the script below and will tune them in a windowed session; your job is to install them, make them compile and run, and test what can be tested without a renderer.

You touch only: `shaders/style_poster.gdshader` (new), `scripts/styles/poster.gd` (replace the stub), `shaders/foliage_card.gdshader` (one uniform, section 3), `tests/test_style_poster.gd` (new). Nothing else.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot bare: every run goes through `orb-test --host -- <command>` (one headless run at a time). **No windowed Godot runs at all.** No full-suite runs: only the tests named below.
- First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang).
- Before any `--script` test run, parse what you edited: `orb-test --host -- godot --headless --path . --check-only --script <file.gd>`; a script error in a `--script` run hangs instead of failing.
- Do not sleep or poll. Leave nothing behind (no scratch files).
- Every time you write down carries its zone (`2026-11-16 18:30 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`. Commit to `art/sa-poster` and `git push -u origin art/sa-poster`. No PR.

## The shaders cannot be compiled here: read them as the compiler would

Headless Godot uses a dummy renderer that never compiles shaders, so a syntax or type error in a `.gdshader` shows up only in the art director's windowed session, where it costs render time. After installing the files, go through both shaders line by line against the Godot 4.7 shading language and fix what would not compile, without changing what they compute. Check in particular: no implicit `int`→`float` conversion (every literal in float maths has a decimal point); built-ins (`SCREEN_UV`, `FRAGCOORD`, `VIEWPORT_SIZE`, `PROJECTION_MATRIX`, `INV_PROJECTION_MATRIX`, `INV_VIEW_MATRIX`) are used only inside `fragment()`; `fwidth` is called only in `fragment()` or in a function called from it, and never inside an `if` or a loop; every variable is declared before use and not redeclared in the same scope; ternaries have matching types on both sides; a `uniform vec2 star_pos[12];` array is declared and indexed as `shaders/eclipse_sky.gdshader` does; the render modes and uniform hints exist in 4.7 for `shader_type spatial`; a full-screen quad is written `POSITION = vec4(VERTEX.xy, 1.0, 1.0);` (reversed Z, Godot ≥ 4.3); in Forward+ the depth texture is 1 at the near plane and 0 at the far plane, and NDC is `vec3(SCREEN_UV * 2.0 - 1.0, depth)`. List in your report every line you changed and why.

## 1. `shaders/style_poster.gdshader`

The cloud, Sun, Moon and corona maths repeat `shaders/eclipse_sky.gdshader` (lines 62–72 and 92–110) on purpose: the pass redraws the same sky flat, so the clouds stay where the simulation has them. Do not change `eclipse_sky.gdshader`.

```glsl
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
// Style audition: poster (scripts/styles/poster.gd). A full-screen pass over a
// toon-lit frame. Geometry keeps its flat colours and steps back through a
// warm-then-cool haze. The sky is redrawn flat from the simulation's own cloud
// field (same maths as shaders/eclipse_sky.gdshader): bands of equal altitude,
// clouds cut in two tones, and at totality a corona in three flat tones.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D cloud_tex : repeat_enable, filter_linear;

uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);   // world, toward the Sun
uniform float sun_r = 0.02;                    // the Sun's angular radius in radians
uniform vec2 wind = vec2(0.0042, 0.0026);
uniform float cloud_scale = 0.35;
uniform float cloud_time = 0.0;
uniform float contact = 0.8;                   // 0 Moon far off the disc … 1 centred
uniform float darkness = 0.0;                  // 0 day … 1 totality
uniform float night = 0.0;
uniform float star_vis = 0.0;
uniform vec2 star_pos[12];                     // in solar radii about the Sun

// The inks. Set from scripts/styles/poster.gd (INKS).
uniform vec3 sky_top : source_color = vec3(0.30, 0.56, 0.62);
uniform vec3 sky_low : source_color = vec3(0.96, 0.87, 0.68);
uniform vec3 cloud_a : source_color = vec3(0.98, 0.94, 0.84);
uniform vec3 cloud_b : source_color = vec3(0.78, 0.72, 0.74);
uniform vec3 sun_ink : source_color = vec3(1.0, 0.96, 0.80);
uniform vec3 tot_top : source_color = vec3(0.055, 0.075, 0.20);
uniform vec3 tot_mid : source_color = vec3(0.16, 0.17, 0.38);
uniform vec3 tot_low : source_color = vec3(0.86, 0.47, 0.30);
uniform vec3 tot_cloud_a : source_color = vec3(0.13, 0.14, 0.30);
uniform vec3 tot_cloud_b : source_color = vec3(0.08, 0.09, 0.21);
uniform vec3 corona_a : source_color = vec3(1.0, 0.97, 0.88);
uniform vec3 corona_b : source_color = vec3(0.78, 0.82, 0.93);
uniform vec3 corona_c : source_color = vec3(0.36, 0.40, 0.68);
uniform vec3 moon_ink : source_color = vec3(0.03, 0.035, 0.09);
uniform vec3 prom_ink : source_color = vec3(0.89, 0.33, 0.25);
uniform vec3 haze_near : source_color = vec3(0.98, 0.80, 0.60);
uniform vec3 haze_far : source_color = vec3(0.62, 0.72, 0.82);
uniform vec3 tot_haze : source_color = vec3(0.10, 0.11, 0.26);

uniform float gain = 0.78;            // exposure of the lit geometry
uniform float sat = 1.15;             // saturation of the lit geometry
uniform float sky_bands = 5.0;        // flat bands from horizon to zenith
uniform float cloud_lo = 0.50;        // cloud density where the cloud shape starts
uniform float cloud_hi = 0.74;        // … and where its darker core starts
uniform float veil = 0.55;            // how far thin cloud lets the Sun or corona through
uniform float haze_k = 0.012;         // haze per metre
uniform float haze_max = 0.88;
uniform float haze_turn = 0.45;       // share of the haze where warm has turned cool
uniform float corona_fall = 3.2;
uniform float corona_base = 0.35;
uniform float streamer = 1.3;
uniform float streamer_reach = 0.25;
uniform float corona_1 = 0.30;        // the three cuts of the corona, inner to outer
uniform float corona_2 = 0.11;
uniform float corona_3 = 0.035;
uniform float star_px = 2.2;          // radius of a field star in pixels

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

// An antialiased step: 0 below the edge, 1 above.
float cut(float edge, float x) {
	float w = max(fwidth(x) * 0.7, 0.0005);
	return smoothstep(edge - w, edge + w, x);
}

// x cut into whole steps with antialiased risers at the half steps.
float stairs(float x) {
	float w = max(fwidth(x) * 0.7, 0.0005);
	return floor(x) + smoothstep(0.5 - w, 0.5 + w, fract(x));
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 c = texture(screen_tex, uv).rgb;
	float raw = texture(depth_tex, uv).r;
	vec4 p4 = INV_PROJECTION_MATRIX * vec4(uv * 2.0 - 1.0, max(raw, 0.00001), 1.0);
	vec3 pv = p4.xyz / p4.w;
	vec3 d = normalize((INV_VIEW_MATRIX * vec4(normalize(pv), 0.0)).xyz);
	float is_sky = raw < 0.00001 ? 1.0 : 0.0;

	// --- Sky, computed for every pixel (no derivative calls inside branches).
	float h = d.y;
	float e = clamp(h, 0.0, 1.0);
	float bq = stairs(pow(e, 0.6) * sky_bands) / sky_bands;
	float gq = stairs(exp(-e * 6.0) * 4.0) / 4.0;
	vec3 day = mix(sky_low, sky_top, clamp(bq, 0.0, 1.0));
	vec3 tot = mix(mix(tot_mid, tot_top, clamp(bq, 0.0, 1.0)), tot_low, clamp(gq, 0.0, 1.0));
	vec3 sky = mix(day, tot, darkness);

	vec2 plane = d.xz / max(h, 0.06);
	float dens = textureLod(cloud_tex, plane * cloud_scale - wind * cloud_time, 0.0).r;
	dens = mix(dens, 0.97, smoothstep(0.35, 0.05, h));
	dens = h > 0.0 ? dens : 1.0;
	float body = cut(cloud_lo, dens);
	float core = cut(cloud_hi, dens);
	vec3 cloud = mix(mix(cloud_a, cloud_b, core), mix(tot_cloud_a, tot_cloud_b, core), darkness);

	// Sun, Moon and corona, in solar radii about the Sun's centre.
	vec3 t1 = normalize(cross(sun_dir, vec3(0.0, 1.0, 0.0)));
	vec3 t2 = cross(t1, sun_dir);
	vec2 lp = vec2(dot(d, t1), dot(d, t2)) / sun_r;
	float r = length(lp);
	float front = step(0.0, dot(d, sun_dir));
	vec2 moon_c = vec2((1.0 - contact) * 2.1, 0.12 * (1.0 - contact));
	float in_sun = 1.0 - cut(1.0, r);
	float in_moon = 1.0 - cut(1.0, length(lp - moon_c));
	float a = atan(lp.y, lp.x);
	float lobes = 0.55 + 0.45 * sin(a * 3.0 + 1.3) * sin(a * 7.0 - 0.4);
	float rr = max(r, 1.0);
	float corona = pow(1.0 / rr, corona_fall) * (corona_base + streamer * lobes * exp(-(rr - 1.0) * streamer_reach));
	float k_c3 = cut(corona_3, corona);
	float k_c2 = cut(corona_2, corona);
	float k_c1 = cut(corona_1, corona);
	float spike = pow(max(sin(a * 5.0 + 2.0), 0.0), 8.0);
	float prom = (1.0 - cut(1.07, r)) * cut(0.75, spike);
	vec3 solar = sky;
	solar = mix(solar, corona_c, k_c3 * darkness);
	solar = mix(solar, corona_b, k_c2 * darkness);
	solar = mix(solar, corona_a, k_c1 * darkness);
	solar = mix(solar, prom_ink, prom * darkness);
	solar = mix(solar, sun_ink, in_sun * (1.0 - darkness));
	solar = mix(solar, mix(sky, moon_ink, darkness), in_moon);
	// Field stars: the same twelve the plates record.
	float px = 2.0 / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y);   // radians per pixel
	float stars = 0.0;
	for (int i = 0; i < 12; i++) {
		float sd = length(lp - star_pos[i]) * sun_r;
		stars = max(stars, 1.0 - smoothstep(0.6, 1.0, sd / (star_px * px)));
	}
	solar = mix(solar, corona_a, stars * star_vis);
	// Thin cloud lets the lit things through as a veil; a cloud's core hides them.
	float lit = max(max(k_c3 * darkness, in_sun * (1.0 - darkness)), stars * star_vis) * front;
	vec3 sky_col = mix(sky, solar, front);
	sky_col = mix(sky_col, cloud, body * (1.0 - veil * lit * (1.0 - core)));

	// --- Geometry: the toon-lit frame, stepped back through the haze.
	float z = max(-pv.z, 0.0);
	vec3 geo = c * gain;
	float lum = dot(geo, vec3(0.2126, 0.7152, 0.0722));
	geo = max(mix(vec3(lum), geo, sat), vec3(0.0));
	float t = 1.0 - exp(-z * haze_k);
	vec3 hz = mix(mix(haze_near, haze_far, smoothstep(0.0, haze_turn, t)), tot_haze, max(darkness, night));
	geo = mix(geo, hz, t * haze_max);

	// The night sky (the darkroom chapter) is left as rendered.
	vec3 sky_out = mix(sky_col, c, step(0.5, night));
	ALBEDO = mix(geo, sky_out, is_sky);
}
```

## 2. `scripts/styles/poster.gd` (replaces the stub)

```gdscript
extends RefCounted
## Style audition: poster (docs/design/SLICE_PRINCIPE.md, 2026-11-16).
## Flat colour and light: toon diffuse on every lit surface, a warm key with
## hard cast shadows, a violet ambient as the one shadow tone, no texture noise.
## The pass in shaders/style_poster.gdshader adds the haze and redraws the sky.

const SHADER := preload("res://shaders/style_poster.gdshader")
const FoliageCard := preload("res://shaders/foliage_card.gdshader")
const Palette := preload("res://scripts/palette.gd")

## Every key is a float and can be overridden with --style-set. Keys listed in
## UNIFORMS are shader uniforms of the same name; the others are read here.
const PARAMS := {
	"gain": 0.78, "sat": 1.15, "sky_bands": 5.0, "cloud_lo": 0.50, "cloud_hi": 0.74, "veil": 0.55,
	"haze_k": 0.012, "haze_max": 0.88, "haze_turn": 0.45,
	"corona_fall": 3.2, "corona_base": 0.35, "streamer": 1.3, "streamer_reach": 0.25,
	"corona_1": 0.30, "corona_2": 0.11, "corona_3": 0.035, "star_px": 2.2,
	"key": 1.1, "ambient": 0.6, "ambient_totality": 0.9, "terminator": 0.08,
	"shadow_blur": 0.5, "sun_angle": 0.0, "flatten": 0.85, "ground_patches": 1.0,
	"vignette": 0.0, "grain": 0.04, "fov": 60.0,
}
const UNIFORMS := [
	"gain", "sat", "sky_bands", "cloud_lo", "cloud_hi", "veil", "haze_k", "haze_max", "haze_turn",
	"corona_fall", "corona_base", "streamer", "streamer_reach", "corona_1", "corona_2", "corona_3", "star_px",
]
## The inks, as display colours (the uniforms are source_color).
const INKS := {
	"sky_top": Color(0.30, 0.56, 0.62), "sky_low": Color(0.96, 0.87, 0.68),
	"cloud_a": Color(0.98, 0.94, 0.84), "cloud_b": Color(0.78, 0.72, 0.74),
	"sun_ink": Color(1.0, 0.96, 0.80),
	"tot_top": Color(0.055, 0.075, 0.20), "tot_mid": Color(0.16, 0.17, 0.38), "tot_low": Color(0.86, 0.47, 0.30),
	"tot_cloud_a": Color(0.13, 0.14, 0.30), "tot_cloud_b": Color(0.08, 0.09, 0.21),
	"corona_a": Color(1.0, 0.97, 0.88), "corona_b": Color(0.78, 0.82, 0.93), "corona_c": Color(0.36, 0.40, 0.68),
	"moon_ink": Color(0.03, 0.035, 0.09), "prom_ink": Color(0.89, 0.33, 0.25),
	"haze_near": Color(0.98, 0.80, 0.60), "haze_far": Color(0.62, 0.72, 0.82), "tot_haze": Color(0.10, 0.11, 0.26),
}
const KEY_COLOR := Color(1.0, 0.86, 0.62)
const SHADOW_DAY := Color(0.42, 0.44, 0.72)        # the ambient is the shadow tone
const SHADOW_TOTALITY := Color(0.10, 0.11, 0.26)
const SHADOW_NIGHT := Color(0.03, 0.035, 0.06)
const DIALOGUE := {
	"portrait": "res://assets/portraits/eddington_poster.jpg",
	"panel": Color(0.09, 0.11, 0.24, 0.96), "border": Color(0.80, 0.42, 0.28),
	"speaker": Color(0.95, 0.62, 0.42), "text": Color(0.97, 0.93, 0.82),
	"mount": Color(0.09, 0.11, 0.24), "mount_border": Color(0.97, 0.93, 0.82),
}


func apply(main: Node, style: RefCounted) -> void:
	var p: Dictionary = style.params
	var env: Environment = main.env
	# The pass writes final colours: nothing may grade, bloom or fog them afterwards.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = false
	env.glow_enabled = false
	env.fog_enabled = false
	env.sdfgi_enabled = false
	env.ssao_enabled = false
	env.volumetric_fog_enabled = false
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# Settings.apply_quality() restores these three from the node's metas.
	for we in main.get_tree().get_nodes_in_group("quality_env"):
		we.set_meta("standard_ssao", false)
		we.set_meta("standard_sdfgi", false)
		we.set_meta("standard_volumetric_fog", false)
	main.sun.light_color = KEY_COLOR
	main.sun.light_angular_distance = p.sun_angle
	main.sun.shadow_blur = p.shadow_blur
	main.player.camera.fov = p.fov
	style.each_material(main, func(m: Material, _node: Node): flatten_material(m, p))
	if p.ground_patches > 0.5:
		for ground in main.get_tree().get_nodes_in_group("ground"):
			if ground is MeshInstance3D:
				ground.material_override = ground_material(p)
	var uniforms := INKS.duplicate()
	uniforms["sun_dir"] = main.sim.sun_dir
	uniforms["sun_r"] = main.sim.SUN_R
	uniforms["wind"] = main.sim.wind
	uniforms["cloud_scale"] = main.sim.CLOUD_SCALE
	uniforms["cloud_tex"] = main.sky_mat.get_shader_parameter("cloud_tex")
	uniforms["star_pos"] = main.sim.star_offsets
	style.add_quad(main, SHADER, uniforms)
	style.set_post(main, p.vignette, p.grain)


## One flat colour and one hard shadow tone per surface. Evidence, glass, lamps
## and anything unshaded keep their materials.
static func flatten_material(m: Material, p: Dictionary) -> void:
	if m is ShaderMaterial:
		if m.shader == FoliageCard:
			m.set_shader_parameter("flatten", p.flatten)
		return
	var b := m as BaseMaterial3D
	if b == null or b.has_meta("evidence") or b.resource_name.begins_with("E1919_plate_glass"):
		return
	if b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or b.emission_enabled or b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return
	b.detail_enabled = false
	b.normal_enabled = false
	b.roughness_texture = null
	b.metallic_texture = null
	if b.albedo_texture is NoiseTexture2D:
		# A noise ramp becomes its middle colour.
		var ramp: Gradient = (b.albedo_texture as NoiseTexture2D).color_ramp
		if ramp != null:
			b.albedo_color = b.albedo_color * ramp.sample(0.5)
		b.albedo_texture = null
	b.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	b.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	b.metallic = 0.0
	b.metallic_specular = 0.0
	b.roughness = p.terminator   # with toon diffuse this is the width of the terminator


## The clearing as cut paper: three flat greens with organic edges.
static func ground_material(p: Dictionary) -> StandardMaterial3D:
	var tex := NoiseTexture2D.new()
	tex.width = 1024
	tex.height = 1024
	tex.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.006
	n.fractal_octaves = 3
	tex.noise = n
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.44, 0.62])
	g.colors = PackedColorArray([
		Palette.C["foliage_deep"].darkened(0.10),
		Palette.C["foliage_deep"].lerp(Palette.C["foliage_light"], 0.45),
		Palette.C["foliage_light"],
	])
	tex.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.035, 0.035, 0.035)
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.metallic_specular = 0.0
	m.roughness = p.terminator
	return m


func light(main: Node, style: RefCounted, contact: float, darkness: float, night: float) -> void:
	var p: Dictionary = style.params
	# A poster has one key: constant by day whatever the cloud, gone by totality.
	main.sun.light_energy = 0.0 if night > 0.5 else p.key * (1.0 - smoothstep(0.5, 0.95, darkness))
	main.env.ambient_light_color = SHADOW_DAY.lerp(SHADOW_TOTALITY, darkness).lerp(SHADOW_NIGHT, night)
	main.env.ambient_light_energy = lerpf(p.ambient, p.ambient_totality, darkness)
	if style.quad_material == null:
		return
	var q: ShaderMaterial = style.quad_material
	q.set_shader_parameter("contact", contact)
	q.set_shader_parameter("darkness", darkness)
	q.set_shader_parameter("night", night)
	q.set_shader_parameter("cloud_time", main.sky_mat.get_shader_parameter("cloud_time"))
	q.set_shader_parameter("star_vis", main.sky_mat.get_shader_parameter("star_vis"))
```

Check while installing (read the code, then fix this script, not the others, and say what you changed):

- `style.add_quad` already pushes every `params` key to the material (keys that are not uniforms are ignored by the shader). If the plumbing's `add_quad`, `set_post`, `each_material` or `quad_material` differ from what this script assumes, adapt this script, not `scripts/style.gd`.
- `main._apply_light()` (`scripts/main.gd`) sets `cloud_time` and `star_vis` on `sky_mat` before it calls the style's `light()`; confirm the order, and that `light()` runs after `_apply_light` has written `sun.light_energy`, `ambient_light_color` and `ambient_light_energy` (this style overwrites all three).
- `each_material` mutates shared materials in place (imported GLB materials, `world_builder._mats`). That is intended for a `--style=poster` process. If a material resource is shared with something that must not change (an evidence surface not marked `evidence`, the plates, the measuring sheet, UI viewports), list it in the report; do not add special cases beyond the three skip rules above.
- `Palette.C` keys `foliage_deep` and `foliage_light` exist (`scripts/palette.gd` lines 8–9). `Gradient.GRADIENT_INTERPOLATE_CONSTANT`, `Environment.REFLECTION_SOURCE_DISABLED`, `BaseMaterial3D.DIFFUSE_TOON`, `SPECULAR_DISABLED`, `metallic_specular`: check each name against Godot 4.7; a wrong name is a script error in the headless run.
- `main.sim.star_offsets` is a `PackedVector2Array` of 12 (the sky material gets the same array, `scripts/main.gd` line 334).
- Whether anything writes the tonemap, fog, ambient source or the sun's colour after `Style.apply()` in `main._ready()` or per frame (`_apply_light` sets `env.fog_light_color`: harmless with fog off). Report what you find; do not change those files.

## 3. `shaders/foliage_card.gdshader`: one uniform, 0 by default

Current `fragment()` (lines 24–32) samples one of three cut-outs into `c` and writes `ALBEDO = c.rgb * tint.rgb`. Add

```glsl
uniform float flatten = 0.0;   // poster style: 1 = the cut-out's broad colour only, no brushwork
```

and, right after `c` is sampled, take the same texture's colour from mip level 5 (the same three-way choice as the sample above it) and blend: `c.rgb = mix(c.rgb, <mip 5 colour>.rgb, flatten);`. Alpha stays from the sharp sample, so the silhouette is unchanged. With `flatten = 0` the shader's output is exactly what it is today. The samplers already use `filter_linear_mipmap_anisotropic`; check that the imported cut-outs under `assets/textures/principe/foliage/` have mipmaps on (`mipmaps/generate=true` in their `.import` files) and report the answer; do not change import settings.

## 4. `tests/test_style_poster.gd` (SceneTree script, the `check()` pattern of `tests/test_style.gd`)

- Text checks (read with `FileAccess`): `res://shaders/style_poster.gdshader` contains `uniform float <name> ` for every name in `UNIFORMS`, `uniform vec3 <name> ` for every key of `INKS`, and `hint_screen_texture`, `hint_depth_texture`, `uniform vec2 star_pos[12]`, `POSITION = vec4(VERTEX.xy, 1.0, 1.0)`; `res://shaders/foliage_card.gdshader` contains `uniform float flatten = 0.0`.
- Every `UNIFORMS` name is a `PARAMS` key; every `PARAMS` value is a float.
- `flatten_material` on fresh materials: a plain `StandardMaterial3D` with `detail_enabled`, metallic 0.8 and roughness 0.9 comes out toon, specular disabled, `detail_enabled` false, metallic 0, `metallic_specular` 0, roughness 0.08; one with a `NoiseTexture2D` albedo whose ramp is black→white comes out with `albedo_texture == null` and a mid-grey `albedo_color`; one with meta `evidence`, one unshaded, one with `emission_enabled`, one with alpha transparency: each unchanged (compare the properties above before and after); a `ShaderMaterial` using `foliage_card.gdshader` gets `flatten` 0.85.
- `ground_material`: its albedo is a `NoiseTexture2D` whose ramp has `interpolation_mode == Gradient.GRADIENT_INTERPOLATE_CONSTANT` and three colours; toon diffuse.
- With the main scene and this style applied (set up exactly as `tests/test_style.gd` does for its main-scene case): tonemap is linear; `adjustment_enabled`, `glow_enabled`, `fog_enabled`, `ssao_enabled`, `sdfgi_enabled`, `volumetric_fog_enabled` are false; ambient source is colour; one node in group `style_quad` whose material uses this shader; `get_shader_parameter("sun_r")` equals `main.sim.SUN_R`; `get_shader_parameter("sky_top")` equals `INKS.sky_top`; `get_shader_parameter("cloud_tex")` is the sky material's `cloud_tex`; the ground node's `material_override` is toon with the constant-ramp noise; `main.world_builder`-made materials: at least one `MeshInstance3D` under `main` has an active `StandardMaterial3D` with `diffuse_mode == DIFFUSE_TOON`; no `BaseMaterial3D` with meta `evidence` under `main` is toon; the camera FOV is 60.
- `main._apply_light(0.62, 0.0, -150.0, 0.0)`: `main.sun.light_energy == 1.1`, ambient colour `SHADOW_DAY`, ambient energy 0.6, quad `cloud_time == -150.0`, `darkness == 0.0`, `contact == 0.62`. `main._apply_light(1.0, 1.0, 215.0, 0.0)`: sun energy 0, ambient colour `SHADOW_TOTALITY`, energy 0.9, quad `darkness == 1.0`, `cloud_time == 215.0`. `main._apply_light(0.0, 0.0, 400.0, 1.0)`: sun energy 0, ambient colour `SHADOW_NIGHT`.
- After `Settings.apply_quality(get_tree())` at standard quality: `ssao_enabled`, `sdfgi_enabled` and `volumetric_fog_enabled` still false.
- An override: a `Style.from_args({"style": "poster", "style-set": "key=1.4,ground_patches=0,haze_k=0.02"})` instance applied to a second main scene gives sun energy 1.4 after `_apply_light(0.62, 0.0, -150.0, 0.0)`, `haze_k` 0.02 on the quad, and a ground override that is not the constant-ramp material.
- Last line `test_style_poster: <n> checks, <f> failures`, exit code 1 on failures. Restore any `Settings` value the test changes. Materials flattened in this test process stay flattened: run this suite as its own process (it is, in the `Test:` line).

## Report

The shader lines you changed and why; the mipmap answer for the foliage cut-outs; shared materials you found that the pass should not have touched; anything that overwrites this style's settings after `apply`; the headless smoke `orb-test --host -- sh -c 'perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . -- --benchmark=/private/tmp/sa-poster-smoke --seed=7 --style=poster --bench-only=arrival,coelostat_still,totality_sky,dialogue > /private/tmp/sa-poster-smoke.log 2>&1; echo exit=$?; grep -cE "SCRIPT ERROR|STYLE ERROR|SHADER ERROR" /private/tmp/sa-poster-smoke.log; grep -c "\[BENCH\]" /private/tmp/sa-poster-smoke.log; rm -rf /private/tmp/sa-poster-smoke /private/tmp/sa-poster-smoke.log'` → `exit=0`, `0`, `4`; the commit hash pushed.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; for t in test_style_poster test_style test_look test_vegetation_cards; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . --script res://tests/$t.gd || exit 1; done'

Acceptance cases:
- `--style=poster`: linear tonemap, no grade, glow, fog, SSAO, SDFGI or volumetric fog; colour ambient; every lit opaque `BaseMaterial3D` that is not evidence is toon with no detail texture; the ground is the three-tone patch material; foliage cards have `flatten` 0.85; the quad is present with every `PARAMS` value and every ink on its material.
- The key is constant by day (1.1) and 0 at totality and at night; the ambient colour and energy follow `darkness` and `night`; the quad's `contact`, `darkness`, `night`, `cloud_time` and `star_vis` follow `_apply_light`.
- Without `--style`, or with another style: nothing of `style_poster` loads into the scene, no material is changed, and `foliage_card` draws exactly as before (`flatten` is 0).
- The four suites in the `Test:` line pass; the smoke gives `exit=0`, `0`, `4`.
