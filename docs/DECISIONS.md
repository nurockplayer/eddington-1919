# Decisions & Scope

**2026-10-19 JST — Owner decisions**. Newer Owner instructions supersede older brainstorming. Decisions may evolve as gameplay is tested; do not treat reference prose as strict screenplay.

## D001 — Separate project
- 《雲層之後》 / `eddington-1919` is a **separate historical adventure**, not a rebuild of 《沒有名字的病》.
- `nurockplayer/unnamed-disease` keeps its independent Web detective game workstream. Shared ideas are allowed, but no cross-repo editing or schedule disruption is needed.
- Series name, published game title, definitive timeline/number of sequels and Hub mystery are undecided.

## D002 — Godot + 3D (Owner confirmed)
- The **Godot engine** and a *genuinely explorable, controllable 3D game* are requirements. Prefer a native desktop prototype; exact stable Godot version, scripting language, camera design and distribution are Game Director choices.
- A static 3D render or walking demo with automatic exposition does **not** satisfy the gameplay requirement.
- Small scene and reusable player interaction are more valuable than large terrain or high-poly assets.

## D003 — Solo-first, future optional 1–4 co-op
- First playable version must be independently completable by **one player**.
- Design simple boundaries between local input/presentation and meaningful shared scene/observation/decision state, when convenient. **Do not implement matchmaking, networking, accounts, online persistence or MMO infrastructure in MVP.**
- Consider co-op only after the solo gameplay loop is independently verified. Never require three extra players for the primary story.

## D004 — First playable test and historical responsibility
- Prove a playable loop: **3D exploration → purposeful action → observable evidence consequence → player judgment → character/world reaction**.
- 1919 Príncipe observatory is the setting. Historical record, dramatic reconstruction and fiction must be distinguishable; no unfair invented wrongdoing by real people.
- Existing 2D Notion proposal offers potentially useful mechanics and atmosphere but is not binding. Hub, exact countdown, fictional jammed equipment, scene count and scripted endings may all change according to better gameplay evidence and historical checks.

## D005 — Direction, engineering autonomy, evidence
- **Opus 5.5 = Game Director**. May change approach and direct Sol/Codex or independent reviews without Owner micro-approvals, while preserving D001–D004.
- Avoid imposing `CLAUDE.md`, `AGENTS.md`, generalized agent frameworks or heavy pipelines before real need.
- Record milestones and truthful playable verification in [GitHub Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1), keeping [HANDOFF](HANDOFF.md) current.
- Do not call screenshots, imported assets, a successful compilation, or a spec document a gameplay-complete result.

## New decision entry format
- **Identifier and date**
- **What changed and why**
- **What was actually verified**
- **Risks/reversibility and linked commit / issue / playtest**

## D006 — First playable slice design (Game Director, 2026-10-19)
- **What changed and why**
  - **Engine and look.** Godot **4.7.2 stable**, GDScript, Forward+. The scene is built in code from primitives: no imported assets, so there are no licensing questions, and the build is reproducible from a fresh clone.
  - **Camera.** First-person, because looking up at the cloud over the Sun *is* the core action.
  - **Loop.** Prepare the station (three optional tasks under a countdown) → call exposures through a drifting cloud field during 302 s of totality, compressed ×2.5 → inspect plates rendered from what each exposure actually recorded → select plates before seeing values, then measure → choose a telegram and a reason → Eddington and Cottingham react → ending with the historical record → replay with the same or a new sky.
  - **The sky is the evidence.** One cloud texture feeds both the sky shader and the simulation's sample at the Sun. What the player sees is exactly what the plate receives, so there is no hidden dice roll.
  - **Player role.** The player is a fictional "cloud caller". Cottingham keeps the hand-held screen and Eddington keeps changing plates, matching the record, so no real person's contribution is displaced.
  - **Judgment.** The telegram is graded against the evidence class (none / favors 1.75″ / favors 0.87″ / ambiguous) and against selection integrity (omitted good plates, included trailed or fogged plates, re-selecting after seeing values). The point is calibrated claims, not "pick Einstein".
  - **Co-op boundary.** `scripts/eclipse_sim.gd` holds all shared observation and decision state with no nodes. Input, camera and UI stay local. There is no networking.
- **What was actually verified:** 151 headless logic checks pass. Three autoplay strategies (careful / rushed / cherry-pick) reach three different endings through real input events, with screenshots. The macOS universal export launches. **No human playtest yet.**
- **Risks and reversibility:**
  - Exposure difficulty, prep timing (150 s) and gap readability are tuned only by bot runs and need human tuning.
  - The art is primitive.
  - The measurement model is illustrative.
  - All of these are isolated in a few files and easy to change.

## D007 — Lightweight Art Bible and fast generate→Godot loop (Game Director, 2026-10-19)
- **What changed and why:**
  - The Owner asked for a reusable visual design system in which fast image generation is part of production, not only early reference.
  - Direction **"Diorama + Plate Grade"** was chosen from four generated directions by a weighted scorecard ([art/BIBLE.md](../art/BIBLE.md) §2):
    - Simplified, bevelled, flat-palette 3D forms. They are buildable, cheap and readable.
    - A subtle toned-glass-plate grade applied in-engine. It carries the era.
  - Series-wide principles (BIBLE §1) are kept separate from 1919-specific rules. They become series rules only after a second era uses them.
  - Instruments and architecture are modelled procedurally in Blender to spec dimensions. Image-to-3D (Tripo) is reserved for organic props.
- **Supersedes:** D006's "no imported assets". GLBs are now built reproducibly by committed Blender scripts (`art/pipeline/blender/`). Every primitive fallback still works if a model is missing.
- **What was actually verified:**
  - 25 generated images across 4 rounds, with exact prompts and timings in `art/runs/*/manifest.jsonl`.
  - 2 production assets (coelostat, packing crate) pass the G2 mesh gate, the G3 lookdev and the G4 in-game benchmark against the v0.1 baseline (`art/validation/`).
  - 155/155 logic checks pass after integration. The careful autoplay reaches its ending, with the drive wound and rate-checked through the new model and restart working. Receipts are in `art/validation/autoplay-r03/`. The benchmark harness itself does not exercise gameplay.
- **Not verified:** the Tripo route (no API key), Gemini (no quota), "dot" (unidentified), and human judgment of the new look.
- **Risks/reversibility:**
  - The grade is one file (`scripts/look.gd`, `--no-grade` turns it off).
  - The palette is one file (`art/palette.toml` → `scripts/palette.gd`).
  - Models fall back to primitives.
  - **Owner confirmation of the direction is requested** (major-direction rule); the work is not blocked on it.
