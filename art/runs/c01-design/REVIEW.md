# c01 character design: steps 0-2 of the target-first pipeline

Started 2026-10-27 20:20 JST after the Owner paused HG slider iteration
("back to first principles"). Images: codex gpt-6.1-terra image generation
through `art/pipeline/gen.py`; prompts and provenance in `manifest.jsonl`,
prompt sources in `art/prompts/chardesign/` and `art/prompts/target/`.
Everything here is a design draft, not a game asset.

## Step 0: shot list
See [SHOTS.md](SHOTS.md). 3D faces in game are 20-110 px; the 2D dialogue
portrait is the only larger face.

## Step 1: design sheets (lead verdict)
| Sheet | Verdict |
|---|---|
| eddington_1917-D1-gpt-1 | Good likeness cues (long face, receding temples, pince-nez). Dark umber suit merges with a dark study (cast_lineup_dark.jpg). |
| eddington_1917-D1-gpt-2 | Hair too full and wavy; not picked. |
| **eddington_1917_v2-D1-gpt-1** | **Lead pick.** Mid brown-grey herringbone separates from the room; same face cues. |
| **ashby_1917-D1-gpt-1** | **Lead pick.** Slate grey, grey hair and moustache, heavier stooped build: distinct silhouette. |
| kit_1917-D1-gpt-1 | Reads clearly as a young woman; Kit has no stated gender. Rejected. |
| **kit_1917_v2-D1-gpt-1** | **Lead pick, Owner to confirm** the gender-neutral read. Lightest figure in the cast. |

`cast_lineup_dark_v2.jpg`: front views keyed onto the study's dark warm
value, at mid-shot scale (left) and at the 6 m walking scale (right; body
about 184 px). Heights are normalised in this lineup, not to scale.
Value order dark to light: Eddington v1 < Eddington v2 ≈ Ashby < Kit.

## Step 2: target frames (Owner decision)
- `study_mid-D1-gpt-1`: today's first-person conversation camera (face about
  60-80 px). The figures carry the scene through silhouette, value and light.
- `study_close-D1-gpt-1`: a Tell Me Why-style over-the-shoulder close-up
  (face about 250 px). The game has no such camera yet. Defects: temple-arm
  spectacles (should be pince-nez), a town skyline the Observatory site does
  not have.

The Owner question: is the game shot A (keep first person, faces up to
~110 px, close emotion carried by the 2D portraits) or B (add cinematic
close-ups)? A means a 3D face only needs a good read at that size; B adds
hero-face sculpting per principal (step 4) and a close-up camera system.

## Owner decisions (2026-10-27 21:05 JST)
- **Shot A is the production baseline** (first person, faces up to ~110 px).
  Keep the option of B (cinematic close-ups) for a few key story beats later;
  do not build the B camera system now, and do not make asset choices that rule
  B out.
- **Eddington v2 approved** as the visual direction. Before final modelling,
  check likeness against the historical photos and keep documented vs
  reconstructed features apart.
- **Ashby approved.**
- **Kit v2 rejected**: it read as a butch lesbian, not an ordinary neutral
  assistant. Regenerated as `kit_1917_v3` (2 variants): bookish, round wire
  spectacles, soft medium hair, a long pale linen dust coat over a grey
  pullover. Lead pick v3-1; Owner to confirm.
- The approved sheets are the visual baseline: do not regenerate them. They
  are concept art, not finished 3D assets.
