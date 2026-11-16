# Brief p1-look: Príncipe slice look v2 (lighting, grade, post, FOV)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p1-look`, branch `art/p1-look` (already created from origin/main 73a7ccd). Godot 4.7.2, GDScript, tabs.

## Goal

Replace the Príncipe scene's r05 "plate grade" look with one parameter set (`Look.PRINCIPE`) that the art director can override per run with a user arg `--look-set=key=value,...`. Defaults below are the art director's first pass; they are tuned later from windowed captures, so implement exactly these values and do not tune anything yourself. Cambridge and departure keep the old plate grade untouched.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot or tests bare: every run goes through `orb-test --host -- <command>` (single headless suite). No windowed Godot runs at all in this task (headless only). No full-suite runs.
- First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang).
- Do not sleep or poll. Leave nothing behind (no scratch files, no settings files).
- Every time you write down carries its zone (`2026-11-14 14:10 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## Changes

### 1. `scripts/look.gd` (72 lines; keep everything that exists)

Keep `SATURATION`, `CONTRAST`, `AMBIENT_GAIN`, `SUN_GAIN`, `CLOUD_SHADE`, `DAY_SKY_GAIN`, `NIGHT_SAFELIGHT`, `NIGHT_LINEN_DIM`, `apply_grade()` and `apply_cinematic()` as they are (Cambridge `scripts/cambridge/room_builder.gd:694` still calls `apply_grade`; `NIGHT_*` are used by world_builder, benchmark and look_shots). Update the header comment: the plate grade is now Cambridge/departure only; Príncipe uses `PRINCIPE` (see `docs/design/SLICE_PRINCIPE.md`).

Add:

```gdscript
## Príncipe slice look (docs/design/SLICE_PRINCIPE.md, plan step 1). One parameter
## set; a windowed comparison run overrides single values with the user arg
## --look-set=key=value,key=value (tools/look_matrix.sh). No sepia in play.
const PRINCIPE := {
	"tonemap": "aces",          # aces | agx | filmic
	"exposure": 1.1,
	"white": 5.0,               # aces/filmic white point: highlights roll off instead of clipping
	"agx_contrast": 1.4,        # agx only
	"saturation": 1.18,         # pushed toward the Y reference (Owner 2026-11-14 JST)
	"contrast": 1.06,
	"split_tone": 1.0,          # 0 = neutral LUT … 1 = cool shadows, faintly warm midtones
	"sun_floor": 0.3,           # key that survives thick cloud, so overcast keeps a light direction
	"sun_gain": 1.8,
	"ambient_gain": 0.5,
	"sky_gain": 0.72,           # daytime sky brightness (shader day_gain): the sky must not clip
	"cloud_shade": 0.34,
	"ssao": 1,
	"sdfgi": 1,
	"sdfgi_energy": 1.0,
	"fog_density": 0.0042,
	"fog_aerial": 0.8,
	"volumetric_fog": 1,
	"volumetric_density": 0.012,
	"vignette": 0.22,           # darkening at the frame corners (0 = off)
	"grain": 0.03,              # film grain strength (0 = off)
	"fov": 60.0,                # vertical degrees, player camera in the Príncipe scene only
}
```

- `static func principe(overrides := "") -> Dictionary`: a copy of `PRINCIPE` with `overrides` (the `--look-set` value, `key=value` pairs separated by commas) applied. A value keeps the type of its default: float defaults parse with `to_float()`, int defaults with `to_int()`, the String default (`tonemap`) stays a string. Unknown keys, pairs without `=`, non-numeric values for numeric keys and a `tonemap` outside `aces|agx|filmic` are ignored here.
- `static func override_errors(overrides: String) -> PackedStringArray`: the offending `key=value` pairs that `principe()` ignored (empty when all are valid; empty string in gives empty out).
- `static func apply_principe(env: Environment, sun: DirectionalLight3D, sky_mat: ShaderMaterial, p: Dictionary) -> void`:

```gdscript
	# Tonemap
	env.tonemap_mode = {"aces": Environment.TONE_MAPPER_ACES, "agx": Environment.TONE_MAPPER_AGX, "filmic": Environment.TONE_MAPPER_FILMIC}[p.tonemap]
	env.tonemap_exposure = p.exposure
	env.tonemap_white = p.white
	env.tonemap_agx_contrast = p.agx_contrast
	# Grade: saturation up, no sepia. LUT is identity from 0.85 up (evidence whites stay clean).
	env.adjustment_enabled = true
	env.adjustment_saturation = p.saturation
	env.adjustment_contrast = p.contrast
	env.adjustment_color_correction = principe_lut(p.split_tone)
	# Contact occlusion (same values as r05)
	env.ssao_enabled = p.ssao != 0
	env.ssao_radius = 1.1; env.ssao_intensity = 2.2; env.ssao_power = 1.6; env.ssao_detail = 0.6; env.ssao_light_affect = 0.15   # one per line in the real code
	# Bounce and sky occlusion
	env.sdfgi_enabled = p.sdfgi != 0
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = true
	env.sdfgi_energy = p.sdfgi_energy
	# Depth fog (aerial perspective) + light volumetric fog. Neither touches the sky.
	env.fog_density = p.fog_density
	env.fog_aerial_perspective = p.fog_aerial
	env.fog_sun_scatter = 0.1
	env.fog_height = 0.3
	env.fog_height_density = 0.02
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = p.volumetric_fog != 0
	env.volumetric_fog_density = p.volumetric_density
	env.volumetric_fog_albedo = Color(0.9, 0.93, 0.95)
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 64.0
	env.volumetric_fog_ambient_inject = 0.3
	env.volumetric_fog_sky_affect = 0.0
	# Key light
	sun.light_angular_distance = 1.2
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 1.0
	sky_mat.set_shader_parameter("cloud_shade", p.cloud_shade)
	sky_mat.set_shader_parameter("day_gain", p.sky_gain)
```

- `static func principe_lut(split_tone: float) -> GradientTexture1D`: same construction as the LUT in `apply_grade` (offsets `[0.0, 0.18, 0.5, 0.85, 1.0]`, width 256). Each colour is `neutral.lerp(toned, split_tone)`:

| offset | neutral | toned |
|---|---|---|
| 0.0 | (0, 0, 0) | (0.012, 0.016, 0.024) |
| 0.18 | (0.18, 0.18, 0.18) | (0.172, 0.182, 0.196) |
| 0.5 | (0.5, 0.5, 0.5) | (0.508, 0.500, 0.488) |
| 0.85 | (0.85, 0.85, 0.85) | (0.85, 0.85, 0.85) |
| 1.0 | (1, 1, 1) | (1, 1, 1) |

### 2. New `shaders/look_post.gdshader` and `scripts/look_post.gd`

Vignette and grain as one multiply pass on a CanvasLayer below the UI (no screen-texture read).

```glsl
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
```

`scripts/look_post.gd`: `extends CanvasLayer`, preloads `res://scripts/settings.gd` and the shader. `func setup(vignette: float, grain: float) -> void` sets `layer = 1` (the UI is layer 10, `scripts/ui.gd:192`), adds itself to group `"look_post"`, and adds one full-rect `ColorRect` (`mouse_filter = Control.MOUSE_FILTER_IGNORE`, anchors preset full rect) with a `ShaderMaterial` carrying the two uniforms; keep the material in `var material: ShaderMaterial`. `_process`: unless `Settings.reduced_motion`, set `grain_seed` to `floor(Time.get_ticks_msec() / 1000.0 * 24.0)` (grain changes 24 times a second; with reduced motion it stays still).

### 3. `scripts/main.gd`

- Vars near line 108–109 (`_look_sun`, `_look_ambient`): add `var _look := {}   # Look.principe() values; empty with --no-grade`. Keep `_look_sun` and `_look_ambient` (the benchmark and line 1420 read `_look_ambient < 1.0`).
- `_build_environment()` (lines 308–359): replace the two `if not _user_args().has("no-grade"):` blocks. After `env.fog_sky_affect = 0.0` no grade call; after `sun.light_color = Color(1.0, 0.96, 0.88)`:

```gdscript
	var args := _user_args()
	if not args.has("no-grade"):
		var sets := str(args.get("look-set", ""))
		for bad in Look.override_errors(sets):
			printerr("LOOK-SET ERROR: ignored ", bad)
		_look = Look.principe(sets)
		Look.apply_principe(env, sun, sky_mat, _look)
		_look_sun = _look.sun_gain
		_look_ambient = _look.ambient_gain
	we.set_meta("standard_ssao", env.ssao_enabled)
	we.set_meta("standard_sdfgi", env.sdfgi_enabled)
	we.set_meta("standard_volumetric_fog", env.volumetric_fog_enabled)
	we.add_to_group("quality_env")
```

  With `--no-grade` the scene is exactly as today's `--no-grade` (no grade, no cinematic, no post layer, FOV 72).
- `_apply_light()` line 404: the cloud floor fades with darkness so there is no pop when the sun cuts out at 0.95:

```gdscript
	var sun_floor := 0.15 if _look.is_empty() else float(_look.sun_floor) * (1.0 - darkness)
	sun.light_energy = (sun_floor + 1.4 * vis * (1.0 - dens * 0.85)) * (1.0 - night) * _look_sun
```

  Lines 405–406 (energy 0 above darkness 0.95 or at night) stay.
- `_ready` flow, after `add_child(player)` (line ~156) and before `ui = UI.new()`:

```gdscript
	if not _look.is_empty():
		player.camera.fov = _look.fov
		if _look.vignette > 0.0 or _look.grain > 0.0:
			var post := LookPost.new()
			post.setup(_look.vignette, _look.grain)
			add_child(post)
```

  with `const LookPost := preload("res://scripts/look_post.gd")` beside the other preloads (line ~19). `scripts/player.gd:34` stays 72 (Cambridge and departure use it).

### 4. `scripts/settings.gd` `apply_quality()` (lines 188–195)

Low quality also turns SDFGI and volumetric fog off; environments without the metas (Cambridge, departure) are unaffected:

```gdscript
	for node in tree.get_nodes_in_group("quality_env"):
		node.environment.ssao_enabled = false if low else node.get_meta("standard_ssao")
		node.environment.sdfgi_enabled = false if low else node.get_meta("standard_sdfgi", false)
		node.environment.volumetric_fog_enabled = false if low else node.get_meta("standard_volumetric_fog", false)
```

### 5. `project.godot` `[rendering]`

Add `global_illumination/gi/use_half_resolution=true`.

### 6. `tools/look_shots.gd` `_hide_ui()` (line ~41)

Skip layers in group `"look_post"` so captures keep the vignette and grain:

```gdscript
		if not layer.is_in_group("look_post"):
			(layer as CanvasLayer).visible = false
```

### 7. Tests

- `tests/test_graphics_quality.gd` `_check_quality()` (line ~36): inside the `quality_env` loop also check `sdfgi_enabled == (false if low else node.get_meta("standard_sdfgi", false))` and the same for `volumetric_fog_enabled` / `"standard_volumetric_fog"`. After `check(game.env.glow_enabled and game.env.fog_enabled, …)` (line ~107) add `check(not game.env.sdfgi_enabled and not game.env.volumetric_fog_enabled, "low disables SDFGI and volumetric fog")`; after the cycle back to standard (line ~121) add `check(game.env.sdfgi_enabled and game.env.volumetric_fog_enabled, "standard restores SDFGI and volumetric fog")`.
- New `tests/test_look.gd` (`extends SceneTree`, same `check()` / summary / `quit(1 if failures else 0)` pattern as `tests/test_graphics_quality.gd`, summary line `test_look: %d checks, %d failures`). It saves and restores `Settings.quality` / `Settings.reduced_motion` static values it changes and writes no settings file. Acceptance cases:
  1. `Look.principe()` equals `Look.PRINCIPE`; `Look.principe("saturation=1.3,tonemap=agx,sdfgi=0,fov=55")` gives `saturation` 1.3 (float), `tonemap` "agx", `sdfgi` 0 (int), `fov` 55.0, all other keys default; `Look.PRINCIPE` itself is unchanged afterwards.
  2. `Look.override_errors("saturation=1.3")` is empty; `Look.override_errors("bogus=1,tonemap=neon,exposure=abc,novalue")` has 4 entries and `Look.principe()` of the same string equals the defaults; `Look.override_errors("")` is empty.
  3. `Look.principe_lut(1.0)`: gradient colours at offsets 0.85 and 1.0 are exactly grey (r == g == b == offset); at 0.18 blue > red (cool shadows). `Look.principe_lut(0.0)`: every stop is neutral grey.
  4. Main scene instantiated (`load("res://scenes/main.tscn").instantiate()`, added to root, one `process_frame`), then `Settings.quality = "standard"` and `Settings.apply_quality(self)` (the scene may load a saved "low" from the settings file; set the statics after instantiating, here and for `reduced_motion` in case 6): `env.tonemap_mode == TONE_MAPPER_ACES`, `tonemap_white` 5.0, `adjustment_saturation` 1.18, `sdfgi_enabled`, `volumetric_fog_enabled`, `fog_sky_affect == 0.0`, `volumetric_fog_sky_affect == 0.0`, `sun.directional_shadow_blend_splits`, `player.camera.fov` 60.0; exactly one node in group `look_post`, a CanvasLayer with `layer` < `game.ui.layer`.
  5. Sun energy on that scene: after `game._apply_light(1.0, 1.0, 0.0, 0.0)` it is 0.0; after `game._apply_light(0.0, 0.0, 400.0, 1.0)` it is 0.0; after `game._apply_light(0.62, 0.0, -150.0, 0.0)` it is at least `0.3 * 1.8` (floor × gain) and `game.env.ambient_light_energy` is `0.5`; after `game._apply_light(0.97, 0.9, -10.0, 0.0)` it is below `0.3 * 1.8` (the floor fades with darkness).
  6. Grain: with `Settings.reduced_motion = true`, the post material's `grain_seed` is unchanged across 3 `process_frame`s.
  7. Cambridge untouched: `load("res://scenes/cambridge.tscn").instantiate()` added to root, one frame: `chapter.world.environment.environment.adjustment_saturation` is `Look.SATURATION` (0.86), `sdfgi_enabled` false, and no node is in group `look_post` (free the main scene first).

Test: godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_look.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd

While iterating run one suite at a time: `orb-test --host -- godot --headless --path . --script res://tests/test_look.gd`. Run the two suites of the `Test:` line once before handing off. A suite must print no `SCRIPT ERROR` and no shader compile error.

## Hand-off

- Commit on `art/p1-look`, push, open a **draft** PR against `main` titled `Príncipe look v2: lighting, grade, post, FOV (slice step 1)`. Body: what changed, the `Test:` results with times in JST, "Acceptance row: SLICE_PRINCIPE §6 Light / Values (not yet judged: no windowed capture, art director looks 2026-11-16 JST)", and the note "Draft until art acceptance (edd-art)". Do not mark it ready and do not merge.
- Do not edit `docs/`, `art/BIBLE.md`, `scripts/world_builder.gd`, `scripts/cambridge/**`, `tests/benchmark.gd` or the sky shader (another worker edits `tests/benchmark.gd` in parallel).
- Final report: files changed, test output lines, PR number, anything you could not do.
