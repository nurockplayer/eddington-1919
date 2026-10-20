# Art Bible: Eddington 1919 (+ series layer)

**Status:** v0.1 (2026-10-19). Minimum viable rules for the Príncipe slice, with every rule backed by a test run in `art/runs/` or a capture in `art/validation/`. It is meant to be short. If a rule here and a screenshot disagree, trust the **in-game screenshot** and fix the rule.

- **How to make things:** [PIPELINE.md](PIPELINE.md)
- **Palette:** [palette.toml](palette.toml)
- **Asset contracts:** [assets.toml](assets.toml)
- **Decision log:** [LOG.md](LOG.md)

The rules come in two layers:
- **Series layer (§1):** holds for every game in a future history-of-science series.
- **Era layer (§2–§5):** specific to 1919.

Promote an era rule to the series layer only after a second era has used it successfully. Until then it is an Eddington rule.

---

## 1. Series layer (candidate series identity)

| # | Principle | Test you can run |
|---|---|---|
| S1 | **Evidence is the light.** The scientific evidence is the brightest, cleanest and highest-contrast thing in the frame. Here that means the Sun and corona, stars, plates and the measuring sheet. Nothing else may compete. | Squint test on the in-game benchmark shots (G4): the first thing you see must be evidence. Albedo value cap (§4). |
| S2 | **Hand-built diorama at 1:1.** Simplified, softly bevelled forms with large silhouettes and flat palette colour. Materials read through colour and big shapes, not micro-detail. | Silhouette camera in lookdev (G3). Any feature under 2 cm is removed. |
| S3 | **The era through its medium.** Each game's grade comes from how that era recorded evidence. For 1919 that is the toned glass-plate print (`scripts/look.gd`). Other eras would get their own medium; for example a copper engraving for the 1600s or a cyanotype for the 1890s. These are examples, not commitments. | The era layer touches only the grade, palette and props. Forms and value rules stay series-wide. |
| S4 | **Real people, respectfully.** Simplify, never caricature. No invented flaws. Clothing and hats are labelled RECONSTRUCTION when they are not documented. | History check at G1. Provenance column in `assets.toml`. |
| S5 | **Gameplay readability beats the picture.** If the art direction makes the cloud gap, an interactable or a plate harder to read, the art direction changes. | Autoplay + human playtest. The totality bookmarks in G4. |

## 2. Era layer: chosen direction "Diorama + Plate Grade"

Round **r01** generated four directions on the same key shot (`art/runs/r01-directions/`):
- A: Silver Plate
- B: Painted Diorama
- C: Naturalist Gouache
- D: Grounded Realism

Round **r02** tested a hybrid on the three gameplay keyframes. They score as follows (1–5, director's review; the details are in each run's `REVIEW.md`):

| Criterion (weight) | A Silver Plate | **B Diorama** | C Gouache | D Realism | **E = B + plate grade** |
|---|---|---|---|---|---|
| Gameplay readability: sky and interactables (×3) | 2 | 4 | 3 | 3 | **4** |
| Buildable by our pipeline: procedural Blender, Tripo, flat materials (×3) | 3 | 5 | 2 | 1 | **5** |
| Real-time cost (×2) | 4 | 5 | 3 | 2 | **5** |
| Tone: serious historical suspense (×2) | 5 | 3 | 4 | 4 | **4** |
| Series extensibility (×2) | 3 | 4 | 3 | 2 | **5** |
| Distinctiveness (×1) | 4 | 3 | 4 | 1 | **4** |
| **Weighted total (/65)** | 43 | 54 | 39 | 29 | **59** |

**Decision (Game Director, reversible):** E.
- Forms come from B: buildable, cheap, readable.
- The era comes from A's idea, applied as a restrained **in-engine grade**, because image models ignore grade wording (r02 finding) and the engine controls it exactly.
- C and D are rejected:
  - C's painterly surface needs hand-painted textures that the pipeline cannot produce consistently.
  - D drifts towards an uncanny, expensive look, and image-to-3D artifacts show most in realism.

**Owner decision (2026-10-20):**
- Adopted provisionally, with room to adjust.
- **Aim for historical weight, cinematic light and shadow, suspense and the characters' emotion. Avoid a cartoon or toy-like read.**
- The forms stay simplified, but presentation follows the anti-toy rules (§3a) and the cinematic lighting (§5), first applied in r05.

## 3. Shape language

- **Bevels:** 0.6–1.2 cm on props and 2–4 cm on architecture. Every hard edge has one. One segment only, so edges read as a painted highlight line, not as smooth chrome.
- **Minimum feature size:** 2 cm. Below that, merge the detail into the form or drop it. The silhouette must read at 64 px tall.
- **Segment counts:** large cylinders 16–20 sides, small ones 8–12. No subdivision surfaces.
- **Instruments are mechanical and dimensioned.** Model them procedurally in Blender to the spec dimensions in `assets.toml`; the spec wins over the concept image. Image-to-3D (Tripo) is for organic or irregular props: sacks, rocks, foliage clumps, cloth, food. Research shows AI 3D is weakest at precise mechanical parts.
- **Moving parts** are separate objects with their pivot at the origin (for example `coelostat_mirror`).

## 3a. Anti-toy rules (r05; Owner tone 2026-10-20)

The forms may stay simplified. These rules stop simplified forms reading as toys:

- **No flat fill larger than about 1 m².** Every non-metal, non-evidence material gets the shared world-space weathering multiply (`world_builder.weather()`, also applied to imported models). The weathering is broad and soft: r05 try4 showed that fine noise reads as camouflage.
- **Objects touch the ground.** SSAO is on (`look.gd`), and nothing floats without a contact shadow.
- **Large ground planes carry macro variation** at two scales. Wet surfaces carry it in roughness, not in loud albedo noise (r05 try2 "pink cobbles").
- **The sky never clips to white** in gameplay views, and the clouds have structure (`cloud_shade`, `day_gain`).
- **No HUD text in vistas.** Name tags fade beyond 9 m.
- **People must have human proportions** (r06). Use MPFB humans with flat palette skin, CC0 garments restyled in period colours, and procedural period accessories. No photographic skin, no caricature, nothing that reads as toy-like. Facial hair is shaped after the sources, and anything that carries unwanted associations is avoided (r06: a narrow "toothbrush" moustache was widened to the full moustache in the source).
- **Evidence is exempt from weathering, marked explicitly:** `evidence_mat()`, the palette `evidence` role and metals. That covers plates, the measuring sheet and the mirror. A brightness cutoff is not used: it also skipped whitewash and canvas (PR #6 review).

## 4. Colour and value

- **Palette:** [palette.toml](palette.toml) is the only source. Godot gets a generated copy (`scripts/palette.gd`, built by `art/pipeline/palette_to_gd.py`); Blender reads it through `kit.mat()`. There are 19 swatches in 7 roles: ground, foliage, structure, instrument, accent, far, evidence.
- **Value:** albedo HSV value stays within **0.08–0.82**. Values above 0.85 are reserved for the **evidence** role (S1). The whitewash house was darkened to 0.82 for this reason.
- **Saturation:** at most 0.65. The only saturated hues are laterite red (ground, the warm anchor) and brass (instrument accents, which draw the eye to things you can operate).
- **Temperature:** warm ground and structures, cool far planes and sky. During totality everything goes cool except the horizon glow.

## 5. Light and grade per game state

These are the states of the benchmark bookmarks in `tests/benchmark.gd`. The lighting code is the game's own `main._apply_light()`.

| State | Key | Ambient | Notes |
|---|---|---|---|
| `prep_early` | Weak sun through cloud, warm white | Grey-blue sky | ACES, fog density 0.0035. Wet laterite reads darker. |
| `prep_late` | Dimming crescent | Cooling | Pre-totality unease. The canvas roof is still on. |
| `totality` | None | Deep blue | 360° orange horizon glow (`eclipse_sky.gdshader`), corona and stars. The roof is rolled back. |
| `night` | Warm oil lamp 1.1 + red safelight 0.25 | Near-black | Darkroom. The plate and measuring sheet are the brightest things. |

- **Cinematic layer (`look.gd`, r05):**
  - ACES tonemap at exposure 0.95.
  - SSAO: radius 1.1, intensity 2.2.
  - Aerial-perspective fog at 0.0042, plus low height fog. **`fog_sky_affect` stays 0**, so fog never alters the evidence sky.
  - Sun: soft shadow edges, warm key (1.0, 0.91, 0.78) with gain 1.25. The direction stays historical; no golden-hour sun at 14:00.
  - Ambient gain 0.72.
  - Sky gains apply to daytime only and fade out with `darkness`.
  - Night safelight 0.5.
- **Grade (`scripts/look.gd`):** saturation 0.86, contrast 1.04, and a per-channel LUT with sepia-warm shadows and warm midtones, identity from 0.85 up.
- Disable the grade with `--no-grade` for A/B checks.
- The grade must never tint the evidence whites. The LUT is identity above 0.85.

## 6. Asset standards (checked by G2, `art/pipeline/blender/validate.py`)

| Category | Triangles | Materials | Texture | Example |
|---|---|---|---|---|
| hero_prop (interactable or focal) | ≤ 6 000 | ≤ 6 | ≤ 1024 px | coelostat |
| kit_prop (repeated) | ≤ 600 | ≤ 3 | ≤ 512 px | packing_crate |
| set_prop | ≤ 2 000 | ≤ 3 | ≤ 512 px | table, chronometer |
| architecture | ≤ 3 000 | ≤ 4 | ≤ 1024 px | shelter, darkroom |
| character (rigged, animated) | ≤ 16 000 | ≤ 10 | none (palette) | eddington, cottingham |

- **Units and axes:** metres. Blender is Z-up. Export glTF Y-up (GLB). The front faces −Y in Blender, which is +Z in Godot. The origin is at bottom-centre; a pivot object's origin is on its pivot.
- **Names:** every mesh object starts with the asset id (`coelostat`, `coelostat_mirror`). Materials are `E1919_<swatch>`. Files are `assets/models/<asset_id>.glb`.
- **Materials:** flat palette factors and no textures for procedural assets.
  - **Tripo assets:** keep their texture, but it must be **de-lit** (`delight: true`; no baked shadows in albedo). It must also pass a palette and value check at G3.
  - **Texel density for textured assets:** 256–512 px/m. Consistency matters more than the number.
- **Collision:** box colliders written in `world_builder.gd`. Never use mesh colliders from imported art. Interaction hotspots stay in code, so art changes cannot break gameplay.
- **LOD:** none needed at the current scene size. Godot's import-time LOD is on by default. Revisit if `primitives` in G4 exceeds 600k.
- **History tag:** every asset carries a `history` line (RECONSTRUCTION, HISTORICAL_RECORD or FICTION), matching `docs/PROVENANCE.md`.

## 7. Camera and framing

- **In game:** eye height 1.62 m, vertical FOV 72°, which is about 103° horizontal at 16:9 (`scripts/player.gd`).
- **Concept keyframes** ask for an eye-level, 50 mm-equivalent view. They are mood targets, not 1:1 camera matches. The comparison that matters is concept keyframe ↔ in-game benchmark bookmark of the same state (`art/validation/*/compare.jpg`).

## 8. Do and don't (from our own runs)

| Do | Don't |
|---|---|
| Open-sided timber sun-shelter with a canvas roof, a long horizontal tube on trestles, and a coelostat on a brick pier (r01 B, r02 E). | **Observatory domes.** The first unconstrained image drew one (r00 probe), and it is historically wrong for Príncipe. Domes are banned in `base.toml`. |
| A **windowless** darkroom lit by a lamp and a red safelight. | The r02 darkroom drew a window onto the night sky. A darkroom cannot have one. Fixed in `darkroom_night` v2. |
| A brass cell and fork around a ~40 cm mirror. Follow the **spec** proportions. | The r03 concept drew an oversized mirror. Images are shape references only; `assets.toml` dimensions win. |
| Banana clumps with broad leaves that **arch outward and droop** (r04 v2). Repeated foliage is one kit mesh drawn as a MultiMesh. | Upright, spiky leaves that rise as much as they reach (r04 v1 read as bare stems). Default `SphereMesh` shrubs (≈4k triangles each, 52–81 % of the scene's primitives). |
| Warm 360° horizon glow at totality. | A clear, saturated blue sky at totality ("clear sky" is a myth the docs avoid). |
