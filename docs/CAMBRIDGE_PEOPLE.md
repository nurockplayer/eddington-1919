# Cambridge people slice

Implementation started 2026-10-26 03:08 JST from `origin/main` at `7bef3cf`.
The unchanged baseline was captured before project edits, using the ordinary
prologue bot with seed 7 and `--speed=2`, at 1280 × 720.

Draft checkpoint: 2026-10-26 04:16 JST. Both G2 asset reports and all 65 new
portrait/runtime checks pass. The full suite batch, E2E routes and corrected
final captures are queued behind the shared heavy lock; the after-image links
below are planned delivery paths, not completed evidence yet.

## Diagnosis

The baseline does **not** reproduce missing body geometry. Both principals have
complete solid coats, sleeves and legs; front-facing and oblique captures show
those surfaces. The current torso already uses a Godot `CylinderMesh`, and the
remaining parts use Godot primitives. There is no observed culling/normal hole
in the retained frames. Ashby's coat is visible under the existing conversation
fill. Eddington's coat (sRGB components 0.19–0.21), the trousers (0.16–0.17), dark
panelling and floor lose value separation; the exposed heads and collars carry
nearly all the attention. The camera-facing 0.85-energy fill flattens the faces.
Rigid hanging arms and simplified oval heads amplify the prototype appearance.

The change addresses silhouette, posture, material separation, motivated light,
and a separate emotional portrait. It does not claim that more facial polygons
alone solve the problem.

## Staging and presentation

- Cambridge-only `ashby.glb` and `eddington_cambridge.glb` replace the two
  principals under the existing named `StaticBody3D` wrappers. Capsule collider,
  `room_collision_shape`, interaction ids, and visibility-driven collision stay.
- Ashby leans slightly toward the desk with both hands forward. Eddington stands
  at its left end with his head inclined toward the papers. The chair moves aside
  so it does not cut through Ashby's legs. Principals retain their table blocking
  when the speaker changes; Kit still turns to the player.
- Coat, waistcoat and leather have distinct broad roughness regions. Midtone
  slate/umber wool separates from dark wood without a noisy cloth or skin texture.
  Shadowed desk light and existing cool window fill shape the figures; dialogue
  bounce is a restrained side spotlight. SSAO and grounded soles retain contact.
- Runtime pose check: the imported GLB initially displayed its bind/rest pose.
  The figure builder now evaluates the authored `idle` frame zero once and
  pauses it. Hand-position tests guard against silently returning to the rest
  pose; Blender's posed G2 bounds alone do not verify Godot presentation.
- The dialogue lens tweens 72° → 55° → 72°. Floating name tags hide throughout
  dialogue and restore afterwards. No extra animation is enabled: stillness keeps
  the hands in place and avoids an unreviewed head-look loop.
- Mounted prints occupy a dedicated left column beside the dialogue panel, away
  from its text/choice buttons and the central evidence. They opt in only in the
  Cambridge director; shared 1919/departure UI does not display or preload them.
  Every displayed print carries `重建肖像，非歷史照片` in the existing muted colour.
- Images are unchanged 1254 × 1254 JPEG copies of the four approved p02 picks.
  An entry's optional `mood` selects an existing variant, otherwise neutral. Only
  synthetic tests use mood keys. No authored dialogue was edited.
- Grade audit: `Look.apply_grade()` modifies a 3D `WorldEnvironment`. Portraits
  are ordinary `TextureRect` controls on UI `CanvasLayer` 10, with default white
  modulation and no grading shader. Their existing tone is not graded again.

## Matched screenshot bookmarks

Final delivery retains exactly six JPEGs (quality 85, 1280 × 720). Both passes use the same
bot route, seed and bookmarks. The room-wide comparison uses the EXAM Ashby
speaker bookmark, where both principals are visible; the bot's separate
`interlude_room` bookmark looks at the evidence and does not show the people.

| Moment | Before | After |
|---|---|---|
| Both principals at the worktable (`speaker_exam_mentor`) | [before-room.jpg](screens/cambridge-people/before-room.jpg) | [after-room.jpg](screens/cambridge-people/after-room.jpg) |
| Ashby dialogue (`speaker_mentor_mentor`) | [before-ashby.jpg](screens/cambridge-people/before-ashby.jpg) | [after-ashby.jpg](screens/cambridge-people/after-ashby.jpg) |
| Eddington dialogue (`speaker_exam_eddington`) | [before-eddington.jpg](screens/cambridge-people/before-eddington.jpg) | [after-eddington.jpg](screens/cambridge-people/after-eddington.jpg) |

## Provenance and boundaries

Build specs and historical/reconstruction distinctions are in
[people.toml](../art/people/people.toml),
[REFERENCE.md](../art/people/REFERENCE.md) and
[LICENSES.md](../art/people/LICENSES.md). Both exports use the existing pinned
MPFB 2.0.18 bundled inputs and affirmative-header CC0 MakeHuman system assets.
No new third-party pack, generated image, paid API or photographic skin is used.
Ashby is fictional. Eddington's Cambridge costume/pose/height are reconstruction.

Príncipe character exports, Príncipe scenes, departure figure construction,
authored dialogue, eclipse simulation and judgment rules are outside this slice.
Oracle review is reserved for edd-director, as required by the brief. The Owner
must judge the actual screenshots before visual acceptance is claimed.
