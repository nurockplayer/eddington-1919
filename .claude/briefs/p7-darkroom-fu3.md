# p7-darkroom follow-up 3: round 2 judged (art director, 2026-11-15 20:1x JST)

Judged `closeup.jpg`, `props.jpg`, `bench.jpg` at 156b92e. **Tray accepted** (pale wall band, brown liquid): do not touch it, nor the bottle, plate holder, plate rack, plate box. The jug now reads as a jug and the pail rim and bail are right. Three things are left, all in `art/pipeline/blender/build_darkroom_props.py`. No swatch, render-script, `_darkroom()` or test change.

## 1. Pail outer wall renders near black, jug base and belly shade blotchy: vertex normals
`lathe()` (lines 25–32) smooth-shades every face, caps included. On the pail the outer wall is one 23 cm span between the bottom n-gon and the underside of the rim roll, so both of its vertex rings carry normals dragged downward and the whole wall shades as if it faced the floor (inside: grey, outside: charcoal, same `zinc`).
- Add a helper `sharpen(obj, deg)`: mark sharp every edge whose two faces meet at more than `deg` degrees (Blender 5.2: `obj.data.set_sharp_from_angle(angle=math.radians(deg))`), and also every edge of the two cap n-gons (polygons 0 and 1 of a lathe mesh), so the exported normals split there.
- Call it with 75 on the pail lathe body, and on the jug body **after** the spout pinch loop. Not on the bottle: `lathe()` itself stays as it is, so the bottle GLB does not change.
- Self-check in the build (print, and `assert`): the corner normals of the pail's outer wall faces (lathe polygons 2…25) have |z| < 0.3 (expected about −0.15). Report the printed min/max.

## 2. `jug()` inside: the mouth is closed by a disc 3.5 cm down
The inner profile stops at `(.053,.205)` and the cap sits there, so the jug looks full of enamel. Continue the profile down the inside: after `(.053,.205)` add `(.072,.10) (.056,.012)`; the cap is then the floor at z = 0.012. The `iron` band slice `polygons[2+6*24:2+7*24]` stays valid (the new bands come after it).

## 3. `jug()` handle: seven straight segments read as a bent polygon
Resample the path before sweeping: one Catmull-Rom midpoint between each pair of the seven points (13 points, 12 segments), end offsets (−3 mm) applied to the first and last as now. Cross-section, material and flat shading unchanged.

Budgets still hold: jug ≤ 700 triangles (expected about 624), pail unchanged at 580, `max_materials = 3`.

## Run
- One heavy job: `job-run --id p7-darkroom-props-3 -- orb-test --heavy --host -- art/pipeline/blender/darkroom_props.sh` (build, G2 for all seven, three renders); end the turn with its `WAIT:` line. Then the Godot line below through `job-run --id p7-darkroom-godot-3`.
- Commit the two regenerated GLBs (`dr_pail`, `dr_jug`), any changed `.import` files, the G2 reports and the three JPEGs; push to `art/p7-darkroom`; PR #344 stays **draft**; update the three images and the jug triangle count in the PR body.
- Limits as before: 16 GB shared Mac, Blender and Godot only through `orb-test`, no windowed runs, no sleeping or polling inside the run; every time written down carries `JST`.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_darkroom_props.gd && godot --headless --path . --script res://tests/test_darkroom_lantern.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd'

Acceptance cases: G2 passes for all seven; in `closeup.jpg` the pail's outer wall is the same grey family as its inside, with a light-to-dark turn round it (not a flat charcoal), the jug mouth shows a deep interior instead of a disc, the handle is a smooth curve; the pail normal self-check passes; `dr_tray`, `dr_bottle`, `dr_plate_holder`, `dr_plate_rack`, `dr_plate_box` GLBs are byte-identical to 156b92e.
