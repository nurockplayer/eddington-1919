# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md`.

**Written 2026-11-26 03:13 JST.** Slice acceptance **5/9** on main (met 1,3,6,7,9; open 2,4,5,8). Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`.

**Journey (Owner 2026-11-26, decisions #316 / memory owner-journey-story-1126):** scope B + interludes, slice first. Design `docs/design/JOURNEY.md` merged #528; scene briefs one chapter at a time in its "Later scene briefs" order.

**In flight (lead-wait):**
- #529 TRIBUNAL.md MERGED 97225691; wt/branch removed.
- #530 (#515 clock fix) MERGED 03:14 JST; major → follow-up issue (test last frame + second contact); wt/branch removed.
- `lw-journey-madeira-20261126-031232-34468`: Sol, wt journey-madeira (branch docs/journey-madeira), brief `.claude/briefs/journey-scene-madeira.md` → `docs/design/journey/MADEIRA.md` docs PR. On event: check acceptance, gate; next brief = Sundy (chapter 3), same shape.
- `lw-fix-427-fu2-20261126-031201-29739`: #427 resume (session 01a211d0) → before frames + draft PR (branch art/fix-427 head 27644019; after frames on KIOXIA accept/issue-427/27644019…). On event: send draft PR + frames to edd-art (herdr pane run w7:pB "…"); stays draft until art accepts.
- cap-main45 resume fu1 (session 01a21397, brief `.claude/briefs/accept-shots-main-row45-fu1.md`): round 1 gave thick stills only (seed 7, 0.93); fu1 = clear/thin seeds + clip + sheets via heavy queue → KIOXIA `accept/main-row45/57d81edc…/`; on event message edd-art to re-score rows 4+5.

**Queue after these:** pkg 5 (find in SLICE_PRINCIPE.md); edd-art takes #505 #482 #486; naming follow-up (ja/ko/zh_TW labels, lead-decision 11-24 23:00 JST).

**Standing:** Owner 11-25: push the game on Codex, minimal Claude; quota 03:12 JST Codex 19% vs 20% (on), Claude on. cx-exec needs a real worktree path (create with `wt-add --holder edd-lead . ../eddington-1919-wt/<name> -b <branch> origin/main`), not `wt:<name>`. Janitor refuses eddington worktrees (submodule): after MERGED `git worktree remove --force` + `git branch -D` by hand. Disk free 26.6 GiB (below 40 GiB warning). Re-draft visual PRs until art accepts. Wake-ups: none.
