# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 11:3x JST.** Slice acceptance **7/9 recorded, rows 1/4/6 disputed** on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**In flight (lead-wait):**
- `lw-cx-pr465-r4b` — #465 vo-slips (pkg 8) draft e94d315: fix slow UI setup so test_layout_bounds meets 900 s, CI green, then art items (brief pr465-fu4.md + pr465-fu4-resume1.md; session 01a20afe…). On event: check CI on head, recapture with ISOLATED settings, send frames to edd-art; on art accept `lead-wait pr 465`.
- `lw-cx-vo-pkg1-blk2` — #472 vo-pkg1 draft e29cff3 (gate blocker fixed: rehearsal cloud now prints in daylight; test_style_engraving 524/0, revert-check fails on b2b13a2). Worker waits on capture job vo-pkg1-rehearsal-remaining-e29cff3, then writes KIOXIA accept/vo-pkg1/e29cff3…/rehearsal/index.md. On event: send rehearsal frames (clear/thin/thick/edge) to edd-art (lead-board visual-overhaul-proposal-20261124); on re-accept `lead-wait pr 472` (round 2). Major #479. On merge: `wt-add --holder edd-lead . ../eddington-1919-wt/vo-haze -b art/vo-haze origin/main` then `lead-wait run cx-vo-haze -- cx-exec ../eddington-1919-wt/vo-haze .claude/briefs/vo-pkg1-haze-telescope.md`.

**Merged today:** #474 P5 slower totality (11:27 JST; follow-ups #480: pause right column empty cell, Normal/Slower duration labels, ja/zh-TW locked-row frames). #475 P4 0fed703 (fu #477, #476; worktree mech-p4 cleanup: retry `git-worktree-janitor --run --merged-pr 475 --repo .`; also clean mech-p5 for #474).

**Next when a slot frees:** visual package 3 (passage into totality: paper dims/cools over last minute, decision 3; clips aimed at the sky from shelter edge) — write brief from VISUAL_OVERHAUL_PROPOSAL pkg 3. Order P0,1,3,6,2,4,5,7,9,10 (8 alongside). Then queued fu briefs (fu-provenance-ci-paths, fu-phase0-baseline, fu-menus-contrast, fu-report-chart-rows), Sol high.

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
