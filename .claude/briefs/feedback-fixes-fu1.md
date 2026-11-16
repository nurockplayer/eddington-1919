# feedback-fixes follow-up 1 (2026-11-16 23:5x JST)

The Mac test slot is jammed; your retry job was stopped by the lead (it sat 4 h waiting for a slot). GitHub CI `suites` passed on fda10aa (Linux, Godot 4.7.2), so the full suite is covered. Do NOT use `--host` or the Mac slot again.

Still owed, all through `orb-test --dot` (dot may still run Godot 4.6.3 until harness switches it to 4.7.2; note the version printed in your report):
1. The focused suites in the Test line below on fda10aa.
2. The revert check from the brief: with the fix committed, temporarily revert the behaviour change, run the touched suites on dot, confirm they fail, then restore with git (`git revert --no-commit` / `git reset --hard fda10aa` on a clean tree only). Report which checks failed in the reverted run.
3. Update the PR #353 body with both results. No code changes unless a test turns out not to fail on revert: then strengthen it (drive the real flow) and push, and say so.
4. Delete /tmp/edd-feedback-pr.md, /tmp/edd-feedback-validate-*.sh and /tmp/edd-feedback-validation-* (`rm -r`, not `rm -rf`).

Test: orb-test --dot -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --script res://tests/test_prologue.gd && godot --headless --path . --script res://tests/test_gamepad.gd && godot --headless --path . --script res://tests/test_totality.gd && godot --headless --path . --script res://tests/test_reduced_motion.gd && python3 -I tools/i18n.py check --require-translated'
