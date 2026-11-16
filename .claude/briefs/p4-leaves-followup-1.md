# p4-leaves follow-up 1 (edd-art, 2026-11-14 14:47 JST)

The run stopped at the wrapper's wait limit; the brief is not finished. I looked at the cut-outs and the raws myself. Two defects, both fixed in a script I have already run over all 12 raws:

1. **All ten committed cut-outs are black.** `cutout.sh` destroys the colour in the spread step (`-morphology Voronoi …`): the files are grey values under 0.17 with the right alpha. `--check` passed because it never looks at colour.
2. **`forest_edge`:** the three-image composite in the `--wrap-x` branch drops the alpha (hence 99 % coverage), and the cross-fade my brief asked for leaves ghost palms at the seam. The wrap is now a **mirror**: the tile is the matte followed by its flopped copy, 2048 px wide.

## Do this

1. Replace `art/pipeline/cutout.sh` with `/Users/tachikoma/Developer/eddington-1919/.claude/briefs/p4-leaves-cutout-fixed.sh`, verbatim (`cp`, keep it executable). Changes in it: mirror wrap at 2048 px; colour spread by blurred copies composited underneath; `--check` prints one more number, `chroma <percent>` (mean max−min of RGB over opaque pixels), and fails under 8 %; coverage limit 90 % for files named `forest_edge-*`, 75 % for the rest.
2. Ignore job `p4-forest-preview` (do not wait for it). If `art/runs/p4-leaves/forest-preview.jpg` exists, delete it; never commit it.
3. Rebuild all 12 cut-outs from the raws on KIOXIA (`/Volumes/KIOXIA/eddington-1919-cache/director/p4-leaves/raw/`; `--wrap-x` for the two `forest_edge` files) and run `--check` on each, in **one** `job-run` through `orb-test --host`. **No new image generation.** Expected numbers (my run, 2026-11-14 14:46 JST):

   | cut-out | size | coverage | chroma |
   |---|---|---:|---:|
   | coconut_frond-v1 | 1024×500 | 56.097 | 30.415 |
   | coconut_frond_dry-v1 | 1024×336 | 38.987 | 39.075 |
   | cacao_branch-v1 | 1024×688 | 53.872 | 20.520 |
   | banana_leaf-v1 | 1024×414 | 58.585 | 29.805 |
   | undergrowth-v1 | 1024×701 | 58.268 | 29.444 |
   | forest_edge-v1 | 2048×341 | 75.116 | 21.360 |
   | forest_edge-v2 | 2048×338 | 71.704 | 23.549 |

   A number that differs by more than 0.5 is a finding: report it, do not tune the script.
4. `art/pipeline/test_cutouts_manifest.py`: the manifest lines also carry `chroma`; assert `chroma` ≥ 8 for every line, and `forest_edge` width exactly 2048 (the others: long side 1024). Everything else as in the brief.
5. Finish the brief's deliverables: `manifest.jsonl`, `sheet-colour.jpg`, `sheet-silhouette.jpg`, `sheet-dusk.jpg`, `REVIEW.md`. For the two `forest_edge` cells in the sheets, show the tile rolled by half its width (`-roll +1024+0`) so the wrap seam is in the middle of the cell.
6. `REVIEW.md` gets the art director's picks (write them as given, 2026-11-14 14:47 JST):
   - `coconut_frond`: pick: v1 and v2 (both, for variation)
   - `coconut_frond_dry`: pick: v1 (v2 has keyed-out holes near the base)
   - `cacao_branch`: pick: v1 and v2
   - `banana_leaf`: pick: v1 and v2 (v1 first)
   - `undergrowth`: pick: v1 and v2
   - `forest_edge`: pick: v1 and v2, mirror-wrapped. Note for the wiring brief: the bottom third (cocoa pods, large leaves) reads as near-scale and is to be hidden or cropped by UV on the ring.
7. Commit and push on `art/p4-leaves`. Still no PR, nothing in `assets/`, `scripts/`, `shaders/`, `tests/`, `docs/`.

Host rules as in the brief: ImageMagick processing and tests through `orb-test` (long commands through `job-run`; never sleep or poll), every written time carries JST, one-off data only on KIOXIA, nothing left behind in the worktree (`.cutout.*` temp dirs).

Acceptance cases: 12 cut-outs pass the new `--check`; the committed PNGs are colour (chroma ≥ 8); `forest_edge` tiles are 2048 px wide and show no seam or ghost in the rolled sheet cells; no white fringe on `sheet-dusk.jpg`; picks in `REVIEW.md` as above.

Test: python3 -I art/pipeline/test_cutouts_manifest.py
