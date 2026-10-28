# c03 — Kit bake-off: procedural vs MPFB vs Human Generator (review)

Captured 2026-10-28 09:00–09:21 JST: windowed Godot, `--prologue-autoplay=honest --seed=77 --fixed-fps 60`, all three ENDING with `failures=[]`. Kit swapped at runtime with `E1919_KIT_GLB`. The sheet is not committed, because HG renders may not go into this public repo; it is on KIOXIA at `eddington-1919-cache/c03-shots/c03_sheet.jpg`, with the full captures in `c03-shots/{proc,mpfb,hg}`.

Same spec for both routes: Kit v3-1 (about 23, no stated gender, about 1.68 m, side-parted brown hair, round spectacles, pale linen coat). The MPFB build is `[person.kit]` in people.toml (913d0b3). The HG build is `hg_person.py --person=kit` (PR #38).

| | procedural (main) | MPFB | HG |
|---|---|---|---|
| Close-up read | toy: box head, cartoon face | the face is hidden behind the hair; what shows is low-detail | a person: face, eyes and spectacles read |
| Hair | painted cap | CC0 `bob02` falls across one eye; the CC0 library has about 10 hairstyles | strand hair, side part; reddish under the lamp |
| Defects seen | — | black artefact on the shirt front (formal zones on the suit) | brows too heavy and dark (stern look); trousers share the pale coat material (reads as a jumpsuit) |
| GLB | — | 0.6 MB, 13.1k tris | 84 MB (strand hair) |
| Licence | repo | CC0, can ship from this public repo | personal licence: evaluation only; release needs the commercial tier (US$128) + non-extractable packaging, and assets only in the private repo |

Bugs found and fixed on the way (HG side, PR #38): hair systems in female content were classified as brows (960 → 84 MB); strand colour was hardcoded; scalp tint used raw base-mesh coordinates and painted a beard onto the face.

## Lead verdict
HG has the clearly higher ceiling. Its remaining defects (brows, trouser material, hair hue, coat and pullover) are tuning work. MPFB's are limits of the CC0 asset library (hair, clothes) and of the low-poly face. Recommendation: **HG for the principals**, provided the Owner accepts the licence path (commercial tier + private assets + PCK encryption before release). MPFB stays as the fallback and for background people.

## If HG is chosen, next
1. Kit HG tuning: lighter and finer brows, separate trouser/pullover materials, hair hue toward the design's medium brown, wavier hair.
2. Eddington and Ashby onto the same HG route (`--person`), then the face rig (FACS is already in the GLB) for blink and gaze.
3. GLB budget: strand count per person (84 MB × 3 principals), checked in game.
