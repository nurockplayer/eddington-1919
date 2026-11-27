# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md`.

**Written 2026-11-27 21:47 JST.** Slice 7/9 (open rows 2, 8). Plan = Príncipe vertical slice, engraving style; art director Fable 5.2 in edd-art (w7:pB, message with `herdr pane run w7:pB "…"`), art log `docs/design/SLICE_PRINCIPE.md`. Owner 2026-11-27: Codex 24h, AA polish, fun first, story heart; **Owner 21:20 JST "全力開工"**: keep the slots full (≥3, now 9). **Owner 22:4x JST completion gate** (RELEASE_READINESS.md top): slice 9/9, journey route incl. London, top AA fun rows → then store work; rank dispatch by these.

**Codex runs in flight (lead-wait; on each event read final.md, check acceptance; visual → edd-art; else gh pr ready + lead-wait pr N; ≥4 reviewed heads need --reason):**
- lw-fun-03-fu1: #604 plate-holder order; DECISION answered (new prompt in-branch, en `[%s] Change plate holder`, zh_TW `［%s］換底片匣`); review 4-locale copy; visual → edd-art. wt fun-03.
- lw-fun-04-fu2: #602 (art-accepted a2fdc9b3) CI red test_micrometer 14 / test_plan_recall 4 / test_principe_audio 1 → on green lead-wait pr 602 (edd-art re-look only if layout changed). rm wt fun-04 after merge.
- lw-fun-01-fu6: #589 seam fix 9e67726 meets contours (max −6.26%); test_totality 900 s deadline: main vs branch timing; revert HUD perf 966e6c0 unless branch-caused → then edd-art. wt fun-01. **Must rebase onto #605 (merged 0b44754, style_engraving.gdshader) before edd-art re-look.**
- lw-j-sobral-fu1: #600 Sobral chapter, fonts regenerated (+107 glyphs) 2862e867; waits job + captures → edd-art; keep B11 diagram (no Mailhat photo). wt journey-sobral.
- lw-journey-corr-fu2: #584 Luna corrections rebased 8d1d9cab; story_invariants/i18n red → fix branch-caused vs main → lead-wait pr 584. wt journey-corr.
- lw-aa-19: AA row 19 resume restores reading (visual draft → edd-art). wt aa-19. After merge: main.gd chain 29→30→31 via `source .claude/briefs/_aa-mk.sh; mk <NN> <branch> "<title>" "<Visual line from aa-19.md>" "<suites>"`.
- lw-sh-step6: story-heart step 6 October reunion; review copy (4 locales). wt sh-step6. Next: step 7 (October ledger) after step 6 merges; 8/9 touch Príncipe totality (after #589/#604); 10 after #600; 11 after London.
- lw-vis-548 (palm pop), lw-vis-549 (panel blue→cream ease): visual drafts → edd-art. wts vis-548, vis-549.
- Waiting on edd-art: #571 AA06 (wt aa-06). edd-art's own: #606 journey drawings (#551). #605 merged 0b44754; PR suites green (2026-11-27 22:24 JST).

**Next when slots free:** London chapter impl (Joint meeting + I4–I6 per JOURNEY.md "Later scene briefs", script #536) after #600 merges; #551 remaining items; AA36 needs a quiet host window (re-brief .claude/briefs/aa-36-fu1.md); pkg 5 (SLICE_PRINCIPE.md); naming follow-up (ja/ko/zh_TW labels, lead-decision 11-24).

**KIOXIA archive done (2026-11-27 22:14 JST):** 27/27 dirs → pCloud, 40Gi freed (KIOXIA 56%); board disk-structure-20261117 replied; branch archive-accept deleted.

**Standing:** worktree cap 12/12 for this repo: before wt-add, free MERGED wts (`git worktree remove --force` + `git branch -D`; janitor refuses this repo); don't hide wt-add output (exit 5 = cap; a failed add can leave a stale branch at main → `git branch -D` it). cx-exec needs a real worktree path. Audio-only PRs gate on measurements; Owner listening owed: #560 #570 #576 #579. Flaky: test_prologue 'Cambridge opening dialogue' once (18:15 JST); if it recurs, file issue + Codex diagnosis. Disk low (KIOXIA archive covers). Inbox: all acked at 21:47 JST. Wake-ups: Owner 2026-11-27 22:3x JST wants a report at least every 50 min and Codex busy 24h → session cron `7,47 * * * *` (cd0b2524, 7-day expiry, session-only: after a restart check CronList and re-create).
