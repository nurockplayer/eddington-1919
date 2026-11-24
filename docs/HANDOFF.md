# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 20:13 JST.** Slice acceptance **7/9 recorded, rows 1/4/6 disputed** on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**Archive job:** `job-run --status edd-archive-20261124` (19:5x JST, 13 finished director/ dirs → pcloud:tachiko-archive/kioxia/eddington-1919/director/, Owner rule archive-not-delete). Not wired to lead-wait: check on next wake, post freed size on lead-board disk-structure-20261117.

**Codex burn (Owner 2026-11-24 20:0x JST):** Codex 93% used, resets 2026-11-25 02:52 JST; fill every free worktree slot (Sol high). Queue: #479 brief `.claude/briefs/issue-479-engraving-tests.md` → next free slot; then #476, #480, #470.


**In flight (lead-wait):**
- `lw-cx-fix-477` (20:03 JST, wt fix-477, brief issue-477-workbook-seen.md, Sol high): non-visual; on event check revert-check + Test rerun → `lead-wait pr <n>`.
- `lw-cx-accept465-ff-fu3` (19:42 JST, session 01a20ca0-2d93…, wt vo-slips, brief accept-shots-465-ff28341-fu3.md): edd-art 19:57 JST not accepted (log a1a54b5): rebase on main + portrait disclosure line (≥ control hint, ko word-safe, no lone CJK char, tested), recapture list + main baseline/ (edd-art re-scores rows 1/3 from it) + #463 direct-conversation clip on main. On event: check CI + index, frames to edd-art on pr463-465-art-captures; on art accept → `lead-wait pr 465`.
- `lw-cx-vo-pkg3-fu5` (19:42 JST, session 01a20caf-94c7…, wt vo-pkg3, brief vo-pkg3-run1-fu5.md): #484 72cdaff, CI green (ridge fixed). Shelter cost open (pairs +0.47/−0.12/+2.02, run cut by heavy-window). Job edd-vo-pkg3-perf3 via tachi-run queue: 5 pairs + per-feature attribution; fix or name feature if median > +0.5. On event: decide; on art accept → `lead-wait pr 484`.
- `lw-cx-vo-pkg6-fu4` (20:12 JST, session 01a20cbf-59c9…, wt vo-pkg6, brief vo-pkg6-run1-fu4.md, Sol high): #485 draft 56ee019, CI green; frames sent to edd-art on visual-overhaul-proposal 20:13 JST; timing (5 pairs + idle penetration) resubmitted via job-run edd-vo-pkg6-perf1 heavy queue. On event: check tables; on art accept → `lead-wait pr 485`.
- Worktrees 4/4 (vo-slips, fix-477, vo-pkg3, vo-pkg6; vo-haze removed after #483); vo-pkg1 removed 13:2x JST. wt-add warned: SSD free 15.2 GiB (< 40 GiB). KIOXIA 3.7 GiB free 17:5x JST after pruning (lead-board disk-structure-20261117); prune finished accept/ dirs (phase0, p3-ridges, hatching-diag referenced in art log: ask edd-art before deleting).

**Merged today:** #483 haze bb15bad (20:0x JST; board notice posted incl. #472/#474). #472 pkg 1 pilot 2871bc4 (gate round 2, 11:38 JST armed). #474 P5 slower totality (11:27 JST; follow-ups #480: pause right column empty cell, Normal/Slower duration labels, ja/zh-TW locked-row frames). #475 P4 0fed703 (fu #477, #476; worktree mech-p4 cleanup: retry `git-worktree-janitor --run --merged-pr 475 --repo .`; also clean mech-p5 for #474).

**Next when a slot frees:** fu briefs P5/phase0/menus/chart-rows dropped (issues closed). Next = pkg 2 after edd-art verdict on #484 (order P0,1,3,6,2,4,5,7,9,10; 8 alongside).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
