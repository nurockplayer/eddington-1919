# Human Generator character prototype (Cambridge 1917 Eddington)

Started 2026-10-27 09:14 JST, prototype captured 2026-10-27 10:00 JST (Opus 5.5 lead,
no workers). Goal set by the Owner on 2026-10-27: people near *Life is Strange: True
Colors* / *Tell Me Why*: natural faces, eyes, skin, hair and emotion, not AAA realism.
The Owner installed the Human Generator (HG) 4.0.29 free trial in Blender 5.2.

## Licence boundary (read first)

- HG assets may not be redistributed. The HG exporter itself stamps "Does not permit
  redistribution except embedded in software or in other formats that do not allow
  easy extraction". This repo is **public**, so no HG mesh, texture, GLB or `.blend` is
  committed, and no HG renders either (trial content, evaluation only).
- Prototype outputs (blend, GLB, bakes, renders, Godot and in-game captures) live at
  `/Volumes/KIOXIA/eddington-1919-cache/hg-prototype/`. They are one-off evaluation data:
  **delete after the Owner's purchase decision** unless the Owner approves keeping them.
- The game loads the GLB at runtime with `GLTFDocument`, so nothing enters `.godot/`.
- A shipped build is allowed to embed HG assets. Keeping them out of the public repo
  would need a private asset repo or store before HG goes to production.

## What was built

| Step | Script | Notes |
|---|---|---|
| Person | `art/pipeline/blender/hg_person.py` | HG Python API, headless. Caucasian 1 preset, age 35, unlocked livekeys (forehead, brow ridge, temples, eye depth/scale/distance, skinny, aged_male), Short Side Part hair, FACS face rig. Includes our own `eddington_face` shape key (narrower jaw, longer chin), because the trial locks the jaw, cheek, chin, nose and lip sliders. |
| Skin | same | A painted-skin material (`zones` vertex colours for redness, beard shadow, under-eye darkening and shine, plus pore noise and HG's unlocked aged-layer normal). Every trial skin map (albedo, normal, roughness) is watermarked "TRIAL" and unusable. |
| Suit | same | MPFB CC0 `male_elegantsuit01`, retargeted from the MakeHuman hm08 joints to the HG joints, then tightened, pushed out only where it is inside the body, heat-weighted to the HG rig, with the covered body masked. HG's own `outfit.add_obj` collapsed the suit onto the skin. |
| Export | `art/pipeline/blender/hg_export.py` | Base keys (Male, LIVE_KEY_*, eddington_face) are folded into the mesh: without this Godot shows the raw base head. Skin, eye and suit albedo are baked at 2K. Particle hair becomes ribbon strands with a hair-coloured scalp, because the trial has no `hair/haircards/*`. Exports FACS morphs and an `idle` pose. |
| Godot viewer | `tools/hg_preview/hg_preview.tscn` | Runtime load, Cambridge-like lamp/window/rim light, Look grade. Performs blinks, gaze saccades, breathing and four moods. |
| In game | `scripts/cambridge/figures.gd` hook | Only when `E1919_HG_EDDINGTON=<glb>` is set. Normal play is unchanged. |

Commands (heavy/GPU work goes through `orb-test`, Mon–Fri 03:00–15:00 JST for windowed runs):

```sh
O=/Volumes/KIOXIA/eddington-1919-cache/hg-prototype
orb-test --heavy --host -- /Applications/Blender.app/Contents/MacOS/Blender -b \
  --python art/pipeline/blender/hg_person.py -- $O --stills neutral intent warm doubt blink --wide
orb-test --heavy --host -- /Applications/Blender.app/Contents/MacOS/Blender -b $O/eddington_hg.blend \
  --python art/pipeline/blender/hg_export.py -- $O
# watch it live (no --shots = runs until closed; moods cycle every 4 s)
godot --path . --always-on-top res://tools/hg_preview/hg_preview.tscn -- --glb=$O/eddington_hg.glb
# in the real Cambridge scene
E1919_HG_EDDINGTON=$O/eddington_hg.glb godot --path . --always-on-top --fixed-fps 60 -- \
  --prologue-autoplay=honest --seed=7 --speed=2 --shots=$O/game
```

## Result (evidence on KIOXIA: `final_sheet.jpg`, `godot/`, `game/`, `hg_eddington_*.png`)

- **In game, at the existing dialogue camera:** HG Eddington reads as a believable adult
  in a period suit. The current MPFB figure reads as a toy (broken collar, cartoon face).
  This is the largest visible gain. The face is still only about 60 px tall at 1280×720.
- **Close-ups in Godot (Forward+):** the four moods read: neutral, intent, warm smile
  and doubt, driven by the 43 ARKit-style FACS blend shapes. Blink and gaze work at runtime.
- **Not yet LiS:TC quality:**
  - The skin reads plasticky, because it uses procedural albedo with no detail normal.
  - The hair strands have no alpha or anisotropic cards.
  - The suit is still too dark for the study.
  - There is no pince-nez (MPFB's `glasses()` was not ported).
  - The cheek takes a cool specular from the fill light.

## Should we buy the commercial Human Generator?

**Recommendation: yes, conditionally.** The price must be confirmed on the store; the
2026-10-27 oracle estimate was US$128 for Ultimate.

The trial already moved Eddington from a toy to a person. The remaining gaps are almost
exactly what the trial locks:

| Gap seen in the prototype | Locked in trial | Commercial |
|---|---|---|
| Plastic skin | Watermarked albedo, normal and roughness | Clean 4K skin sets, to be softened toward the LiS look |
| Strand hair, no alpha | No haircard assets; one hairstyle | Haircards with alpha and ~30 hairstyles, beards and moustaches (Ashby) |
| Likeness, face variety | Nose, jaw, cheek, chin, lip and ear sliders; one face preset | All face sliders and presets, so each cast member gets a distinct face |
| Expressions | Only Happy/Sad presets (the FACS rig *is* unlocked) | Presets + FACS |

Already verified in the trial:
- The headless Python API works on Blender 5.2.
- The FACS rig works and survives glTF into Godot with blink and gaze.
- The base mesh, eyes and teeth are good quality.
- The game camera shows the gain.

Conditions:
1. **Asset hosting:** HG source assets go in a private store (private repo or KIOXIA), and
   the public repo receives only scripts. The release build may embed them.
2. **Period costume stays custom:** HG outfits are modern. The MPFB suit retarget in
   `hg_person.py` works; HG's own `add_obj` did not.
3. **Close-up dialogue framing:** face quality only pays off if conversations cut to
   medium close-ups. Today's lens goes from 72° to 55°. This is tool-agnostic and should
   be done anyway.
4. **Style pass:** keep the painted, softened skin approach on top of HG's textures. LiS
   and Tell Me Why soften detail; they do not show pores.

Alternatives, unchanged from the 2026-10-27 comparison:
- MPFB stays as the fallback. Its ceiling is lower: there is no FACS set and the faces read toy-like.
- MetaHuman: export and rig conversion are fragile.
- CC5: Windows only.
- A freelance hero character costs about US$2k–10k each.

## Second opinion (oracle-ego, GPT-6, 2026-10-27 17:38 JST)

The Owner judged the prototype below expectations. ChatGPT reviewed seven screenshots plus the
export and material code. The full answer is in `oracle_art_critique.md` on KIOXIA.

Ranked by visual impact:
1. Face design: it reads as a modified preset, with a heavy, square jaw and no likeness. It
   needs a sculpt pass from period portraits.
2. Hair: an opaque black ribbon helmet with streaky anisotropy. It needs alpha haircards
   with a flow map.
3. Eyes: they look dead. The alpha-0 cornea gives no wet highlight, and the lid wrap is stiff.
4. Lighting: the warm key blows out the cheek. Look-dev should use a neutral studio first.
5. Skin: it has albedo only. It needs normal and roughness maps (T-zone, lips), and SSS
   should drop to about 0.12 with no rim.
6. In game, the face is about 60 px. The dialogue camera should frame it at 180–250 px.

New lead, unverified in the trial: HG's Early Access "Process" system is said to include a
Godot glb recipe, haircards with alpha, normal and flow maps, and a free Godot Companion
for hair, SSS and the rig, tested on Godot 4.7. The Companion targets editor import, not our
runtime `GLTFDocument` load.

Price check: US$128 for commercial use, US$68 for personal use (Superhive).

Verdict: HG commercial plus our own sculpt, look-dev and camera work. HG alone would only
give "a better-textured preset person". CC5, MetaHuman and AI 3D are not recommended.

## Not done

- Ashby (needs a moustache, which is locked).
- Pince-nez.
- Close-up camera in the game.
- Performance check: the GLB is 79 MB with full-resolution morphs and about 75k
  hair quads, so morph and LOD budgets are needed before shipping.
- Oracle review: this is an evaluation branch, not for merge before the Owner decides.

## Round r1: free fixes with the full HG (2026-10-27 18:00–19:20 JST)

The Owner chose to try the no-cost fixes before buying. The Owner also owns a **personal-licence** full HG
(Humble Bundle, content v4.1), approved for evaluation only. A commercial licence is still
needed before release. It is installed in an isolated Blender user dir on KIOXIA (`hg-full/`), and
`hg_person.py` now needs that install (`BLENDER_USER_RESOURCES`).

Done:
- **Look-dev light:** `hg_preview --light=studio` (neutral grey, no grade) is the default. `--light=study` uses a softer warm key.
- **Skin:** SSS is down to 0.12 and the rim light is gone. Roughness and a tangent normal map are now baked into the GLB (#33); lips and the T-zone are glossier.
- **Eyes:** the old cornea (alpha 0) also zeroed its specular. The cornea stays hidden, and the eyeball now has a soft clearcoat. The interim additive cornea glowed white and was dropped.
- **Face:** the formula shape key was replaced by unlocked HG livekeys (jaw, chin, nose, cheek, brow, eye depth), tuned over 4 rounds (#34).
  Measured from the base preset to the final face: eye→chin 115.5→117.1 mm, jaw width 135.6→132.1 mm, nose forward 47.6→54.2 mm.
- **Hair:** `Regular/Slicked Back Side Part`. `Aged/Thin Side Comb` is broken in our pipeline: strands smear across the face.

Result (KIOXIA `hg-prototype/r1/r1_sheet.jpg`, judged by the lead because the oracle was unavailable, since ChatGPT was logged out):
not yet a clear win over the first prototype.
- Better: the eyes, the neutral look-dev light, and the face shape moving the right way.
- Still wrong:
  - The likeness: the face still reads as a square-jawed modern man. Slider gains flattened out by round 4, so the next step is a hand sculpt.
  - The hair: dense, with a hot anisotropic highlight and stray strand tips on the forehead. The GLB grew to 112 MB, about 1M hair vertices.
  - The painted beard-shadow zone reads as pale blotches under strong light.
  - The export still aborts after the GLB is written (exit 134/250, "Attempt to free nullptr pointer").

Next options for the Owner:
1. Replace the painted skin with HG's own skin textures, now unwatermarked.
2. Cut the hair density, and lower its anisotropy and specular.
3. Get the likeness from a sculpt pass by hand, or by an artist.
4. Re-run the oracle comparison once ChatGPT is logged in again.
