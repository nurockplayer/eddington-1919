# Brief p7-darkroom: darkroom props (Blender kit builds) and their placement

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p7-darkroom`, branch `art/p7-darkroom` (already created from origin/main a88f496). Godot 4.7.2 (GDScript, tabs), Blender 5.2 headless.

## Goal

The Príncipe darkroom is an empty hut: three flat boxes stand in for the developing trays (`scripts/world_builder.gd` `_darkroom()`, lines 512–565). Build seven small period props with the existing procedural kit and place them in the hut. Slice plan step 7 (`docs/design/SLICE_PRINCIPE.md` §4). All of it is RECONSTRUCTION (a generic 1919 field darkroom).

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot, Blender, Python or tests bare.
  - First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang). Run it again after new GLBs exist.
  - One headless suite at a time: `orb-test --host -- godot --headless --path . --script res://tests/<x>.gd`. No windowed Godot, no full-suite runs.
  - Blender only through the heavy queue, detached: `job-run --id p7-darkroom-<n> -- orb-test --heavy --host -- art/pipeline/blender/darkroom_props.sh`. The queue can take a long time (one heavy job on the whole Mac). Do not sleep or poll: end that turn's report with the `WAIT:` line job-run prints; you are resumed with the result. Put all builds, validations and renders of one iteration in that one script so each iteration costs one queue wait. If Blender crashes at start-up, do not retry: report it under Blocked.
  - Python: `orb-test --image python:3.12-slim -- python3 -I <script>`.
- Leave nothing behind (no scratch files, no settings files).
- Every time you write down carries its zone (`2026-11-14 14:40 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## Changes

### 1. `art/palette.toml`: five swatches appended at the end of the file

```toml
[swatch.enamel]
hex = "#C8C5B8"
role = "structure"
roughness = 0.35

[swatch.amber_glass]
hex = "#3A2412"
role = "structure"
roughness = 0.12

[swatch.tray_liquid]
hex = "#1E1A16"
role = "structure"
roughness = 0.08

[swatch.plate_dark]   # developed negatives in the rack: dim on purpose, set dressing must not outshine the evidence plate
hex = "#2A2826"
role = "structure"
roughness = 0.15

[swatch.zinc]
hex = "#6E7273"
role = "structure"
roughness = 0.5
metallic = 0.6
```

Regenerate `scripts/palette.gd` with `art/pipeline/palette_to_gd.py` (never edit it by hand).

### 2. `art/pipeline/blender/build_darkroom_props.py` (new; same structure as `build_packing_crate.py`, uses `kit.py` only)

One GLB per prop in `assets/models/`, one joined object per GLB named like the file, origin at bottom-centre, front toward −Y in Blender. Sizes are Blender metres, X × Y × Z. Soft bevels, smooth shading on round forms (no visible facets at 1 m: 24 or more segments round, smooth normals).

| id | size | parts and materials | tri budget |
|---|---|---|---|
| `dr_tray` | 0.34 × 0.28 × 0.05 | developing tray: thin walls sloping out from a 0.30 × 0.24 bottom, rounded corners, rolled rim; body `enamel`, rim `iron`, a liquid surface 1 cm below the rim `tray_liquid` | 400 |
| `dr_bottle` | Ø 0.09 × 0.24 | chemical bottle: straight body to 0.15, round shoulder to a Ø 0.035 neck, lip, cork; glass `amber_glass`, cork `pine`, a plain 0.05 × 0.06 paper label on the front `canvas` (no text) | 500 |
| `dr_plate_holder` | 0.32 × 0.27 × 0.03 | plate holder (dark slide) lying flat: frame `teak_dark`, inset slide panel `ebonite`, four corner clips and a pull tab at one short end `brass` | 300 |
| `dr_plate_rack` | 0.30 × 0.16 × 0.23 | drying rack: base and two grooved end rails `teak`, six glass plates 0.254 × 0.003 × 0.203 standing on their long edge, 22 mm apart, leaning 6° `plate_dark` | 600 |
| `dr_pail` | Ø 0.28 × 0.26 | open zinc pail: Ø 0.20 bottom, rolled rim, inner wall visible, wire bail handle resting to one side; `zinc` | 600 |
| `dr_jug` | Ø 0.16 × 0.24 | enamel jug: lathe body, pinched spout, strap handle; body `enamel`, rim and handle edge `iron` | 700 |
| `dr_plate_box` | 0.30 × 0.24 × 0.07 | plate box: body and lift-off lid with a visible seam `pine`, plain paper label on the lid `canvas` (no text) | 150 |

Add one `[asset.<id>]` entry each to `art/assets.toml` after the `packing_crate` entry (category `kit_prop`, `source = "blender_procedural"`, `build`, `export`, `dims_m` as above, `dims_tolerance = 0.10`, `tri_budget`, `max_materials = 3`, `max_texture_px = 0`, `history = "RECONSTRUCTION: generic 1919 field darkroom …"`, `status = "validated"`).

### 3. `art/pipeline/blender/render_row.py` (new) and `art/pipeline/blender/darkroom_props.sh` (new)

- `render_row.py -- <out.png> <glb> [<glb> …]`: imports the GLBs side by side on a mid-grey floor (spacing from their bounding boxes), one soft sun from upper left plus a dim world light, EEVEE, a three-quarter camera fitted to the row, 1600 × 600.
- `darkroom_props.sh`: (a) `blender -b --factory-startup -P art/pipeline/blender/build_darkroom_props.py`; (b) G2 for each of the seven: `blender -b --factory-startup -P art/pipeline/blender/validate.py -- assets/models/<id>.glb <id>` (writes `art/validation/<id>.g2.json`); (c) `render_row.py` of all seven to `art/validation/p7-darkroom/props.png`, then a second render `bench.png`: three trays in a row with three bottles behind them and the jug at the right, lit by one warm point light (colour 1.0, 0.80, 0.58) from above right, dark background; (d) convert both to JPEG quality 88 with `magick` and delete the PNGs. Exit non-zero if any step fails.

### 4. `scripts/world_builder.gd` `_darkroom()` only (lines 512–565)

`c` is the hut centre `Vector3(10, 0, 3)`. Use `model(id, pos, rot_y_deg)` (line 33); each placed prop gets `add_to_group("darkroom_props")` and a `name`. No colliders. Positions are `c +`:

| name | id | position | yaw ° |
|---|---|---|---|
| `DrTray0`, `DrTray1`, `DrTray2` | `dr_tray` | (−0.28, 0.88, −1.3), (0.17, 0.88, −1.3), (0.62, 0.88, −1.3) | 4, −3, 2 |
| `DrBottle0`–`DrBottle2` | `dr_bottle` | (−0.40, 0.88, −1.53), (−0.05, 0.88, −1.54), (0.40, 0.88, −1.53) | 20, 140, 260 |
| `DrBottle3` | `dr_bottle` | (1.70, 1.025, −1.22) | 80 |
| `DrPlateRack` | `dr_plate_rack` | (1.66, 1.025, −0.32) | 90 |
| `DrPlateHolder` | `dr_plate_holder` | (1.64, 1.025, 0.03) | 90 |
| `DrPail` | `dr_pail` | (−0.25, 0.04, −1.3) | 30 |
| `DrJug` | `dr_jug` | (0.30, 0.04, −1.35) | −40 |
| `DrPlateBox0`, `DrPlateBox1` | `dr_plate_box` | (0.72, 0.04, −1.3), (0.72, 0.11, −1.3) | 0, 12 |

The tray loop at lines 534–535 becomes: try the model; only when `model()` returns null keep today's flat box at today's position (`dx` in −0.35, 0.15, 0.6). The other props are simply skipped when their model is missing. Nothing else in `_darkroom()` changes: the plate box interactable, the measuring table and sheet, both lights, the lantern and the returned positions stay exactly as they are.

### 5. Tests

New `tests/test_darkroom_props.gd` (`extends SceneTree`, same `check()` / summary / `quit(1 if failures else 0)` pattern as `tests/test_graphics_quality.gd`; summary line `test_darkroom_props: %d checks, %d failures`). Main scene instantiated (`load("res://scenes/main.tscn").instantiate()`, added to root, one `process_frame`). Acceptance cases:
1. Group `darkroom_props` has exactly 13 nodes; three names begin with `DrTray`, four with `DrBottle`, two with `DrPlateBox`.
2. Every prop's `global_position` is inside the hut: x in 8.0–12.0, z in 1.3–4.7, y in 0.0–1.1.
3. No prop stands over the measuring table: none with x in 10.0–11.2 and z in 3.7–4.5.
4. `game.world.plate_box_pos` is `Vector3(11.65, 1.18, 2.25)` and `game.world.measure_pos` is `Vector3(10.6, 0.82, 4.1)` (unchanged).
5. Evidence stays the brightest thing: no surface material under a prop has an albedo with HSV value above 0.82.
6. No `StaticBody3D` under any prop.

Test: godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_darkroom_props.gd && godot --headless --path . --script res://tests/test_darkroom_lantern.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd

While iterating run one suite at a time through `orb-test --host --`. A suite must print no `SCRIPT ERROR`.

## Hand-off

- Commit on `art/p7-darkroom` (GLBs with their `.import` files, `art/validation/*.g2.json`, the two JPEGs), push, open a **draft** PR against `main` titled `Darkroom props: trays, bottles, plate rack, pail (slice step 7)`. Body: what changed, the seven G2 results, the `Test:` results with times in JST, both JPEGs embedded by their repo path on the branch, "Acceptance row: SLICE_PRINCIPE §6 Light (nothing self-lit) / Fidelity; not yet judged in game", and "Draft until art acceptance (edd-art)". Do not mark it ready and do not merge.
- Do not edit `docs/`, `art/BIBLE.md`, `scripts/main.gd`, `scripts/look.gd`, `art/pipeline/blender/kit.py`, `art/pipeline/blender/validate.py`, or any function of `scripts/world_builder.gd` other than `_darkroom()` (other workers edit other functions of that file in parallel).
- Final report: files changed, G2 lines, test output lines, PR number, anything you could not do.
