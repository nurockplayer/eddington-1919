# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 21:15 JST.** Worker rules now `.claude/cx-header.md` (tracked, auto-appended by cx-exec on fresh runs since 21:08 JST; Part A stays in briefs/_codex-common.md). Slice acceptance **7/9** (edd-art 20:45 JST: row 1 met again from 97bfbc8, row 3 holds) on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**Archive job:** `job-run --status edd-archive-20261124` (19:5x JST, 13 finished director/ dirs → pcloud:tachiko-archive/kioxia/eddington-1919/director/, Owner rule archive-not-delete). Not wired to lead-wait: check on next wake, post freed size on lead-board disk-structure-20261117.

**Codex burn (Owner 2026-11-24 20:0x JST):** Codex 93% used, resets 2026-11-25 02:52 JST; fill every free worktree slot (Sol high). Queue (#479 out 20:36 JST): package 8 run 2, then #476, #480, #470.


**Waiting on edd-art:** #484 pkg 3 run 1 72cdaff, CI green, perf settled (5 pairs median +0.38 ms; cooling −0.77, cloud +0.51, forest cards +0.71 savings). Sent 20:16 JST. On accept → `lead-wait pr 484`, then pkg 2. Worktree vo-pkg3 idle (clean, = origin); removing it for #479 was denied by auto mode (open PR): Owner may run `! git worktree remove --force ../eddington-1919-wt/vo-pkg3` or wait for the next run to finish.

**In flight (lead-wait):**
- `lw-cx-fix-477` (20:03 JST, wt fix-477, brief issue-477-workbook-seen.md, Sol high): non-visual; on event check revert-check + Test rerun → `lead-wait pr <n>`.
- #465 MERGED 557efe9 (20:3x JST; board notice posted; wt vo-slips removed). Package 8 run 2 = edd-art's #465 comment list + lead-decision (portrait card proportion first; serif CJK ≤ 8 MB; slip paper at totality/darkroom); next capture's main baseline must include arrival at ≥ 97bfbc8. Dispatch at the next free slot.
- #489 (fix-479, engraving bindings test, non-visual) at 5fe1e85: wrapper Test rerun exit 0 (day_return 1107/0, engraving 643/0, 4 revert checks); `lead-wait pr 489` 21:1x JST. On merge: clean wt fix-479, then dispatch package 8 run 2 there.
- #485 pkg 6 ACCEPTED by edd-art at 9929a87 (21:12 JST, log 424d3bb); gate round 1 (21:14 JST) blocker: Eddington's interaction capsule 0.615 m off his visible figure (day + night main.gd:1698); `lw-cx-vo-pkg6-fu8` 21:15 JST fixes it (figure stays, frames must not change: pixel diff). On event → `lead-wait pr 485` again. edd-art gate note: diff adds two dark cylinders to fallback figure in npc() (no frame shows it). Later figures run list: dot in left lens, broken mouth dash at talk distance, Eddington's open right hand by day, Cottingham's hand on crank. On merge: clean wt vo-pkg6, next slot.
- Worktrees 4/4, fix-477, fix-479, vo-pkg6 running; vo-pkg3 idle (#484 awaiting edd-art) on open draft PRs (#479 waits for one to merge or Owner removal) ( vo-haze removed after #483); vo-pkg1 removed 13:2x JST. wt-add warned: SSD free 15.2 GiB (< 40 GiB). KIOXIA 3.7 GiB free 17:5x JST after pruning (lead-board disk-structure-20261117); prune finished accept/ dirs (phase0, p3-ridges, hatching-diag referenced in art log: ask edd-art before deleting).

**Merged today:** #483 haze bb15bad (20:0x JST; board notice posted incl. #472/#474). #472 pkg 1 pilot 2871bc4 (gate round 2, 11:38 JST armed). #474 P5 slower totality (11:27 JST; follow-ups #480: pause right column empty cell, Normal/Slower duration labels, ja/zh-TW locked-row frames). #475 P4 0fed703 (fu #477, #476; worktree mech-p4 cleanup: retry `git-worktree-janitor --run --merged-pr 475 --repo .`; also clean mech-p5 for #474).

**Next when a slot frees:** fu briefs P5/phase0/menus/chart-rows dropped (issues closed). Next = pkg 2 after edd-art verdict on #484 (order P0,1,3,6,2,4,5,7,9,10; 8 alongside).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
