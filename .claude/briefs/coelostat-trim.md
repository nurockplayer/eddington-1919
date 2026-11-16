# Brief coelostat-trim: rate checking becomes a trim skill (fun audit option 4, design A)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/coelostat-trim`, branch `fun/coelostat-trim` from origin/main. Godot 4.7.2, GDScript with tabs. First, in the fresh worktree: `orb-test --host -- godot --headless --path . --import`.

## Design (decided)
Read `/Users/tachikoma/Developer/eddington-1919/.claude/briefs/coelostat-skill-report.md` first: section 1 maps the current flow, flags, consumers and tests; **implement section 3 design A (continuous trim)** as written there, with these decisions by the lead (2026-11-16 18:2x JST, issue #351):
- Entry: after winding, a fresh interact press at the drive hotspot opens the panel; the chronometer hold for rate checking goes away (the chronometer stays inspectable).
- Inputs: left/right (D-pad) trim, Shift/LT fine, interact/Enter/A record, B leave with the current setting, Esc/Start pause. Show the bound keys through `scripts/prompts.gd` like other prompts.
- Success: drift below the deadband for 3 s sets `drive_rate_checked = true`. Cap 45 active s per attempt or remaining prep time; prep time runs while the panel is open, pause freezes it; on prep expiry close with the current result.
- Hint after 10 s with no reduction of measured drift (Cottingham's line from the report). No auto-correction.
- Consequence: signed residual `drive_error` on the sim; for a wound drive `drift = 0.012 + 0.038 * abs(drive_error)` outside the deadband, 0.012 inside it; unwound stays 0.075. Store the final residual in `_record_run`. Unchecked wording means "not verified".
- Reduced motion: the two stationary marks "previous" / "now", updated once a second, with text direction and separation.
- **History honesty:** the panel carries the caption 「追蹤示意圖——示意重建，非史料」 (with en/ja/ko). Cottingham stays responsible for the mechanism; the player watches and asks for adjustments. No regulator hardware, graduations or a live pre-eclipse star check stated as fact. Mark the new code with the repo's existing `# FICTION:` comment convention (see `scripts/eclipse_sim.gd:199-200`).
- Autoplay: the bots observe the drift in the panel and trim toward stillness through real input (no reading of the hidden correct value). The `rushed` route still skips. Replace the binary 16/6 s exposure policy at `tests/autoplay_bot.gd:457` with one that reads `drive_rate_checked` plus the residual.
- The panel is a new UI surface: open the PR as **draft**; the art director accepts its look after the style pick. Include one headless-safe description of the layout in the PR body (no screenshots needed from you).

## Acceptance
1. Real input path: calibration input → real shutter exposure → developed plate. At equal seed, cloud and duration: successful trim < partial trim < abandoned (wound only) in trail length. Test it in a suite that drives `_interact`/input, not only the sim.
2. Keyboard and gamepad both complete the trim; pause during the panel freezes prep time; prep expiry closes it with the current result.
3. Reduced motion shows the stationary marks and the same success rule.
4. All existing suites in the `Test:` line pass after updating the ones the report lists (`test_autoplay_hold`, `test_replay_experiment` direct `_hold_complete("chronometer")`, fixtures). Revert check for acceptance 1.
5. Every e2e route reaches its phases.

## Rules
- Player-facing text in zh-TW wrapped in `L.t("…")`, then `python3 -I tools/i18n.py extract` and en/ja/ko via `tools/i18n.py apply`; `check --require-translated` passes.
- Tests through orb-test only; while iterating, only the suites you touch. Revert check: commit first, revert temporarily, run, restore with git.
- Host: 16 GB shared Mac. Times in JST. PR against main naming "Refs #351", draft; do not merge. If a design point above conflicts with the code in a way that changes behaviour, stop with a `DECISION:` line.

Test: ORB_TEST_TIMEOUT=90 orb-test --host -- sh -c 'for t in test_autoplay_hold test_sim test_totality test_plan_recall test_principe_story test_ending_snapshot test_plate_reading test_i18n test_replay_experiment test_gamepad test_reduced_motion test_layout_bounds; do godot --headless --path . --script res://tests/$t.gd || exit 1; done; python3 -I tools/i18n.py check --require-translated && ./tools/e2e_headless.sh'
