# p7-darkroom follow-up 4: round 3 judged (art director, 2026-11-15 20:5x JST)

Judged `closeup.jpg` and `bench.jpg` at a2fe8c9. **Pail accepted** (grey outside with a light-to-dark turn): do not touch it, nor the tray, bottle, plate holder, plate rack, plate box. Jug mouth depth, belly shading and handle curve are accepted. Two jug defects are left, both in `jug()` in `art/pipeline/blender/build_darkroom_props.py` (lines 128–166). No other function, swatch, render-script, `_darkroom()` or test change.

## 1. The spout is a box stuck on the neck, not a pulled lip
The pinch loop (lines 132–139) moves every vertex with `z >= .20` by the full offset, so the ring at z = .205 jumps out 2 cm while the ring at z = .19 stays: a near-horizontal shelf under the spout, which `sharpen()` then flat-shades. In `bench.jpg` it is the dark stepped tongue below the lip.
Make the offset grow with height from the neck to the rim:

```python
        if z >= .19 and abs(angle) <= limit:
            rise = min(1.0, (z - .19) / .05)
            offset = .02*math.cos(angle/limit*math.pi/2)**2 * rise**2
```

(the next two lines, `radius` and `vertex.co`, unchanged). The rings at z = .205 then move about 2 mm at most, the two rim rings at z = .24 the full 2 cm.

## 2. The handle's top end pokes through the wall into the mouth
The top end is pulled in 3 mm to radius .055 (line 146), but the inner wall there is at radius .0557, so the end face shows inside the jug (the light dash on the inner back wall in `bench.jpg`). Change the top end only to 1.5 mm:

```python
    path[0] = (path[0][0]-.0015,path[0][1])
```

The lower end (line 147) keeps −3 mm.
Self-check in the build (print and `assert`), after the handle vertices are built: for the first four handle vertices, `math.hypot(x, y) >= .0562`. Report the printed minimum.

Budgets: jug stays at 624 triangles (no topology change), `max_materials = 3`.

## Run
- One heavy job: `job-run --id p7-darkroom-props-4 -- orb-test --heavy --host -- art/pipeline/blender/darkroom_props.sh` (build, G2 for all seven, three renders); end the turn with its `WAIT:` line. Then the Godot line below through `job-run --id p7-darkroom-godot-4`.
- Commit the regenerated `dr_jug.glb`, any changed `.import` file, its G2 report and the three JPEGs; push to `art/p7-darkroom`; PR #344 stays **draft** (do not mark it ready); update the three images in the PR body.
- Limits as before: 16 GB shared Mac, Blender and Godot only through `orb-test`, no windowed runs, no sleeping or polling inside the run; every time written down carries `JST`.

Test: orb-test --host -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_darkroom_props.gd && godot --headless --path . --script res://tests/test_darkroom_lantern.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd'

Acceptance cases: G2 passes for all seven; in `bench.jpg` the jug has no dark stepped block under the lip and nothing shows on the inner wall of the mouth; in `closeup.jpg` the lip flares smoothly from the neck to the rim and the dark rim band follows it; the handle self-check passes; `dr_pail`, `dr_tray`, `dr_bottle`, `dr_plate_holder`, `dr_plate_rack`, `dr_plate_box` GLBs are byte-identical to a2fe8c9.
