# Brief measure-flow: the player owns the number (fun audit option 1)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/measure-flow`, branch `fun/measure-flow` from origin/main. Godot 4.7.2, GDScript with tabs. First, in the fresh worktree: `orb-test --host -- godot --headless --path . --import` (else suites fail or hang).
Source: the fun audit of 2026-11-16 18:06 JST (issue #351 quotes it). Design intent: issue #37.

## Problem
In the plate viewer the player picks plates, presses measure (locks the selection, `scripts/main.gd:_on_measure` ~1648 and `_finish_measurement` ~1663), then is meant to read each included plate with the micrometer. But `report_btn` is enabled as soon as the viewer is locked (`scripts/ui.gd:set_viewer_locked` ~1348–1357), so the player can report with zero readings; the only signals are per-plate notes (`ui.gd:_select_plate` ~1325–1332, `main.gd` ~1632–1634). The micrometer instructions sit mostly in a tooltip (`ui.gd` ~791–807).

## Change
1. A visible three-step strip in the viewer, above or beside the buttons: `① 選片 → ② 測微器讀數 n/m → ③ 向 Eddington 報告`, where m = included usable plates and n = those with `read`. The current step is highlighted; it updates on every reading (`refresh_thumbs` / `_refresh_viewer` are the hooks).
2. Move the micrometer's how-to (align the crosshair on the reference star, then record) from the tooltip into a one-line hint shown next to the micrometer controls while the micrometer is on and the plate is unread.
3. Report with n = 0: do not proceed. Keep the button enabled (gamepad focus paths rely on it, see `tests/test_gamepad.gd`) but on press show an Eddington line in the viewer note, e.g. "一張都還沒讀。選中的底片要用測微器讀過，才有數字可以報告。", and play no report sound. n ≥ 1 with some unread: proceed as today (the existing "not counted" note stays).
4. After each recorded reading, flash the thumbnail's "✓讀" mark (a short modulate pulse; respect `Settings.reduced_motion`: no pulse, just the mark).

Check every autoplay route in `tests/autoplay_bot.gd` (~441–461, ~535–547): a route that today reports with zero readings must now read at least one plate, or, if a route exists on purpose to test "no reading", change it to assert the refusal. Do not change scoring or `Judgment`.

## Acceptance
- Reporting with zero readings shows the refusal line and stays in the viewer; with one reading it proceeds.
- The strip shows 0/m after lock and m/m after reading all; it is in the en, ja and ko catalogues.
- All e2e routes still reach their phases (GitHub CI all-suites runs them on the PR; not run locally).

## Rules
- Player-facing text: write the zh-TW source wrapped in `L.t("…")` (the msgid), then `python3 -I tools/i18n.py extract` and add en, ja and ko translations with `tools/i18n.py apply` (match the tone of neighbouring entries; keep placeholders and BBCode). `tools/i18n.py check --require-translated` must pass.
- Tests through `orb-test` only, only the suites in the `Test:` line while iterating. A behaviour test must drive the real flow (the same calls the player's input makes), not only a helper, and must fail when the fix is reverted: commit the fix first, revert the change temporarily, run, then restore with git (never `git checkout` over uncommitted work). Report the revert result.
- Host: 16 GB shared Mac. Times in reports carry JST. Open a ready PR against main naming "Refs #351"; do not merge.

Test: orb-test --dot -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_micrometer.gd && godot --headless --path . --script res://tests/test_plate_reading.gd && godot --headless --path . --script res://tests/test_totality.gd && godot --headless --path . --script res://tests/test_gamepad.gd && godot --headless --path . --script res://tests/test_ending_snapshot.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && python3 -I tools/i18n.py check --require-translated'
