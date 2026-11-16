# Brief coda-trim: a trim proposal for the post-experiment dialogue (read-only)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/fun-audit` (detached, shared read-only with another read-only run). **Change no file**; the report is your final message.

## Why
The fun audit (issue #351, option 3 and section 3) found the longest stretches without a meaningful input after the experiment: judgment → island opening → workbook reread (≈16–17 entries; `scripts/judgment.gd` ~150–196, ~234–305; `scripts/main.gd` ~1710–1720, ~1118–1134; `scripts/content_coda.gd` ~14–26), loupe → first words to Kit (≈13–15; `main.gd` ~975–976, ~1135–1138; `content_coda.gd` ~32–110), and the October reunion → first Sobral interpretation (≈15; `scripts/cambridge/content_epilogue.gd` ~24–57, ~72–75; `scripts/cambridge/epilogue_chart.gd` ~137–170).

## Report
For each stretch: list every entry in order (file:line, speaker, first ~20 characters of the zh-TW text, the condition that shows it). Then a proposal: keep / cut / move-to-ending-history (`scripts/ending.gd`, `scripts/ui.gd` ~1614) / merge-with-line-N, with a one-line reason. Rules for the proposal: keep every line that is run-specific (reads the player's own choices, numbers or relationship state), keep one callback per thread, never cut a line another script or test reads by key (grep the keys in `tests/` and say which tests would need updating), and keep Kit's own half of the relationship beats. Target: no stretch above ~8 entries before the next real input. Give the resulting entry counts per route (clean route and the longest route). Mark estimates as estimates.

## Limits
No Godot, tests, builds or web research. Times in JST.

Test: none (read-only proposal)
