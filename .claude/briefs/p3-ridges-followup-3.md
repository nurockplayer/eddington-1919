# p3-ridges follow-up 3: round 2 judged (art director, 2026-11-15 20:3x JST)

Judged `towers.jpg`, `panorama.jpg`, `silhouette.jpg` at 328a439. **Accepted as built: both towers, the massif, the crest detail, the gullies, the haze preview, the mid ring.** Do not touch them. Three things are left, in `art/pipeline/blender/build_ridges.py` (`build()`) and `render_ridges.py`. No change to tests, palette, `world_builder.gd` or `assets.toml` (update `dims_m` only if the measured bounds move outside the tolerance).

PR #349 was opened ready; the brief said draft and I have put it back. **It stays draft; do not mark it ready.** Push to `art/p3-ridges` and update the three images in the PR body.

## 1. Far ring, low sector: the skyline is a ruler line for 45°
`build_ridges.py:79` blends the far ring to a constant 28 m, and at 470 m that line stands above the near and mid crests, so in `silhouette.jpg` (−37° and −20° frames) the horizon is dead straight. Replace the constant: `height = height*(1-low) + (22.5 + 3.5*noise(t, 6.1))*low` (19–26 m, so near, mid and far take turns on the skyline).

## 2. Near ring billows: every crown is the same 11 m scallop
Lines 59–63. Make the period and the size wander:
- phase instead of arc: `phase += ds / period`, `period = 11 + 3.5*sin(7*t + 0.6) + 1.5*sin(19*t + 2.1)` metres (6–16 m), `ds` the arc step as now;
- two passes so the ring closes: sum the phase round the whole ring first, then scale every step by `round(total)/total`, so the last column meets the first without a jump;
- `billow = (0.7 + 0.3*sin(13*t + 1.1)) * (2*abs(sin(pi*phase)) - 1)` (crowns 0.4–1.0 m).
The low-sector crest must still stay within 4.5–7.5 m: assert it in the build.

## 3. Dark patches in the lit panorama: find out what they are
In `panorama.jpg` there are dark quads one column wide on the near ring at bearings about −78°, −72° and +15°, and darker blue-grey lumps on the mid ring just above the near crest at about −90°, +11° and +23°. In the game these ridges lie beyond the 60 m shadow distance and do not cast, so the preview must not shade them either: in `render_ridges.py` set `sun.data.use_shadow = False` for the lit views.
- If the patches are gone in the new `panorama.jpg`: say so in the report, nothing else to do.
- If any remain: do **not** reshape anything. Report for one affected column (near ring, bearing −78°) the nine row radii and heights and the face normals of the dark quad, name the cause, and end the report with `DECISION: <cause; options; recommendation>`.

## Run
- One heavy job: `job-run --id p3-ridges-4 -- orb-test --heavy --host -- art/pipeline/blender/ridges.sh`; end that turn with its `WAIT:` line. Then the Godot line below through `job-run --id p3-ridges-godot-4`, again ending with `WAIT:`.
- Commit the GLB (with its `.import` if it changed), `art/validation/principe_ridges.g2.json` and the three JPEGs; push. Whole GLB still ≤ 30 000 triangles, G2 passes with the one skipped check.
- Limits as before: 16 GB shared Mac, Blender and Godot only through `orb-test`, no windowed runs, no sleeping or polling inside the run; every time written down carries `JST`.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_ridges.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && godot --headless --path . --script res://tests/test_sim.gd'

Acceptance cases: in `silhouette.jpg` the −37° and −20° frames show a horizon that rises and falls across the whole low sector (no straight run longer than about 10°); in `panorama.jpg` the near-ring crowns differ in width and height; the towers frame (`towers.jpg`) is unchanged apart from the near-ring crowns; the dark patches are gone or explained; the seven `test_ridges.gd` cases pass unchanged.
