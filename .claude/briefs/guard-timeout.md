# Brief guard-timeout: an outer wall-clock cap for test_test_guard's child runs (issues #347, #348)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/guard-timeout`, branch `fix/guard-timeout` from origin/main. Godot 4.7.2, GDScript with tabs. First run in a fresh worktree: `orb-test --host -- godot --headless --path . --import` (else suites fail or hang).

## Problem
`tests/test_test_guard.gd:19-25` `_fixture()` runs each fixture with a blocking `OS.execute(..., output, true)`. If a regression stops `TestGuard` (`scripts/test_guard.gd`) from enforcing `EDD_TEST_DEADLINE`, the `guard_idle` fixture never exits and the parent test blocks forever; the parent's own 900 s guard cannot fire while blocked in `OS.execute`.

## Change
Replace the blocking call with a launched process and a wall-clock cap the code under test does not control. Sketch (portable to the macOS host, which has no GNU `timeout`):

```gdscript
const CHILD_CAP_S := 30.0

func _fixture(filename: String) -> Dictionary:
	var log_path := ProjectSettings.globalize_path("user://guard_%s.log" % filename)
	var cmd := "exec %s --headless --path %s --script res://tests/fixtures/%s.gd >%s 2>&1" % [
		OS.get_executable_path().c_escape()..., ...]   # quote each path for /bin/sh
	var started := Time.get_ticks_msec()
	var pid := OS.create_process("/bin/sh", ["-c", cmd])
	while OS.is_process_running(pid) and Time.get_ticks_msec() - started < CHILD_CAP_S * 1000.0:
		OS.delay_msec(100)
	var capped := OS.is_process_running(pid)
	if capped:
		OS.kill(pid)
	var code := OS.get_process_exit_code(pid)   # -1 when killed or unknown
	... read and delete log_path ...
	return {"code": code, "output": text, "seconds": ..., "capped": capped}
```

- Quote paths for `/bin/sh` safely (single quotes, escape embedded single quotes); the project path can contain spaces.
- A capped child is a failure: add `check(not result.capped, "<fixture> finished before the %d s outer cap")` for every fixture call in `_run()`, and keep the existing exit-code checks (70, 124, 0) as they are.
- Verify `OS.get_process_exit_code` returns the child's real exit code after `exec` on Godot 4.7.2; if it does not, say so in the report with a `DECISION:` line instead of guessing.
- Delete the per-fixture log files at the end (one-off data rule).
- Close both issues in the PR body with "Closes #347" and "Closes #348" (#348 is the same finding).

## Acceptance
1. All current checks in `test_test_guard` still pass.
2. Revert check: temporarily make `scripts/test_guard.gd` skip the deadline (commit the fix first, then edit, run, `git checkout` the file): the test now fails with the cap message within ~35 s instead of hanging. Report the output; do not commit the broken guard.

## Limits
Host: 16 GB shared Mac; tests only through orb-test, only the suite you touch. Times in reports carry JST. Open a PR (ready, not draft) against main; do not merge.

Test: orb-test --dot -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_test_guard.gd'
