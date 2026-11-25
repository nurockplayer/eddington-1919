# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md`.

**Written 2026-11-26 02:04 JST.** Slice acceptance **5/9** on main (met 1,3,6,7,9; open 2,4,5,8). Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. #506 + #524 merged (main 57d81edc); their worktrees/branches removed.

**Journey (Owner 2026-11-26, decisions #316 / memory owner-journey-story-1126):** scope B + interludes, Kit/Ashby POV, no invented romance, sensitive topics truthful, slice first, spine hatred vs internationalism → cloud wait → Nov 6 epic. Research dossier merged #527; design `docs/design/JOURNEY.md` merged #528 (4 chapters + 6 interludes, 62–90 min) (`docs/research/expedition_journey_2026-11-26.md`).

**In flight (lead-wait):**
- `lw-journey-tribunal-20261126-020041-77709`: Sol, wt journey-tribunal, brief `.claude/briefs/journey-scene-tribunal.md` → `docs/design/journey/TRIBUNAL.md` docs PR (JOURNEY.md merged #528). On event: check acceptance, gate; then next scene brief = Madeira (+I2), same shape.
- `lw-fix-515-20261126-020114-81860`: Terra, wt fix-515, brief `.claude/briefs/fix-515-clock-slip.md` → draft PR; gate after test/revert check (text timing, not art).
- `cap-main45` (Terra, wt cap-main45 detached 57d81edc, brief `.claude/briefs/accept-shots-main-row45.md`) → KIOXIA `accept/main-row45/<sha>/`; on event message edd-art (herdr pane run w7:pB) to re-score rows 4+5. lw-cap-main45-20261126-014357-57318.
- `lw-fix-427-fu-20261126-011738-54965`: #427 resume (session 01a211d0): parse error tests/test_style_engraving.gd:64, draft PR, golden_arrival/arrival frames → edd-art.

**Queue after these:** pkg 5 (#491 is actually #489 review follow-ups; find pkg 5 in SLICE_PRINCIPE.md); edd-art takes #505 #482 #486; naming follow-up (ja/ko/zh_TW labels, lead-decision 11-24 23:00 JST).

**Standing:** Owner 11-25: push the game on Codex, minimal Claude; quota 01:39 JST Codex 15% vs 19% (on). Janitor refuses eddington worktrees (submodule): after MERGED `git worktree remove --force` + `git branch -D` by hand. Disk free 29 GiB (below 40 GiB warning). Re-draft visual PRs until art accepts. Wake-ups: none.
