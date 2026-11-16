# Brief sa0-plumbing: style switch, audition bookmarks and runner

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/style-audition`, branch `art/style-audition` (exists: main 699c81d + the look, matrix, vegetation, ridges, darkroom, dialogue-camera and totality-staging branches merged; never merged to main as it is, no PR). Godot 4.7.2 Forward+, GDScript (tabs), bash.

## Goal

Tooling for a style audition (`docs/design/SLICE_PRINCIPE.md`, top section): three looks rendered in engine on four frames. This task builds only the switch and the capture path. The three looks themselves are written by three later tasks, each in its own files; here they are stubs. With no `--style` argument the game and every existing test behave exactly as before.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot bare: every run goes through `orb-test --host -- <command>` (one headless run at a time). **No windowed Godot runs at all** (so never run `tools/style_audition.sh` or `tools/look_matrix.sh` beyond `sh -n`). No full-suite runs: only the tests named below.
- First command in this worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang).
- Before any `--script` test run, parse what you edited: `orb-test --host -- godot --headless --path . --check-only --script <file.gd>`; a script error in a `--script` run hangs instead of failing.
- Do not sleep or poll. Leave nothing behind (no scratch files; delete `/private/tmp/sa0-*` when done).
- Every time you write down carries its zone (`2026-11-16 04:30 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`. Commit to `art/style-audition` and `git push -u origin art/style-audition`. No PR.

## 1. New `scripts/style.gd`

```gdscript
extends RefCounted
## Style audition (docs/design/SLICE_PRINCIPE.md, Owner direction 2026-11-16).
## --style=<id> picks one look; --style-set=key=value,key=value overrides single
## values of that look's PARAMS. Without --style nothing here runs.

const STYLES := {
	"silver": "res://scripts/styles/silver.gd",
	"poster": "res://scripts/styles/poster.gd",
	"engraving": "res://scripts/styles/engraving.gd",
}
const QUAD_GROUP := "style_quad"

var id := ""
var impl: RefCounted            # instance of the style's script
var params := {}                # impl.PARAMS with the overrides applied (all floats)
var quad_material: ShaderMaterial  # set by add_quad()
```

Functions (exact names, the style tasks code against them):

- `static func arg_errors(style_id: String, overrides: String) -> PackedStringArray`: an unknown id gives `["style=<id>"]`; otherwise one entry per bad pair in `overrides` (not `key=value`, key not in that style's `PARAMS`, value not `is_valid_float()`). Empty overrides are fine.
- `static func from_args(args: Dictionary) -> RefCounted`: `args` is `main._user_args()`. No `style` key: return `null`. Print each error as `printerr("STYLE ERROR: ignored ", e)`; an unknown id returns `null`. Otherwise a new instance with `id`, `impl = load(STYLES[id]).new()`, `params = impl.PARAMS.duplicate()` with the valid overrides stored as floats.
- `func apply(main: Node) -> void`: `impl.apply(main, self)`, then `dress_dialogue(main.ui)`.
- `func light(main: Node, contact: float, darkness: float, night: float) -> void`: `impl.light(main, self, contact, darkness, night)`.
- `func add_quad(main: Node, shader: Shader, uniforms := {}) -> ShaderMaterial`: the full-screen pass every style uses:

```gdscript
	var m := ShaderMaterial.new()
	m.shader = shader
	m.render_priority = RenderingServer.MATERIAL_RENDER_PRIORITY_MAX
	for k in params:
		m.set_shader_parameter(k, params[k])
	for k in uniforms:
		m.set_shader_parameter(k, uniforms[k])
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	var mi := MeshInstance3D.new()
	mi.name = "StyleQuad"
	mi.mesh = quad
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	mi.add_to_group(QUAD_GROUP)
	main.add_child(mi)
	quad_material = m
	return m
```

- `func each_material(root: Node, fn: Callable) -> void`: calls `fn.call(material, node)` once per distinct `Material` under `root`: for every `MeshInstance3D` (per surface: `get_active_material(i)`, which covers `material_override`, surface overrides and mesh materials) and every `MultiMeshInstance3D` (`material_override`, else each surface material of `multimesh.mesh`). Skip nulls and nodes in `QUAD_GROUP`.
- `func set_post(main: Node, vignette: float, grain: float) -> void`: the `look_post` CanvasLayer (`scripts/look_post.gd`, group `look_post`). If one exists under `main`, set its two shader parameters; else create it as `main.gd` line 170–172 does. `vignette == 0 and grain == 0` with an existing layer: set both to 0 (do not free it).
- `func dress_dialogue(ui: Node) -> void`: reads `impl.DIALOGUE` (all keys optional): `portrait` (res path), `panel`, `border`, `speaker`, `text`, `mount`, `mount_border` (Colors).
  - `panel`/`border`: `ui.dialog_panel.add_theme_stylebox_override("panel", ui._panel_style(panel, border))` (current values `Color(0.07, 0.06, 0.05, 0.9)`, `Color(0.5, 0.4, 0.26)`, `scripts/ui.gd` line 498, are the defaults when one of the two is missing).
  - `speaker`: `ui.speaker_label.add_theme_color_override("font_color", …)`; `text`: `ui.text_label.add_theme_color_override("default_color", …)`.
  - `portrait`: `ui.cambridge_portraits = true` and `ui.dialogue_portrait.prints_override = {"Eddington": path}`.
  - `mount`/`mount_border`: the portrait's own panel stylebox (`scripts/cambridge/dialogue_portrait.gd` `setup()`, lines 24–29): change `bg_color` / `border_color` on a duplicate and set it again.

## 2. Stubs `scripts/styles/silver.gd`, `poster.gd`, `engraving.gd` (new directory)

Identical apart from the comment line. The style tasks replace them.

```gdscript
extends RefCounted
## Style audition stub: <id>. Replaced by the style's own task.

const PARAMS := {"vignette": 0.22, "grain": 0.03}
const DIALOGUE := {"portrait": "res://assets/portraits/eddington_neutral.jpg"}


func apply(main: Node, style: RefCounted) -> void:
	style.set_post(main, style.params.vignette, style.params.grain)


func light(_main: Node, _style: RefCounted, _contact: float, _darkness: float, _night: float) -> void:
	pass
```

## 3. `scripts/main.gd`

- Line 20 area: `const Style := preload("res://scripts/style.gd")`. Line 119 area: `var _style: RefCounted   # Style; null without --style`.
- `_ready()` (line 144, right after `var args := _user_args()`): `_style = Style.from_args(args)`.
- `_ready()` right after `add_child(ui)` and `ui.process_mode = …` (lines 176–178): `if _style != null: _style.apply(self)`.
- `_apply_light()` (lines 417–442), as its last statement: `if _style != null and not world.is_empty(): _style.light(self, contact, darkness, night)`. Check that `world` is filled before the first `_apply_light` call that can reach this line; if `_apply_light` can run before `_ready()` reaches the `apply` call, also guard with a member `_style_applied` set after `apply`.
- Nothing else in `main.gd`.

## 4. `scripts/world_builder.gd` (groups only, no visual change)

- `_ground()` (line 303): `mi.add_to_group("ground")` on the ground `MeshInstance3D`.
- `npc()` (line 951): `add_to_group("npc")` on the node it returns.

## 5. `scripts/cambridge/dialogue_portrait.gd`

`var prints_override := {}   # speaker → res path; style audition (scripts/style.gd)`. In `show_entry()`: when `prints_override.has(speaker)`, load that path instead of the `PRINTS` lookup (the null/hide handling stays as it is). Empty dictionary: behaviour unchanged.

## 6. `tests/benchmark.gd`: two audition bookmarks

They are shot **only when named in `--bench-only`**; a run without `--bench-only` shoots exactly the ten bookmarks of today, in today's order.

```gdscript
## Style audition frames (tools/style_audition.sh): shot only when named in --bench-only.
const AUDITION_BOOKMARKS := [
	# The instrument alone: no figure close to the camera.
	["coelostat_still", Vector3(1.5, 0.05, -4.9), Vector3(0.1, 1.15, -6.6), "prep_early"],
	# Eddington small under the shelter, dialogue panel and portrait on screen.
	["dialogue", Vector3(-1.1, 0.05, 3.6), Vector3(-1.1, 1.35, -0.9), "prep_early"],
]
const AUDITION_LINE := "我從早上就盯著那道雲縫。每次我開始相信它，它就合上。"
```

- `_run()` (line 274): the shot list is `_shots(BOOKMARKS)` plus those `AUDITION_BOOKMARKS` whose name is in `only`, appended in that order (so `--bench-only=arrival,coelostat_still,totality_sky,dialogue` gives arrival, totality_sky, coelostat_still, dialogue). `_shots()` must not report an audition name as unknown.
- `coelostat_still`: `main.world.cottingham.visible = false` before the frame, `true` again after `_sample_bookmark`.
- `dialogue`: before the frame `main.ui.visible = true`, `main.ui.hud.visible = false`, `main.ui.cambridge_portraits = true`, `main.ui.play([{"s": "Eddington", "t": AUDITION_LINE}])`, then `await _frames(4)`. After `_sample_bookmark`: leave no dialogue behind (`main.ui.dialog_active()` false, the pending sequence cleared without emitting `dialogue_done`, `Input.mouse_mode` as before, `main.ui.visible = false`). The line is one that `scripts/content.gd` line 17 already has; do not add a locale key (it is passed as the already-translated text).
- `_light()` and everything else unchanged. `tests/benchmark_cambridge.gd` extends this script: it must behave as before.

## 7. `tools/look_matrix.sh` (one line) and new `tools/style_audition.sh`, `tools/style_audition.tsv`

- `look_matrix.sh` line 38: the success test also fails on `STYLE ERROR` (`! grep -qE 'LOOK-SET ERROR|STYLE ERROR' …`).
- `tools/style_audition.tsv`:

```
# variant	extra user args (after --); tuned by the art director
silver	--style=silver
poster	--style=poster
engraving	--style=engraving
```

- `tools/style_audition.sh <out dir> [variants.tsv]` (bash, `set -u`, executable, same header style as `look_matrix.sh`):
  1. `ONLY=${ONLY:-arrival,coelostat_still,totality_sky,dialogue} tools/look_matrix.sh "$1" "${2:-tools/style_audition.tsv}"`; keep its exit code but go on to the sheets when at least one variant directory has PNGs.
  2. For each variant directory that has all four frames: `magick montage arrival.png coelostat_still.png totality_sky.png dialogue.png -tile 2x2 -geometry 1280x720+8+8 -background '#202020' "$OUT/sheets/style-<variant>.jpg"`.
  3. `side-by-side.jpg`: rows = the four frames in that order, columns = the variants in TSV order, tiles 853x480 `+6+6`, same background. No `-label` (this host's ImageMagick has no font).
  4. Print the sheet paths and a last line with the time (`date '+%F %H:%M %Z'`). JPEG quality 92.

## 8. New `tests/test_style.gd` (SceneTree script, same `check()` pattern as `tests/test_look.gd`)

- `arg_errors`: unknown id; bad pairs (`bogus=1`, `vignette=abc`, `novalue`); valid pair; empty.
- `from_args({})` is null; `from_args({"style": "silver", "style-set": "vignette=0.4"})` has `id == "silver"`, `params.vignette == 0.4` as float, `params.grain` the default; `from_args({"style": "nope"})` is null.
- For each of the three ids: the script loads, has `PARAMS`, `DIALOGUE`, `apply`, `light`.
- `add_quad` on a bare `Node3D` (use any existing shader, e.g. `res://shaders/sun_crescent.gdshader`): one `MeshInstance3D` named `StyleQuad` in `QUAD_GROUP`, `render_priority` max, a param from `params` and one from `uniforms` readable through `get_shader_parameter`.
- `each_material`: a small tree with two `MeshInstance3D` sharing one material, one with a surface override, and one `MultiMeshInstance3D`: each distinct material visited once; the quad skipped.
- Main scene with a style: set the user args the way `tests/test_look.gd` or `tests/test_totality.gd` drive `main` (read them first; if they cannot pass user args, instance `res://scenes/main.tscn`, and after `_ready` call `Style.from_args({"style": "silver"})`, assign it to `main._style` and call `apply(main)` yourself): the `look_post` layer has `vignette` 0.22; `main._apply_light(0.62, 0.0, -150.0, 0.0)` runs without error; `main.ui.dialogue_portrait.prints_override` has the `Eddington` key; the ground node is in group `ground`; two nodes are in group `npc`.
- Benchmark selection (pure functions, no scene): with `only = ["arrival", "dialogue"]` the audition bookmark is selected and no unknown-name error is raised; with `only` empty the list equals `BOOKMARKS`.
- Last line `test_style: <n> checks, <f> failures`, exit code 1 on failures.

## 9. Report (in the final report, no committed file)

- Headless smoke of the whole path, once per style id: `orb-test --host -- sh -c 'godot --headless --path . -- --benchmark=/private/tmp/sa0-smoke --seed=7 --style=silver --bench-only=arrival,coelostat_still,totality_sky,dialogue > /private/tmp/sa0-smoke.log 2>&1; echo exit=$?; grep -cE "SCRIPT ERROR|STYLE ERROR|LOOK-SET ERROR" /private/tmp/sa0-smoke.log; grep -c "\[BENCH\]" /private/tmp/sa0-smoke.log'` → `exit=0`, `0`, `4`. (Headless saves no images; that is expected.) Use a `perl -e 'alarm shift; exec @ARGV' 300` guard in front of `godot` as `look_matrix.sh` does.
- A table for the art director to choose the totality frame's cloud: for seed 7, `sim.cloud_over_sun(t)` for `t = 0, 10, …, 300` (one headless run of a throwaway script or a temporary print; nothing committed). Paste the 31 values.
- `git diff --stat main...HEAD -- scripts tests tools | tail -n 1` and the commit hash pushed.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; for t in test_style test_look test_bench_stats test_totality test_dialogue_camera test_benchmark_cambridge; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 300 godot --headless --path . --script res://tests/$t.gd || exit 1; done'

Acceptance cases:
- Without `--style`: `main._style` is null, no `StyleQuad` exists, a benchmark run without `--bench-only` lists the same ten bookmarks as before.
- `--style=silver --style-set=vignette=0.4`: the `look_post` vignette is 0.4. `--style=nope` or `--style-set=bogus=1` prints one `STYLE ERROR:` line each and the run goes on.
- The three smoke runs give `exit=0`, `0`, `4`.
- The six suites in the `Test:` line pass.
