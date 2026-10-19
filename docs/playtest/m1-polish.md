# Cambridge M1 presentation polish — 2026-10-20

Base: Director script commit `6318681`, worktree `m1-sol`, branch `m1/cambridge-prologue`. Local delivery only. `scripts/cambridge/content_1917.gd` is unchanged.

## Changes

- Readable plaster and wainscot room planes, corridor door, warmer lamp/fire bounce, restrained fire flicker, cool window floor bounce, softer contact occlusion and a Cambridge-only contrast adjustment. Daylight turns the lamp off, brightens grey window fill, and briefly establishes the room before the exam.
- Cambridge-only primitive people: tapered coats and lapels, necks, cuffs/hands, hair, trousers/shoes; Ashby has a grey-haired stooped silhouette and waistcoat; Eddington has round spectacles. Clothing and hair are RECONSTRUCTION. Príncipe still uses its existing figure builder.
- Dialogue entry notifications drive a 0.4-second eased turn to visible NPCs, with a soft speaker fill. Ending dialogue cancels the turn before free input resumes. Standing positions and the lower dialogue panel preserve full figures in the captured routes.
- Report and plan are warm paper with dark ink; selected choices have a check mark and stronger border. Numbered plan slots repeat the chosen text. The plate has a cool glass edge and fine deterministic grain; tracing is warm translucent paper with ink stars.
- Rain streak distribution repaired (the old modulo expression put all streaks on one line). Bot evidence waits for transitions/turns, captures speakers and daylight, and maps real synthetic input through the window stretch transform at 720p.

## Native before/after evidence

The baseline is an actual honest run from unmodified `6318681`, not a reference painting. The after run uses the production game and normal input path. All files below are local temporary captures.

| Beat | Before | After |
|---|---|---|
| Opening | `/tmp/m1p-before-honest/honest_01_opening.png` | `/tmp/m1p-honest/honest_beat_opening.png` |
| Investigate | `/tmp/m1p-before-honest/honest_beat_investigate.png` | `/tmp/m1p-honest/honest_investigate_room.png` |
| Mentor | `/tmp/m1p-before-honest/honest_dialogue_mentor_review.png` | `/tmp/m1p-honest/honest_beat_mentor.png` |
| Interlude / exam | `/tmp/m1p-before-honest/honest_dialogue_exam.png` | `/tmp/m1p-honest/honest_beat_exam.png` |
| Plan | `/tmp/m1p-before-honest/honest_10_fair_plan.png` | `/tmp/m1p-honest/honest_10_fair_plan.png` |
| Trial | `/tmp/m1p-before-honest/honest_beat_trial.png` | `/tmp/m1p-honest/honest_beat_trial.png` |
| Coda | `/tmp/m1p-before-honest/honest_dialogue_coda.png` | `/tmp/m1p-honest/honest_beat_coda.png` |

Additional evidence: `honest_interlude_room.png` (grey window, lamp off), `honest_investigate_door.png`, `honest_08_report.png`, `honest_05_aligned.png`, and `honest_speaker_<beat>_<actor>.png` in the after directory. The 1280×720 run is under `/tmp/m1p-720/`, including the report and plan.

## Follow-up defects reproduced and repaired

A standing-height physics audit found the left north-wall pier ended at x=-2.5 while the sill began at -1.45, leaving a player-width gap. Three boundary regressions fail before the repair and pass after extending the pier and its plaster facing. A layout regression also proves the authored three-choice trial extended below the viewport; the dialogue panel now grows upward from its bottom edge. Speaker focus rises at close range so a nearby conversation keeps the face visible. Native input captures now include choice layouts and a close Kit conversation.

The first Oracle/Ego-lite review returned "No blocking findings" on `e34f7b6`, but explicitly could not independently verify containment or every dynamic choice layout. These follow-up checks supplement those limits; the repaired candidate receives a separate exact-commit review. Receipts: `/tmp/m1p-oracle-e34-review.txt` and `/tmp/m1p-oracle-final-review.txt` (the latter is written after the repair commit).

## Validation

Godot 4.7.2 stable (`ed1daf0bf`), Metal Forward+ on Apple M2 Pro. Final frozen-source import succeeds; simulation 155 checks / 0 failures; prologue 182 checks / 0 failures. The four added checks cover three north-wall rays and the authored three-choice dialogue bounds, with RED and GREEN logs retained under `/tmp`.

| Native run | Result | Valid PNGs |
|---|---|---|
| honest | PREP, 17 matches, bias blocked, no failures; includes close Kit and choice captures | 49 |
| accuse | PREP, 17 matches, report revised, bias blocked, no failures | 50 |
| tidy | PREP, 17 matches, bias blocked, no failures | 48 |
| honest at 1280×720 | PREP, 17 matches, bias blocked, no failures | 49 |
| careful at speed 2 | ENDING, favors_e, score 4, stuck 0; new-sky restart shows the title with a different seed | ending and restart captured |

All 196 prologue capture files decode at the expected native resolution. The after captures were inspected beat by beat, including the grey window with lamp off, paper forms at both resolutions, choice buttons, and close conversation. Observed free-investigation draw-call maxima are 114–124; the original baseline sample was 122. The new route adds a close conversation and different camera views, so this is a budget observation, not a controlled performance comparison or FPS claim.

Full logs are `/tmp/m1p-{import,test-sim,test-prologue,honest,accuse,tidy,careful,720}.log`. Exact command tails (ANSI removed):

```text
import:
[   0% ] loading_editor_layout | Loading editor layout...
[  16% ] loading_editor_layout | Loading docks...
[ DONE ] loading_editor_layout

test-sim:
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
155 checks, 0 failures

test-prologue:
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org
182 checks, 0 failures

honest:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE honest] PREP matched=17 bias_blocked=true screenshots=49 failures=[]

accuse:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE accuse] PREP matched=17 bias_blocked=true screenshots=50 failures=[]

tidy:
[PROLOGUE tidy] PREP matched=17 bias_blocked=true screenshots=48 failures=[]
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

careful:
[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0
[BOT careful] restart run 2: seed 76766 (first run seed 88446) title_visible=true
[BOT careful] shot 11_after_restart
WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)

720:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE honest] PREP matched=17 bias_blocked=true screenshots=49 failures=[]
```

No final run logged a Godot script error. Some exit paths logged `2 ObjectDB instances were leaked at exit`; the unmodified baseline also emitted that warning. This is not diagnosed here as a runtime leak. Native macOS launches also print the baseline IMK mach-port notice.

## Limits

These are automated native-input smoke runs with visual inspection by the implementation engineer, not human playtests. The people are deliberately simple reconstructed primitives, not documented portraits. Camera turns do not move the player; a player who walks unusually close to a speaker may frame only the upper body. Draw-call counts are observed per-frame samples, not a controlled performance benchmark; other native workloads were active on this machine. Screenshots and full logs under `/tmp` are temporary and are not exported assets.
