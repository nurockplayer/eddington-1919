# Brief p5-install: install the picked surface tiles and paint them through `weather()`

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p5-install`, branch `art/p5-install` (created from `origin/art/p5-tiles` f295064, which holds the tiles and the picks).

## Goal

Every Príncipe surface is a flat palette colour times one shared procedural noise (`scripts/world_builder.gd` `weather()`, lines 133–158). Replace the flat colour with the painted albedo tile picked for its palette swatch (`art/runs/p5-tiles/REVIEW.md`, column `pick`), projected world-triplanar, so code primitives (`mat(P("teak"))`) and kit GLBs (materials named `E1919_<swatch>`, see `art/pipeline/blender/kit.py:44`) pick them up without re-export. The broad noise stays on top (UV2, as now) to break repetition. No normal maps. The ground (`_ground_material()`) is **not** part of this task (a later ground-shader brief uses the four ground tiles).

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot, ImageMagick or Python bare: `orb-test --host -- <command>` (Godot needs `--host`; fresh worktree: `godot --headless --path . --import` first, or suites fail or hang). No windowed Godot, no screenshots from Godot (the art director renders on Monday).
- Long commands (> 2 min) through `job-run`; end your run with the `WAIT:` line. Never sleep or poll.
- Every time you write down carries its zone (`2026-11-15 14:40 JST`). Commit messages: never put "fix", "close" or "resolve" right before a `#N`.
- Leave nothing behind outside the paths named here.

## 1. Re-wrap `roof_tile` (before installing)

The pick is `roof_tile-v2`, but the cross-fade wrap doubles the tile ridge at the seam (see KIOXIA `/Volumes/KIOXIA/eddington-1919-cache/director/p5-tiles/judged-20261115/seam-crops-laterite-litter-roof.jpg`, right panel). Re-make it from its raw (`raw_path` in `art/runs/p5-tiles/manifest.jsonl`) **without cross-fade**: find the horizontal and vertical repeat period of the tile pattern (autocorrelation of the luma, e.g. a small Python/numpy step in `python:3.12-slim` with `pip install numpy pillow` inside the container, or ImageMagick), crop the largest centred region that is a whole number of periods on each axis, resize to 1024×1024, colour-match to `#93493A` exactly as `art/pipeline/tile.sh` does (reuse its colour-match code path), JPEG q90. Write it over `art/runs/p5-tiles/tiles/roof_tile-v2.jpg`, add a `rewrap` note to its manifest line, and write `art/runs/p5-tiles/roof_tile-v2-rewrap-3x3.jpg` (the tile repeated 3×3 at 420×420 per cell) for the art director. It must pass `tile.sh --check`. If no clean period exists (check ratio > 1.6 either way), keep the old file, say so under Blocked, and go on.

## 2. Install

Copy the picked variant of each id to `assets/textures/principe/<id>.jpg` (13 files, no variant suffix):

| id | pick | metres per repeat |
|---|---|---|
| laterite_wet | v2 | 2.0 |
| laterite | v2 | 2.0 |
| ground_cover | v2 | 1.5 |
| leaf_litter | v2 | 1.5 |
| whitewash | v2 | 2.0 |
| roof_tile | v2 (re-wrapped) | 1.0 |
| brick | v1 | 0.6 |
| teak | v2 | 0.9 |
| teak_dark | v1 | 0.9 |
| pine | v1 | 0.6 |
| canvas | v2 | 1.2 |
| iron_sheet | v1 | 0.6 |
| palm_bark | v1 | 0.5 |

Import them with mipmaps and VRAM compression (in each `.import`: `compress/mode=2`, `mipmaps/generate=true`; run `godot --headless --path . --import` and commit the `.import` files, as the repo already does for `assets/`). Add `assets/textures/principe/SOURCES.md`: one line per file naming its source tile in `art/runs/p5-tiles/tiles/` and pointing to the manifest for provenance.

## 3. Wire

In `scripts/world_builder.gd`:

- `const TILES := {"laterite_wet": 2.0, …}` (id → metres per repeat, the table above) and `const TILE_DIR := "res://assets/textures/principe/"`.
- `weather(m: BaseMaterial3D, tile := "")`: keep the early return exactly as it is (no tile when `look` is false, on metals, on evidence, on `E1919_plate_glass*`). Then resolve the tile id: the `tile` argument if given; else `m.resource_name` with the `E1919_` prefix and any suffix from the first `.` removed, if that is a `TILES` key; else the palette swatch whose colour equals `m.albedo_color` exactly (compare `to_html(false)` against `Palette.C`), if that is a `TILES` key; else none. With a tile: `m.albedo_texture = load(TILE_DIR + id + ".jpg")`, `m.uv1_triplanar = true`, `m.uv1_world_triplanar = true`, `m.uv1_scale = Vector3.ONE / TILES[id]`, `m.uv1_triplanar_sharpness = 4.0`, and `m.albedo_color` becomes the per-channel ratio of the old albedo colour to the swatch colour of `id` (clamped 0–2; exactly white for an exact match), so a tinted kit material keeps its offset. For `iron_sheet` and `palm_bark` (no palette swatch) the reference colour is the tile's own match hex (`#4D4B4A`, `#6B5A44`). The UV2 noise detail stays exactly as now, with or without a tile. Cache loaded textures in a dictionary.
- `mat(color, rough := 0.85, metal := 0.0, tile := "")`: pass `tile` through; include it in the cache key.
- Darkroom roof (`_darkroom()`, the `box(... roof ...)` line, ~line 524): after `box()` returns, set its mesh's `material_override` to `mat(roof, 0.85, 0.0, "iron_sheet")` (look at how `box()` builds the node; keep collision and transform as they are).
- `_weathered_mesh()` and `weather_model()` call `weather(w)` unchanged; the resource name of the duplicate must still carry `E1919_<swatch>` (check that `duplicate()` keeps `resource_name`; if not, copy it).
- Nothing else changes: no palette edits, no ground changes, no shader files.

## 4. Test

New `tests/test_surface_tiles.gd`, in the style of `tests/test_sun_crescents.gd` (build the world the same way it does; `check()` lines; exit code):

1. `mat(P("teak"))` has `albedo_texture` with path `res://assets/textures/principe/teak.jpg`, `uv1_world_triplanar`, `uv1_scale ≈ Vector3.ONE / 0.9`, `albedo_color ≈ white`, and still has the UV2 noise detail.
2. `mat(P("teak").darkened(0.1))` gets no albedo texture (noise only).
3. A `StandardMaterial3D` named `E1919_brick.001` with albedo `#985B45` gets the brick tile after `weather()`; one named `E1919_brick` with albedo `P("brick").darkened(0.2)` gets the brick tile with `albedo_color ≈ 0.8` per channel (ratio).
4. No tile on: `evidence_mat(...)`; a material with `metallic = 0.85`; `E1919_plate_glass`; any material when `look = false`.
5. After `build()`, the darkroom roof's material has the `iron_sheet` tile at `uv1_scale ≈ Vector3.ONE / 0.6`.
6. Every file in `TILES` loads as a `Texture2D` with mipmaps, under 1 MB on disk.
7. In a built world, at least one kit GLB surface (the shelter, `E1919_teak` or `E1919_pine`) carries its tile.

Test: orb-test --host -- bash -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_surface_tiles.gd && godot --headless --path . --script res://tests/test_sun_crescents.gd && godot --headless --path . --script res://tests/test_darkroom_lantern.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd'

Acceptance cases: the seven test checks above; `--no-grade` gives exactly the old materials (no tile anywhere); `roof_tile-v2-rewrap-3x3.jpg` committed; repo growth under 12 MB.

## Hand-off

- Commit on `art/p5-install`, push, and open a **draft** PR against `main` titled `Paint Príncipe surfaces with the picked tiles` whose body lists the tile table, says the PR moves SLICE_PRINCIPE §6 acceptance rows for the camp surfaces (none pass until the art director's render), and states that it stays draft until the art director accepts renders. Do not run the review gate.
- Do not edit `docs/`, `art/BIBLE.md`, `art/palette.toml`, `shaders/`, `_ground_material()`, or anything in `scripts/` other than `world_builder.gd`.
- Final report: files changed, the roof re-wrap periods and check numbers, the test output lines, anything you could not do.
