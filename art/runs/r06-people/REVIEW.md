# r06 · people: Eddington and Cottingham (2026-10-20)

**Owner brief (2026-10-20):**
- Download and verify MPFB 2, but treat it as a candidate, not a requirement.
- Prioritise the quality of Eddington and Cottingham: historical appearance, clothing, animation.
- Fit Diorama + Plate Grade without a toy-like read.
- Confirm Blender compatibility, the official source and every asset licence, especially third-party clothes and hair.
- Compare before and after in real Godot gameplay frames.
- Keep gameplay, interaction and performance.

## Decisions
- **Tool: MPFB 2.0.18**, the MakeHuman add-on for Blender. It was checked first against the alternatives:
  - **Tripo:** no key. Even with one, image-to-3D people come out unrigged, with baked lighting and uncertain topology.
  - **Hand-modelling in `kit.py`:** this would reproduce the toy problem.
  - **MPFB:** from the official Blender Extensions platform (sha256-verified URL). Runs headless on **Blender 5.2.2**. Gives a parametric, **rigged** (`game_engine`), proportioned human. Its base mesh, rig and system assets are **CC0**, and each asset file says so in its header.
  - MPFB's code is GPL-3 and is used as a tool only. It never ships.
- **Isolation:** MPFB is installed into a separate `BLENDER_USER_RESOURCES` (`art/pipeline/setup_mpfb.sh`). The user's own Blender profile is untouched.
- **Licence gate:** `build_person.py` refuses any descriptor, and any `obj_file` geometry it references, whose header lacks the affirmative line "This asset was explicitly released as CC0". The first version only searched for the substring "CC0" (review fix).
  - **No CC-BY packs** and no community assets are used.
  - **No photographic skin textures** are used; all materials are flat palette colours ([LICENSES.md](../../people/LICENSES.md)).
- **Appearance from evidence** ([REFERENCE.md](../../people/REFERENCE.md)):
  - **Eddington:** slender, clean-shaven, dark hair brushed back, thin rimless glasses (c.1915 portrait).
  - **Cottingham:** full moustache and soft felt hat (Thrapston photo c.1910).
  - **Dress:** pale linen and drill with straw hats (Sobral 1919 group photo). **Eddington's v0.1 pith helmet becomes a straw hat**, because the Sobral photo shows none.
  - Everything else is labelled RECONSTRUCTION.
- **Clothing:**
  - Eddington wears CC0 `male_elegantsuit01` (jacket, shirt, tie) in linen, with a dark tie region cut from the same mesh.
  - Cottingham wears CC0 `male_casualsuit01` in shirtsleeves. It is split at the waist into a pale shirt and dark trousers, for the practical working look.
  - Hats, glasses and the moustache are procedural (`kit.py`), parented to the head bone.
- **Animation:**
  - A natural standing pose, with arms down from MPFB's A-pose.
  - A baked 4 s breathing `idle`, de-synchronised per character.
  - A **head look-at** toward the player within conversation distance (Godot `LookAtModifier3D`; influence 0 beyond 4.5 m, up to 0.85 at 2.5 m). Verified visually side-on: the head turns to the player with it on and stays in profile with it off.
  - Godot's `get_bone_global_pose()` does not show modifier output, so a numeric probe could not be used.
- **Tie region:** cut geometrically from the suit mesh (a front-centre strip). The edge is a little ragged up close. It is an approximation, not the garment's real tie.
- **Gameplay safety:**
  - The capsule colliders, interaction metadata and name tags stay on the NPC body exactly as before. Only the visual figure changes.
  - If a GLB is missing, the old primitive figure is used.
  - Characters are not weathered, because grime noise on faces reads as blotches.

## Iterations (in-game benchmark, seed 7)
| Try | Change | Finding |
|---|---|---|
| 1 | First build | Big step up. Cottingham's `casualsuit02` in one colour read as a onesie. His moustache was inside the face (wrong offset sign). Eddington's linen suit lost its jacket read. Look-at unverified. |
| 2 | Dark tie region; moustache offset fixed; Cottingham `short01` hair | The tie reads, and the moustache shows. Cottingham's light, voluminous grey hair under the hat read as a woman's bob. |
| 3 | `short02` hair in darker greying; leaner build | Reads as a moustached Edwardian working man. The muscle setting produced a slightly busty shirt. |
| 4 | Muscle 0.45; the moustache widened with drooping ends | The narrow dark moustache read as a "toothbrush" moustache, an unwanted association. It is now a full period moustache matching the source photo. |
| 5 (review fix) | Forearm aim now measured from the bone's posed frame | A fresh Codex review decoded frame 0 of the GLBs and found a **33° forearm error**: the rest-frame aim compounded the upper-arm rotation and pulled the hands inward. Arms now hang naturally at the sides. **Accepted.** |

## Gates
- **G2:** both PASS ([eddington](../../validation/eddington.g2.json), [cottingham](../../validation/cottingham.g2.json)).
  - About 14.2k and 15.0k triangles against a 16k character budget; 8 and 7 palette materials; no textures.
  - Posed dimensions 0.57 × 0.36 × 1.87 m and 0.53 × 0.37 × 1.83 m, with hats (after the forearm fix).
  - G2 found and drove three fixes: a stray importer bone-shape mesh (the validator now ignores bone shapes), an unapplied height scale (now baked in), and soles 1.7 cm below the ground (now lifted).
- **G3:** [g3-r06](../../validation/g3-r06/sheet.jpg). Scale against the 1.75 m reference; silhouettes read.
- **G4 visual:**
  - [before-after.jpg](before-after.jpg) shows `main` vs r06 at the new `eddington_talk` and `cottingham_talk` bookmarks, plus coelostat and arrival.
  - [briefing-before-after.jpg](briefing-before-after.jpg) is the real opening conversation from autoplay.
- **G4 performance** ([perf-r06](../../validation/perf-r06/SUMMARY.md); 5 interleaved repetitions of `main` and r06 on `0ff8c60`):
  - **Load:** the machine was not idle (load average 6–8 from other apps). `main` repetitions 1–2 were outliers, so the paired median delta per bookmark is the figure to use.
  - **Forced draw (uncapped render cost):**
    - **+0.3–0.4 ms** where the characters are on screen (arrival, shelter, coelostat, both talk views).
    - **±0.0 ms** where they are not (house, both totality views, darkroom).
  - **Draw calls:** +0–4.
  - **Wall-clock p95 (median of the 5 repetitions):** at most 9.94 ms in every view. A single repetition reached 10.31 ms (arrival).
  - **Final-head attempt discarded:** a 3-repetition run on the final head (`dafc94e`) happened under load average 25–27, from another project's `cargo` tests and other Godot processes. Its paired deltas swung between −2.3 and +6.3 ms, so no conclusion is drawn from it ([discarded-loaded](../../validation/perf-r06/discarded-loaded/README.md)).
  - The commits after `0ff8c60` change only the arm pose, build-time checks, setup, the load fallback and look-at caching (less per-frame CPU), so they add no render work.
  - The final Cottingham tweaks after `0ff8c60` (muscle setting, moustache shape) added under 200 triangles.
- **Gameplay:**
  - 155/155 logic tests.
  - Autoplay careful / rushed / cherry produce the same 3 endings, scores 4 / 0 / 3, stuck 0, on the final head (`art/validation/autoplay-r06/`).

## Known limits and next steps
- Faces are simple sculpted forms in flat skin colour. Up close they read as stylised but human, not uncanny. There is no facial animation and no lip-sync.
- Clothes come from modern CC0 garments restyled in period palette colours. Collar and lapel cut are not period-exact.
- **Next:** gestures for dialogue (a nod, a hand to the instrument), the night-scene posture, and the remaining environment items (vegetation, daytime clouds, darkroom performance).
