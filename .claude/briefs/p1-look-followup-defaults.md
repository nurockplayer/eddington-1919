# p1-look follow-up: set the judged defaults (edd-art 2026-11-15 14:0x JST)

The art director judged the windowed look matrix (8 variants, /Volumes/KIOXIA/eddington-1919-cache/director/look-matrix/1114/stats.tsv and sheets/). Set these defaults on branch `art/p1-look` (worktree is already on it), push, no new PR (#318 stays draft).

1. `scripts/look.gd` `PRINCIPE` (lines ~79-102):
   - `"sdfgi": 0` (was 1). Reason: SDFGI crushes faces/hats to black in shaded areas (coelostat clip_black 21.9% → 0%, shelter 5.2% → 0%, eddington_talk luma p05 0.062 → 0.123).
   - `"saturation": 1.30` (was 1.18). Reason: Owner wants saturation toward concept Y; lower-half saturation is under target in every day frame.
   - Restore one short inline comment per key (what it controls, unit/range) — they were dropped in the first round. Keep `sdfgi_energy` (used if a later round turns SDFGI back on).
2. Tests that pin the old values:
   - `tests/test_look.gd:56-57`: saturation 1.30; GI check becomes `not game.env.sdfgi_enabled and game.env.volumetric_fog_enabled`, message "SDFGI off, fog on".
   - `tests/test_graphics_quality.gd:125` (and line 44 if it breaks): standard quality must restore what the scene's look set, not force SDFGI on. Check `game.env.sdfgi_enabled == game.env.get_meta("standard_sdfgi", false)` (or whatever node carries the meta per `scripts/main.gd:370`) plus volumetric fog on. Do not change `scripts/settings.gd` behaviour.
   - Grep `tests/` for any other `sdfgi_enabled` or `1.18` expectations on the Príncipe environment and update them the same way; Cambridge (`test_look.gd:85-86`) stays as is.
3. Commit message: `Set judged Príncipe look defaults: SDFGI off, saturation 1.30`.

Acceptance: `PRINCIPE.sdfgi == 0`, `PRINCIPE.saturation == 1.30`, standard quality in Príncipe leaves SDFGI off and volumetric fog on, low still disables both, Cambridge unchanged.

Test: orb-test --host -- sh -c 'export EDD_SETTINGS_PATH=$PWD/.godot/test-settings.cfg; godot --headless --path . --script res://tests/test_look.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd'
