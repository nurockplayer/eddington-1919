You are a Blender technical artist on the eddington-1919 repo (current directory). This is the af01 FIX ROUND r1: rework six existing procedural asset build scripts after a Director review. The tone is cinematic and historical, NOT toy-like (art/BIBLE.md §3, §3a, §4, §6).

READ FIRST: art/BIBLE.md §3, §3a, §4, §6; art/pipeline/blender/kit.py; art/palette.toml (note the NEW swatches `zinc` and `basalt` at the end); art/factory/af01/batch.toml (the specs for your six assets were updated for this round: read `dims_m`, `tri_budget`, `max_materials`, `pivots` and `parts` again; they win over anything below); art/factory/af01/review.toml (the review notes); and the current builder for each asset in art/pipeline/blender/factory/.

YOUR ASSETS AND THE FIX FOR EACH:

1. laterite_steps (verdict was REWORK). The blocks read as soft pillows: the bevel is too large for the block size and the pale `stone` reads as a toy. Rebuild with FEWER, LARGER, FLATTER, DARKER dressed blocks:
   - Material: `basalt` for the dressed blocks (both treads and riser faces), `laterite` for the infill/joints. 2 materials max. No `stone`.
   - 2–3 blocks per course (not 4), tread slabs 0.08–0.10 m thick, riser faces as long low slabs. Bevel ≤ 0.008 m with 1 segment on every block, so edges are crisp but not sharp.
   - Keep the exact geometry the spec requires: 0.15 m risers, 0.36 m treads, top step flush with a 0.30 m terrace behind; dims 1.6 × 0.8 × 0.3. Keep the small per-block irregularity (±1.5 cm, 1–2° yaw), varied block widths (not equal), and a visible but narrow laterite joint (1–2 cm) between blocks.
2. zinc_bucket. It reads as a black iron pot. Use the new `zinc` swatch for the shell, rim, ears and bail; `teak_dark` for the wooden grip. 2 materials. Geometry can stay; check the rolled rim and the bail still read at 3 m.
3. plate_rack. Under the darkroom safelight the bright `plate_glass` plates compete with the evidence (BIBLE S1). Replace `plate_glass` with `sea_slate` (dark developed negatives, dimmed non-evidence glass). Keep teak / teak_dark for the rack. 3 materials max. Plates stay 0.003 m slabs leaning in the grooves.
4. cocoa_drying_barcaca. It reads as a pavilion. A barcaça must read as a LONG, LOW drying bed with a roof that visibly runs on rails. New spec dims 3.2 × 8.0 × 2.2 (was 6.0 long):
   - Deck 4.4 m long (along Y) at 0.6 m on brick piers, at the -Y end of the footprint; low edge boards (~0.12 m) around it.
   - Bean bed: `laterite_wet`, NOT one flat slab: shallow raked ridges running along the deck (3–6 low ridges, 2–4 cm relief), filling the deck inside the edge boards, so it reads as a bed of beans from a standing eye height (1.6 m) at 4–8 m.
   - Two legible rails (`iron` runners on `teak` beams) on both long sides, running the full deck length and continuing 3.6 m beyond the +Y end of the deck on their own posts/piers, so the roof could roll off the deck.
   - Separate object `cocoa_drying_barcaca_roof` with its origin at (0,0,0) exactly as the pivot spec says: a corrugated `iron` gable roof on small wheels/rollers sitting on the rails, currently over the deck. Eaves high enough (~1.7–1.8 m) that the bean bed is visible under them from 1.6 m eye height; ridge at 2.2 m.
   - Max 4 materials (brick, teak, iron, laterite_wet). Tri budget 3000 (aim ≤ 85%).
5. post_rail_fence. The pine rails read new and yellow next to the weathered post. Use `teak` for both rails and `teak_dark` for the post (2 materials, no `pine`). Keep the tiling contract (2.5 m along X, the next segment supplies the +X post) and the sag.
6. coconut_palm. The fronds read as stiff spikes. Make them DROOP and give a LEAFLET read:
   - Each frond arches up briefly from the crown and then falls: tips end 1.2–2.0 m below the crown, varied per frond; a few younger fronds stand higher and droop less.
   - Leaflet read: a clearly serrated/zig-zag outer edge along each frond (alternating notches), plus the folded V spine, so the silhouette against the sky reads as pinnate leaves, not paddles. Both faces visible (the material/mesh must not vanish from below).
   - Keep 10 fronds, 5 coconuts, the curved ringed S-lean trunk, ONE joined mesh named `coconut_palm`, 3 materials (teak_dark, foliage_deep, foliage_light), dims 6 × 6 × 8 within tolerance.
   - HARD: ≤ 600 triangles total (it will be one MultiMesh in a 15-palm forest). Aim ≤ 590. Spend triangles on the frond silhouette, not the trunk or nuts.

For EACH asset <id>:
- Edit art/pipeline/blender/factory/build_<id>.py (keep the existing house style: one-line docstring, kit import pattern, kit.join/set_origin/export, deterministic — no random() without a fixed seed).
- Run:  blender -b --factory-startup -P art/pipeline/blender/factory/build_<id>.py
- Validate:  blender -b --factory-startup -P art/pipeline/blender/validate.py -- assets/candidates/af01/<id>.glb <id> --registry art/factory/af01/batch.toml --out art/factory/af01/g2
  Iterate until "G2 PASS". Do not change batch.toml to make it pass; if a spec value is physically wrong, stop that asset and explain.
- Quality bar: reads as a real 1919 object at 3 m in a cinematic game, not a toy: believable proportions, slight irregularity where wood/stone would have it, no perfectly uniform repeats, no floating parts, all parts touching, min feature 2 cm.
- Optional self-check: render a quick Workbench/EEVEE still into /tmp (never into the repo) to look at the silhouette.

HARD RULES:
- Create/modify ONLY: art/pipeline/blender/factory/build_{laterite_steps,zinc_bucket,plate_rack,cocoa_drying_barcaca,post_rail_fence,coconut_palm}.py, assets/candidates/af01/<those ids>.glb, art/factory/af01/g2/<those ids>.g2.json. Do NOT edit kit.py, validate.py, batch.toml, palette.toml, review.toml or any other file. Do not touch the other eight assets.
- NO git commands at all (no checkout, commit, stash, branch, diff is fine via plain `diff`, not git).
- Never write into assets/models/. Do not download anything. Do not call any paid API.
- Do not run a long-running "Oracle" or multi-agent sub-review at the end; finish with your final message as soon as the six assets pass G2.
FINAL MESSAGE: per asset: G2 result, triangles/budget, materials, measured dims, and one sentence on what changed and any compromise.
