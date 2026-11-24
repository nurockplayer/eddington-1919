# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 21:42 JST.** Worker rules now `.claude/cx-header.md` (tracked, auto-appended by cx-exec on fresh runs since 21:08 JST; Part A stays in briefs/_codex-common.md). Slice acceptance **7/9** (edd-art 20:45 JST: row 1 met again from 97bfbc8, row 3 holds) on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**Archive job:** `job-run --status edd-archive-20261124` (19:5x JST, 13 finished director/ dirs → pcloud:tachiko-archive/kioxia/eddington-1919/director/, Owner rule archive-not-delete). Not wired to lead-wait: check on next wake, post freed size on lead-board disk-structure-20261117.

**Codex burn (Owner 2026-11-24 20:0x JST):** Codex 96% used 21:3x JST, resets 2026-11-25 02:52 JST; fill every free worktree slot (Sol high). Queue after the runs below: package 8 run 2b (CJK serif subset ≤ 8 MB, lead-decision 06:34 JST; split recorded 21:35 JST), #480 rest (duration labels, ja/zh-TW locked-row frames), #470; pkg 2 after #484 verdict.

**Waiting on edd-art:** #484 pkg 3 run 1 72cdaff, CI green, perf +0.38 ms. Sent 20:16 JST. On accept → `lead-wait pr 484`, then pkg 2. Worktree vo-pkg3 idle.

**In flight (lead-wait):**
- #485 at 8e0a693 (route-driver aim fix; e2e pseudo 6/6, night_dress 31/0, leak-gate SUCCESS): gate round 3 `lead-wait pr 485` 21:42 JST. ACCEPTED by edd-art at 9929a87 (log 424d3bb), frames 0 px diff. Later figures run list: dot in left lens, broken mouth dash at talk distance, Eddington's open right hand by day, Cottingham's hand on crank. On merge: remove wt vo-pkg6 by hand.
- `lw-cx-vo-pkg8-run2` (21:34 JST, wt vo-pkg8, branch art/vo-pkg8-run2, Sol high, brief vo-pkg8-run2.md): portrait card proportion, slip paper at totality/darkroom, pause title + empty cell (Refs #480). Visual: on event post frames to edd-art (visual-overhaul-proposal-20261124).
- `lw-cx-fix-476` (21:34 JST, wt fix-476, Sol high, brief issue-476-blink-hint.md): blink hint returns after Continue. Small visual: frames to edd-art.
- Worktrees 4/4: vo-pkg6, vo-pkg8, fix-476 running; vo-pkg3 idle. SSD free 13.7 GiB (< 40). KIOXIA 3.7 GiB free 17:5x JST (lead-board disk-structure-20261117).
- Janitor refuses eddington worktrees (uninitialized submodule assets/licensed = "nested repository"); lead-board janitor-submodule-protect-20261124 to harness-lead. Until fixed, after MERGED: `git worktree remove --force` + `git branch -D` by hand.

**Merged today:** #487 workbook seen 827e762 (21:3x JST, wt removed). #489 engraving tests 2f9fec9 (21:28 JST, wt removed). #465 pkg 8 run 1 557efe9. #483 haze bb15bad. #472 pkg 1 2871bc4. #474 P5 (fu #480). #475 P4 0fed703 (fu #477 done, #476 out; old wts mech-p4/mech-p5 still to clean by hand).

**Next when a slot frees:** pkg 8 run 2b, then #480 rest, #470; pkg 2 after #484 (order P0,1,3,6,2,4,5,7,9,10).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
