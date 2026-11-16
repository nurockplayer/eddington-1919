# coelostat-trim follow-up 1 (2026-11-17 00:2x JST)

The lead stopped job coelostat-trim-full: it ran on `--host` and sat in the Mac eddington slot behind two other workers. The working tree was restored (`git restore scripts/eclipse_sim.gd`); head is 2253863, tree clean. From now on every Godot run goes through `orb-test --dot` (never `--host`/the Mac slot). dot may still run Godot 4.6.3 until harness switches it to 4.7.2; put the version printed in your report.

Still owed:
1. `test_replay_experiment` passes after your NIGHT-readiness fix (last run exit 70) — run it alone on dot first.
2. The revert check (your /tmp/coelostat-binary-drift.patch against test_autoplay_hold) on dot: apply, run, confirm it fails, restore with `git restore` on a clean tree.
3. The full Test line below once, on dot.
4. PR #356 body with the results; it stays draft (art acceptance comes from edd-art after the style pick).
5. Delete your /tmp/coelostat-* files at the end (`rm`, not `rm -rf`).

Test: orb-test --dot -- sh -c 'godot --headless --path . --import >/dev/null 2>&1; for t in test_autoplay_hold test_sim test_totality test_plan_recall test_principe_story test_ending_snapshot test_plate_reading test_i18n test_replay_experiment test_gamepad test_reduced_motion test_layout_bounds; do godot --headless --path . --script res://tests/$t.gd || exit 1; done; python3 -I tools/i18n.py check --require-translated'
