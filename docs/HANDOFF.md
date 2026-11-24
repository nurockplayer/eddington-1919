# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-25 04:20 JST.** Worker rules now `.claude/cx-header.md` (tracked, auto-appended by cx-exec on fresh runs since 21:08 JST; Part A stays in briefs/_codex-common.md). Slice acceptance **7/9** (edd-art 20:45 JST: row 1 met again from 97bfbc8, row 3 holds) on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**Archive job:** `job-run --status edd-archive-20261124` (19:5x JST, 13 finished director/ dirs → pcloud:tachiko-archive/kioxia/eddington-1919/director/, Owner rule archive-not-delete). Not wired to lead-wait: check on next wake, post freed size on lead-board disk-structure-20261117.

**Codex burn (Owner 2026-11-24 20:0x JST):** Codex 100% used 00:05 JST 11-25, resets 2026-11-25 02:52 JST; fill every free worktree slot (Sol high). Queue: pkg 2 after #484 verdict.

**#484 pkg 3 run 1:** edd-art ACCEPTED 2051d4d 04:11 JST (PR comment 7141734400, log 92f27a01). Gate FAILED 04:18 JST: conflict in shaders/style_engraving.gdshader. Rebase run `lw-pkg3-rebase-20261125-041923-30483` (Sol high, resume 01a20eed, brief fu10) in flight; on event: if resolution changes accepted pixels → edd-art re-looks; else `lead-wait pr 484 --reason rebase-conflict`. On merge: remove wt vo-pkg3 by hand + branch -D; tell edd-art (re-scores row 3 from main); dispatch pkg 2 run 1 from main: `wt-add` art/vo-pkg2, brief `.claude/briefs/vo-pkg2-run1.md` (written, Sol high). edd-art later-run asks (capsule clear patch, reticle on crescent, ridge clip −2..+10 s) folded into pkg 2 brief / next run touching them.

**In flight (lead-wait):**
- Totality dialogue: not reachable in play (Sol 23:03 JST, repro 5/5); only toasts beside the clock; told edd-art; wt removed.
- Naming lead-decision 23:00 JST on #494: ja/ko/zh_TW speaker labels + name tags take locale transliteration; follow-up PR after #496 merges (queue with #480 rest).
- #492 MERGED 22:08 JST; wt fix-476 removed. Inherited defects #494.
- Worktrees 1/4: vo-pkg3 (run in flight).
- #470 closed 22:45 JST (edd-art: not a hang, log 928c195).
- Janitor refuses eddington worktrees (submodule); after MERGED: `git worktree remove --force` + `git branch -D` by hand.

**Merged today:** #500 #494 names 71aa33d (03:15 JST 11-25, wt removed; backlog #504). #499 #480 rest 2e66776 (02:35 JST 11-25, wt removed; fu #501, #502). #496 pkg 8 run 2b (00:0x JST 11-25, wt removed). #493 pkg 8 run 2a eb4cc4b (23:3x JST, wt vo-pkg8 removed). #485 pkg 6 figures (22:3x JST, wt vo-pkg6 removed). #492 blink hint (22:08 JST). #487 workbook seen 827e762 (21:3x JST, wt removed). #489 engraving tests 2f9fec9 (21:28 JST, wt removed). #465 pkg 8 run 1 557efe9. #483 haze bb15bad. #472 pkg 1 2871bc4. #474 P5 (fu #480). #475 P4 0fed703 (fu #477 done, #476 out; old wts mech-p4/mech-p5 still to clean by hand).

**Next:** pkg 2 run 1 after #484 merges; then order 4,6,5,7,9,10 (edd-art re-ranks after pkg 2).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
