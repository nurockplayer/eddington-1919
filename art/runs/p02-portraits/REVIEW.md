# p02 · P1 dialogue-portrait production candidates (2026-10-25)

**Purpose.** Four proposed dialogue bust assets: one neutral and one expression variant per character. The Owner chose P1 Toned Print in p01. Eddington's neutral candidates use subject v2. Ashby's neutral is carried forward from the p01 image explicitly judged clean; it was not regenerated.

**Labels.** Eddington's narrow long face, high forehead, strong brows, receding dark hair brushed back, clean-shaven face, and pince-nez-style glasses are the documented c.1915 cues in `art/people/REFERENCE.md` (confidence varies by cue). All other details are **RECONSTRUCTION**, including the shown 1917 age, clothing, collar, tie, pose, lighting, expression, photographic medium, and background. Mr Ashby is fictional; his entire depiction is **RECONSTRUCTION**.

**Contact sheet:** [contact.jpg](contact.jpg), all nine candidates in filename order. The copied Ashby neutral is labelled with its p01 source in the manifest.

## Per-image notes

### `eddington_1917-P1-gpt-1-neutral.jpg`

- **Glasses:** thin oval lenses with a small bridge and nose clips; no temple arms are visible. The lens edges have a fine outline, so the image does not make a fully rimless construction unambiguous. Of this batch, it reads most like a nose-clipped pince-nez.
- **Identity:** this is the selected neutral reference. Narrow face, high forehead, strong brows, receding brushed-back hair and clean-shaven face align with the documented cues.
- **Artefacts:** ears look natural. Collar and tie are clean. Skin keeps visible texture and does not look airbrushed. Glass bridge is slightly bright but coherent.
- **Read:** strongly resembles a toned archival studio photograph; it could be mistaken for a real photograph without a visible **RECONSTRUCTION** disclosure.

### `eddington_1917-P1-gpt-2-neutral.jpg`

- **Glasses:** thin outlined oval lenses and a bridge; no temple arms are apparent at this size. They read as wire spectacles more than clearly rimless pince-nez.
- **Identity:** same sitter as neutral-1; facial proportions, hairline and brows are consistent. The face is a little fuller and less narrow.
- **Artefacts:** ears are plausible. Collar and tie are clean. Skin texture is natural with mild softness. The glasses have a small bright reflection at the bridge.
- **Read:** archival toned-print appearance, with the same risk of being mistaken for a real photograph; label **RECONSTRUCTION**.

### `eddington_1917-P1-gpt-1-neutral-r.jpg`

- **Glasses:** retry after neutral-1 and neutral-2 did not clearly establish rimless lenses. The bridge and nose clips read as pince-nez, and no temple arms are visible, but both lenses still have a visible fine outline; the retry did not make the lenses unambiguously rimless.
- **Identity:** consistent with the same Eddington depiction and documented facial cues, though the head angle and face shape differ from the selected neutral.
- **Artefacts:** ears look plausible. Collar and tie are clean. Skin texture is natural. The lens outlines and bridge are the main uncertainty.
- **Read:** convincing toned archival portrait and needs a **RECONSTRUCTION** disclosure.

### `eddington_1917-P1-gpt-2-neutral-r.jpg`

- **Glasses:** visible oval wire outlines and bridge; one side appears to continue toward the temple. This is the weakest match to the no-frame/no-arm target.
- **Identity:** still reads as the same Eddington depiction; long face, high forehead, brows and receding hair are present.
- **Artefacts:** ears are plausible. Collar and tie are clean. Mild softening in the skin; no obvious airbrush effect. Glasses are the main artefact and mismatch.
- **Read:** reads as a toned archival studio photograph; mark **RECONSTRUCTION**.

### `eddington_1917-P1-gpt-1-intent.jpg`

- **Glasses:** same thin outlined, bridge-clipped lenses as neutral-1, with no temple arms visible. Not unambiguously rimless.
- **Identity:** very close match to selected neutral-1; same sitter, hair, face shape and framing.
- **Artefacts:** ears, collar and tie remain clean. Skin texture is natural. Expression is restrained and earnest, but subtle.
- **Read:** archival toned-print look; could be mistaken for a real portrait, so label **RECONSTRUCTION**.

### `eddington_1917-P1-gpt-2-intent.jpg`

- **Glasses:** thin outlined ovals and bridge, without clearly visible temple arms; not clearly rimless.
- **Identity:** reads as the same sitter as neutral-1, with a slightly longer-looking face and the same hairline and clothing.
- **Artefacts:** ears are plausible, collar and tie clean. Skin texture looks natural. The brow is a little more intent than neutral, though the difference is slight.
- **Read:** archival toned-print appearance; label **RECONSTRUCTION**.

### `ashby_1917-P1-gpt-1-neutral.jpg` (reused from p01)

- **Identity:** this is the p01 image judged clean and the reference for the expression candidates. It establishes the same older fictional man with grey hair and a full grey moustache.
- **Artefacts:** ears and moustache read naturally. Collar and tie are clean; the waistcoat and watch chain are legible. No obvious skin retouching.
- **Read:** convincing archival studio portrait, and therefore needs a **RECONSTRUCTION** label; Ashby is fictional.

### `ashby_1917-P1-gpt-1-doubt.jpg`

- **Identity:** strongly matches the neutral reference: same face shape, grey hair, moustache and age impression.
- **Artefacts:** ears are plausible. Moustache hairs are very finely and somewhat uniformly detailed, but not visibly malformed. Collar, tie and chain are coherent. Skin is textured, without obvious airbrushing.
- **Expression:** gently concerned, looking down toward the desk; lips closed. The brows are less drawn than in candidate 2.
- **Read:** convincing toned archival photograph; label **RECONSTRUCTION**.

### `ashby_1917-P1-gpt-2-doubt.jpg`

- **Identity:** strongly matches the neutral reference in face, hair and moustache.
- **Artefacts:** ears look plausible. Moustache ends are slightly curly and unusually detailed. Collar and tie remain coherent; watch chain is visible. No obvious retouched-skin effect.
- **Expression:** more clearly sceptical and concerned, looking down with brows drawn; lips closed.
- **Read:** archival studio-photo appearance; label **RECONSTRUCTION**.

## Picks

- **Eddington neutral:** `eddington_1917-P1-gpt-1-neutral.jpg` — best available bridge-clipped, no-visible-arms glasses and the strongest combination of natural skin, clean collar and tie, and documented facial cues. The lens edge is still visible, so rimlessness is not fully resolved.
- **Eddington intent:** `eddington_1917-P1-gpt-2-intent.jpg` — same sitter and outfit as the neutral, with the slightly clearer intent expression while retaining a closed mouth and no smile. The expression change is subtle.
- **Ashby neutral:** `ashby_1917-P1-gpt-1-neutral.jpg` — reuse of the p01 image judged clean; establishes the identity reference without another generation.
- **Ashby doubt:** `ashby_1917-P1-gpt-2-doubt.jpg` — strongest sceptical/concerned expression while preserving the reference identity, clothing and framing.

## Generation record

Six new images succeeded on the first attempt across the three initial calls. The Eddington glasses retry produced two more images; both succeeded. No call failed or hung, and no further retries were used. Total: eight generated images plus the reused p01 Ashby neutral. The retry improved the pince-nez bridge/clip appearance but did not make the lenses unambiguously rimless. Expression identity remained consistent; the Eddington variants are particularly close to the neutral, while Ashby's two variants preserve the reference face and moustache.

## Follow-ups

- The Director should decide whether the selected Eddington glasses are acceptable despite the visible lens edge. The one allowed retry did not make rimlessness unambiguous.
- Keep the visible **RECONSTRUCTION** disclosure required by the P1 adoption decision; these portraits read strongly as archival photographs.
- All candidates are square busts. A vertical dialogue crop still needs to be decided in the game UI.
