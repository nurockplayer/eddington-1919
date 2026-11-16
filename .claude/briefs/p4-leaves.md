# Brief p4-leaves: painted foliage cut-outs for the Príncipe slice (source images only)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p4-leaves`, branch `art/p4-leaves` (already created from origin/main a88f496).

## Goal

The palms are combs of triangles and the shrubs faceted blobs (`scripts/world_builder.gd` `palm()`, `_vegetation()`). The replacement vegetation will be alpha-card foliage: Blender-built trunks carrying cards textured with painted fronds and leaves. This task produces those painted cut-outs with clean alpha, two variants each, and the sheets the art director judges (silhouette first: these shapes stand against the eclipse sky). **No game code, no models and no `assets/` files change in this task.**

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run tools or tests bare: ImageMagick and shell scripts run as `orb-test --host -- <command>` (light host run); Python as `orb-test --image python:3.12-slim -- python3 -I <script>` (stdlib only). No Godot, no Blender in this task.
- Generate images with your built-in image generation tool (the one that made `docs/design/slice_principe/concepts/*.jpg`), **one image at a time, never in parallel**. Do not use `art/pipeline/gen.py`.
- Do not sleep or poll. Leave nothing behind outside the paths named here.
- Raw generator PNGs go to `/Volumes/KIOXIA/eddington-1919-cache/director/p4-leaves/raw/<id>-v<n>.png` (not in the repo).
- Every time you write down carries its zone (`2026-11-14 14:40 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## The subjects (6 ids, 2 variants each = 12 images)

Prompt = STYLE + " Subject: " + subject. Use the text verbatim; variant 2 is a second generation of the same prompt. If a generation has a non-white background, a cast shadow, or more than the one subject, regenerate that one once and note it.

STYLE: `Hand-painted gouache botanical cut-out for a stylised game, in the manner of a painted animation background: opaque matte paint, visible flat brush strokes, simplified shapes, a few broad tones per leaf (deep olive and blue-green in the shade, yellow-green where lit), no photographic detail, no gloss. One isolated subject on a pure flat white background, evenly lit, no cast shadow, no ground, no pot, no border, no text. The subject fills the frame and is not cropped by the frame edge.`

| id | landscape or square | subject |
|---|---|---|
| `coconut_frond` | landscape | a single green coconut palm frond laid flat and seen from above: the straight midrib runs horizontally from the base at the left edge to the tip at the right, with about sixty narrow pointed leaflets on each side, a few with ragged or split tips, clear gaps between leaflets toward the tip |
| `coconut_frond_dry` | landscape | a single dead coconut palm frond laid flat and seen from above: the midrib runs horizontally from the base at the left to the tip at the right, brown and ochre leaflets, many broken, bent or missing |
| `cacao_branch` | landscape | the end of a cacao tree branch seen from the side, the woody stem entering from the left edge: eight large drooping oblong leaves with pointed tips, dark green, two young leaves in red-bronze |
| `banana_leaf` | landscape | a single large banana leaf laid flat and seen from above: the thick midrib runs horizontally from the stalk at the left to the tip at the right, the blade torn into strips along the side veins by wind |
| `undergrowth` | square | a clump of tropical undergrowth seen from the side, growing upward from the bottom centre of the frame: broad arching leaves and a few fern fronds, no flowers |
| `forest_edge` | landscape | the edge of a tropical cocoa plantation forest seen from a distance, exactly side-on, as one continuous band: dense rounded canopy of shade trees with five tall coconut palms rising above it, trunks hidden in dark undergrowth at the bottom, the band runs off the left and right frame edges at the same height, flat bottom edge; simplified shapes, three or four greens only |

## What to build

1. `art/pipeline/cutout.sh <in.png> <out.png>` (bash + ImageMagick `magick`):
   - alpha from distance to white: opaque where the pixel differs from white by more than about 12 %, transparent where under about 5 %, a soft ramp between; then shrink the alpha by 1 px to remove the pale fringe;
   - fill the RGB of fully transparent pixels with the colour of the nearest opaque pixels (edge bleed, at least 16 px), so mipmaps never show white halos;
   - trim to the bounding box of the alpha plus 8 px padding, scale so the long side is 1024 px, write PNG with alpha (8-bit, no metadata).
   - For `forest_edge` only (`--wrap-x`): no trim on x; make it wrap horizontally (cross-fade with a copy rolled by half the width, mask 0 at the left and right borders and 1 across the middle, ramp 160 px, alpha included); trim top and bottom only.
   - `art/pipeline/cutout.sh --check <cut.png>` prints `size WxH coverage <percent of opaque pixels> fringe <percent>` where fringe = share of pixels with alpha > 0.5 whose luma is above 0.92; exits 1 if coverage is outside 8–75 % or fringe is above 1 %.
2. Run `art/runs/p4-leaves/` (committed):
   - `cut/<id>-v1.png`, `cut/<id>-v2.png` (12 files).
   - `manifest.jsonl`: one line per image: `id`, `variant`, `prompt`, `tool_model`, `time` (JST), `retries`, `raw_sha256`, `raw_path`, `cut` (repo path), and the `--check` numbers.
   - `sheet-colour.jpg`: every cut-out composited on `#8FA3AD` (hazy sky), fitted into a 480×320 cell, labelled `<id>-v<n>`, 4 columns.
   - `sheet-silhouette.jpg`: the same layout, the alpha drawn as flat `#101418` shapes on `#C9D2D6`.
   - `sheet-dusk.jpg`: the same layout, the cut-outs at 25 % brightness on `#2B2F4A` (totality sky).
   - `REVIEW.md`: the three sheets linked, the `--check` numbers per file, anything odd. Leave `pick: ` empty for the art director.
3. `art/pipeline/test_cutouts_manifest.py` (stdlib `unittest`, run as a script): every manifest line has all keys; every `cut` file exists, is a PNG with an alpha channel (IHDR colour type 6) whose long side is 1024 px (`forest_edge`: width 1024 or more), and is under 2.5 MB; 6 ids × 2 variants present exactly once.

Acceptance cases: 12 cut-outs, all pass `cutout.sh --check`; no white fringe visible on `sheet-dusk.jpg`; manifest and sheets as above; `assets/` and `scripts/` untouched.

Test: python3 -I art/pipeline/test_cutouts_manifest.py

## Hand-off

- Commit on `art/p4-leaves` and push. **Do not open a PR** (the art director picks variants first, then resumes you).
- Do not edit `assets/`, `scripts/`, `shaders/`, `tests/`, `docs/`, `art/BIBLE.md`, `art/palette.toml`.
- Final report: files added, the `--check` table, the test output line, generation count and retries, anything you could not do.
