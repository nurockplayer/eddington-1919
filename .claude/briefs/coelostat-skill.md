# Brief coelostat-skill: design options for a calibration skill at the coelostat (read-only)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/fun-audit` (detached, shared read-only with another read-only run). **Change no file**; the report is your final message.

## Why
Fun audit (issue #351, option 4): preparation at Príncipe is timed holds that set flags (`scripts/main.gd` ~878–958: `drive_wound`, `drive_rate_checked`), yet drift from a badly driven coelostat is a real consequence on the plates (`scripts/eclipse_sim.gd` ~194–206, ~239–281; rendering `scripts/plate_render.gd` ~31–81). The idea: replace the rate-check hold with a short skill where the player sees a star drift and trims the clock rate until it holds still, so the result they later see on the plates is theirs.

## Report
1. Current flow: every hold, flag and consumer of those flags (file:line), what the autoplay bot does there (`tests/autoplay_bot.gd`), which tests assert it (grep `tests/`).
2. Historical check from repo sources only (`docs/HISTORY_1919.md`, `docs/research/`): how the 1919 Príncipe coelostat drive was regulated and checked, so the interaction is honest. Flag anything the repo does not support.
3. Two or three interaction designs (sketch the screen and inputs, keyboard and gamepad, ≤ 60 s of play, how failure shows up later on the plates, a hint after N s of no progress, reduced-motion behaviour). For each: files to touch, new state (save/checkpoint impact), test and autoplay changes, estimated effort S/M/L, risks.
4. Your recommendation with the reason. The lead decides.

## Limits
No Godot, tests, builds or web research. Times in JST.

Test: none (read-only design proposal)
