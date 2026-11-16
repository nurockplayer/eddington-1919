# p5-install follow-up: roof tile decided (art director, 2026-11-15 19:0x JST)

Decision on your `DECISION:` line: neither option. No replacement source and no fallback to the doubled ridge. The art director re-wrapped `roof_tile-v2` and has **already put the result in your worktree, uncommitted** (`git status` shows three modified files). Do not regenerate or re-crop them.

- `art/runs/p5-tiles/tiles/roof_tile-v2.jpg` and `assets/textures/principe/roof_tile.jpg`: the same file, sha256 `c511ff2ffbdf7fc0d75219fbdb598a5bdbfe3c11df8369461dcb4c6801afafef`.
- `art/runs/p5-tiles/roof_tile-v2-rewrap-3x3.jpg`: its 3×3 preview (420 px per cell).

How it was made (this is the provenance to record): raw `roof_tile-v2.png`, centred crop 1086×1085 (6×5 of your measured 181×217 px periods), resized to 1024×1024, **no half-roll cross-fade**, only the 16 px opposing-border feather of `art/pipeline/tile.sh` (its second `magick … -fx` step), colour match to `#93493A` as `tile.sh` does, JPEG q90. `tile.sh --check`: `wrap_x 0.641818 wrap_y 0.563404 mean #8F4739`. The feather is what my first brief forbade; with the crop on whole periods it no longer doubles the ridge (judged on a full-resolution seam crop and the 3×3).

## Do
1. Re-run `bash art/pipeline/tile.sh --check` on both jpg files inside `orb-test --host` and confirm the numbers above.
2. `art/runs/p5-tiles/manifest.jsonl`, the `roof_tile` variant 2 line: `wrap_x`, `wrap_y`, `mean` become the new values; the `rewrap` note says what is written under "How it was made", `by: edd-art`, `time: 2026-11-15 18:55 JST`, `installed: true`; keep one short clause on the two earlier whole-period crops that failed without a feather (5.81/3.72 and 3.10/3.99).
3. `assets/textures/principe/SOURCES.md` line 8: source is the re-wrapped `roof_tile-v2.jpg`; drop "known doubled-ridge artifact remains pending the lead's decision".
4. `art/runs/p5-tiles/REVIEW.md`, `roof_tile` row: append `re-wrapped 2026-11-15 18:55 JST (edd-art): 0.641818, 0.563404, #8F4739; installed`.
5. Run the test line through `job-run` and end with the `WAIT:` line, as before. After the import, `git status` must show no change to `roof_tile.jpg.import`; if the importer changes it, commit its version.
6. Commit, push. PR #340 stays draft; add one line to its body: roof tile re-wrapped by the art director on whole periods, check values as above.

## Not in this PR
The review's two majors (palm trunks without `palm_bark`; the manifest test not enforcing the wrap limit) are issue #345. Do not touch `palm()` or `test_tiles_manifest.py`.

Limits as in the brief: 16 GB shared Mac, Godot only through `orb-test --host`, headless only, no screenshots; every written time carries `JST`.

Test: orb-test --host -- bash -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_surface_tiles.gd && godot --headless --path . --script res://tests/test_sun_crescents.gd && godot --headless --path . --script res://tests/test_darkroom_lantern.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd'

Acceptance cases: both jpg files keep the sha256 above; `tile.sh --check` passes on them; the four suites pass; manifest line, SOURCES line and REVIEW row say re-wrapped and installed. Final report: the check line, the four test output lines, the pushed commit.
