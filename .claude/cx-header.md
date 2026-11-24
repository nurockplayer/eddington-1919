# Eddington worker rules (current; cx-exec appends this to every fresh run)

- Work only in your worktree; repo nurockplayer/eddington-1919 (public, oracle-OK). Godot 4.7.2 is `godot`. In a fresh worktree run `tachi-run --host -- godot --headless --path . --import` once first.
- Tests: every test through `tachi-run --host -- …`. Run `godot --headless --path . --check-only --script <t>` first, and wrap each run in `perl -e "alarm shift; exec @ARGV" 1500 …`. Run only the suites for the files you touch. test_totality, test_coda and test_layout_bounds overrun on E-cores: CI `suites` is their gate. Python is `~/.local/bin/python3`.
- Windowed Godot (captures, perf) only as `job-run --id <id> -- tachi-run --heavy --host -- /Applications/Godot.app/Contents/MacOS/Godot … --fixed-fps 60 --always-on-top`, ending your run with the `WAIT:` line. tachi-run queues until the GPU window opens. **Never check `heavy-window` or host load in your own script and exit:** the queue handles both. One render job at a time. Headless compiles no shaders: capture windowed to see shader errors.
- Captures: ISOLATED (only this PR on top of main), with an isolated settings file (`EDD_SETTINGS_PATH`). Every receipt carries locale, text_scale and reduced_motion. Output to `/Volumes/KIOXIA/eddington-1919-cache/director/accept/<pr or pkg>/<head sha>/index.md` (every file: state, locale, size, time JST, exact command).
- Visual PRs stay draft; edd-art accepts them before the gate. Do not merge, do not run review-bundle/review-run/review-gate, never pass `--scope`.
- PR body: the acceptance row from the brief's `Moves:` line, the exact test command with pass counts, and the revert check (the new test fails with the fix reverted).
- Commits: never put fix/close/resolve right before `#N`; write `Refs #N`.
- Every written time carries its zone (`2026-11-24 20:05 JST`).
- Keep CPU low: everything through tachi-run or `nice -n 15`, no parallel fan-out, stop what you start. Delete scratch. Finished data goes to pCloud only when the lead asks. A process killed by SIGTERM/SIGKILL was likely stopped for memory: report it, do not rerun it unchanged.
- No defensive code the problem does not need; no polish nobody asked for.
- Stuck: ask `oracle-ego` (send only this task's files). A change to saved data, a public interface or scope: end with `DECISION: <question; options; recommendation>`.
