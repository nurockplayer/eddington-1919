# Brief p1-matrix: benchmark image stats + look comparison matrix tool

Lead: edd-art (art director). Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/p1-matrix`, branch `art/p1-look-matrix` (already created from origin/main 73a7ccd). Godot 4.7.2, GDScript (tabs), bash, Python 3 stdlib.

## Goal

Tooling only, no change to how the game looks or plays:
1. `tests/benchmark.gd` records value/saturation statistics of every bookmark screenshot, so the slice's value targets are numbers instead of screenshots.
2. `tools/look_matrix.sh` runs the benchmark once per look variant (extra user args from a TSV), then writes one stats table and one contact sheet per bookmark. The art director runs it on a weekday; you never run it (it needs a window).

Everything is decided below. If something that changes behaviour, data, a public interface or scope is still open, do not guess: end your report with a last line `DECISION: <question; options; recommendation>`.

## Rules on this host

- 16 GB Mac shared by many sessions. Never run Godot or tests bare: every run goes through `orb-test --host -- <command>` (single headless suite); Python through `orb-test --image python:3.12-slim -- python3 -I <script>`. No windowed Godot runs at all in this task, so do not execute `tools/look_matrix.sh` beyond `sh -n`. No full-suite runs.
- First command in this fresh worktree: `orb-test --host -- godot --headless --path . --import` (without it scenes load as null and suites hang).
- Do not sleep or poll. Leave nothing behind (no scratch files).
- Every time you write down carries its zone (`2026-11-14 14:10 JST`).
- Commit messages: never put "fix", "close" or "resolve" right before a `#N`.

## Changes

### 1. `tests/benchmark.gd`

- New `static func image_stats(img: Image) -> Dictionary` (pure, no scene access). Work on a copy converted to `Image.FORMAT_RGB8` and resized to 320×180 with `Image.INTERPOLATE_NEAREST` (skip the resize when the image is already that size or smaller). Per pixel, from the 8-bit display values scaled to 0..1: `luma = 0.2126 r + 0.7152 g + 0.0722 b`; `sat = 0 if max == 0 else (max - min) / max`. Return:

| key | meaning | rounding |
|---|---|---|
| `luma_mean` | mean luma | 0.001 |
| `luma_p05`, `luma_p50`, `luma_p95` | luma percentiles: sorted ascending, index `int(n * 0.05)`, `int(n * 0.5)`, `int(n * 0.95)` | 0.001 |
| `sat_mean` | mean saturation, whole frame | 0.001 |
| `sat_low_mean` | mean saturation of the lower half (rows `h / 2` to the bottom: ground and vegetation, not sky) | 0.001 |
| `clip_white_pct` | percent of pixels with luma ≥ 0.98 | 0.1 |
| `clip_black_pct` | percent of pixels with luma ≤ 0.02 | 0.1 |

- `_shot(path)` (line ~171): store the image it saves in a new member `var last_image: Image`, so `_sample_bookmark` can measure it. Nothing else in `_shot` changes.
- `_sample_bookmark()` (line ~229): after `await _shot(...)`, add `"image": image_stats(last_image)` to the result dictionary `r` (when `last_image` is null, `{}`). `tests/benchmark_cambridge.gd` extends this script and calls `_sample_bookmark`, so it gets the key too; `art/pipeline/compare.py` reads only named keys and needs no change.
- Header comment: one sentence saying each bookmark also records `image` statistics (targets in `docs/design/SLICE_PRINCIPE.md` §6: under 3% clipped white, under 3% pure black).

### 2. New `tests/test_bench_stats.gd`

`extends SceneTree`, same `check()` / summary / `quit(1 if failures else 0)` pattern as `tests/test_graphics_quality.gd` (lines 1–21, 163–164); summary line `test_bench_stats: %d checks, %d failures`. Build images with `Image.create(w, h, false, Image.FORMAT_RGB8)` + `fill` / `fill_rect`. Acceptance cases:
1. 320×180 all white: `clip_white_pct` 100.0, `clip_black_pct` 0.0, `luma_mean` 1.0, `sat_mean` 0.0.
2. 320×180 all black: `clip_black_pct` 100.0, `clip_white_pct` 0.0, `sat_mean` 0.0 (no division by zero).
3. 320×180, top half mid grey `Color8(128, 128, 128)`, bottom half pure red `Color8(255, 0, 0)`: `sat_low_mean` 1.0, `sat_mean` 0.5, `luma_p05` ≈ 0.213 (±0.002), `luma_p95` ≈ 0.502 (±0.002), both clip values 0.0.
4. 1280×720 with the left 10% of columns white and the rest `Color8(128, 128, 128)`: `clip_white_pct` 10.0 (±0.5) (the resize keeps proportions).
5. The input image is not modified (size and format unchanged after the call, for the 1280×720 case and for an `FORMAT_RGBA8` input).

### 3. New `tools/look_matrix.tsv`

Two tab-separated columns: variant name (`[a-z0-9_]+`), extra user args (may be empty). Lines starting with `#` and blank lines are skipped. Exactly this content:

```
# variant	extra user args (after --); tuned by the art director
base	
nograde	--no-grade
agx	--look-set=tonemap=agx,agx_contrast=1.4
white1	--look-set=white=1.0,exposure=0.95
sat_lo	--look-set=saturation=1.08
sat_hi	--look-set=saturation=1.30
key_hi	--look-set=sun_gain=2.6,ambient_gain=0.4
no_sdfgi	--look-set=sdfgi=0
no_volfog	--look-set=volumetric_fog=0
fov72	--look-set=fov=72
fov55	--look-set=fov=55
```

(`--look-set` is added to the game by a parallel PR; this tool only passes the string through.)

### 4. New `tools/look_matrix.sh` (bash, executable, `set -u`)

Header comment in the style of `tools/all_suites.sh`, including the run line:
`orb-test --heavy --host -- tools/look_matrix.sh <out dir> [variants.tsv]` and the Owner rule "windowed Godot only Mon–Fri 09:00–15:00 JST".

Behaviour:
1. Args: `$1` = out dir (required, created; absolute or relative), `$2` = variants file (default `tools/look_matrix.tsv`). Env `ONLY=name,name` passes `--bench-only=$ONLY` to every run; env `SEED` (default 7).
2. Guard: unless `WINDOWED_OK=1`, exit 2 with a one-line message when `TZ=Asia/Tokyo date +%u` is 6 or 7, or `TZ=Asia/Tokyo date +%H` is outside 09–14.
3. `godot --headless --path . --import >/dev/null 2>&1` once.
4. For each variant, in file order:
   `perl -e 'alarm shift; exec @ARGV' 600 godot --path . --resolution 1280x720 --fixed-fps 60 --always-on-top -- --benchmark="$OUT/$name" --seed="$SEED" $extra ${ONLY:+--bench-only=$ONLY} >"$OUT/$name.log" 2>&1`
   (`$OUT` made absolute first; `$extra` unquoted on purpose so several args split). A variant fails when the exit code is not 0, `$OUT/$name/benchmark.json` is missing, or the log contains `LOOK-SET ERROR`. Print one line per variant: name, `ok`/`FAIL`, seconds. Continue with the next variant after a failure.
5. `python3 -I tools/look_matrix_stats.py "$OUT"` writes `$OUT/stats.tsv`.
6. Contact sheets: for every bookmark png name found in the first successful variant's directory, `magick montage` of that bookmark across the successful variants, in file order, each tile labelled with the variant name: `-label "$name" "$OUT/$name/$b.png"` pairs, then `-resize 640x360 -tile 3x -geometry +6+6 -background '#202020' -fill white "$OUT/sheets/$b.jpg"`. When `magick` is not installed, print a note and skip the sheets.
7. Last line `look matrix: <n ok>/<n total> variants -> <out dir> <date '+%F %H:%M %Z'>`; exit 1 when any variant failed, else 0.

### 5. New `tools/look_matrix_stats.py` (Python 3 stdlib only) and `tools/test_look_matrix_stats.py`

- `collect(out_dir) -> list[dict]`: for each `<out_dir>/<variant>/benchmark.json` (variants sorted by name), one row per bookmark: `variant`, `bookmark`, `lighting`, `forced_draw_ms_avg`, `draw_calls`, and the eight `image` keys (blank when the bookmark has no `image` key, as in files written before this change).
- `main(argv)`: writes `<out_dir>/stats.tsv` (header row + rows, tab-separated) and prints the path; exit 1 with a message when no `benchmark.json` is found.
- `tools/test_look_matrix_stats.py` (unittest, run as a script like `tools/test_i18n_po.py`; temp dirs via `tempfile.TemporaryDirectory`): two variants with two bookmarks each give 4 rows in variant, then bookmark-file order with the right values; a bookmark without `image` gives blank image cells; an empty dir makes `main` return 1 and write no file.

Test: godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_bench_stats.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd && python3 -I tools/test_look_matrix_stats.py && sh -n tools/look_matrix.sh

While iterating run one at a time through `orb-test` as in the rules above; run the whole `Test:` line's parts once before handing off (`tests/test_graphics_quality.gd` exercises the Benchmark class).

## Hand-off

- Commit on `art/p1-look-matrix`, push, open a PR against `main` titled `Benchmark image stats and look comparison matrix tool`. Body: what changed, the `Test:` results with times in JST, "Acceptance row: none (tooling for SLICE_PRINCIPE §6 Values)". Not a visual change. Do not merge.
- Do not edit `scripts/**`, `shaders/**`, `tools/look_shots.gd`, `tests/test_graphics_quality.gd`, `project.godot` or `docs/` (another worker edits those in parallel).
- Final report: files changed, test output lines, PR number, anything you could not do.
