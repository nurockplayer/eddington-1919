# Engraving on main

Príncipe defaults to engraving. This ports the judged look of `art/style-audition`
`7406dec` onto main's geometry. Slice rows **1, 3 and 6** are available for the
art director to rejudge; acceptance remains **0/9** until that judgement.

## Source

- #318 (`a4ef072`): Príncipe lighting parameters, lighting hooks, quality metadata,
  camera FOV and vignette post. Cambridge and departure keep their existing look.
- #339 (`9a53b98`): benchmark image statistics and the TSV comparison runner.
- Audition `7406dec`: unchanged `shaders/style_engraving.gdshader` and
  `scripts/styles/engraving.gd`, runtime pass, portrait and its provenance,
  named bookmarks, resolution capture and the motion tools.
- This PR supersedes #318 and #339; both remain open and untouched.

The runtime wrapper always selects engraving; `--style-set=key=value,key=value`
overrides its float parameters. Main's existing `--no-grade` comparison option
retains its ungraded rendering behavior. No saved setting or measurement changes.
The rejected audition styles and the four geometry PRs are not imported.

## Capture

From the branch root, choose a fresh job ID and an absolute KIOXIA output path.
All windowed commands run through `job-run` and `orb-test --heavy --host`.

```sh
job-run --id eng-main-frames -- orb-test --heavy --host -- godot --path . --resolution 1280x720 --fixed-fps 60 --always-on-top -- --benchmark=<OUT>/<short-head>/branch --bench-only=arrival,house,coelostat_still,totality_sky,totality_wide,totality_horizon,dialogue,darkroom --bench-size=1280x720 --bench-cloud-t=215 --seed=7
```

Run the same Godot command from the read-only audition checkout with
`--style=engraving` and an `audition` output directory. Repeat `arrival` on the
branch into `repeat` to measure the wind/animated-ring range. Pixel counts use
maximum RGB difference strictly above 6%, in twelve 320x240 cells, row-major.

For a table of variants, write tab-separated names and Godot user arguments:

```tsv
judged	--bench-cloud-t=215
lines7	--bench-cloud-t=215 --style-set=line_px=7
```

```sh
FRAMES=arrival,house,coelostat_still,totality_sky,totality_wide,totality_horizon,dialogue,darkroom job-run --id eng-main-variants -- orb-test --heavy --host -- tools/style_audition.sh <OUT>/variants variants.tsv
job-run --id eng-main-motion-day -- orb-test --heavy --host -- tools/style_motion.sh <OUT>/motion-day day
job-run --id eng-main-motion-totality -- orb-test --heavy --host -- tools/style_motion.sh <OUT>/motion-totality totality --style-set=ground_mottle=0.7
```

The motion command records 960 PNGs: ten seconds walking and six seconds turning,
at 60 fps, plus camera coordinates, image-change statistics and an MP4 when
ffmpeg is installed. Use fresh directories. For resolution comparison, render
`--bench-only=coelostat_still` with `--bench-size=1920x1080` or
`--bench-size=2560x1440` and distinct output directories; retain fixed 60 fps.

## Validation and frames

Pending the detached import, focused suites and windowed capture. The delivery
report records their actual results, per-cell counts, evidence-image counts,
windowed diagnostics and CI status; no art acceptance is claimed here.

## Assumptions

The explicit requirement to keep the PR draft takes precedence over the generic
one-shot instruction to open it ready. The diff exceeds 300 lines because it
ports the existing shader, parameter table, benchmark/statistics and motion
capture tools required by the acceptance cases, rather than replacing them.
The audition's sky-bookmark framing lives in the benchmark; gameplay geometry,
totality staging, story and measurement code remain main's.

## Out of scope

Alpha-blended signs, Sun crescents and fireflies can be hidden or drawn wrongly
by the pass. HUD and menus retain their existing colours. Main's vegetation,
ridges, darkroom props and totality staging differ from the audition's four
unmerged geometry PRs. These are reported on the captured bookmarks, not tuned.
