# Brief veg-cards: painted alpha-card vegetation for the Príncipe camp

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/veg-cards`, branch `art/veg-cards` (created from `origin/art/p4-leaves` b11b8e4, which holds the painted cut-outs and the picks in `art/runs/p4-leaves/REVIEW.md`).

## Goal

The palm crowns are combs of flat triangles (`scripts/world_builder.gd` `_palm_frond_mesh()` lines 616–647, `palm()` 651–710) and the shrubs are faceted low-poly GLBs (`_vegetation()` 713–759, models `shrub_cocoa` / `banana_clump`). Replace them with alpha cards textured with the picked painted cut-outs, and add a painted forest-edge band round the clearing. **Layout, node structure, groups and RNG use stay exactly as they are**: the pinhole crescents, fireflies, sway, benchmark groups and the layout test depend on them.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot or ImageMagick bare: `orb-test --host -- <command>` (fresh worktree: `godot --headless --path . --import` first, or suites fail or hang). No windowed Godot, no screenshots (the art director renders on Monday).
- Long commands (> 2 min) through `job-run`; end your run with the `WAIT:` line. Never sleep or poll.
- Every time you write down carries its zone (`2026-11-15 14:40 JST`). Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## 1. Install the cut-outs

Copy these from `art/runs/p4-leaves/cut/` to `assets/textures/principe/foliage/` (same file names): `coconut_frond-v1/v2`, `coconut_frond_dry-v1`, `cacao_branch-v1/v2`, `banana_leaf-v1/v2`, `undergrowth-v1/v2`, `forest_edge-v1/v2` (11 PNGs). Import with mipmaps and VRAM compression (`compress/mode=2`, `mipmaps/generate=true`, keep `process/fix_alpha_border=true`); commit the `.import` files, as the repo does for `assets/`. Add `assets/textures/principe/foliage/SOURCES.md` pointing each file to `art/runs/p4-leaves/manifest.jsonl`.

## 2. Card shader

New `shaders/foliage_card.gdshader` (spatial):

- `render_mode cull_disabled;` two samplers `tex_v1`, `tex_v2` (`source_color, filter_linear_mipmap_anisotropic, repeat_enable`), `uniform bool use_custom_variant = false;` (true: `INSTANCE_CUSTOM.r > 0.5` picks `tex_v2`, passed from `vertex()` as a flat varying; false: always `tex_v1`), `instance uniform vec4 tint : source_color = vec4(1.0);`, `uniform float backlight = 0.3;`, `uniform float sway = 0.0;`.
- `fragment()`: `ALBEDO = c.rgb * tint.rgb; ALPHA = c.a; ALPHA_SCISSOR_THRESHOLD = 0.5; ROUGHNESS = 0.9; SPECULAR = 0.2; BACKLIGHT = ALBEDO * backlight;` (alpha scissor, so the cards stay in the opaque pass and cast cut-out shadows).
- `vertex()`: when `sway > 0`, offset `VERTEX.xz` by `sway * max(VERTEX.y, 0.0) * vec2(sin(TIME * 1.3 + w.x * 0.4 + w.z * 0.3), cos(TIME * 1.1 + w.z * 0.35))` with `w` the instance origin in world space (`MODEL_MATRIX[3].xyz`).
- In `world_builder.gd` a helper `_card_mat(key, tex_a, tex_b := "", custom := false, sway := 0.0, backlight := 0.3) -> ShaderMaterial` cached in `_mats`.

## 3. Palm crowns

- Replace `_palm_frond_mesh()` with a card along the **same spine** (26 segments of 0.1 m, pitch from +10° to −65°). Cross-section per spine point: the rib on the spine and two edges `±0.65 m` across (x), each dropped by `0.65 * sin(28°)` and pulled in by `0.65 * (1 − cos(28°))`, so the card is a Λ bent along the rib (not flat). UV: `u` from 0 at the base to 1 at the tip (the cut-out's base is at its left edge), `v` 0 at the −x edge, 0.5 on the rib, 1 at the +x edge. Generate normals; keep the static cache.
- In `palm()`: drop the inline `palm_frond` shader. Leaves `i < 12` use `_card_mat("frond_v1", …coconut_frond-v1.png)` when `(palm_crowns.size() + i) % 2 == 0`, else the `-v2` material; dead leaves (`i >= 12`) use `coconut_frond_dry-v1.png`. Keep **every** `randf()` / `rng` call in the same order; the existing `tint` value becomes `set_instance_shader_parameter("tint", Color.WHITE.darkened(tint))` for every leaf (the dry texture already carries the brown). `sway = 0` (PalmSway already moves the fronds); `backlight = 0.35`.
- Trunk, collision, `palm_crowns`, `PalmSway`, the group `veg_palm` and the child order (trunk first, then leaves) stay unchanged.

## 4. Shrubs (same transforms, new meshes)

In `_vegetation()` keep the loop, its RNG calls, the house exclusion and the per-kind transform lists exactly. Remove the GLB/sphere branch: always build two code meshes and pass them to a new helper `card_multimesh(name, mesh, xforms, group)` that makes one `MultiMeshInstance3D` named `name` (multi-surface mesh, `use_custom_data = true`, instance `j` gets custom `r = j % 2`), in group `veg_shrub`. Names stay **`shrub_cocoa_multi`** and **`banana_clump_multi`**, so `tests/test_sun_crescents.gd` `_check_vegetation_layout()` passes unchanged. Cache both meshes statically.

- `shrub_cocoa` mesh (young cacao with undergrowth at its foot, about 2.0 × 2.0 × 1.6 m at scale 1): a trunk cylinder (radius 0.05 m, 1.1 m tall, 6 sides, `mat(P("teak_dark"))`); four `cacao_branch` cards 1.5 × 1.0 m, each with its stem edge (u = 0) at the trunk at heights 0.9, 1.05, 1.2, 1.35 m, pointing out at yaw 0°, 95°, 185°, 275°, tilted 12° down, vertical plane, UV v = 0 at the top; two crossed `undergrowth` cards 1.2 × 0.82 m standing on y = −0.05 at yaw 30° and 120°. Materials: `_card_mat("cacao", v1, v2, true, 0.03)` and `_card_mat("undergrowth", v1, v2, true, 0.04)`.
- `banana_clump` mesh (about 2.6 m): a pseudo-stem cylinder (radius 0.09 m, 1.5 m, 8 sides, `mat(P("foliage_light").darkened(0.25))`); six `banana_leaf` cards from the stem top: each a strip along an arched spine (10 segments over 1.6 m, pitch +35° at the base to −40° at the tip), 0.65 m wide with a 15° Λ fold like the fronds, at yaw `k * 60° + (k * 17) % 23` degrees for k = 0…5. Material `_card_mat("banana", v1, v2, true, 0.03)`.
- Leave `assets/models/shrub_cocoa.glb`, `banana_clump.glb` and their `art/assets.toml` entries untouched; list them as unused under Follow-ups.

## 5. Forest edge

New `_forest_edge()` called from `build()` right after `_vegetation()`. It uses **no** RNG (deterministic). One `Node3D` named `ForestEdge` in group `veg_forest_edge`, with two `MeshInstance3D` loops, `cast_shadow = SHADOW_CASTING_SETTING_OFF`:

| loop | shape (rounded square centred on the origin) | band | texture |
|---|---|---|---|
| `Front` | half-side 47 m, corner radius 12 m | y −0.6 to 13.0 m | `forest_edge-v1.png` |
| `Back` | half-side 57 m, corner radius 16 m | y −0.6 to 17.0 m | `forest_edge-v2.png` |

- A vertical strip, one column every 2 m of perimeter (corners sampled at the same spacing), front faces toward the origin. Normals: `normalize(horizontal direction to the origin + Vector3.UP)` for every vertex, so every bearing lights alike.
- UV: `v` = 0 at the top of the band and 0.67 at the bottom (the bottom third of the cut-out, cocoa pods and big leaves at near scale, is cropped). `u` = perimeter distance / tile length, tile length = perimeter / N, N = max(3, round(perimeter / (band height × 9))), so the wrap closes on a whole number of tiles.
- **Low sector** (the house and the Sun, bearing −38°; bearing θ measured from −Z toward +X, direction `(sin θ, 0, −cos θ)`): for columns with θ in −62°…−14° move the column down by 55 % of the band height (the ground plane hides what sinks), with a cosine ramp over 10° outside each end. Do not squash the texture.
- Material `_card_mat("forest_edge_v1"/"_v2", …, false, 0.0, 0.2)`.

## 6. Test

New `tests/test_vegetation_cards.gd`, in the style of `tests/test_sun_crescents.gd` (build the world the same way; `check()` lines; exit code):

1. Every frond under every `veg_palm` node is a `MeshInstance3D` whose material uses `res://shaders/foliage_card.gdshader`; fronds 0–11 sample a `coconut_frond-v1/v2.png` texture, every frond ≥ 12 `coconut_frond_dry-v1.png`; both frond variants occur; `wb.palm_crowns.size() == 15`.
2. The frond mesh is not planar: its rib vertices sit above both edge vertices at the same spine index.
3. `veg_shrub` holds exactly `shrub_cocoa_multi` (45 instances) and `banana_clump_multi` (21), each with `use_custom_data` and custom `r` alternating 0/1, and every surface material uses the card shader or a palette `mat()`.
4. `ForestEdge` exists with `Front` and `Back`, shadows off; every vertex has horizontal distance ≥ 46 m from the origin and |x|, |z| ≤ 57.5 m; for columns with θ in −50°…−25°, the top vertex y ≤ 0.45 × band top + 0.1; the `v` range is 0…0.67.
5. Building the world twice gives identical `ForestEdge` vertex arrays.

Test: orb-test --host -- bash -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_vegetation_cards.gd && godot --headless --path . --script res://tests/test_sun_crescents.gd && godot --headless --path . --script res://tests/test_fireflies.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd'

Acceptance cases: the five test checks; `tests/test_sun_crescents.gd` passes **unchanged** (layout and crowns preserved); no other test file edited; `--bench-hide=veg_palm,veg_shrub,veg_forest_edge` still hides all vegetation.

## Hand-off

- Commit on `art/veg-cards`, push, open a **draft** PR against `main` titled `Paint the Príncipe vegetation as alpha cards` (body: what changed, the p4-leaves picks it installs, that it stays draft until the art director accepts renders, the unused GLBs as follow-up). Do not run the review gate.
- Do not edit `docs/`, `art/`, `tools/`, `scripts/palm_sway.gd`, `scripts/sun_crescents.gd`, `scripts/fireflies.gd`, `weather()` or any existing test.
- Final report: files changed, triangle counts of the frond, shrub and banana meshes and of each forest loop, the test output lines, anything you could not do.
