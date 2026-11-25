# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md`.

**Written 2026-11-26 01:21 JST.** Slice acceptance **5/9** on main (met 1,3,6,7,9; open 2,4,5,8; rows 4+5 return with #506 + one main capture). Plan = Príncipe vertical slice, style = engraving; art director = Fable 5.2 in edd-art (w7:pB), art log `docs/design/SLICE_PRINCIPE.md`. Reboot done; fleet back.

**NEW Owner request 2026-11-26 01:1x JST (in chat):** burn Codex as much as possible; recreate the whole expedition journey's 愛恨情仇 and the social atmosphere of 1919 in the game; discuss open questions first. Lead asked the Owner 8 questions in chat (scope A/B/C, player POV, invented romance, sensitive topics: colonial labour / slurs / antisemitism / private lives, history strictness, priority vs slice, 4-language volume, scene form). **Owner 01:2x JST: all lead recommendations accepted** (lead-decision #316 c7167979143; memory owner-journey-story-1126): scope B + interludes, fictional assistant POV, no invented romance, sensitive topics truthful without relish, slice first / journey in parallel, +1–1.5 h, spine hatred vs internationalism → cloud wait → Nov 6 epic. Next after research PR: Codex (Sol) writes `docs/design/JOURNEY.md` (chapter beats, provenance per beat), then scene briefs one chapter each.
- `lw-research-journey-20261126-011936-69099`: Sol high, wt research-journey (branch docs/research-journey), brief `.claude/briefs/research-journey.md` → `docs/research/expedition_journey_2026-11-26.md` + docs PR (timeline, people, atmosphere, quotes, myths, gap map vs repo, options A/B/C, sensitivity list). On event: skim the PR, gate via `lead-wait pr <n>` (docs lane if path allowed), feed the options + Owner answers into a design note; then Codex writes scenes per answer.

**In flight (lead-wait):**
- `lw-pr-506-20261126-011954`: #506 gate rerun (first try died on GitHub GraphQL 5xx). After merge: remove wt vo-pkg2 + branch, one main capture rows 4+5 for edd-art, dispatch pkg 5 (#491).
- `lw-pr-524-20261126-011946`: #524 gate (edd-art OK 17:35 JST at 44358b0). After merge remove wt fu-pkg4.
- `lw-fix-427-fu-20261126-011738-54965`: #427 resume (session 01a211d0): fix parse error tests/test_style_engraving.gd:64, test + revert check, push, draft PR, golden_arrival/arrival frames → edd-art.

**Queue after these:** #515 clock slip; pkg 5 (#491); edd-art takes #505 #482 #486; naming follow-up (ja/ko/zh_TW labels, lead-decision 11-24 23:00 JST).

**Standing:** Owner 11-25: push the game on Codex, minimal Claude; quota-advisor 01:19 JST: Codex 14% used vs 19% target (on pace) → fill free slots. Janitor refuses eddington worktrees (submodule): after MERGED `git worktree remove --force` + `git branch -D` by hand. Disk free 20.5 GiB (below 40 GiB warning). Re-draft visual PRs until art accepts. Wake-ups: none.
