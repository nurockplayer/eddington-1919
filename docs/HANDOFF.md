# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 12:4x JST.** Slice acceptance **7/9 recorded, rows 1/4/6 disputed** on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**In flight (lead-wait):**
- `lw-cx-pr465-r4c` — #465 vo-slips (pkg 8) draft ff28341, CI green (suites incl. test_layout_bounds). Local 900 s overrun = E-core slowness, not chased (lead-decision on #465). Worker now does remaining art items (pr465-fu4.md + resume2; session 01a20b64-4a63…). On event: CI green on head → recapture ISOLATED, frames to edd-art; on art accept `lead-wait pr 465`.
- `lw-cx-vo-haze` — #472 follow-up (horizon haze flat tone + telescope highlight/rim), wt vo-haze, Terra, brief vo-pkg1-haze-telescope.md. On event: frames to edd-art, keep draft.
- `lw-cx-vo-pkg3` — pkg 3 run 1 (passage into totality + one cloud drawing), wt vo-pkg3, Sol high, brief vo-pkg3-run1.md. On event: frames (KIOXIA accept/vo-pkg3/<sha>/) to edd-art on visual-overhaul-proposal-20261124.
- Worktrees 4/4 for this repo (vo-slips, vo-pkg1 idle merged, vo-haze, vo-pkg3). vo-pkg1 can be removed (merged #472; only untracked .uid). Janitor keeps merged trees over uninitialised submodule assets/licensed → reported to harness-lead on wt-lifetime-20261124; I removed mech-p4/p5 by hand.

**Merged today:** #472 pkg 1 pilot 2871bc4 (gate round 2, 11:38 JST armed). #474 P5 slower totality (11:27 JST; follow-ups #480: pause right column empty cell, Normal/Slower duration labels, ja/zh-TW locked-row frames). #475 P4 0fed703 (fu #477, #476; worktree mech-p4 cleanup: retry `git-worktree-janitor --run --merged-pr 475 --repo .`; also clean mech-p5 for #474).

**Next when a slot frees** (remove vo-pkg1 first): queued fu briefs, Sol high: fu-provenance-ci-paths, fu-phase0-baseline, fu-menus-contrast, fu-report-chart-rows; then pkg 6. Order P0,1,3,6,2,4,5,7,9,10 (8 alongside).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
