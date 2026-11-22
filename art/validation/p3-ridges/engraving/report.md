# p3-ridges: engraving regression results

Written 2026-11-22 00:45 JST. Draft PR #349; based on main `4a3004fbc6eba41ae6892b0c6c4dd5104e086f02`.

## PR or commit

Three sculpted ridge rings replace the five hemisphere hills. The rebased palette changes only add the near-ridge swatch; unrelated old palette changes were removed. Engraving tunable defaults, the eclipse simulation and the ridge GLB are unchanged. The motion launcher omits `--bench-size`, using native `--resolution 1280x720` without assigning `content_scale_size`.

Acceptance scope: **slice acceptance rows 1, 2, 4, 9 (regression check), silhouette and depth**. PR stays draft. These checks preserve the seven accepted main rows; they do not promote the still-open slice rows 2 or 8.

## Acceptance cases

### 1. Integration and geometry

Rebased without conflicts onto main `4a3004f`. `test_ridges`: **373 checks, 0 failures**. Three rings; no hemisphere hills; the open sector and tower dimensions pass the existing test. The unchanged GLB retains G2 qualification: **26,032 / 30,000 triangles**, **2 / 2 materials**, **0 texture pixels**, **0 degenerate faces**, **0 loose vertices**. No Blender rebuild was needed or run. The recorded bottom-centre exemption remains as declared.

### 2. Distant land

Native 1280x720 frames; main left, ridge head right in each sheet. Ink share is the fraction of a rectangular patch whose ImageMagick grayscale value is below 50%, matching the mid-grey method of the 2026-11-19 09:4x JST log entry.

| frame | main matched ridge patch | main matched sky patch | head ridge | head sky above | head ridge minus sky |
|---|---:|---:|---:|---:|---:|
| house | 0.120313 | 0.157813 | 0.235938 | 0.157813 | +0.078125 |
| arrival | 0.231944 | 0.197917 | 0.231944 | 0.152083 | +0.079861 |
| coelostat_still | 0.250000 | 0.270000 | 0.235556 | 0.136667 | +0.098889 |

The ridge patches on head are all darker than the sky above. Upper edges are continuous, with a flat ruled tone; no dotted seam or pale blob with wavering edges was seen at native scale. Rectangles (x,y,width,height) are in `ridge-ink.json`. Baseline values use the exact same rectangles; because the hemisphere skyline differs, a rectangle sampling head sky can contain a main hill, and a head ridge rectangle can contain main sky. The numbers compare the same screen area rather than claiming identical land masks. See the full sheets and native crops alongside the measurements.

### 3. Row 4: totality and Sun clearance

**2 / 2 frames** checked: `totality_horizon` shows the massif and two plugs as dark silhouettes against blue paper; `totality_wide` keeps the eclipse-Sun sector below the Sun and corona. No new star-like hatching artefact was seen. The Sun/corona box at (520,20,240,250) is pixel-identical to main: **0 / 60,000 pixels** differ, at any RGB difference. The open-sky box of `totality_horizon`, (950,0,300,90), is also identical: **0 / 27,000**. These are measured boxes, not a claim that the complete horizon frame is identical. The star-position and Sun-track tests pass below.

### 4. Row 1: line work

**7 / 7** named head frames inspected at native scale with main/head comparison sheets: `house`, `arrival`, `coelostat_still`, `dialogue`, `totality_wide`, `totality_horizon`, `darkroom`. No new moire patch, dotted seam or noise field wider than **64 px** (1280 / 20) was seen. Near surfaces retain main's deliberate cross-hatching. The complete darkroom frame is pixel-identical to main: **0 / 921,600 pixels** differ. Full-size PNG sheets preserve exact pixels; the committed JPEG sheets make the comparisons accessible in the PR. Numeric frame differences in `pixel-regression.json` describe changed geometry, not an automated visual-artifact classifier.

### 5. Row 2: motion regression

`tools/style_motion.sh <out> day` and `totality`, native 1280x720, fixed 60 fps, seed 7. Compare frames **300 and 330**, bottom **140 rows**, any RGB channel differing by strictly more than **6%** (15.3 / 255).

| state | head changed pixels / 179,200 | main | delta |
|---|---:|---:|---:|
| day | 138,568 | 138,568 | 0 |
| totality | 35,222 | 35,222 | 0 |

Retained in each `motion-<state>/`: `motion.mp4`, `f_00300.png`, `f_00330.png`, camera/statistics/logs and `bottom140.json`. The other **958 PNG frames per state** were deleted after their sheets were made. This meets the requested motion regression metric; the slice's broader art-director/Owner motion verdict remains as recorded on main.

### 6. Row 9: performance

**3 / 3 clean repetitions**, standard quality, native 720p, seed 7, totality cloud time 215, Apple M2 Pro/Metal. Historical shelter probe and existing benchmark sampler: 60 warm-up frames, 20 settle frames, 180 wall frames, **240 forced draws** per variant, pass on/off adjacent; reverse order in repetition 2. Windowed launches use `--fixed-fps 60 --always-on-top`. No viewport-size override. The inherited method hides the shelter roof, as in the baseline.

| repetition | pass-on forced avg ms | pass-on forced p95 ms | pass-off forced p95 ms |
|---|---:|---:|---:|
| 1 | 3.73 | 6.36 | 3.84 |
| 2 | 3.30 | 5.27 | 3.90 |
| 3 | 3.36 | 5.28 | 3.90 |

Worst p95 **6.36 ms × 3 = 19.08 ms**, estimated **52.4 fps**, against the **33.33 ms / 30 fps** row. Baseline at `198877e`: **56.2 fps**; difference **-3.8 fps**. Median p95 **5.28 ms**, ×3 **15.84 ms / 63.1 fps**. Row 9's threshold remains met under the same dev-Mac class estimate; these are not direct GTX 1650 measurements. Boundary snapshots, overlap-ledger and pause checks record all three repetitions clean in `performance.json`.

### 7. Numerical regression tests

`test_sim`: **241 checks, 0 failures**. `test_totality`: **658 checks, 0 failures**. Both passed check-only first. Star positions and the Sun's track are unchanged; no simulation code was edited.

## Tests

All Godot launches ran inside `orb-test --heavy --host`, with import first and check-only before the test/probe scripts. The exact six-test Test line is left to cx-exec, as instructed; it has not been run separately by this worker.

Completed capture job:

```sh
orb-test --heavy --host -- python3 /Volumes/KIOXIA/eddington-1919-cache/director/p3-ridges/e1e6a56f1baa9a6d3468c6d1152d4cceeef18250/shots.py /Users/tachikoma/Developer/eddington-1919-wt/p3-ridges
```

Last script result: `SHOTS: 7 native 1280x720 main/head pairs; PNG scratch removed; full-size PNG and JPG sheets retained`. Wrapper exit **0**.

Completed regression script, followed by nonzero wrapper exit:

```sh
orb-test --heavy --host -- python3 /Volumes/KIOXIA/eddington-1919-cache/director/p3-ridges/92823ac1f9d1272d6fbdbc73ea344e18e833c488/regressions.py /Users/tachikoma/Developer/eddington-1919-wt/p3-ridges
```

Last script result: `REGRESSIONS: two motion captures, retained frames, and three clean performance repetitions complete`. Last wrapper line: `tachi-run: OrbStack VM stopped (memory released)`. Job result: **status failed, exit_code 145, signal null**. The saved script outputs include both movies, retained frames and all three clean repetitions; subprocesses used check=True and the script reached its final completion line. This aggregate job is not reported as a passing wrapper run, and it was not retried.

Individual test commands inside those wrappers:

```sh
perl -e 'alarm shift; exec @ARGV' 1500 godot --headless --path . --script res://tests/test_ridges.gd
# test_ridges: 373 checks, 0 failures
perl -e 'alarm shift; exec @ARGV' 1500 godot --headless --path . --script res://tests/test_sim.gd
# 241 checks, 0 failures
perl -e 'alarm shift; exec @ARGV' 1500 godot --headless --path . --script res://tests/test_totality.gd
# 658 checks, 0 failures
```

Godot emitted ObjectDB/resource-in-use exit warnings; these remain recorded in the test logs. No shader, script or style compilation failure occurred in the accepted captures. Do not treat the exit warnings as absent.


### Layout timeout follow-up

The cx-exec six-test run passed `test_ridges` (373 checks), `test_style_engraving` (459 checks), and `test_look` (54 checks), then stopped at `FAIL: deadline 900 s exceeded (res://tests/test_layout_bounds.gd)`.

The focused diagnostic at `d76420c` completed successfully on 2026-11-22 01:52 JST:

```sh
orb-test --host -- sh /Volumes/KIOXIA/eddington-1919-cache/director/p3-ridges/d76420ccd14526bf90a64559487496756b7abb33/layout-profile.sh
```

The legacy command delegated to `tachi-run` on the host. The script imports, runs check-only, then executes an inherited `test_layout_bounds.gd` with timing overrides; every assertion, case, five-frame settle, and the **900-second guard** remain active (`EDD_TEST_DEADLINE=900`). Result: `test_layout_bounds: 12243 checks, 0 failures`; job exit **0**. The final log lines retain the existing ObjectDB/resource-in-use exit warnings.

Measured stages: totality toast **140.471 s**, merged dialogue **112.785 s**. At the last window/scale entry, elapsed time was **721.120 s** and accumulated settle waits were **351.127 s** across **815 calls**. Waiting for layout frames accounts for much of the observed runtime; this successful run does not establish why the earlier run exceeded its deadline. No product or test change is justified by a failure that did not reproduce. The diagnostic script and complete 76-line log remain beside the other head artifacts.

## Assumptions

- The latest continuation explicitly requests a ready PR; marking #349 ready does not grant lead art acceptance.
- No engraving default needed changing. `far_in` 0.25, `far_step` 0.16 and `wash_far` 0.4 remain unchanged.
- Capture provenance names rendered head `e1e6a56` and reference main `94a7255`; motion/tests/performance ran at `92823ac`. Later rebases add main's documentation, tests, Cambridge overlay/locale and capture-postprocessing changes, with no Príncipe rendering/gameplay-code difference. The last commit adds evidence only.
- The inherited diff exceeds 300 lines because it contains the original ridge generator, previews and existing ridge test, plus this requested acceptance report. No vegetation-card integration is included.

## Follow-ups

Lead art acceptance and cx-exec's six-test Test line. The focused layout diagnostic passed without changing code; the complete six-test command has not subsequently completed. Whichever geometry PR lands second rebases.

## Blocked

No product action blocked. The regression wrapper returned **145** after completed measurements and VM cleanup; lead should retain that infrastructure result alongside the complete per-command evidence rather than call the aggregate job green. No denied action and no retry.


## Rendering head 1689fe1: capture handoff

This section supersedes earlier rendering, motion, and performance claims for the current candidate. PR #349 stays draft pending lead art acceptance. Totality now flattens the ridge below eye level, drops the tower spike, and prints sparse horizontal ruling on cream paper; day rendering is unchanged.

Seven native 1280 × 720 main/head pairs and two full-size horizon crops completed at rendering commit `1689fe126cb9bb2b65c579da86471fd6a83df580`. Main is left and candidate is right. JPEG sheets and PNG horizon crops are attached under `docs/design/slice_principe/accept/349/1689fe1/`. Original frames, PNG sheets, scripts, and logs remain at `/Volumes/KIOXIA/eddington-1919-cache/director/p3-ridges/1689fe126cb9bb2b65c579da86471fd6a83df580/`. These attachments carry no new visual acceptance claim.

Completed inside `tachi-run --heavy --host` after import and check-only:

- `test_ridges`: 373 checks, 0 failures.
- `test_sim`: 241 checks, 0 failures.
- `test_totality`: 658 checks, 0 failures. Existing ObjectDB exit warnings remain in the logs.

Command:

```sh
job-run --id p3-ridges-perf-1689fe1 -- tachi-run --heavy --host -- python3 /Volumes/KIOXIA/eddington-1919-cache/director/p3-ridges/1689fe126cb9bb2b65c579da86471fd6a83df580/capture.py /Users/tachikoma/Developer/eddington-1919-wt/p3-ridges
```

Result: job failed, exit 145, ended 2026-11-22 14:09:29 JST. Last error: `subprocess.CalledProcessError: Command ['bash', 'tools/style_motion.sh', '/Volumes/KIOXIA/eddington-1919-cache/director/p3-ridges/1689fe126cb9bb2b65c579da86471fd6a83df580/motion-day', 'day'] returned non-zero exit status 143.` The interrupted day capture has 389 files and no completed movie; totality motion and performance repetitions did not start. Earlier-head motion/performance values above do not qualify this candidate.

One infrastructure retry resumes only both motion runs and three performance repetitions using `resume.py`; it preserves the partial day capture and writes fresh `motion-day-retry1` and `motion-totality-retry1` folders. The exact six-test Test command remains for cx-exec. No product code, test code, or rendering changes accompany this evidence commit.

## Rendering head 9840e74: CI capture handoff

CI captured main `4534b57faee9b108a646cf83a94938672666c051` and head `9840e74d459e41c2236579ba74d73c78619873b7` at 1280 × 720. The seven main-left/head-right sheets and two horizon crops are in `docs/design/slice_principe/accept/349/9840e74/`. Runs 45012350835, 45017225345, and 45019042172 succeeded; the first main batch was previously downloaded. These images await lead art judgment.

Whole-frame day differences, counting pixels with any RGB channel changed: arrival 58,401; house 53,905; coelostat_still 73,226; darkroom 0; dialogue 59,036, out of 921,600 pixels each. No far-land region mask was supplied, so these counts do not establish whether pixels outside that region match.

The imported Mac job completed 960 frames in each motion run: day 139,895 / 179,200 changed bottom-band pixels, totality 24,535 / 179,200. It exited 1 after performance repetition 1 (`totality_sky off forced avg 3.09`; ObjectDB leak warning), with `AssertionError: ['another active run at repetition boundary']`; repetitions 2 and 3 did not run. These results do not establish three clean performance repetitions.
