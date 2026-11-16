# #358: fifth-card rejection must not fire after the plan board closed

Worktree: /Users/tachikoma/Developer/eddington-1919-wt/plan-shake-finish (branch fix/plan-shake-finish from main 56b5bd9). Public repo, oracle-OK.

## Bug (issue #358)
`scripts/cambridge/plan_board.gd` `_toggle_card()` lines ~144-155: with reduced motion off, a fifth pick shakes the button (`await shake.finished`, ~160 ms) and then emits `reaction`. Finish stays usable during the shake. If the player presses Finish in that window, `_finish()` emits `finished` (director `_finish_plan`, scripts/cambridge/director.gd:566, hides the board and starts the `plan_finish` dialogue) — or `blocked` (director.gd:141, also hides the board). The late `reaction.emit` then opens a `board_reaction` dialogue (director.gd:140) that replaces the pending purpose; dismissing it returns to the board instead of the trial.

## Change (diff sketch)
```gdscript
				await shake.finished
				button.disabled = false
+				# The player may finish (or be blocked) during the shake; the board is then closed.
+				if not visible:
+					return
			reaction.emit([...])
```
Nothing else in product code.

## Test (tests/test_prologue.gd, next to `_test_plan_limit` ~line 280)
Add a case driving the real flow with reduced motion OFF: open the board, pick four valid cards by focus + KEY_ENTER (as `_test_plan_limit` does, advancing dialogues), focus the fifth card ("conditions") and press ENTER, then immediately (same or next frame, before ~160 ms) focus `finish_btn` and press ENTER. Then wait ≥ 350 ms of frames. Acceptance:
- the active dialogue is the plan-finish one (not "板上只寫得下四件事——先拿掉一張。"); after advancing it through, the story moves on as in the existing plan-finish path (`Story.plan` equals the four ids, the board stays hidden) — check what the existing plan-finish test asserts and assert the same end state;
- restore `Settings.reduced_motion` afterwards.
Pick four cards that pass `can_finish` without a bias card (see `_finish()`).
Revert check: commit the fix first, temporarily remove the 2 guard lines, run the suite, confirm the new case fails, restore with git on a clean tree. Report it.

## Rules
- Godot only via `orb-test --dot` (never `--host`/the Mac slot). dot may run Godot 4.6.3 until harness moves it to 4.7.2; report the version printed. Long runs through `job-run`, end with a `WAIT:` line.
- Every written time carries its zone (JST).
- Open a ready PR "fix: drop the plan limit reaction after the board closes" that says "Closes #358" in the body, and names acceptance row: none (bug fix). Delete any /tmp files you made.

Test: orb-test --dot -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_prologue.gd'
