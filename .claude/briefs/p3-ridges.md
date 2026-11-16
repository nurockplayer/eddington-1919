# Brief p3-ridges: sculpted ridgelines replace the hemisphere hills (Príncipe slice, terrain)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p3-ridges`, branch `art/p3-ridges` (already created from origin/main a88f496). Godot 4.7.2 (GDScript, tabs), Blender 5.2 headless.

## Goal

The far hills of the Príncipe scene are five `SphereMesh` hemispheres (`scripts/world_builder.gd` `_sea_and_hills()`, lines 390–407). Replace them with three rings of sculpted ridgeline, built procedurally in Blender, that close the view all round the camp: a near forested ridge, a middle range and a far massif with two steep rock towers (Príncipe's phonolite plugs) behind the camp. Depth fog already in the scene hazes them by distance. Slice plan step 3 (`docs/design/SLICE_PRINCIPE.md` §4). RECONSTRUCTION: the skyline is composed, not surveyed.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot, Blender, Python or tests bare.
  - First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang). Run it again after the GLB exists.
  - One headless suite at a time: `orb-test --host -- godot --headless --path . --script res://tests/<x>.gd`. No windowed Godot, no full-suite runs.
  - Blender only through the heavy queue, detached: `job-run --id p3-ridges-<n> -- orb-test --heavy --host -- art/pipeline/blender/ridges.sh`. The queue can take a long time (one heavy job on the whole Mac). Do not sleep or poll: end that turn's report with the `WAIT:` line job-run prints; you are resumed with the result. Put build, validation and renders in that one script so each iteration costs one queue wait. If Blender crashes at start-up, do not retry: report it under Blocked.
  - Python: `orb-test --image python:3.12-slim -- python3 -I <script>`.
- Leave nothing behind (no scratch files, no settings files).
- Every time you write down carries its zone (`2026-11-14 14:40 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## Geometry (all numbers in Godot space: Y up, metres, camp at the origin)

Bearing θ is measured in the ground plane from −Z, turning toward +X: the direction of bearing θ is `(X, Z) = (sin θ, −cos θ)`. (Blender is Z-up and the glTF exporter maps Blender `(x, y, z)` to Godot `(x, z, −y)`; build so the exported file matches the numbers here.) The plantation house and the eclipse Sun both stand at θ ≈ −38°; that sector stays low and open.

Three objects in one GLB `assets/models/principe_ridges.glb`, each a closed ring strip round the origin with its object origin at (0, 0, 0), named `ridge_near`, `ridge_mid`, `ridge_far`. Each ring: 480 columns (0.75° each) × 9 rows across the ridge: foot toward the camp at Y = −2, a concave front slope, the crest, a back slope down to Y = −2. Smooth shading, no flat-shaded facets, no holes. Deterministic (fixed seeds): two builds give the same file.

Crest height H(θ) = base range from low-frequency noise (2–3 octaves, period of the first octave about 70°) + the authored features below, blended with smooth (cosine) windows. Slopes carry gullies: displace the slope rows along the ring with noise whose amplitude grows from 0 at the crest to about 12 % of the crest height at mid-slope.

| ring | crest radius | front foot radius | crest height H | features |
|---|---|---|---|---|
| `ridge_near` | 95–130 m (wanders with noise) | never under 76 m | 7–16 m | canopy texture on the crest: extra noise of 6–10 m period, ±1.2 m. Low sector: H between 4.5 and 5.5 m and crest radius 95–105 m for θ in −60°…−15° (low, but still above eye height so the sea never shows) |
| `ridge_mid` | 200–260 m | never under 170 m | 22–45 m | two broad hills centred at θ = 60° (H 45 m) and θ = 205° (H 40 m). Low sector: H ≤ 8 m for θ in −70°…−10° |
| `ridge_far` | 420–520 m | never under 380 m | 40–70 m outside the massif | massif for θ in 110°…200°: H rises to 95 m, with two steep towers on it: θ = 140°, top at 150 m, base about 90 m wide, near-vertical upper flanks, slightly rounded top; θ = 168°, top at 120 m, base about 70 m wide. Low sector: H ≤ 30 m for θ in −70°…−10° |

Materials (palette only, via `kit.mat`): `ridge_near` uses a new swatch `hill_near`; `ridge_mid` and `ridge_far` use the existing `hill_far`. Add to `art/palette.toml` directly after the `[swatch.hill_far]` block (not at the end of the file: another worker appends there):

```toml
[swatch.hill_near]
hex = "#3A5236"
role = "far"
roughness = 0.9
```

Regenerate `scripts/palette.gd` with `art/pipeline/palette_to_gd.py` (never edit it by hand). Triangle budget for the whole GLB: 30 000.

## Files

1. `art/pipeline/blender/build_ridges.py` (new; uses `kit.py` for materials, reset and export; mesh built with `from_pydata` like `build_packing_crate.py` `corner_strap`).
2. `art/assets.toml`: `[asset.principe_ridges]` after the `sun_shelter` entry: `category = "architecture"`, `source = "blender_procedural"`, `build`, `export`, `dims_m` from the measured bounds, `tri_budget = 30000`, `max_materials = 2`, `max_texture_px = 0`, `history = "RECONSTRUCTION: composed skyline; the two towers stand for Príncipe's phonolite plugs."`, `status = "validated"`. G2 (`validate.py`) must pass; if one of its checks cannot apply to a ring of terrain, do not change `validate.py`: report the check under Blocked.
3. `art/pipeline/blender/render_ridges.py` (new): imports the GLB, adds a flat disc of radius 70 m at height 0 in `#3F5A2A`, a plain world colour `#C9D2D6`, a sun at 56° altitude from bearing −38°; camera at the origin, 1.6 m up, 60° vertical field of view, 1280 × 720, EEVEE. Renders six views, looking horizontally (pitch +6°) toward bearings −37, −20, 52, 142, 200 and 270: `art/validation/p3-ridges/view_<bearing>.png`; then the same six with every ridge material replaced by flat unlit `#101418` (silhouette).
4. `art/pipeline/blender/ridges.sh` (new): build → G2 (`blender -b --factory-startup -P art/pipeline/blender/validate.py -- assets/models/principe_ridges.glb principe_ridges`) → renders → `magick montage` of the six lit views (3 columns, each tile 640 × 360, labelled with the bearing) to `art/validation/p3-ridges/panorama.jpg` and of the six silhouettes to `silhouette.jpg`; delete the PNGs. Exit non-zero if any step fails.
5. `scripts/world_builder.gd` `_sea_and_hills()` only (lines 390–407). After the sea is added:

```gdscript
	var ridges := model("principe_ridges", Vector3.ZERO)
	if ridges:
		ridges.name = "FarRidges"
		ridges.add_to_group("far_ridges")
		for mi in ridges.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		for i in 5:
			randf()  # the hemispheres drew five values: keep the global RNG stream as it was
		return
```

   The hemisphere loop stays below as the fallback when the GLB is missing.

## Tests

New `tests/test_ridges.gd` (`extends SceneTree`, same `check()` / summary / `quit(1 if failures else 0)` pattern as `tests/test_graphics_quality.gd`; summary line `test_ridges: %d checks, %d failures`). Main scene instantiated (`load("res://scenes/main.tscn").instantiate()`, added to root, one `process_frame`). Read vertices with `mesh.get_faces()` transformed by the instance's global transform; elevation of a vertex = `atan2(y − 1.6, horizontal distance from the origin)`. Acceptance cases:
1. Group `far_ridges` has one node with exactly three `MeshInstance3D` descendants named `ridge_near`, `ridge_mid`, `ridge_far`; no `MeshInstance3D` in the scene has a `SphereMesh` with radius 26 or more (the hemispheres are gone).
2. No ridge vertex is closer than 75 m to the origin (horizontal distance).
3. Skyline height: the highest elevation over all ridge vertices is between 15° and 20°, and it lies at a bearing between 130° and 150° (the tall tower).
4. Open sector: for vertices with bearing in −60°…−15°, the highest elevation is at most 5°.
5. Closed horizon: for each of the 36 ten-degree bearing sectors, the highest elevation of `ridge_near` vertices is at least 1.2°.
6. Every ridge mesh has `cast_shadow` off and `gi_mode` disabled; the three meshes together have at most 30 000 triangles.

Test: godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_ridges.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && godot --headless --path . --script res://tests/test_sim.gd

While iterating run one suite at a time through `orb-test --host --`. A suite must print no `SCRIPT ERROR`.

## Hand-off

- Commit on `art/p3-ridges` (the GLB with its `.import` file, `art/validation/principe_ridges.g2.json`, the two JPEGs), push, open a **draft** PR against `main` titled `Sculpted ridgelines replace the hemisphere hills (slice step 3)`. Body: what changed, the G2 result, the `Test:` results with times in JST, both JPEGs embedded by their repo path on the branch, "Acceptance row: SLICE_PRINCIPE §6 Silhouette and depth (not yet judged in game)", and "Draft until art acceptance (edd-art)". Do not mark it ready and do not merge.
- Do not edit `docs/`, `art/BIBLE.md`, `scripts/main.gd`, `scripts/look.gd`, `tests/benchmark.gd`, `art/pipeline/blender/kit.py`, `art/pipeline/blender/validate.py`, or any function of `scripts/world_builder.gd` other than `_sea_and_hills()` (other workers edit other functions of that file in parallel).
- Final report: files changed, the G2 line, test output lines, PR number, anything you could not do.
