# p7-darkroom follow-up 2: round 1 judged, not accepted yet (art director, 2026-11-15 18:4x JST)

Judged `art/validation/p7-darkroom/props.jpg` and `bench.jpg` at 4ff605e. Bottle, plate holder, plate rack and plate box are accepted as they are: do not touch them. Jug, pail and tray need the changes below (all in `art/pipeline/blender/build_darkroom_props.py`, plus two swatches). Placement in `_darkroom()` and the tests stay as they are.

## 1. `jug()` (lines 88–95): it reads as a vase
The handle torus sits inside the body (a black nub in the render), the spout is one loose triangle, and the body is nearly a cylinder.
- Body profile (r, z), wide belly low, narrow neck, flared lip: `(.060,0) (.068,.008) (.080,.07) (.076,.13) (.058,.19) (.056,.205) (.066,.24)`, then the inner lip `(.062,.24) (.053,.205)` so the wall has thickness at the mouth.
- Spout: delete the triangle. Pinch the lip instead: every vertex with z ≥ 0.20 within ±35° of −Y moves outward along its radius by `0.02 * cos²(angle / 35° * 90°)` and up by a fifth of that. Build the `iron` rim as a thin band on the same displaced top ring (outer lip ring to inner lip ring), not as a separate torus, so the rim follows the spout.
- Handle opposite the spout, on +Y: a strap 0.02 wide (X) and 0.004 thick, swept along this path in the YZ plane (y, z): `(.058,.188) (.085,.196) (.108,.180) (.116,.150) (.112,.115) (.098,.088) (.078,.076)`; both ends sink 3 mm into the body. Material `enamel` (the dark line is the rim only).
- `art/assets.toml` `dr_jug`: `dims_m` becomes 0.16 × 0.21 × 0.24 (handle and spout lie along Y).

## 2. `pail()` (lines 80–85): notched rim, bail sunk inside
- Rolled rim in the lathe profile itself, no separate torus (the 4-sided torus cuts through the 24-gon and shows as notches): `(.10,0) (.135,.232) (.141,.236) (.143,.242) (.139,.247) (.133,.245) (.130,.238) (.095,.008)`, smooth.
- Bail: a **half** ring of wire (ring radius 0.142, wire radius 0.004, 14 segments along, 6 round) hinged at (±0.139, 0, 0.240), swung about the X axis 80° from upright toward −Y, so it rests just above the rim on one side, outside the wall. Two ears: boxes 0.012 × 0.004 × 0.024 on the rim at x = ±0.139. All `zinc`.

## 3. `tray()` (lines 41–51) and swatches: the liquid is a black slab
- Liquid surface 2 cm below the rim instead of 1 (z = 0.03; shrink its outline to the inner wall at that height minus 1 mm), so a band of white enamel wall shows all round.
- `art/palette.toml`: `tray_liquid` hex `#54432F` (roughness stays 0.08); `zinc` hex `#7F8483`, roughness 0.55, metallic 0.3 (at 0.6 it goes near black in a dark room). Regenerate `scripts/palette.gd` with the repo's `palette_to_gd.py` as before. If the palette validator rejects a value, report its message and the nearest value it accepts as a `DECISION:` line; do not pick another colour yourself.

## 4. `render_row.py` line 60
Bench light energy 60 → 200: at 60 the enamel and the labels are too dark to judge. Add a third render to `darkroom_props.sh`: `closeup.jpg`, the jug, pail and tray only, same sun set-up as `props.jpg`, 1600 × 600 (they are 150 px wide in the row of seven).

## Run
- One heavy job as before: `job-run --id p7-darkroom-props-2 -- orb-test --heavy --host -- art/pipeline/blender/darkroom_props.sh` (build, G2 for all seven, three renders), end the turn with its `WAIT:` line. The heavy gate opens Monday 2026-11-16 08:30 JST or when the Owner has been away 45 min: just wait. Then the Godot line below through `job-run` (a script error makes a `--script` test hang: if you edit any `.gd`, parse it first with `godot --headless --path . --check-only --script <file>`).
- Commit the regenerated GLBs, their `.import` files, the G2 reports and the three JPEGs; push to `art/p7-darkroom`; PR #344 stays **draft**; add the three images and the triangle counts of jug, pail and tray to the PR body. Tri budgets and `max_materials = 3` still hold.
- Limits as in the brief: 16 GB shared Mac, Blender and Godot only through `orb-test`, no windowed runs; times carry `JST`.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_darkroom_props.gd && godot --headless --path . --script res://tests/test_darkroom_lantern.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd'

Acceptance cases: G2 passes for all seven; in `closeup.jpg` the jug shows a handle loop with daylight through it and a spout on the opposite side, the pail rim is one smooth roll with the bail lying outside it, the tray shows a pale wall band round a brown liquid; the four accepted props are byte-identical GLBs or differ only by export metadata.
