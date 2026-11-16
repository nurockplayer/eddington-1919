# guard-timeout diagnosis (read-only) — PR #350, issue #347

Worktree: /Users/tachikoma/Developer/eddington-1919-wt/guard-timeout (branch fix/guard-timeout, head 7b8e0b3). Do NOT commit, push or edit tracked files. Report facts and options; the lead decides the fix.

## Facts so far (2026-11-16 JST, Mac host under heavy swap, 6 workers)
`tests/test_test_guard.gd` (PR diff: `_fixture()` now runs each child via `/bin/sh -c exec godot ... >log`, polls `OS.is_process_running`, kills at CHILD_CAP_S=30 s) failed twice on the Mac host:
- run 1: 20 checks, 14 failures; run 2: 20 checks, 3 failures:
  - `idle deadline takes 3 to 20 s` (guard_idle took >= 20 s)
  - `guard_script_error finished before the 30 s outer cap` and `fail-fast opt-out still exits 124` — output shows `SCRIPT ERROR ... FAIL: deadline 3 s exceeded (res://tests/fixtures/guard_script_error.gd)` then the child kept running until the 30 s cap (`capped: true`, 30.249 s).
- Guard: `scripts/test_guard.gd:47-52` `_process` prints the deadline line then `get_tree().quit(124)`; `_exit_tree` lines 54-59.
Old logs: /tmp/guard-timeout-validation/normal.log.

## Questions
1. Is it host load? Run the focused suite on dot (Linux, no shared Mac load) 3 times; report checks/failures and the child `seconds` values for each fixture.
   Test: orb-test --dot -- godot --headless --path . --script res://tests/test_test_guard.gd
   (If the worktree needs import first: `orb-test --dot -- godot --headless --path . --import` once.)
2. If it still fails on dot: why does a child that printed the deadline line and called `quit(124)` not exit (or exit slowly)? Check with the opt-out fixture (EDD_FAILFAST=0, EDD_TEST_DEADLINE=3) run directly as one child under `orb-test --dot`, timing with `/usr/bin/time`. Candidates to confirm or rule out: quit() from `_process` in this node not ending the main loop when the main script is a SceneTree `_run`/`_initialize` that blocks; child stdout redirection through `/bin/sh -c exec`; `OS.is_process_running` on the sh pid vs the godot pid.
3. Options for the fix (each with a one-line diff sketch and its risk), plus your recommendation. Also say whether the 20 s / 30 s bounds should be widened or the check made load-tolerant.

## Rules
- All Godot runs through `orb-test --dot` (never bare godot on the host; never the Mac slot). Long runs via `job-run`, end with a `WAIT:` line.
- Every time you write carries its zone (JST; convert UTC container output).
- Leave nothing behind; you may delete /tmp/guard-timeout-validation at the end (`rm -r`, not `rm -rf`).
- Final report: facts (with run outputs summarised), answers to 1–3, recommendation. Any choice that changes behaviour → `DECISION:` line.
