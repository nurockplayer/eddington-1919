# af01 palm A/B (G4)

Commit c73b0c9, the same build both ways, seed 7, three interleaved reps each
(`art/pipeline/baseline.sh`; screenshots kept for rep1 only).
- **prim**: today's 15 primitive palms (a 9-node trunk-plus-boxes tree each).
- **kit**: `E1919_PALM_KIT=1` runs `world_builder.gd` with the factory candidate `coconut_palm` (588 tris, one mesh, 3 materials) as one MultiMesh. Positions, heights, leans and colliders are the same; it consumes the same RNG draws, so the shrub layout is identical.

The machine was not fully idle: load was 8–10 (another project was active after a reboot), the same for both arms. The `provenance.txt` files record the load per run.

## Result (medians; full tables in SUMMARY.md)

| bookmark | draw calls prim → kit | primitives (k) prim → kit | forced-draw avg ms prim → kit |
|---|---|---|---|
| arrival | 389 → 255 (−34%) | 205 → 235 | 5.45 → 5.57 |
| totality_sky | 194 → 67 (−65%) | 116 → 139 | 3.47 → 3.62 |
| totality_horizon | 156 → 61 (−61%) | 88 → 122 | 4.87 → 4.60 |
| darkroom | 298 → 112 (−62%) | 131 → 152 | 6.25 → 6.26 |
| eddington_talk | 355 → 258 (−27%) | 220 → 243 | 6.01 → 6.22 |

- **Draw calls:** down 15–65% at every bookmark. Palms were most of the sky submissions.
- **Primitives:** up 20–34k. The kit palm carries more triangles than the primitives, and it adds shadow passes.
- **Render cost (forced draw):** no measurable change. Every difference sits inside the min–max spread between reps. Wall-clock time is display-capped and unchanged.
- **Look:** the drooping, notched fronds replace the stiff propeller crowns. Compare `prim-rep1/shots/arrival.jpg` with `kit-rep1/shots/arrival.jpg`.

**Reading:** this scene is not draw-call bound on the M2 Pro at this size, so the swap is a visual upgrade at equal cost, not a speed-up. The draw-call headroom matters on weaker GPUs and for denser vegetation later.

**Adoption** needs the Owner to promote `coconut_palm`: the GLB moves to `assets/models/` and an `art/assets.toml` entry is added. After that, a production switch in `_vegetation()` replaces this env flag.
