# Brief feedback-fixes: two silent rules made visible (fun audit gaps 4 and 6)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/feedback-fixes`, branch `fun/feedback-fixes` from origin/main. Godot 4.7.2, GDScript with tabs. First, in the fresh worktree: `orb-test --host -- godot --headless --path . --import` (else suites fail or hang).
Source: the fun audit of 2026-11-16 18:06 JST (issue #351 quotes it). Design intent: issue #37.

## Changes
1. Plan board fifth card (`scripts/cambridge/plan_board.gd:_toggle_card` ~138–146): today a fifth pick is silently un-pressed. Instead keep it un-pressed and show a one-line reaction in the board's existing reaction area (emit `reaction` with one line, e.g. "板上只寫得下四件事——先拿掉一張。"), and give the card a short shake (none under `Settings.reduced_motion`).
2. Rehearsal plate-change timing (`scripts/main.gd:_finish_rehearsal` ~1238–1246): it waits `sim.PLATE_CHANGE_S` real seconds, but in real totality `change_left` counts game time at `sim.TIME_SCALE` (~1307–1343), i.e. about `PLATE_CHANGE_S / TIME_SCALE` real seconds. Make the rehearsal wait match the real rhythm (`PLATE_CHANGE_S / sim.TIME_SCALE`), and keep the toast's "四秒左右" only if it still matches what the player experiences; if not, reword it to the real-time feel (it is game-clock seconds, say so plainly or drop the number).

## Rules
- Player-facing text: write the zh-TW source wrapped in `L.t("…")` (the msgid), then `python3 -I tools/i18n.py extract` and add en, ja and ko translations with `tools/i18n.py apply` (match the tone of neighbouring entries; keep placeholders and BBCode). `tools/i18n.py check --require-translated` must pass.
- Tests through `orb-test` only, only the suites in the `Test:` line while iterating. A behaviour test must drive the real flow (the same calls the player's input makes), not only a helper, and must fail when the fix is reverted: commit the fix first, revert the change temporarily, run, then restore with git (never `git checkout` over uncommitted work). Report the revert result.
- Host: 16 GB shared Mac. Times in reports carry JST. Open a ready PR against main naming "Refs #351"; do not merge.

Test: orb-test --dot -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_prologue.gd && godot --headless --path . --script res://tests/test_gamepad.gd && godot --headless --path . --script res://tests/test_totality.gd && godot --headless --path . --script res://tests/test_reduced_motion.gd && python3 -I tools/i18n.py check --require-translated'
