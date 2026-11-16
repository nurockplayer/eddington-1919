# Brief coda-merge: fewer advances after the experiment (fun audit option 3)

Lead: edd-lead. Worktree: `/Users/tachikoma/Developer/eddington-1919-wt/coda-merge`, branch `fun/coda-merge` from origin/main. Godot 4.7.2, GDScript with tabs. First, in the fresh worktree: `orb-test --host -- godot --headless --path . --import`.

## Design (decided)
Read `/Users/tachikoma/Developer/eddington-1919/.claude/briefs/coda-trim-report.md` first. **Implement its proposal for all three stretches** (judgment → island → workbook reread; loupe → first words to Kit; October reunion → first Sobral question), with these lead decisions (2026-11-16 18:2x JST, issue #351):
- **Merge at presentation only.** Join entries that are already translated (`L.t(...)` results) into one dialogue entry at the point they are queued (e.g. with "\n" or "\n\n"; narration in parentheses stays its own paragraph). Do not concatenate msgids or create new combined msgids, so the en/ja/ko catalogues need no new translations. Keep `grade.lines` raw for other consumers (`test_sim.gd` membership checks); group only the live sequence.
- **Cuts:** C:17 (rain/insect narration), C:81 (blank-pages transition), P:75 (Ashby "copy them onto your chart"). Remove their msgids from the catalogues via `tools/i18n.py extract`.
- **J:159** (measurement-context line on `confirmed`): merge it into the verdict entry instead of moving it to the ending history (no new ending UI).
- Keep every key named in the report's "Do not remove or rename" list, and the separate promise entry immediately before `kit_first`.
- **Readability guard:** no merged entry may overflow the dialogue box at the largest text-size setting in any of zh-TW, en, ja, ko. Use the existing layout/text-size tests (`tests/test_layout_bounds.gd`, `tests/test_text_size.gd`); if a merged entry overflows, split it at the nearest paragraph boundary and report which one. Speaker changes start a new entry (never merge two speakers into one box), except the parenthetical staging merges the report explicitly lists.
- Update the three structural tests the report lists (`test_night_story.gd:58`, `test_prediction_ledger.gd:276–277`, `test_epilogue.gd:71`) to the new structure while keeping their exact text checks.

## Acceptance
1. Static counts from the report hold: judgment stretch ≤ 8 entries on the longest route, loupe → Kit ≤ 8 including the choice prompt, reunion → Sobral question ≤ 8 including the question. Add one test per stretch that drives the real flow on its longest route and asserts the entry count (the report's routes) and that every run-specific line it lists as Keep still appears.
2. Revert check for those three tests.
3. All suites in the `Test:` line pass; every e2e route reaches its phases (GitHub CI all-suites; not run locally).

## Rules
- Tests through orb-test only; while iterating, only the suites you touch. Revert check: commit first, revert temporarily, run, restore with git.
- Host: 16 GB shared Mac. Times in JST. Ready PR against main naming "Refs #351"; do not merge. A conflict with the decisions above that changes behaviour → stop with a `DECISION:` line.

Test: orb-test --host -- sh -c 'for t in test_night_story test_prediction_ledger test_epilogue test_coda test_sim test_kit_recall test_ending_snapshot test_layout_bounds test_text_size test_i18n; do godot --headless --path . --script res://tests/$t.gd || exit 1; done; python3 -I tools/i18n.py check --require-translated'
