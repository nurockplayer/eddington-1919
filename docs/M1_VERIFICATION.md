# M1 Cambridge prologue — engineering verification

**Current status (round 3, `4831a61` + Director content `8b1f2de`).** The sections below "Results" are the
round-1 receipt (`847af08`), kept for history. Current numbers from Sol's round-3 run (all exit 0):

| Check | Result |
|---|---|
| `test_sim.gd` | 155 checks, 0 failures |
| `test_prologue.gd` | 267 checks, 0 failures |
| `test_report_review.gd` (all 320 report × state combinations produce a valid mentor review) | 649 checks, 0 failures |
| `test_overlay_hits.gd` (clue hit areas cover rendered arrows/labels) | 56 checks, 0 failures |
| `test_plaster_material.gd` | PASS |
| Prologue routes honest / tidy / accuse (real input, windowed) | all reach 1919 PREP, 17 matches, bias card blocked, 0 failures |
| careful autoplay after prologue changes | ending 雲層之後的希望, favors_e, score 4, stuck 0 |

Merged-`main` verification is recorded in Issue #1 and HANDOFF, not here. **No human has played the prologue.**

## Run and reproduce

```sh
godot --path .
# Choose the first button: 序章　劍橋，1917

godot --headless --path . --import
godot --headless --path . --script res://tests/test_sim.gd
godot --headless --path . --script res://tests/test_prologue.gd
godot --path . --always-on-top -- --prologue-autoplay=honest --shots=/tmp/m1-honest
godot --path . --always-on-top -- --prologue-autoplay=tidy --shots=/tmp/m1-tidy
godot --path . --always-on-top -- --prologue-autoplay=accuse --shots=/tmp/m1-accuse
godot --path . --always-on-top -- --autoplay=careful --shots=/tmp/m1-careful --speed=2
godot --headless --path . --export-release "macOS" build/Eddington1919-macOS.zip
```

In Cambridge: WASD/mouse, E to interact; overlay drag/flip/Q/E/rotation buttons; Tab opens the shared dialogue history; Esc pauses. The original 1919 button still starts the original game. The bridge consumes `Story.from_prologue` and enters PREP with its title hidden.

## Files and responsibilities

| Files | Implementation |
|---|---|
| `scenes/cambridge.tscn`, `scripts/cambridge/director.gd` | All nine narrative beats, clue/independent-check state, report review and optional revision, montage and bridge. |
| `scripts/cambridge/room_builder.gd` | Procedural room using WorldBuilder helpers/NPCs, no indoor hats, graded warm lamp/cold window lighting, rain streak MultiMesh, enclosed corridor. |
| `scripts/cambridge/overlay_math.gd`, `overlay_viewer.gd` | Real one-to-one geometric matching, mirrored tracing, dragging/rotation/snap, difference arrows, clue details, unresolved loupe and inactivity hint ladder. |
| `scripts/cambridge/report_sheet.gd`, `plan_board.gd` | Data-gated report choices, four plan slots, eight cards, character reactions and bias-card reconsideration. |
| `scripts/cambridge/cast.gd`, `content_1917.gd` | Replaceable role constants and all documented stub signatures/data shapes. Dialogue written by the Director (8b1f2de); names are placeholders. |
| `scripts/story.gd`, `project.godot` | Data-only Story autoload; original main scene retained. |
| `scripts/main.gd`, `ui.gd`, `content.gd` | First prologue button, original start button preserved, shared last-60-line Tab history, PREP bridge and two 1919 continuity hooks. |
| `tests/test_prologue.gd`, `prologue_bot.gd` | Headless contract/mechanics checks and real-input end-to-end driver. Existing tests/autoplay files remain unchanged. |
| `README.md`, `docs/HANDOFF.md`, `docs/PROVENANCE.md`, this file | Play instructions, content replacement handoff, verification and fiction boundaries. |

Godot-generated `.gd.uid` companions are included for all new scripts.

## Results

The 170 prologue checks cover matching (0 unflipped, partial after flipping, 17/18 aligned), angle/offset boundaries and unique matching; every report clue combination; missing residual and independent-check credit; Story survival across real scene replacements; all valid 3/4-card combinations and bias/unknown/duplicate rejection; UI control bounds, dialogue history/Tab, and the 90-second hint progression.

Each final input run visited all nine prologue beats and reached 1919 PREP. All had 17 matches, bias blocking verified, independent credit retained, zero failed checks, and zero real-click retries. Honest also reopened and resubmitted the report after mentor review. Screenshots wait for each beat before automated dialogue advances. The driver never teleports, changes Story, emits button signals or calls gameplay interaction handlers; it observes button signals to confirm actual input delivery. Its old receipt is removed before a new run to prevent stale-pass readback.

| Route | Cause / original / residual | Screenshots | Destination | Failures |
|---|---|---:|---|---:|
| honest | both / keep / unresolved | 28 | PREP | 0 |
| tidy | both / redraw / delete | 26 | PREP | 0 |
| accuse | accuse / keep / new_object | 26 | PREP | 0 |

The three room walks each observed a maximum of **105 draw calls**. This is a route observation, not a frame-time benchmark or broad performance claim.

The original careful run reached ENDING (`雲層之後的希望`, evidence `favors_e`, seed `83808`, score `4`) with drive wound, rate checked and **0 stuck events**. The bot also clicked “新的天空” and verified a changed seed and visible title after restart.

### Output tails

```text
Import
[  16% ] loading_editor_layout | Loading docks...
[ DONE ] loading_editor_layout

Existing simulation
155 checks, 0 failures

Prologue headless
170 checks, 0 failures

Honest
[PROLOGUE honest] PREP matched=17 bias_blocked=true screenshots=28 failures=[]

Tidy
[PROLOGUE tidy] PREP matched=17 bias_blocked=true screenshots=26 failures=[]

Accuse
[PROLOGUE accuse] PREP matched=17 bias_blocked=true screenshots=26 failures=[]

Existing careful
[BOT careful] shot 10_ending
[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0
[BOT careful] restart run 2: seed 98591 (first run seed 83808) title_visible=true
[BOT careful] shot 11_after_restart

macOS export
[  50% ] export | Code signing bundle
[  75% ] export | Making ZIP
[ DONE ] export
```

Final logs had no Godot `SCRIPT ERROR` or `ERROR` lines. A macOS IMK input-method diagnostic appeared in some windowed logs; it did not prevent final screenshots or input delivery.

### Receipts and selected frames

Full screenshots are in `/tmp/m1-honest`, `/tmp/m1-tidy`, `/tmp/m1-accuse`, `/tmp/m1-careful` on this machine. Durable copies of the final JSON receipts and four representative frames are committed here:

- [Honest receipt](playtest/m1-cambridge/result_honest.json), [tidy](playtest/m1-cambridge/result_tidy.json), [accuse](playtest/m1-cambridge/result_accuse.json).
- [Careful receipt](playtest/m1-cambridge/result_careful.json), [restart](playtest/m1-cambridge/restart_careful.json).
- [Aligned overlay and clue feedback](playtest/m1-cambridge/honest_05_aligned.png), [unresolved loupe](playtest/m1-cambridge/honest_06_loupe.png).
- [Settled daylight examination](playtest/m1-cambridge/honest_beat_exam.png), [fair plan](playtest/m1-cambridge/honest_10_fair_plan.png).

The macOS ZIP is `60768581` bytes, SHA-256 `0edc0c400695632bb7e4008d0c4d8b3ccce818c9f9778b2e3099705eb7878398`. `build/` is gitignored. [Package check](playtest/m1-cambridge/package-check.json) confirms the Cambridge scene remap and compiled scene/director/Story are present, and both new test scripts are absent. The exported app was built and inspected, not manually played.

## Review and remaining gates

Bounded Luna workers implemented room, overlay, and content/sheets/headless tests; the lead integrated and ran all listed commands. A fresh read-only GPT-6 Sol reviewer found and rechecked fixes for provenance, report wording, report revision automation, and evidence/window contrast, then issued PASS for the inspected code/visual paths. Oracle with Ego-lite was unavailable; no Oracle review is claimed.

Round-3 review: an independent gpt-6-astra review of `6318681` found 4 P1 and 3 P2 defects. All were addressed in `8b1f2de` (content) and `4831a61` (code), with regression tests named above. The delta re-review result is in the PR.

Remaining gates: a newcomer/human playtest ([PLAYTEST_NEWCOMER](PLAYTEST_NEWCOMER.md)). The 12–18 minute experience and the four player-understanding statements are acceptance targets, not measured results. Figures are primitive. No childhood keepsake or microimage was introduced, and the residual stays unresolved by design.
