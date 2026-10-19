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

## Validation

The final frozen-source import and logic runs pass: simulation 155 checks / 0 failures; prologue 178 checks / 0 failures. The final honest route reaches PREP with 17 matches, bias blocked, 41 captures and no failures. One input retry was needed and succeeded through the normal click path. The free-investigation draw-call sample was 114 maximum versus 122 in the unmodified baseline. This is not an FPS or performance-regression claim.

Implementation-engineer visual readback: opening/mentor/exam/trial/coda have visible full speaking figures in the staged route; room planes, shelves, hearth and corridor door are readable. The daylight establishing capture shows a grey window and unlit lamp. Both evidence layers remain distinct and bright, and selection marks/borders remain visible on the paper forms. The renewed 1280×720 run also reaches PREP with 41 valid captures and no failures; its report, board, and standing figures were inspected at native capture size. All four prologue receipts have exactly 17 matches and the bias gate blocked. The accuse receipt confirms report revision. Príncipe careful reaches ENDING, `favors_e`, score 4, stuck 0; the new-sky restart returns to a visible title with a different seed.

Full logs: `/tmp/m1p-import.log`, `/tmp/m1p-test-sim.log`, `/tmp/m1p-test-prologue.log`, `/tmp/m1p-honest.log`, `/tmp/m1p-accuse.log`, `/tmp/m1p-tidy.log`, `/tmp/m1p-careful.log`, `/tmp/m1p-720.log`.

Final command tails (ANSI removed):

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
178 checks, 0 failures

honest:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE honest] PREP matched=17 bias_blocked=true screenshots=41 failures=[]

accuse:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE accuse] PREP matched=17 bias_blocked=true screenshots=43 failures=[]

tidy:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE tidy] PREP matched=17 bias_blocked=true screenshots=41 failures=[]

careful:
[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0
[BOT careful] restart run 2: seed 93801 (first run seed 18643) title_visible=true
[BOT careful] shot 11_after_restart

720:
[PROLOGUE INPUT] click 　　量之前先寫下：什麼樣的底片不能用 [P: (120.0, 388.5), S: (674.0, 125.0)] attempt=1
[PROLOGUE INPUT] click 完成計畫 [P: (746.0, 794.5), S: (108.0, 47.0)] attempt=1
[PROLOGUE honest] PREP matched=17 bias_blocked=true screenshots=41 failures=[]
```

The final logs contain no Godot script errors or engine warnings. Native macOS launches print an IMK mach-port notice, also present in the baseline.

## Limits

These are automated native-input smoke runs with visual inspection by the implementation engineer, not human playtests. The people are deliberately simple reconstructed primitives, not documented portraits. Camera turns do not move the player; a player who walks unusually close to a speaker may frame only the upper body. Draw-call counts are observed per-frame samples, not a controlled performance benchmark; other native workloads were active on this machine. Screenshots and full logs under `/tmp` are temporary and are not exported assets.
