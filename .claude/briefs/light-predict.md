# Brief light-predict: predict the light before you see it (fun audit option 5 + feedback gap 3)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/light-predict`, branch `fun/light-predict` from origin/main. Godot 4.7.2, GDScript with tabs. First, in the fresh worktree: `orb-test --host -- godot --headless --path . --import` (else suites fail or hang).
Source: the fun audit of 2026-11-16 18:06 JST (issue #351 quotes it). Design intent: issue #37.

## Problem
The light-in-the-box sketch (`scripts/cambridge/box_sketch.gd`, light mode ~196–209, ~263–281, ~370–384, ~454–486) only illustrates an answer the interview already gave (`scripts/cambridge/content_1917.gd:eddington_box` ~446–469; departure use `scripts/cambridge/content_departure.gd` ~115–154). In light mode the prompt is blank, the launch button says "let go", and closing silently needs both frames played.

## Change
1. Before the first launch in light mode, ask for a prediction inside the sketch: three buttons where the beam lands on the far wall — 比出發點高 / 一樣高 / 比出發點低. Store the pick (e.g. `Story.light_guess`, add it to the save and checkpoint data the same way neighbouring Story fields are saved; check `scripts/checkpoint.gd`).
2. Light-mode prompt and button: the button reads "放出光" in light mode; the prompt names the frames still to play ("還要從艙外看一次" / "還要從艙內看一次") and, when both are done, "兩邊都看過了——可以關上". 
3. After both frames, one line comparing with the pick (right: "你猜對了：…"; wrong: "你猜的是…；艙內看，它落得比出發點低。"), using the existing physics wording in content_1917 so the science text stays identical.
4. Move the explanation in the earlier interview so the interview raises the question ("光在加速的艙裡會怎樣？先別回答。") and the sketch delivers the answer; the existing explanation lines move after the sketch. Keep every fact sentence verbatim; only order and the one question line change. If moving it breaks a recall elsewhere (grep the keys used in `tests/test_exam_recall.gd`), stop and report with a `DECISION:` line.

## Acceptance
- First light launch requires a prediction; the pick is saved and survives a checkpoint load.
- The prompt names the remaining frame; closing before both frames is impossible and explained.
- No physics sentence changes wording (diff shows moves only, plus the new lines).

## Rules
- Player-facing text: write the zh-TW source wrapped in `L.t("…")` (the msgid), then `python3 -I tools/i18n.py extract` and add en, ja and ko translations with `tools/i18n.py apply` (match the tone of neighbouring entries; keep placeholders and BBCode). `tools/i18n.py check --require-translated` must pass.
- Tests through `orb-test` only, only the suites in the `Test:` line while iterating. A behaviour test must drive the real flow (the same calls the player's input makes), not only a helper, and must fail when the fix is reverted: commit the fix first, revert the change temporarily, run, then restore with git (never `git checkout` over uncommitted work). Report the revert result.
- Host: 16 GB shared Mac. Times in reports carry JST. Open a ready PR against main naming "Refs #351"; do not merge.

Test: orb-test --host -- sh -c 'godot --headless --path . --script res://tests/test_box_sketch.gd && godot --headless --path . --script res://tests/test_prologue.gd && godot --headless --path . --script res://tests/test_departure.gd && godot --headless --path . --script res://tests/test_exam_recall.gd && godot --headless --path . --script res://tests/test_checkpoint.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && python3 -I tools/i18n.py check --require-translated'
