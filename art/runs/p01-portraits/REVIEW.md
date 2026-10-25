# p01 · dialogue-portrait style test (2026-10-25)

**Purpose.** A small style test only, not a pick. The Owner judged the characters the
weakest part of the game, and approved a hybrid direction (2026-10-25): 3D bodies stay in
the world, and dialogue shows an illustrated head-and-shoulders bust in the manner of a
toned early-twentieth-century print. No realistic 3D faces, no lip-sync. This run makes
2 styles × 2 characters × 2 variants = 8 images so the Owner and the Director can choose a
style before any mass run. **Nobody is chosen here.**

- **Run id:** `p01-portraits`
- **Contact sheet:** [contact.jpg](contact.jpg). Rows are subjects, columns are
  P1 variant 1, P1 variant 2, P2 variant 1, P2 variant 2.
- **Prompts:** [styles](../../prompts/portrait/styles.toml) P1_toned_print, P2_drawn_over_print;
  [subjects](../../prompts/portrait/subjects.toml) `eddington_1917`, `ashby_1917`;
  portrait base blocks and framing in [base.toml](../../prompts/portrait/base.toml).
- **Generator:** `codex exec` (`gpt-6-astra`, the `image_generation` tool) through
  `art/pipeline/gen.py --gens gpt`, max 3 jobs in flight, one wall-clock cap per invocation.
  8 of 8 succeeded on the first attempt, no retries, 48–88 s each.
- The exact prompt for every image, and the prompt the image tool actually received
  (`tool_prompt`, verified verbatim), are in [manifest.jsonl](manifest.jsonl).

## Labels (S4)

- **Documented (from [REFERENCE.md](../../people/REFERENCE.md)):** Eddington's clean-shaven
  face, narrow long face, high forehead, strong brows, dark hair brushed back with a slight
  side parting receding at the temples, thin rimless / pince-nez style glasses, slender build
  (c.1915 portrait, medium confidence).
- **RECONSTRUCTION:** every garment, collar, tie, watch chain, background, lighting, pose
  and expression in all eight images; Eddington's 1917 (rather than 1915) age as shown here;
  the whole of Mr Ashby, who is a **fictional** character and must not resemble a real person.
- No photograph was used as a reference image. Likeness comes only from the written cues.

## Per-image notes (honest, from looking at the 1280 px JPEGs)

### eddington_1917-P1-gpt-1
- **Likeness:** long narrow face, high forehead, strong brows and dark hair brushed back and
  receding at the temples all read. Clean-shaven. Slender enough in the shoulders.
- **Glasses:** round, thin metal rims with thin temple arms. Period-plausible spectacles, but
  they are **not** pince-nez and not rimless, so they do not match the documented eyewear
  (REFERENCE.md: thin or rimless lenses, pince-nez style). The likeness here is partial.
- **Age:** reads late 30s to early 40s; the brief asks 34. Slightly old.
- **Expression:** reserved and attentive, slightly stern; no smile. Good.
- **Dress:** dark three-piece suit, white collar, dark tie; no hat. Collar reads as a rounded
  club collar, which is period-plausible.
- **Artefacts:** clean ears; no hands in frame; no text or watermark. Mild studio mottling in
  the background, consistent with a print.
- **Read:** the most convincing print of the four Eddington images.

### eddington_1917-P1-gpt-2
- **Likeness:** same documented cues read, with a fuller cheek and a slightly heavier neck —
  reads less "slender" than the cue. Temple recession and part are clear.
- **Glasses:** same round thin-rim style with arms.
- **Age:** reads about 40; the youngest-looking of the four is not this one.
- **Expression:** calm, a little distant; acceptable for "reserved".
- **Artefacts:** cheeks look faintly retouched/smoothed compared with P1-1; the hair edge
  against the background is soft. No hands, no text.
- **Read:** a softer, more studio-glossy print than P1-1.

### eddington_1917-P2-gpt-1
- **Likeness:** the narrowest face of the four; high forehead and strong brows read well;
  hair line and part read.
- **Medium:** photographic base with graphite over it — the background and jacket show drawn
  tone, the face is softly modelled. This is close to a real early-20th-century "crayon
  portrait" (charcoal or graphite over a photograph), which is useful precedent for P2.
- **Glasses:** thin rims; the far-side rim fades slightly into the cheek. Minor.
- **Artefacts:** the shadow-side ear is simplified/flat but not deformed. No hands, no text.
- **Read:** sober, slightly severe. Not cartoon, no ink outlines.

### eddington_1917-P2-gpt-2
- **Likeness:** strongest match to "narrow long face" and "slender"; brow and forehead read.
- **Medium:** the drawing is the most visible of the four P2 images (hatching in the
  background and on the suit), so it is the clearest test of "drawn over print".
- **Glasses:** left lens rim partly lost against the cheek; the arm on the far side meets the
  hair awkwardly. Cosmetic, not structural.
- **Artefacts:** no hands, no extra features, no text. Ears plausible.
- **Read:** reads as a period pencil portrait, expressive but restrained, not a filter.

### ashby_1917-P1-gpt-1
- **Brief match:** about 60; grey hair; a full grey moustache; dark wool suit with waistcoat,
  watch chain visible; no hat. Expression reads kindly but exacting.
- **Fiction safety:** generic Edwardian elder. It does not obviously copy a known portrait,
  but a real public figure of the period could resemble it by chance; the Director should
  look before this face is adopted.
- **Artefacts:** collar and knot clean; watch chain links plausible; ears clean. No text.
- **Read:** dignified, not caricature.

### ashby_1917-P1-gpt-2
- **Brief match:** same cues; slightly softer, more "grandfatherly" read than P1-1.
- **Artefacts:** the tie knot is a small dark mass with little structure — the weakest clothing
  detail in the batch. Watch chain reads. No hands, no text.
- **Read:** acceptable print; the tie would need a re-run before use.

### ashby_1917-P2-gpt-1
- **Brief match:** cues read; the watch chain and its fob are clearly drawn; waistcoat buttons
  read.
- **Medium:** drawn-over-photo reads well, especially in the background and the jacket.
- **Artefacts:** chain links are slightly irregular up close; left ear is simplified. No hands.
- **Read:** sober and period; no ink outlines.

### ashby_1917-P2-gpt-2
- **Brief match:** cues read; a watch-chain medallion/fob appears, which is plausible but is an
  invented detail (RECONSTRUCTION).
- **Medium:** visible hatching across the background; clear drawing hand.
- **Artefacts:** the tie knot is mushy, as in P1-2; the far ear is large but natural. No text.
- **Read:** the most "drawn" Ashby; still restrained, not cartoon.

## Cross-image notes

- **Consistency:** within a subject the four images read as the same man; across subjects the
  two men are clearly different and read as different ages.
- **Anti-toy / anti-cartoon:** none of the eight reads toy-like, anime, or like an RPG
  character card. P2 stays clear of ink outlines and cel shading.
- **Uncanny:** mild on P1-2 (retouched cheeks) and P2-1 (flat shadow-side ear). None of the
  eight has the airbrushed, hyperreal surface of a modern "deepfake" render; the toned-print
  look is visibly a print (grain, tonal compression). But a convincing toned print of a named
  person **can be mistaken for a real archival photograph**, so the game must carry a
  RECONSTRUCTION disclosure with the portraits (see Follow-ups).
- **Framing:** all eight are square head-and-shoulders busts in three-quarter view on a plain
  dark ground — directly usable as a dialogue bust crop.
- **Anachronisms found:** none in clothing or hair that I can defend as wrong for 1917.
  The uncertain item is Eddington's spectacle type (temple arms rather than pince-nez).
- **Not visible:** hands are out of frame in every image, so hand artefacts could not be
  assessed; bust crops in game would not show them either.

## Provenance

| Image | Subject | Style | Variant | Generator / model | Created (UTC) | s |
|---|---|---|---|---|---|---|
| eddington_1917-P1-gpt-1.jpg | eddington_1917 | P1_toned_print | 1 | codex:gpt-6-astra/image_generation | 2026-10-25T05:52:11 | 66.8 |
| eddington_1917-P1-gpt-2.jpg | eddington_1917 | P1_toned_print | 2 | codex:gpt-6-astra/image_generation | 2026-10-25T05:51:52 | 48.1 |
| eddington_1917-P2-gpt-1.jpg | eddington_1917 | P2_drawn_over_print | 1 | codex:gpt-6-astra/image_generation | 2026-10-25T05:52:05 | 60.7 |
| eddington_1917-P2-gpt-2.jpg | eddington_1917 | P2_drawn_over_print | 2 | codex:gpt-6-astra/image_generation | 2026-10-25T05:52:46 | 54.0 |
| ashby_1917-P1-gpt-1.jpg | ashby_1917 | P1_toned_print | 1 | codex:gpt-6-astra/image_generation | 2026-10-25T05:53:44 | 54.4 |
| ashby_1917-P1-gpt-2.jpg | ashby_1917 | P1_toned_print | 2 | codex:gpt-6-astra/image_generation | 2026-10-25T05:53:57 | 67.2 |
| ashby_1917-P2-gpt-1.jpg | ashby_1917 | P2_drawn_over_print | 1 | codex:gpt-6-astra/image_generation | 2026-10-25T05:54:18 | 88.2 |
| ashby_1917-P2-gpt-2.jpg | ashby_1917 | P2_drawn_over_print | 2 | codex:gpt-6-astra/image_generation | 2026-10-25T05:54:53 | 68.5 |

- **Prompts and hashes:** [manifest.jsonl](manifest.jsonl) holds the exact composed prompt,
  the block versions (`series` = portrait base `p1`, `style` / `subject` = `v1`), the model,
  the timestamp, and the raw PNG sha256 for each image.
- **Raw PNGs** are in `_raw/` (git-ignored, as for every earlier run).
- Committed JPEGs are 1254 × 1254, 148–334 KB each.

## Independent review (oracle-ego, GPT-6, 2026-10-25)

Verdict: **pass for an exploratory style test**, with no production adoption yet. It raised
two points, both about the notes rather than the images:
1. Eddington's spectacles are rimmed, with temple arms, and so do not match the documented
   pince-nez; the earlier wording here called them "within the brief". Corrected above.
2. The claim that the images cannot read as deepfakes because no photograph was supplied was
   not a sound inference. Reworded above, and the in-game RECONSTRUCTION disclosure is now a
   follow-up.
It found no defensible clothing or hairstyle anachronism for 1917, and no regression from the
`gen.py` base-selection change. It could not see the JPEGs themselves.

## Follow-ups (not done here)

- **Eddington's glasses.** All four came back as rimmed spectacles with temple arms. A v2
  subject wording ("rimless pince-nez clipped at the nose bridge, no temple arms") would test
  the documented type, unless the Owner prefers ordinary period spectacles.
- **RECONSTRUCTION disclosure in game.** The busts carry no caption (the prompt forbids text).
  The dialogue UI needs a visible RECONSTRUCTION note or credits line before adoption.
- **Ashby resemblance check.** The face is generic, but the Director should confirm it does not
  read as an identifiable real person before it is used.
- **Consistency across a mass run.** Two variants per style already differ in age and build.
  A production batch needs a consistency method (a fixed seed or a locked character
  reference); a `--ref` would also copy composition, per PIPELINE.md rule 2.
- **Bust crop.** The images are 1:1 because the Codex image path offers square or landscape
  only. A vertical UI crop needs either a new aspect or an in-game crop.
- **Small artefacts:** the tie knot is mushy in `ashby_1917-P1-gpt-2` and
  `ashby_1917-P2-gpt-2`; `eddington_1917-P1-gpt-2` has slightly retouched cheeks. Re-run
  before production use.
- **Hands** are out of frame everywhere, so hand artefacts are untested.
- **Grade interaction.** The toned look is baked into these prints, as the medium requires.
  Decide whether the in-game grade (`scripts/look.gd`) should be bypassed for the portrait
  layer so the tone is not applied twice.

## Decision (2026-10-25)

The Owner picked **P1 Toned Print**. P2 is not taken forward. The Director had recommended
P2 because P1 can be mistaken for a real archival photograph. With P1, the in-game
RECONSTRUCTION disclosure is therefore a must before adoption, not a nice-to-have. The
`eddington_1917` subject moves to v2 (pince-nez wording) for the next batch; the images in this
run were made with v1.
