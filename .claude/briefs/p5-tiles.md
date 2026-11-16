# Brief p5-tiles: painted gouache surface tiles for the Príncipe slice (source images only)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p5-tiles`, branch `art/p5-tiles` (already created from origin/main a88f496).

## Goal

The Príncipe scene paints every surface with one procedural noise (`scripts/world_builder.gd` `weather()`). This task produces the replacement source material: hand-painted-looking, seamless, colour-matched albedo tiles, two variants per surface, with contact sheets the art director judges. **No game code and no `assets/` files change in this task**: the art director picks variants first; installing and wiring them is a later brief.

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run tools or tests bare: ImageMagick and shell scripts run as `orb-test --host -- <command>` (light host run); Python as `orb-test --image python:3.12-slim -- python3 -I <script>` (stdlib only). No Godot, no Blender in this task.
- Generate images with your built-in image generation tool (the one that made `docs/design/slice_principe/concepts/*.jpg`), **one image at a time, never in parallel**. Do not use `art/pipeline/gen.py` (it shells out to another codex).
- Do not sleep or poll. Leave nothing behind outside the paths named here.
- Raw generator PNGs go to `/Volumes/KIOXIA/eddington-1919-cache/director/p5-tiles/raw/<id>-v<n>.png` (not in the repo).
- Every time you write down carries its zone (`2026-11-14 14:40 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## The surfaces (11 sources, 2 variants each = 22 images)

Prompt = STYLE + " Surface: " + subject. Use the text verbatim; variant 2 uses the same prompt (a second generation), no rerolls beyond that. If a generation plainly ignores "flat-on" (perspective, an object, a horizon), regenerate that one once and note it.

STYLE: `Hand-painted gouache texture swatch for a stylised game, in the manner of a painted animation background: opaque matte paint, visible flat brush strokes, simplified shapes, gentle value range, no photographic detail, no film grain, no gloss. A seamless tileable surface seen exactly flat-on, filling the whole square frame edge to edge with even detail density; even diffuse light, no cast shadows, no perspective, no vignette, no border, no text.`

| id | match hex | subject |
|---|---|---|
| `laterite_wet` | `#6E3B29` | wet red laterite earth of a trampled camp ground after rain, seen from straight above: darker damp patches, a few small pebbles and flattened leaf fragments |
| `laterite` | `#9A5637` | dry red laterite earth path seen from straight above: fine cracks, scattered small pebbles, dusty lighter patches |
| `ground_cover` | `#3F5A2A` | low tropical ground cover seen from straight above: short grass tufts, clover-like weeds and small broad leaves, a little red earth showing between them |
| `leaf_litter` | `#5A4630` | fallen cacao leaves seen from straight above: large oblong leaves in brown, ochre and dull red overlapping on dark soil |
| `whitewash` | `#D1C9B8` | an old lime-washed plaster wall: faint horizontal brush marks, hairline cracks, pale grey-green damp stains |
| `roof_tile` | `#93493A` | horizontal courses of terracotta barrel roof tiles, weathered brown-red with patches of dark moss |
| `brick` | `#985B45` | handmade red brick wall in running bond, about eight courses, pale lime mortar joints, uneven brick tones |
| `teak` | `#6E4C31` | weathered tropical hardwood planks, vertical boards about 15 cm wide, visible grain, narrow dark gaps, a few nail heads |
| `canvas` | `#CFC3A4` | raw cotton canvas tarpaulin: visible plain weave, faint water stains, one stitched seam |
| `iron_sheet` | `#4D4B4A` | corrugated galvanised iron roofing with vertical corrugations, dull grey with rust streaks running down |
| `palm_bark` | `#6B5A44` | coconut palm trunk bark unrolled flat: horizontal leaf-scar rings, grey-brown, fibrous vertical cracks |

## What to build

1. `art/pipeline/tile.sh <in.png> <out.jpg> <#hex>` (bash + ImageMagick `magick`, no other dependency):
   - centre-crop to a square, resize to 1024×1024;
   - make it wrap in x, then in y: per axis, cross-fade the image with a copy rolled by half the size on that axis, using a mask that is 0 at both borders of that axis and 1 across the middle (ramp width 160 px), so the borders come from the rolled copy (continuous across the wrap) and the rolled copy's seam in the middle is covered by the original;
   - colour-match: scale R, G and B (in linear light) so the tile's mean colour equals the given hex; clamp;
   - write JPEG quality 90, sRGB, no metadata.
   - `art/pipeline/tile.sh --check <tile.jpg>` prints `wrap_x <ratio> wrap_y <ratio> mean #RRGGBB`, where ratio = mean absolute difference between the first and last column (row) divided by the mean absolute difference between adjacent interior columns (rows), and exits 1 if either ratio is above 1.6.
2. Run `art/runs/p5-tiles/` (committed):
   - `tiles/<id>-v1.jpg`, `tiles/<id>-v2.jpg`: the processed tiles. Two derived ids come from the `teak` sources by colour-match only: `teak_dark` (`#463022`) and `pine` (`#9C7B50`), so 26 tiles in all.
   - `manifest.jsonl`: one line per generated image: `id`, `variant`, `prompt` (full text sent), `tool_model`, `time` (JST), `retries`, `raw_sha256`, `raw_path` (the KIOXIA path), `tile` (repo path), `match_hex`, and the `--check` numbers of the tile.
   - `sheet-v1.jpg` and `sheet-v2.jpg`: for each of the 11 source ids (file order of the table) the tile repeated 3×3 and shown at 420×420, labelled with the id, montaged 4 columns, background `#202020`. Each sheet at most 1760 px wide.
   - `sheet-flat.jpg`: all 22 source tiles once each at 256×256, labelled `<id>-v<n>`, 6 columns.
   - `REVIEW.md`: the three sheets linked, one line per id with the `--check` numbers of both variants, and anything odd you saw. Leave the pick column empty (`pick: `): the art director fills it.
3. `art/pipeline/test_tiles_manifest.py` (stdlib `unittest`, run as a script like `tools/test_i18n_po.py`): every manifest line has all keys; every `tile` path exists, is a 1024×1024 JPEG (parse the SOF marker with `struct`), and is under 700 kB; the 11 ids × 2 variants are all present exactly once; `teak_dark` and `pine` tiles exist for both variants; `raw_sha256` is 64 hex chars.

Acceptance cases: 26 tiles, all pass `tile.sh --check`; manifest and sheets as above; `assets/` and `scripts/` untouched; nothing imported by Godot (`art/` has `.gdignore`).

Test: python3 -I art/pipeline/test_tiles_manifest.py

## Hand-off

- Commit on `art/p5-tiles` and push. **Do not open a PR** (the art director picks variants first, then resumes you).
- Do not edit `assets/`, `scripts/`, `shaders/`, `tests/`, `docs/`, `art/BIBLE.md`, `art/palette.toml`.
- Final report: files added, the `--check` table, the test output line, generation count and retries, anything you could not do.
