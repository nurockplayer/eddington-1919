# veg-cards follow-up 2: renderer readback decided (art director, 2026-11-15 19:0x JST)

Decision on your `DECISION:` line: **accept the headless limitation in the headless run; the readback assertion runs only on a real renderer.** No other machine. The art director runs this same test windowed in the Monday 2026-11-16 09:00 JST render window, where `get_instance_custom_data()` returns what was written.

Why the count was 32: the dummy renderer returns `Color(0,0,0,0)`, so every even `j` passed by accident and the odd ones failed (22 of 45 + 10 of 21).

## Change (only `tests/test_vegetation_cards.gd`)
Lines 133–134, the loop `for j in mm.instance_count: check(is_equal_approx(mm.get_instance_custom_data(j).r, float(j % 2)), "alternating texture variant")`:

```gdscript
		if DisplayServer.get_name() == "headless":
			readback_skipped += mm.instance_count
		else:
			for j in mm.instance_count:
				check(is_equal_approx(mm.get_instance_custom_data(j).r, float(j % 2)), "alternating texture variant")
```

`readback_skipped` is a script-level `var readback_skipped := 0`. Just before the final summary line print, when it is non-zero: `print("renderer readback skipped (headless dummy renderer): %d checks" % readback_skipped)`. The checks of `mm.use_custom_data`, the instance counts and `use_custom_variant` stay unconditional. The frond `pick` checks (line 61) stay as they are: instance shader parameters read back headless. Nothing in the test may depend on running headless, since it will also run windowed.

`scripts/world_builder.gd` does not change. Your normal tolerance (`0.0002`, commit `e8d9f59`) is accepted; it still needs its first full run.

## Also decided
- The now-unused cacao shrub and banana GLBs stay in this PR (they are the fallback if the cards fail the render). Do not delete them.
- PR #341 stays draft. Add to its body: the per-instance custom-data readback is asserted only on a real renderer (headless prints the skipped count); the art director runs it windowed before accepting.

Run the test line through `job-run --id veg-cards-full-3 -- …` and end with the `WAIT:` line. Limits as in the brief: 16 GB shared Mac, Godot only through `orb-test --host`, headless only, no windowed runs, no screenshots; every written time carries `JST`.

Test: orb-test --host -- bash -c 'godot --headless --path . --import >/dev/null 2>&1; godot --headless --path . --check-only --script res://tests/test_vegetation_cards.gd && godot --headless --path . --script res://tests/test_vegetation_cards.gd && godot --headless --path . --script res://tests/test_sun_crescents.gd && godot --headless --path . --script res://tests/test_fireflies.gd && godot --headless --path . --script res://tests/test_layout_bounds.gd && godot --headless --path . --script res://tests/test_graphics_quality.gd'

Acceptance cases: the vegetation test reports 0 failures headless and prints `renderer readback skipped (headless dummy renderer): 66 checks`; the other four suites pass unchanged; no file other than `tests/test_vegetation_cards.gd` changes. Final report: the five test output lines, the skipped line, the pushed commit.
