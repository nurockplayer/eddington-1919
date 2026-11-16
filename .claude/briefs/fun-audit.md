# Brief fun-audit: where the game is fun, where it is not (read-only diagnosis)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/fun-audit` (detached at origin/main). Godot 4.7.2 project, GDScript. **Read-only: change no file in the repo**; write your report as the final message only.

## Why
The Owner (2026-11-16 JST) wants the game both good-looking and fun. Art is handled elsewhere. Your job is the facts the lead needs to decide gameplay changes. The design intent is issue #37 (`gh issue view 37`): one playable motif that comes back five times (Newton's success and the Mercury 43″ residual; the closed box and the ball; light in the box; the 1919 eclipse with the 0 / 0.87″ / 1.75″ predictions; the Cambridge coda), each time with deeper understanding. Issue #1 is the director handoff. The newcomer test sheet `docs/PLAYTEST_NEWCOMER.md` lists the moments that matter.

## Read
- `scripts/story.gd`, `scripts/content.gd`, `scripts/content_coda.gd`, `scripts/main.gd` (phases, `_interact`, the totality and plate flow), `scripts/judgment.gd`, `scripts/ending.gd`, `scripts/eclipse_sim.gd`, `scripts/chart.gd`, `scripts/plate_render.gd`, `scripts/cambridge/` and `tests/autoplay_bot.gd` (the routes show the intended paths).
- `docs/PLAYTEST.md`, `docs/PLAYTEST_NEWCOMER.md`, `docs/DECISIONS.md` (skim), `docs/playtest/` notes.
- Use `grep` and `sed -n` ranges; do not dump whole large files.

## Report (final message, Markdown, at most ~250 lines)
1. **Beat table**, in play order from title to credits: beat name, where in code (file:function), what the player *does* (the verb: walk, choose, align, measure, bet, none), estimated minutes, number of dialogue lines before the next real input, and which #37 loop (1–5 or none) it serves.
2. **The five #37 loops**: for each, status = playable / dialogue only / missing, with file:line evidence. Say whether the player discovers the idea through an action or is told it.
3. **Dead stretches**: every stretch over ~2 minutes or ~15 dialogue lines with no meaningful choice or skill input, with file:line.
4. **Agency**: which choices change later state (list the variables and where they are read), and which choices are cosmetic.
5. **Feedback gaps**: actions with no visible or audible response, unclear objectives (no prompt, no hint), places a newcomer could stall.
6. **Options**: up to five concrete changes ranked by expected fun gained per effort (S/M/L), each naming the files it would touch and the risk to existing tests. Prefer deepening existing mechanics (plate measurement, the ledger bet, the coelostat) over new systems. Do not decide; the lead decides.

Facts with file:line evidence only; mark any estimate as an estimate. Times in JST if you write any.

## Limits
Host: 16 GB shared Mac. Do not run Godot, tests or builds for this brief. No web research.

Test: none (read-only diagnosis, no code change)
