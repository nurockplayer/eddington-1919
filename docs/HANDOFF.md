# Game Director Handoff

## Current production handoff | 2026-10-20 JST

**Source of truth:** [Notion 《雲層之後》 Narrative Bible — §0 quick handoff, §§1–7 decisions](https://app.notion.com/p/3fed7d8b390781ac848acc2d293ebbde) defines **approved vs proposed** story. [GitHub Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1) is the live Opus Game Director decision, evidence and milestone log. This section **supersedes prior v0.1-only scope**, without claiming any new playable work has been shipped.

**Owner product goal:** Use the current intensive Opus + Codex development window to move the **single** 1919 eclipse historical adventure toward a game players are excited to start, engrossed in, and remember afterward. A completed commercial release in 72 hours is **not** guaranteed. Don't produce extra historical games, build a generalized RPG platform, or turn the prologue into a science lecture.

**Directed team:** **Opus 5.5** final game/story direction and integration; collaborate with **gpt-6.1-sol** on bounded coding tasks and Owner-requested **astra-6-gps** on independent challenge/review where the exact model is accessible. **Do not claim unavailable workers ran**; record substitutes. Use as many clean parallel worktrees as useful, not concurrency for its own sake. Every meaningful merge must be reviewed, verified in *merged* `main`, and handed off.

**Already approved story constraints (details and status in Notion):**
- 1915–1919 narrative begins with a respectful **Newtonian tradition vs general relativity** debate, Dyson's 1919 eclipse plan, and Eddington's involvement; includes Cambridge preparation, eclipse, plate analysis and the documented November 1919 announcement. Preserve real contributions of Dyson, Cottingham, Eddington, Sobral and local workers.
- Fictional protagonist craves recognition and fears the expedition may prove inconclusive. Two fictional childhood friends were accused of inventing mismatched star observations and bullied; observational error does not make them liars. The protagonist's Newtonian mentor is respected, supports departure and gifts a cherished measuring tool.
- **First new playable milestone:** novice-friendly 1917 Cambridge records mystery, comparing an apparently misaligned star field, tracing a mundane observation/calibration problem, retaining the original notes and reporting uncertainty. Mentor then recommends protagonist; Eddington assesses the care taken, entrusts a real preparation task (not immediate expedition membership). Three-way discussion is rational but tense; player should help plan a scientifically fair observation. Wartime logistics are background texture through characters, letters and work, not an unrelated minigame. **No prior physics knowledge required.**
- Warm, capable fictional same-age peer is introduced before real precision-mechanism expert Cottingham. Peer has an independent career in Cambridge; later reunion via shared work, optional unsent letter and understated acknowledgement of unequal opportunity. Optional romantic route: intense affection before departure *without confession*, quiet mutual confirmation **only near ending**. Full, equally moving platonic route. Both promise to share the skies they see.
- Player's evidence judgments must arise from actions and records, never from romance flags. Finale echoes the Cambridge worktable with original eclipse evidence and mentor's inherited instrument. Scientific findings do not depend on invented sentimental artifacts.

**Important unresolved canon:** Owner desires an old object worn/carried since childhood with a historically plausible microscopic image, revealed in Cambridge near the end, tied to the childhood star-chart accusation. **The maker, carrier, manufacture, unseen mechanism, written message and precise romantic staging are still open.** The last suggestion (childhood friend note + adult microphotography) was **not accepted**. Use a reversible placeholder if needed; do not lock the reveal, exact character names/genders, or specific dialogue before Owner picks them.

**Engineering baseline right now:** `main` is the merged v0.1 Godot 4.7.2 3D playable slice (below). [Art PR #3](https://github.com/nurockplayer/eddington-1919/pull/3) targets `main`; [art PR #4](https://github.com/nurockplayer/eddington-1919/pull/4) is stacked **on #3**, not on `main`. Treat those as *unmerged* until verified and integrated; plan review/merge order accordingly. No human blind playtest has been recorded. Begin with an honest play/run and prioritize the most important gameplay/narrative weakness. In parallel, recruit an unbriefed player as soon as feasible for a real newcomer usability check.

**Reporting rhythm:** After each meaningful milestone, post working commit/PR, how to play and reproduce, actual Godot testing, known historical/fictional boundaries, remaining issues and the next highest-value step to [Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1). New sessions start from current `main`, issue comments and this file. This handoff itself does **not** launch an Opus/agent process.

---

**Implementation baseline (2026-10-19 JST): v0.1 playable slice delivered**. The complete loop is verified by automated real-input runs. **There has been no human playtest yet.**

## Current verified state (v0.1)
- **Build.** Godot **4.7.2.stable**.
  - Run: `godot --path .`
  - Export: `godot --headless --path . --export-release "macOS" build/Eddington1919-macOS.zip`
  - Tests: `godot --headless --path . --script res://tests/test_sim.gd`
  - Autoplay: `godot --path . --always-on-top -- --autoplay=careful|rushed|cherry --shots=DIR [--seed=N] [--speed=2]`
- **Play.** About 6–10 min, first person.
  - **Prep:** brief with Eddington, fetch plate holders, wind and rate-check the coelostat drive with Cottingham.
  - **Totality:** call exposures through a drifting cloud field (302 s compressed ×2.5).
  - **Night:** developed plates show stars, fog and trailing from what you did. You choose plates *before* the values appear, then measure.
  - **Judgment:** pick a telegram and a reason. Eddington reacts to calibration and selection integrity.
  - **End:** the historical epilogue, then replay with the same or a new sky.
- **Evidence:** [docs/PLAYTEST.md](PLAYTEST.md) (screenshots and bot JSON in `docs/playtest/`); history and fiction labels in [docs/PROVENANCE.md](PROVENANCE.md); design decision [D006](DECISIONS.md).
- **Code map.**
  - `scripts/eclipse_sim.gd`: shared state and model.
  - `scripts/judgment.gd`: grading and Eddington's lines.
  - `scripts/main.gd`: phase flow.
  - `scripts/world_builder.gd`: procedural site.
  - `scripts/ui.gd` and `scripts/chart.gd`: HUD, dialogue, plate viewer, endings.
  - `shaders/eclipse_sky.gdshader`: sky that shares the cloud texture with the sim.
  - `tests/`: logic tests and the autoplay bot.

## Previous v0.1 playtest priority — still unfulfilled
The previous immediate next step was **a human playtest of v0.1** (about 15 minutes) using the five questions in [PLAYTEST.md](PLAYTEST.md). This remains an **important quality gate**, though product scope has now expanded per the 2026-10-20 checkpoint: Opus should balance this early test with a real playable Cambridge narrative opening, not wait for an entire game before testing or promise that a simulated run counts as a human.

## Canonical GitHub reporting entry

**[Issue #1 — Game Director Handoff](https://github.com/nurockplayer/eddington-1919/issues/1)**. Opus 5.5 should use it to record meaningful progress, playable builds and handoffs. A link to a commit/PR and honest playtest evidence matter more than a long status report.

### Read first (in this order)
1. [README](../README.md) — short owner direction and repo separation.
2. [Decisions](DECISIONS.md) — hard constraints and freedom.
3. [History and provenance](HISTORY_1919.md) — what can/cannot be claimed about 1919.
4. [Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1) and its *latest* comments — the live director handoff.
5. [Earlier Notion slice concept](https://app.notion.com/p/3fdd7d8b39078183a159e6bd58fc0b7e) — optional inspiration, not a binding 2D/Hub specification.

## Model delegation authorization (Owner, 2026-10-19 JST)

Opus 5.5 is the **Game Director and final integrator**. The Owner explicitly authorizes Opus to use **gpt-6-astra, gpt-6.1-sol, sonnet-5.5, and haiku-5.5** as additional collaborating models/agents where the execution environment actually provides access. Opus may select, combine, parallelize, or skip any of them according to the task, cost and demonstrated capability. **No fixed model-to-role mapping, mandatory consultation, or rigid agent workflow is imposed.**

Keep independently edited scopes clear, review integrated outcomes, and record material delegation/verification in the normal GitHub Handoff. Do not claim a model was invoked or a review completed unless it actually happened. Lack of access to one optional model should not block the gameplay milestone.

## Original v0.1 acceptance (historical baseline, superseded as product objective)

A **replayable Godot-native, solo 3D short scene**. Player moves/examines/interacts in a believable expedition environment, takes at least one meaningful observation-related action with a visible consequence, reviews available evidence and makes a judgment that another character/the world reacts to.

- **Minimum acceptance:** exact Godot version + launch command, actual runnable project/build, complete interaction path and restart, different reaction for a relevant alternate action or judgment, plus test/play evidence.
- **Not acceptance:** beautiful screenshots, a read-only history presentation, walking without a meaningful task, build green alone.
- **No need yet:** complete historical site, polished assets, full Hub, four-player networking, login, MMO infrastructure, content management system or elaborate reusable RPG foundation.
- **Autonomy:** Opus chooses player mechanics, camera, scripts, art, test approach, parallel task boundaries and feasible length; preserve the **playable action/evidence/judgment loop** and historical respect.

## How to report

At a meaningful milestone or before stopping, leave a compact comment on Issue #1:

`What actually works · commit/PR/build · how to launch/play · observed test results (incl. real gameplay) · historical/asset caveats · next highest-value step · owner/worker`.

Update this file with the latest verified state, link to playable scene/build and unfinished work. New sessions should read issue/latest main/handoff before editing. After merging a PR, re-run and verify the actual merged game before announcing completion.

## Separation from current work
- **Godot work here**: Eddington 1919 3D adventure slice.
- **Existing Web work elsewhere**: [unnamed-disease](https://github.com/nurockplayer/unnamed-disease) continues with the active Opus workstream, not interrupted by this new 3D request.
- Do not claim collaboration, ownership transfer, delegated agent runs or a build that has not actually occurred.

## History
- 2026-10-19: the reference pack was written. Opus then built v0.1 (plan, delivery and evidence are in Issue #1).
  - **Fact check:** a Sonnet 5.5 subagent checked the history used in the game.
  - **Review:** Codex (gpt-6-astra) ran a fresh, read-only review; its findings were fixed in `f107a85`.
  - **Not used:** gpt-6.1-sol, gpt-6-luna and haiku-5.5 were not used.
