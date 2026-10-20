# Art log

Newest first. One entry per loop iteration: what was tried, what the evidence showed, and what changed. Details live in each run's `REVIEW.md`.

## 2026-10-20: r06 people (Opus 5.5)

**Result:** MPFB 2.0.18 was verified (official source, sha256, Blender 5.2.2 headless, CC0 core and system assets) and installed in isolation.
- Eddington and Cottingham were rebuilt as rigged, proportioned period figures.
- Hats, glasses and the moustache are procedural; the figures have an idle loop and a head look-at.
- The pith helmet became a straw hat (Sobral 1919 evidence).

**Evidence:**
- Four iterations captured with the in-game benchmark, and G2 caught three real export defects.
- Performance: +0.3–0.4 ms forced draw on screen (5 interleaved repetitions; the machine was loaded, so paired deltas were used).
- Gameplay unchanged.
- [REVIEW](runs/r06-people/REVIEW.md)

## 2026-10-20: integration, independent performance check, r05 cinematic pass (Opus 5.5)

**Merged:** PR #4 (r04) → `art/visual-system`, then PR #3 → `main` (`90d9f33`). Verified on a fresh clone of `main`:
- 155/155 tests
- careful autoplay
- export

Before merging:
- rushed and cherry autoplays reached their distinct endings
- the HANDOFF conflict with #5 (narrative scope) was resolved by keeping both

**Independent r04 performance re-check** ([perf-r04](validation/perf-r04/README.md)):
- The geometry cut is confirmed.
- **No measurable render-cost gain:** forced draw stayed at 2.4–3.3 ms.
- Wall-clock p95 is unchanged.
- One contaminated pass (it overlapped image generation) was discarded and re-run.
- Tooling added: forced-draw timing, `perf_summary.py`, and a new G4 performance gate.

**r05 cinematic** ([REVIEW](runs/r05-cinematic/REVIEW.md)):
- **Paint-overs** of real in-game frames served as targets.
- **Five Godot iterations** produced ACES, SSAO, aerial fog, the sky gains, wet laterite, ground macro variation, a world-space weathering layer, a darkroom lamp pool with a stronger safelight, and fading name tags.
- **Cost:** +0.8–1.3 ms forced draw (justified; under the 6 ms absolute gate; wall p95 unchanged).
- **Gameplay:** 155/155 tests, 3 autoplay endings unchanged, evidence sky untouched.

**Next:** people (MPFB 2 proposed in place of Tripo; needs Owner OK to download), vegetation density, and the daytime sky.

## 2026-10-20: r04, foliage cost + shelter and tube (Opus 5.5, Game Director)

**Measured first:**
- `--bench-hide` attribution shows the 70 `SphereMesh` shrubs were 52–81 % of primitives.
- The palms, not the shrubs, dominate draw calls: 125 of 153 in `totality_sky`.

**Built:**
- 4 procedural assets via Codex `gpt-6.1-sol` (Opus rebuilt and re-ran G2, all PASS, deterministic): `sun_shelter` (frame / roof / roll), `horizontal_tube`, `shrub_cocoa`, `banana_clump`.
- Foliage is instanced with one MultiMesh per model.

**Result vs v0.1 baseline:**
- **Primitives:** −42 % to −73 % in 6 of 7 bookmarks (darkroom 497k → 136k).
- **Draw calls:** −5 % to −18 % in the same 6. `totality_sky` is +17 % (within +20 %) because the instanced foliage now draws in the shadow cascades.
- **Frame time:** ≤ 8 ms everywhere.
- **Gameplay:**
  - logic tests 155/155
  - careful autoplay: same ending and score 4
  - the roof still hides at totality, and the rolled canvas appears

**Findings → changes:**

| Finding | Change |
|---|---|
| The lookdev could not frame architecture | `lookdev.gd` auto-framing |
| banana v1 read as spikes | leaf profile v2 and a spec height fix |
| quadrant MultiMesh chunks pushed `totality_sky` draw calls to +21 % | one MultiMesh per model |

**Independent review:** a fresh read-only Codex `gpt-6-astra` session found no blocking issues. Its 3 findings are fixed: cylinder post colliders, bounding-sphere lookdev framing, and receipts for the quadrant and rebuild-hash claims.

Details: `runs/r04-shelter-foliage/REVIEW.md`.

**Next:**
- palm kit (draw calls)
- people (still waiting on the Owner's direction check)
- ground
- a human playtest look at the shelter beam in the totality view

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
