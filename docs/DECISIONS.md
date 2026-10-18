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
