# Brief: MECHANICS_PROPOSAL P4 run 1 — darkroom resume: measure, then save/restore (2026-11-24 07:40 JST)

## Problem
Quitting in the darkroom discards the expedition's plates, readings and selection history: scripts/checkpoint.gd saves chapter starts plus Story only; the live sim holds readings/selection (scripts/main.gd ~1703–1804). Owner approved P1–P5 of docs/design/MECHANICS_PROPOSAL_2026-11-24.md on 2026-11-24 03:1x JST, so "after Owner go-ahead" in P4's acceptance is satisfied.

## Goal / acceptance (P4 section of the proposal; read it)
1. First, record darkroom action count and elapsed time on the careful and prologue-honest bot routes (separate accelerated bot time from an estimate of human reading time); put the numbers in the PR body.
2. Continue from the title returns to the existing darkroom with the same seed, raw/developed plates, recorded readings, selected plate numbers, original/current bets, first result and reason/history. No save slots, no mid-exposure saves.
3. Tests through the title's real Continue path: quit/reload (a) after one recorded reading, (b) after committing a result, (c) after justified and result-driven reselection; restored and uninterrupted runs finish with equal numeric results, verdict class, grade and telegram, no duplicate completed run; direct-1919 and prologue continuations keep their ending/coda; existing chapter checkpoints still load; bots never overwrite a player's checkpoint. Revert check required.
Areas: checkpoint.gd, main.gd, sim state serialization, Story handoff; tests test_checkpoint, test_ending_snapshot, test_replay. Saved-data format is a data change: if the checkpoint format must change incompatibly, end with `DECISION:`. This run may stop after a working save/restore with tests (proposal sizes P4 at 3 runs); say what remains.
Do not change the PR's draft state; the art director must see restored states before merge.

## Constraints (2026-11-24 JST)
- Repo nurockplayer/eddington-1919 (public, oracle-OK). Work only in your worktree; branch already created. Godot 4.7.2 as `godot`, only through `tachi-run --host --` (bare godot denied). Fresh worktree: `tachi-run --host -- godot --headless --path . --import` once first.
- Before running a test script: `--check-only` it; wrap runs in `perl -e "alarm shift; exec @ARGV" 1500 ...`. Run only the suites for files you touch. test_totality and test_coda overrun their 900 s deadline on this Mac's E-cores: leave them to GitHub CI `suites` (push and read the CI result with `gh pr checks`), but you still edit/extend them as needed.
- Owner may be at the Mac: keep CPU low (tachi-run or `nice -n 15`), no parallel workers, no windowed Godot, no screenshots, no `--heavy` except through `job-run` with a `WAIT:` line. Stop what you start; delete scratch output.
- Python: `~/.local/bin/python3` only.
- Other workers are editing scripts/main.gd on parallel branches (P4 darkroom resume and P5 slower totality run in parallel; P1–P3 are merged). Keep your diff to what your package needs; if origin/main moves under you, rebase and resolve conflicts yourself.
- Every written time carries its zone (`date '+%F %H:%M %Z'`). Commit messages: `Refs #N`, never fix/close/resolve right before #N.
- Open a DRAFT PR. Body: package id (MECHANICS_PROPOSAL P<n>), acceptance row (FUN_PLAN F row or `none`), each acceptance case with how it was checked, exact test commands + pass counts, the revert check (new assertion fails with the change reverted). If the PR changes what the screen shows, say so: the art director edd-art must accept rendered frames before merge (the lead arranges captures; you do not take screenshots).
- Review criteria: section 2 of docs/design/MECHANICS_PROPOSAL_2026-11-24.md (on origin/main) applies, with the performance target raised by the Owner 2026-11-24 to 1080p 60 fps on a GTX 1650-class GPU.
- Do not merge or run review tools; never pass `--scope`. No defensive code, no unasked polish. Historical physics/people claims follow the review criteria; uncertain → ask `oracle-ego` (send only your task's files).
- A change to saved-data format, a public interface or scope beyond the package: end the report with `DECISION: <question; options; recommendation>`.

Test: tachi-run --host -- sh -c 'for t in test_sim test_autoplay_hold test_replay_experiment test_plan_recall test_i18n; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 1500 godot --headless --path . --script res://tests/$t.gd || exit 1; done'
Test: tachi-run --host -- sh -c 'for t in test_checkpoint test_ending_snapshot test_replay; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 1500 godot --headless --path . --script res://tests/$t.gd || exit 1; done'
Budget: 50m
