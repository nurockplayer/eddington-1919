# Brief sa-portraits: Eddington's dialogue portrait in two more styles (source images only)

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/sa-portraits`, branch `art/sa-portraits` (created from main 867e55e).

## Goal

A style audition (`docs/design/SLICE_PRINCIPE.md`, top section) renders the game in three looks. Dialogue shows an illustrated portrait beside the text. The toned-print portrait `assets/portraits/eddington_neutral.jpg` (1254×1254, an AI-generated reconstruction, already in the game) serves the first look. This task redraws that same portrait for the other two looks, two variants each, and makes the sheet the art director picks from. **No game code and no `assets/` file changes in this task.**

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. ImageMagick runs as `orb-test --host -- <command>` (light host run). No Godot, no Blender, no tests in this task.
- Generate with your built-in image generation tool, **one image at a time, never in parallel**, each time with `assets/portraits/eddington_neutral.jpg` attached as the reference image. Do not use `art/pipeline/gen.py`.
- Raw generator PNGs go to `/Volumes/KIOXIA/eddington-1919-cache/director/style-audition/portraits/raw/<id>-v<n>.png` (the directory exists; not in the repo). Check after each generation that the file is really there (`ls -l`).
- Do not sleep or poll. Leave nothing behind outside the paths named here.
- Every time you write down carries its zone (`2026-11-16 04:10 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## The images (2 ids × 2 variants = 4)

Use each prompt verbatim; variant 2 is a second generation of the same prompt. Square 1:1. If a result has text, a border, a signature, a second figure, or lost the glasses, regenerate that one once and note it.

`eddington_poster`:

> Redraw the man in the reference image as a 1920s travel-poster lithograph. Keep his likeness, the three-quarter pose, the rimless pince-nez, the dark suit, waistcoat, white collar and tie, and the framing (head and shoulders, same crop). Flat colour shapes only, printed in five inks: deep indigo, warm umber brown, terracotta, pale cream and a muted blue-green. The light comes from the left: the lit side of the face is cream and terracotta, the shadow side one hard-edged indigo-brown shape. No outlines, no gradients, no photographic detail, no hair strands: every form is a cut shape. A faint lithographic crayon grain where two inks overlap. Plain flat muted blue-green background. No text, no border, no signature.

`eddington_engraving`:

> Redraw the man in the reference image as a nineteenth-century steel engraving, the kind printed as a frontispiece portrait in a scientific journal. Keep his likeness, the three-quarter pose, the rimless pince-nez, the dark suit, waistcoat, white collar and tie, and the framing (head and shoulders, same crop). Black ink lines only on cream paper: every tone is built from fine parallel hatching and cross-hatching that follows the form of the face, lines swelling in the shadows, fine stipple on the lit skin, clean contour lines, the dark suit a dense cross-hatch. The figure fades into bare paper toward the bottom and the edges as an engraved vignette; the background is bare cream paper with a little horizontal ruling behind the head. No grey wash, no colour, no photographic shading, no text, no border, no signature.

## What to produce (committed, under `art/runs/style-audition/portraits/`)

1. `<id>-v<n>.jpg`: the raw PNG scaled to 1024×1024 (`magick <raw> -resize 1024x1024 -strip -quality 92`), four files.
2. `sheet.jpg`: one row of five at 512×512 each, `+6+6`, background `#202020`: the reference, `eddington_poster-v1`, `-v2`, `eddington_engraving-v1`, `-v2`. No labels (this host's ImageMagick has no font).
3. `sheet-small.jpg`: the same five at 204×204 (the size the game shows the portrait at), so the art director can see whether the lines hold at that size.
4. `manifest.jsonl`: one line per image: `id`, `variant`, `prompt` (verbatim), `reference` (`assets/portraits/eddington_neutral.jpg` and its sha256), `tool_model`, `time` (JST), `retries`, `raw_sha256`, `raw_path`, `file` (repo path).
5. Copy `sheet.jpg` and `sheet-small.jpg` to `/Volumes/KIOXIA/eddington-1919-cache/director/style-audition/portraits/` as well.

Commit to `art/sa-portraits` and push (`git push -u origin art/sa-portraits`). No PR.

Test: none (image generation and ImageMagick only; no code)

Acceptance cases: four JPEGs of 1024×1024 and the four raws on KIOXIA exist; `manifest.jsonl` has four lines whose `raw_sha256` match the raws; both sheets show five tiles; nothing under `assets/` or `scripts/` changed (`git diff --stat main...HEAD` lists only `art/runs/style-audition/portraits/`).
