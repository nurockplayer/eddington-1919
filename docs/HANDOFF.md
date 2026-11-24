# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-24 22:32 JST.** Worker rules now `.claude/cx-header.md` (tracked, auto-appended by cx-exec on fresh runs since 21:08 JST; Part A stays in briefs/_codex-common.md). Slice acceptance **7/9** (edd-art 20:45 JST: row 1 met again from 97bfbc8, row 3 holds) on main (met 3, 5, 7, 9; open 2, 8). Release readiness frozen; listing paused. Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Previous full state: `git show 4461012:docs/HANDOFF.md`.

**Archive job:** `job-run --status edd-archive-20261124` (19:5x JST, 13 finished director/ dirs → pcloud:tachiko-archive/kioxia/eddington-1919/director/, Owner rule archive-not-delete). Not wired to lead-wait: check on next wake, post freed size on lead-board disk-structure-20261117.

**Codex burn (Owner 2026-11-24 20:0x JST):** Codex 98% used 22:28 JST, resets 2026-11-25 02:52 JST; fill every free worktree slot (Sol high). Queue: #480 rest (duration labels, ja/zh-TW locked-row frames; touches the pause panel like run 2b, so start it after 2b, stacked or as its resume); pkg 2 after #484 verdict.

**Waiting on edd-art:** #484 pkg 3 run 1 72cdaff, CI green, perf +0.38 ms. Sent 20:16 JST. On accept → `lead-wait pr 484`, then pkg 2. Worktree vo-pkg3 idle.

**In flight (lead-wait):**
- `lw-cx-vo-pkg8-run2-fu2` (22:30 JST, resume 01a20da4…): #493 (ACCEPTED 5f2effb, ready) failed gate on CI suites Localization gate: unwrapped 、 ， in scripts/cambridge/dialogue_portrait.gd:66; no visual change asked. On event: CI green → `lead-wait pr 493 --reason` (new head; frames unchanged). On merge: remove wt vo-pkg8; tell run 2b worker to rebase on main.
- `lw-cx-vo-pkg8b-run2b` (22:28 JST, Sol high, wt vo-pkg8b on branch art/vo-pkg8-run2b stacked on 5f2effb; brief .claude/briefs/vo-pkg8-run2b.md): CJK serif subset ≤ 8 MB, portrait oval tint darkroom/totality, rule under pause title, ko/ja name spellings (Cottingham, #494 Eddington). On event: post frames to edd-art (lead-board reply visual-overhaul-proposal-20261124).
- #492 MERGED 22:08 JST; wt fix-476 removed. Inherited defects #494.
- Worktrees 4/4: vo-pkg8, vo-pkg8b, cap-470, vo-pkg3 (idle).
- `lw-cx-cap-470` (22:30 JST, Terra, wt cap-470 detached at d6df6f8): #470 route clip for edd-art → KIOXIA accept/463-route/<sha>/. On event: post to edd-art; then remove wt cap-470. SSD free 12.7 GiB (< 40). KIOXIA 3.7 GiB free 17:5x JST (lead-board disk-structure-20261117).
- Janitor refuses eddington worktrees (submodule); after MERGED: `git worktree remove --force` + `git branch -D` by hand.

**Merged today:** #485 pkg 6 figures (22:3x JST, wt vo-pkg6 removed). #492 blink hint (22:08 JST). #487 workbook seen 827e762 (21:3x JST, wt removed). #489 engraving tests 2f9fec9 (21:28 JST, wt removed). #465 pkg 8 run 1 557efe9. #483 haze bb15bad. #472 pkg 1 2871bc4. #474 P5 (fu #480). #475 P4 0fed703 (fu #477 done, #476 out; old wts mech-p4/mech-p5 still to clean by hand).

**Next when a slot frees:** #480 rest after run 2b; pkg 2 after #484 (order P0,1,3,6,2,4,5,7,9,10).

**Standing:** Owner 11-23: Codex surplus, use freely; otherwise act as if Claude `ahead`. dot paused → Godot tests via CI `suites`. Re-draft visual PRs until art accepts (workers flip them to ready). Owner asks in dot thread pending (info only): lw-dot-row2-clips-main, lw-dot-third-contact-clip, lw-owner-playtest-eclipse. edd-art owns rows 5/8 visuals, #423, #425, #440. Wake-ups: none.
