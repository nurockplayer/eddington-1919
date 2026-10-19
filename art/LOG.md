# Art log

Newest first. One entry per loop iteration: what was tried, what the evidence showed, and what changed. Details live in each run's `REVIEW.md`.

## 2026-10-19: Visual system v0.1 (Opus 5.5, Game Director)

**Built:**
- Art Bible (`BIBLE.md`), loop and gates (`PIPELINE.md`)
- versioned prompt library (`prompts/`), palette (`palette.toml`), asset contracts (`assets.toml`)
- tools: `gen.py`, `contact_sheet.py`, `compare.py`, `baseline.sh`, `palette_to_gd.py`, `tripo.py`, Blender `kit.py` and `validate.py`
- Godot side: lookdev scene (G3), in-game benchmark (G4), era grade (`scripts/look.gd`), and palette and model loading in `world_builder.gd`

**Loop iterations in this session:**

| Run | Images | Result → change |
|---|---|---|
| r00 | 1 | Domed observatory → historical negatives are explicit in `base.toml`. |
| r01 | 4 + 8 | Subject-first prompts collapse styles → medium-first composition (s2, styles v2). Direction scorecard → E (B forms + A grade). |
| r02 | 4 + 4 | Variadic `-i` hang fixed. Tool-prompt audit shows verbatim. A ref copies composition. Grade wording ignored → in-engine grade. Darkroom window → v2 windowless (verified) → v3 star negative. Totality → v2 upward. |
| r03 | 4 | Coelostat and crate concepts → Blender procedural builds (Codex gpt-6.1-sol) → G2 PASS ×2 → G3 (lookdev reflection fix) → G4 in-game. |

**Measured:** GPT images take 48–90 s each; 2–3 parallel jobs are reliable. G2 build + validate takes under 10 s per asset. A G4 benchmark run takes about 40 s.

**Gameplay:** logic tests 155/155 after integration. Careful autoplay: ending reached (score 4, never stuck), drive wound and rate-checked via the model's collider, restart works. Receipts are in `validation/autoplay-r03/`.

**Independent review:** a fresh read-only Codex gpt-6-astra session requested changes, and all were fixed:
- a `baseline.sh` deletion hazard and silent failures
- the drive housing lost solid collision
- stale-image attribution in `gen.py`
- `compare.py` re-encoding evidence
- a weak G2 origin check (now per object, with pivots and loose geometry)
- crate collider vs measured mesh
- scorecard arithmetic (A/C/D = 43/39/29)
- the LUT not identity at 0.85
- laterite over the saturation cap (`palette_to_gd.py` now enforces §4)
- an unsourced 16 × 16 cm plate size
- lookdev now excluded from export

**Blocked / not verified:**
- Tripo (no `TRIPO_API_KEY`; client untested)
- Gemini (free-tier quota is 0)
- "dot" (not found on this machine)
- No human look at the new art in motion yet.

**Unexplained:** during this session the shared checkout was switched to `main` by something outside this session (reflog: `checkout: moving from art/visual-system to main`). The Blender worker reports no git operations. The uncommitted work was unaffected, and the branch was restored.

**Next:** people (S4 care), foliage (primitive cost), shelter and tube, ground. The direction itself awaits an Owner glance (BIBLE §2).
