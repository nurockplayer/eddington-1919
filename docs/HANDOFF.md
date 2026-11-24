# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 13:3x JST.** Slice acceptance **7/9 recorded, rows 1/4/6 disputed** on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**In flight (lead-wait):**
- `lw-cx-accept465-ff-fu1` — #465 vo-slips (pkg 8) draft ff28341, CI green, six art items in body (67d9e62). Recapture ISOLATED running (first run hit wait limit on job accept465-ff-clip; resumed session 01a20bb6-f705…) (brief accept-shots-465-ff28341.md, out KIOXIA accept/465/ff28341/). On event: frames to edd-art; on art accept `lead-wait pr 465`.
- `lw-cx-vo-haze-fu1` — #483 haze draft bb15bad, wt vo-haze, session 01a20ba2-f727…. Frames sent to edd-art (visual-overhaul-proposal). Timing sets 1–2 contradictory (host load); fu1 = 5 load-gated interleaved forced-draw reps arrival/coelostat, fix if > +0.5 ms. On event: clean numbers; on art accept → `lead-wait pr 483`.
- `lw-cx-vo-pkg3-fu2` (resumed 13:3x JST after perf job hit wait limit; #484 now 9d0f5ff, suites pass; job edd-vo-pkg3-opt-perf queued #1659) — pkg 3 run 1, draft #484 c8f28a1, wt vo-pkg3, session 01a20bb1-4c23…. Frames (KIOXIA accept/vo-pkg3/c8f28a1…/index.md) sent to edd-art on visual-overhaul-proposal (contact continuity + cloud). Resumed with vo-pkg3-run1-fu1.md: unexplained arrival/coelostat/dialogue control-view changes (fix or justify) + shelter perf rerun 5 paired reps (candidate 20.37/18.43/11.14 vs main ~10.4, likely contention). On event: check both resolved; on art accept + CI → `lead-wait pr 484`.
- `lw-cx-vo-pkg6` — pkg 6 run 1 (figures pose/contour, #418), wt vo-pkg6 branch art/vo-pkg6, Sol high, brief vo-pkg6-run1.md. On event: frames (accept/vo-pkg6/<sha>/) to edd-art on visual-overhaul-proposal, keep draft.
- Worktrees 4/4 (vo-slips, vo-haze, vo-pkg3, vo-pkg6); vo-pkg1 removed 13:2x JST. wt-add warned: SSD free 15.2 GiB (< 40 GiB).

**Merged today:** #472 pkg 1 pilot 2871bc4 (gate round 2, 11:38 JST armed). #474 P5 slower totality (11:27 JST; follow-ups #480: pause right column empty cell, Normal/Slower duration labels, ja/zh-TW locked-row frames). #475 P4 0fed703 (fu #477, #476; worktree mech-p4 cleanup: retry `git-worktree-janitor --run --merged-pr 475 --repo .`; also clean mech-p5 for #474).

**Next when a slot frees:** fu briefs P5/phase0/menus/chart-rows dropped (issues closed). Next = pkg 2 after edd-art verdict on #484 (order P0,1,3,6,2,4,5,7,9,10; 8 alongside).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
