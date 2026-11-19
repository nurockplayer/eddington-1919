# Art director handoff (edd-art, pane w7:pB, Fable 5.2)

**First read: `docs/design/SLICE_PRINCIPE.md`** (the art-direction log: Owner direction, your audition answer, reference images, round log). This file holds only how the seat works and the current state. Lead: `edd-lead` (pane w7:pA).

## The seat
- **Owner 2026-11-16 03:3x JST: the True Colors / Tell Me Why target is dropped; run the style audition in `SLICE_PRINCIPE.md` (top section) first.** Owner picked you (blind audition label Z) on 2026-11-14 13:0x JST, with **saturation pushed toward Y** (GPT's proposal, `docs/design/slice_principe/concepts/Y_*.jpg`). You own the look of the Príncipe slice (camp → totality → darkroom). **Owner 03:4x JST: you pick the style yourself after the audition; edd-lead only checks the fit to the story (eclipse, plate measurement, Newton-to-Einstein turn). Send edd-lead the contact sheets with the pick.**
- You inspect renders and videos yourself, decide, implement small visual changes directly, and delegate larger implementation: `quota-advisor --tier routine|hard`, then `lead-wait run <label> -- cx-exec <worktree> <brief>` (Terra default; Sol for hard shader/lighting work). **Owner 2026-11-14: Codex quota is ample, use it freely.** Briefs follow the global CLAUDE.md (files, lines, diff sketch, one `Test:` line, acceptance cases).
- Every decision goes in the log in `SLICE_PRINCIPE.md` with the images judged, and through `lead-decision --role edd-art --repo nurockplayer/eddington-1919 "<decision>; <why>"` when it changes behaviour or scope.
- Visually consequential PRs stay draft until you accept them in a PR comment with the screenshots you judged; then run `lead-wait pr <n>` yourself (oracle; the repo is public and oracle-OK) and tell edd-lead on merge: `lead-inbox add edd-lead art merged <pr> "<one line>"` + `herdr pane send-text w7:pA "<one line>"` then Enter. Anything that touches non-art code paths (narrative, audio, release) goes to edd-lead first.

## Rules that bind renders
- Windowed Godot only to look, **only through `orb-test --heavy` (it waits for the heavy gate; when it opens: `heavy-window --help`)**, with `--fixed-fps 60 --always-on-top`, through `orb-test --heavy --host -- …`. Headless runs anytime (but save no images). Capture tool: `tools/look_shots.gd` (see its header); add slice views to it as needed.
- Windowed runs only when `heavy-window` says open (`heavy-window --help`; no clock window, Owner 2026-11-19 JST): `env ORB_TEST_IDLE_MIN=3 orb-test --heavy --host -- /Volumes/KIOXIA/eddington-1919-cache/director/look-matrix/run_windowed.sh <out> <variants.tsv> <deadline HHMM>` from the worktree (stops on any keyboard or mouse activity).
- Perf: memory `eddington-perf-method` (wall-clock is display-capped; forced-draw ≥3 clean reps). Target 30 fps 720p on GTX 1650 class.
- True Colors / Tell Me Why stills: KIOXIA only (`/Volumes/KIOXIA/eddington-1919-cache/director/refs/`), never in the public repo. Codex image gen: record prompt and provenance next to each image.
- Tests through `orb-test` only; Godot suites need `--host` (fresh worktree: `godot --import` first).

## Older art threads (not active)
- HG route from `edd-characters`: draft PRs #31, #38, #52, #80, worktrees `c02`–`c04g`, `hg-proto`; history `.claude/lead-handoff/characters.md`. Read only if characters go the HG way (needs Owner licence/money).

## Status (2026-11-19 09:2x JST)
Slice acceptance (SLICE_PRINCIPE "Slice acceptance (engraving …)"): **0/9** rows pass. Style = **engraving** (picked 2026-11-17; poster fallback). Rows 3 and 6 are met on the audition branch only.

**In flight (each leaves one inbox event; `lead-wait --role edd-art list`, `orb-test --status`):**
- `lw-sa-r11-20261119-092442`: round 11 render of `art/style-audition` 6a48217, 9 variants x 5 frames into KIOXIA `director/style-audition/1119-r11/` (variants `r11.tsv`, script `run_r11.sh`). Never compiled on a GPU: on SHADER ERROR fix and requeue (`lead-wait --role edd-art run sa-r11 -- bash …/run_r11.sh`).
- `lw-dotted-line-diag-20261119-092444`: read-only Codex Sol diagnosis of the dotted sagging line in the totality sky (brief `.claude/briefs/totality-dotted-line-diag.md`). When it reports: decide the removal (it is noise in the hero frame, row 4), log it.

**#372 (micrometer graduations):** head e08a1e8 NOT accepted 2026-11-19 09:2x JST (PR comment 6995642744; first verdict 6993462250). Holds: antialiased ticks and crosshair, ruler beside the star, caret, rows say 測微器. Open: (1) at least 5 px between ticks counted in window pixels (720p shows 4: `_mic_tick_step` counts in the 1600x900 canvas), (2) tick values from the 1, 2, 5, 10 series, numbered ticks on round decimals, (3) numerals readable in the 720p full frame (now 6 px high, 70/255). edd-lead has it (event ev-20261119-092022-64a3 in their inbox). On a new head: resume or restart the capture (brief `.claude/briefs/accept-shots-372-fu1.md`, tool on KIOXIA `director/accept/372/tool/`; frames `micro_r0|r6|r23` at x1 and x2, 720p and 1080p), enlarge the scale 4x (`magick -crop 130x125+530+262 -filter point -resize 400%` on the 720p frame), measure the pitch with a row profile, judge, copy frames to `docs/design/slice_principe/accept/372/<head>/`, PR comment, log entry, `lead-inbox add edd-lead pr '#372' art-accept|art-reject "<line>"` + `herdr pane send-text w7:pA …` + `herdr pane send-keys w7:pA Enter`.

**#376 (bets on the report chart):** ACCEPTED at f19c10a 2026-11-19 09:2x JST (PR comment 6995747346, frames `docs/design/slice_principe/accept/376/`); edd-lead runs the gate. Nothing left for me unless the head moves.

Round 10 is judged (log entry of 2026-11-19 09:2x JST, crops `audition-1119/r10-*.jpg`): contours gone by day, sky opens to the horizon, but distant land still prints paler than the sky (ink share 0.10 to 0.14 against 0.23 to 0.26): the floor was scaled by the distance fade, so mid-distance sunlit palms (40 m) fell into a trough.

Round 11, what to judge (same five frames; compare against `1119-r10/base/`):
- Day: do the far palms and the ridge now print a tone darker than the sky beside them (`far_in` 0.25; `in10`, `in50`, `in100` = close to round 10)? Measure: `magick <png> -crop <patch> -colorspace Gray -threshold 50% -format '%[fx:1-mean]' info:` on `house` patches `200x60+40+270` and `160x80+1050+260` (land) against `160x60+1050+150` (sky); land must exceed sky. Do nearer things (the far building in `arrival`, bushes at 25 to 35 m) get too heavy under the early floor (`start15` moves the fade nearer)?
- `wfar40`, `wfar0`: does distant land read better with less wash (yellow stains in round 10)?
- Totality frames must equal round 10's (the floor is day only).
- If row 1 holds: fix the defaults, log entry with images, memory `style-audition-1116`, then step 1 below. Style suite: `orb-test --host -- godot --headless --path . --script res://tests/test_style_engraving.gd` (15 s).

Next after row 1, in this order:
1. Row 2: 60 fps capture of a walk and a turn (no movie tool yet: `--bench-walk` in `tests/benchmark.gd` or `--write-movie`); judged frame by frame; then ask edd-lead for the Owner's gut reaction. Reference input (read, acked): `docs/research/ref_visuals_2026-11-17.md`.
2. Implementation branch for main (the audition branch never merges): from main, #318 + #339 plumbing, engraving as the default look, audition bookmarks, alpha-blended objects (Label3D signs, Sun crescents, fireflies) drawn after the pass, HUD and panels on paper, evidence UI untouched. Brief for Codex (`quota-advisor --tier hard`; Codex is behind pace: Sol high) once the shader has settled; draft until I accept its frames. #339's `tools/look_matrix.sh` still has the old clock check (fixed on the audition branch: asks `heavy-window`); main's `tools/look_shots.gd` header still names the clock window.
3. Geometry PRs, draft: #341 veg-cards (windowed readback test, forced-draw perf), #349 ridges, #344 darkroom props (shared `eye_white` line / regenerated `scripts/palette.gd` with p3), #329 totality staging: accept each with engraving frames plus its technical check, then `lead-wait pr <n>`.
4. #356 coelostat-trim (edd-lead's draft): see its panel under the pass, comment on the PR.
- Worktrees `-wt/sa-engraving`, `sa-silver`, `sa-poster` (branches `art/sa-*`, merged into `art/style-audition`, no PRs): removable.

Notes that still hold: workers own the problem (brief = problem, goal, acceptance cases, constraints, one `Test:` line; no diff sketch); check a capture run's receipts against the state each file is named for before judging (the first #376 run named nine states it had not reached); a Godot `Test:` line starts with `orb-test --host -- …`; windowed and readback runs stay on the Mac behind the heavy gate; a `--script` test with a script error hangs (`--check-only` first); headless Godot compiles no shader; `test_totality` needs more than 300 s at one CPU; `lead-inbox list edd-art` lists, `herdr pane send-keys w7:pA Enter` submits a pane line; take the time for a log entry from `date`, not from memory.
