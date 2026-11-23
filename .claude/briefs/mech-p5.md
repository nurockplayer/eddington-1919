# Brief: MECHANICS_PROPOSAL P5 run 1 — Slower totality pacing setting (2026-11-24 07:40 JST)

## Problem
Totality compresses 302 game seconds at ×2.5 (scripts/eclipse_sim.gd ~13–14); scripts/main.gd ~1432–1442 advances cloud, exposure and plate changing on that clock; settings (scripts/settings.gd ~15–26) offer no pacing choice. Owner approved P1–P5 of docs/design/MECHANICS_PROPOSAL_2026-11-24.md on 2026-11-24 03:1x JST.

## Goal / acceptance (P5 section; read it)
Normal (default) and Slower, chosen before totality (not during an open exposure); Slower = ×1.25, manual start/stop kept. Slower advances exactly 1.25 game s per unpaused real s vs 2.5 Normal, both end at 302 game s. Same seed + scripted game-time shutter schedule → plate results within 1e-6, same selection and grade. Cloud rendering, change delay, countdown and warning share the clock; look/input stay real-time; pause/log freeze both. Second-contact score hold stays 1.8–2.5 real s; darkroom music off. No future-gap meter, auto-shutter, guaranteed plate or altered truth. No global Engine.time_scale. Setting label in en/ja/zh_TW/ko through the existing i18n.
Tests: test_settings, test_totality (CI only, see constraints), test_score; revert check required. The setting is new player-visible UI: the art director must accept rendered setting/HUD frames before merge; audio timing needs a listening check — list both under Follow-ups. This run may stop at settings + clock integration with tests (proposal sizes P5 at 3 runs); say what remains.
Do not change the PR's draft state.

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
Test: tachi-run --host -- sh -c 'for t in test_settings test_score; do godot --headless --path . --check-only --script res://tests/$t.gd || exit 1; perl -e "alarm shift; exec @ARGV" 1500 godot --headless --path . --script res://tests/$t.gd || exit 1; done'
Budget: 50m
