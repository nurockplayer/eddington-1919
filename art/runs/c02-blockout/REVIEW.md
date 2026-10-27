# c02 — material-only blockout round (review)

Captured 2026-10-27 23:40–23:46 JST: windowed Godot, `--prologue-autoplay=honest --seed=77 --fixed-fps 60`, base = main 3f8a756, c02 = this branch. 92 shots each, both runs passed. The Owner authorized running outside the 03:00–15:00 window. The full captures are one-off data on KIOXIA `eddington-1919-cache/c02/` and will be deleted after review.

`sheet.jpg`: target frame A (study_mid) on top; under it, six in-game shots, base on the left and c02 on the right.

## What changed
- Eddington → `wool_tweed` (#67594C), Ashby → `wool_slate`. Only the glTF material was swapped in the existing GLBs; mesh and rig are byte-identical to main.
- Kit (still the procedural figure) → pale linen dust coat over a grey pullover, taken from the Kit v3 design.

## Lead verdict
- The swap works and is cheap; the colours land where intended. Eddington's tweed is a subtle change from the old brown.
- Ashby's slate reads as a saturated, light blue under the warm lamp. It is the coldest thing in the room and pulls the eye. Next value: roughly −25% value, −40% saturation, towards grey-brown.
- Kit's pale coat blows out into a flat white block on the primitive body. In `honest_close_kit` the procedural head fills the frame at about 300 px, the most toy-like image in the game, against the "cinematic, not toy" tone the Owner set. Colour cannot fix this.
- Gap to target A is mostly not material: the camera is high and wide, faces are about 20 px, the room is empty and flatly lit, and the principals have no face rig (0 face bones, 0 shape keys) and no hair detail.

## Proposed next, in order
1. **Kit as a real person model**: this is the only character the game shows in close-up. It also serves as the HG vs MPFB bake-off subject (same spec, same shot, `honest_close_kit` + `speaker_opening_kit`).
2. Material tweak round (no rebuild): Ashby's slate darker and greyer, Kit's coat value down to about 0.55.
3. Face rig (blink/gaze) for the principals; needed even for shot A.
4. Shot A staging: lamp-lit two-shot camera and set dressing for the study, measured against `study_mid`.
