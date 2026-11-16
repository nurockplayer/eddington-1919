Decision (edd-art, 2026-11-15 15:2x JST): keep the BIBLE §4 rule and the `structure` role; darken the swatch.

In `art/palette.toml`, `[swatch.eye_white]`: change `hex = "#D8CFC2"` to `hex = "#D1C8BC"` (same hue and saturation, V 0.85 → 0.82). Leave role, roughness and `art/pipeline/palette_to_gd.py` unchanged. Commit it on its own: `Darken eye_white to the BIBLE §4 value cap`.

It is used only as the sclera in `art/people/people.toml`; do not rebuild any people assets in this PR. The regenerated `scripts/palette.gd` gaining an `eye_white` entry is expected.

Then continue the brief from where you stopped: rerun the heavy job, G2 validation, renders, the Godot import, the three suites, commit generated files, push, open the draft PR. Mention the eye_white change in the PR body.
