# p3-ridges follow-up 2: round 1 judged, not accepted. Reshape the skyline (2026-11-15 18:1x JST, edd-art)

Same worktree and branch (`/Users/tachikoma/Developer/eddington-1919-wt/p3-ridges`, `art/p3-ridges`, head 487aefa, not pushed yet). The original brief `.claude/briefs/p3-ridges.md` (host rules, hand-off, files not to touch) still holds, except where this file says otherwise. Everything is decided below; anything still open that changes behaviour, data, a public interface or scope comes back as a last line `DECISION: <question; options; recommendation>`.

## What I saw in `panorama.jpg` / `silhouette.jpg` (487aefa)

1. The two towers are flat-topped mesas about 100 m wide and 55 m high. They must read as volcanic plugs: taller than wide, steep, lopsided.
2. Sawtooth "conifers" on `ridge_near` near bearings 297° and 348°. Cause: `build_ridges.py:32`, the canopy phase is `radius*t`, so its frequency climbs with `t` and aliases against the 0.75° columns.
3. The low sector is a ruler line for 70°: `build_ridges.py:33–34` blend to exactly radius 100 and height 5.
4. Dark blotches on the slopes (52° and 270° views). Cause: `build_ridges.py:57` pushes each row radially with its own phase by up to 0.12·H, more than the row spacing, so rows cross.
5. Outside the massif the crest lines are long straight ramps (noise periods 72°/36°/24° only), and the massif top is a flat line at 95 m.
6. Near, mid and far rings have the same value in the lit render, so depth cannot be judged.

## Decisions on the two blocked items

- G2 `names_prefixed`: rename the three objects to `principe_ridges_near`, `principe_ridges_mid`, `principe_ridges_far` (build script, `tests/test_ridges.gd` case 1). No exemption.
- G2 `origin_bottom_centre`: in `art/assets.toml` `[asset.principe_ridges]` add `skip_checks = ["origin_bottom_centre"]  # terrain ring: the feet sit at -2 m so the ring tucks under the ground plane` (same form as the `eddington` entry). Update `dims_m` to the new measured bounds.
- Palette: in `art/palette.toml` change `[swatch.eye_white]` `hex = "#D8CFC2"` to `hex = "#D1C8BC"` (BIBLE §4 cap; decided on #316, and `art/p7-darkroom` carries the identical line: keep it byte-identical, touch nothing else in that block). Then `orb-test --image python:3.12-slim -- python3 -I art/pipeline/palette_to_gd.py` and commit the regenerated `scripts/palette.gd`. Do this first: it is a light run and does not need the heavy queue.

## Geometry changes (`art/pipeline/blender/build_ridges.py`; numbers in Godot space as in the brief)

a. **Crest detail, all rings.** Extend `noise()` with two more octaves that close round the ring, `0.22*sin(27*t + …)` and `0.12*sin(52*t + …)`, renormalised to stay within ±1. The H ranges of the brief's table still hold outside the features.

b. **Canopy billows on the near ring** (replaces the `sin(2π·radius·t/8)` term): phase from the accumulated arc length along the crest (sum of `radius·Δt`), period 11 m, rounded humps `1.0 * (2*abs(sin(π·s/11)) − 1)` m, so tops are round and the notches between crowns are narrow. Keep it in the low sector too.

c. **Low sector** (the house and Sun view), replacing the flat blend:
   - near: crest radius wanders 97–105 m; crest height including the billows stays within 4.5–7.5 m (base 6.0 m ± 0.5 m slow swell + the ±1.0 m billows); fade into the sector over 20° on each side instead of 14°.
   - mid: H between 9 and 14 m for θ in −70°…−10° (two gentle swells, not a constant); this overrides the brief's "H ≤ 8 m".
   - far: unchanged (H ≤ 30 m), with the detail octaves.

d. **Gullies** (replaces line 57): no radial displacement. On the slope rows (not the crest row, not the two foot rows) lower the height by `0.12 * H * g(θ) * sin(π·|u|)`, where `g(θ)` in 0…1 is one noise per ring (periods about 9° and 4°, the same for every row, so a gully runs straight down the slope). Add an assert in the build: for every column the row radii increase strictly from the front foot to the back foot.

e. **Massif** (far ring, θ 125°…185°): crest between 84 and 96 m carrying the detail octaves, not a constant 95. Pin the far crest radius to 470 m ± 5 m for θ in 128°…180° (blend with the same window).

f. **Towers**: added height above the massif crest as a profile along the crest, `x` in metres (`x = (θ − θc)·π/180·470`, positive toward increasing bearing), piecewise linear through the points, then one `[1, 2, 1]/4` smoothing pass over the columns:
   - θc = 140° (top about 160 m): `(−44, 0) (−30, 5) (−21, 14) (−15, 34) (−11, 52) (−7, 61) (−3, 65) (2, 65) (6, 60) (9, 44) (11, 20) (14, 8) (24, 0)`
   - θc = 168° (top about 128 m): `(−30, 0) (−20, 4) (−13, 12) (−9, 26) (−5, 32) (0, 33) (4, 30) (7, 20) (10, 8) (18, 0)`
   The far ring uses 0.25° columns for θ in 120°…190° and 0.75° elsewhere (about 667 columns; the other two rings stay at 480). Whole GLB still ≤ 30 000 triangles.

## Render changes (`render_ridges.py`, `ridges.sh`)

- Lit views only: haze preview. Give each ring its own render material, the swatch colour mixed toward the world colour `#C9D2D6` by 0.12 (near), 0.38 (mid), 0.62 (far). Render-only; the GLB materials are not changed.
- Two extra frames, lit and silhouette: camera at the origin 1.6 m up, bearing 152°, pitch +9°, vertical field of view 24°, 1280 × 720. `magick montage` them side by side at full size to `art/validation/p3-ridges/towers.jpg` (lit left, silhouette right). Keep `panorama.jpg` and `silhouette.jpg` as they are built now. Delete the PNGs.

## Tests (`tests/test_ridges.gd`)

- Case 1: the three names above.
- Cases 2–6 unchanged (the open sector stays ≤ 5°, every 10° sector of the near ring ≥ 1.2°, highest point 15°–20° at bearing 130°–150°).
- New case 7 (towers are slender): every ridge vertex higher than 130 m lies within 2.2° of bearing 140°; every ridge vertex higher than 112 m lies within 5° of bearing 140° or within 1.8° of bearing 168°; at least one vertex is higher than 155 m and at least one within 1.8° of bearing 168° is higher than 122 m.

## Order of work

1. Palette step (light), then all edits, then one heavy job: `job-run --id p3-ridges-3 -- orb-test --heavy --host -- art/pipeline/blender/ridges.sh`; end that turn with its `WAIT:` line. The heavy gate may stay closed until Monday 2026-11-16 08:30 JST.
2. A job `p3-ridges-godot` from the last round is still queued for the Godot slot (result: `/Users/tachikoma/.local/state/job-run/p3-ridges-godot/result.json`). Do not queue it again now. When you are resumed after the Blender job, read that result and its log for errors in the test logic, then queue one new Godot job with the `Test:` command below (as one `job-run … -- orb-test --host -- sh -c '…'`) and end with its `WAIT:` line.
3. Then commit (GLB with its `.import`, `art/validation/principe_ridges.g2.json`, the three JPEGs, `scripts/palette.gd`), push, and open the draft PR as in the brief; embed `towers.jpg` as well. If Blender crashes at start-up or G2 fails on any check other than the skipped one, do not retry: report it under Blocked.

Test: godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_ridges.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && godot --headless --path . --script res://tests/test_sim.gd
