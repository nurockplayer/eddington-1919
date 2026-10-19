# Game Director Handoff

**Latest: 2026-10-19 JST** | Status: **v0.1 playable slice delivered**. The complete loop is verified by automated real-input runs. **There has been no human playtest yet.**

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

## Visual system (art pipeline, 2026-10-19)
- **Read [art/BIBLE.md](../art/BIBLE.md)** (style rules) **and [art/PIPELINE.md](../art/PIPELINE.md)** (generate → choose → Blender/Tripo → Godot gates → feed back) before making any art.
- **Decision record:** [D007](DECISIONS.md). **Log:** [art/LOG.md](../art/LOG.md).
- **Generate concept images:** `python3 art/pipeline/gen.py --run rNN-x --styles E_diorama_plate_grade --subject <subject> --gens gpt --n 2` (GPT via Codex, about 1 min per image).
- **In-game visual benchmark:** `godot --path . --always-on-top -- --benchmark=$PWD/art/validation/g4-<label> --seed=7`, then compare against `art/validation/g4-baseline-v0.1` with `art/pipeline/compare.py`.
- **Lookdev:** `godot --path . --always-on-top res://scenes/lookdev.tscn -- --capture=$PWD/art/validation/g3-<label>`.
- **Blocked:** Tripo needs `TRIPO_API_KEY`; Gemini needs paid image quota; "dot" is unidentified.

## Next single highest-value step
**A human playtest of v0.1**, about 15 minutes, using the five questions in [PLAYTEST.md](PLAYTEST.md). Then tune gap readability, prep pressure and exposure difficulty from what the player actually does. Do not expand the scope before that.

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

## Target next deliverable

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
