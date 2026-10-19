# M2 departure night — engineering verification

Godot **4.7.2.stable.official.ed1daf0bf**, macOS / Apple M2 Pro, branch `m2/departure`,
based on Director content `85f0b4c` and merged M1 `96fd598`.
**No human playtest is claimed.** M2's 6–9 minute duration is a design target; automated
dialogue advancement does not measure normal reading time or emotional pacing.

## Built behavior

The prologue button follows M1 → its existing 1918 bridge → `scenes/departure.tscn` →
the departure montage → `main.tscn` PREP. The original 1919 button still starts directly.
The `Story.from_prologue` consumer path is retained. Both Director-owned content scripts
are unchanged by this implementation; `content_1917.montage()` already contains the bridge,
so no separate `bridge_1918()` content function is needed.

`departure_director.gd` stages the authored conversations, speaker framing and face fill,
quiet clock/street ambience, workbook gesture, brass-loupe HUD icon and montage tags.
`room_builder.gd` adds a 1919 variant with no curtain/rain, warm window light, three shipping
crates, the finished list, Kit's variable-star plates, and a dated workbook. The enclosed M1
corridor is reused for Ashby's farewell.

`departure_checklist.gd` uses the report paper palette. Kit's blue cursive and the player's
brown italic figures differ in ink and font. Each row stays locked until its plate readback
finishes; the read value remains visible. All five marks determine caught/false-alarm flags.
The correction preserves `18.63` with a strike and placeholder initials `Y.` or shows a
smudged `16.83` overwrite. The changed paper remains until the player clicks to put it away.
The brief reveal delay is presentation only; there is no timed decision or failure.

`Story` stores `bond_tone`, `slip_fix`, and `departure_done`, preserves them across the chapter
transition, and resets chapter state on a fresh game. The Príncipe loupe and once-only,
optional night workbook are cosmetic. Simulation, measurement, score and ending code are
unchanged.

## Reproduce

Run all commands in `/Users/tachikoma/Developer/eddington-1919-wt/m2-sol`:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/test_sim.gd
godot --headless --path . --script res://tests/test_autoplay_hold.gd
godot --headless --path . --script res://tests/test_prologue.gd
godot --headless --path . --script res://tests/test_report_review.gd
godot --headless --path . --script res://tests/test_overlay_hits.gd
godot --headless --path . --script res://tests/test_plaster_material.gd
godot --headless --path . --script res://tests/test_departure.gd
godot --path . --always-on-top -- --prologue-autoplay=honest --shots=/tmp/m2r1-honest
godot --path . --always-on-top -- --prologue-autoplay=tidy --shots=/tmp/m2r1-tidy
godot --path . --always-on-top -- --prologue-autoplay=accuse --shots=/tmp/m2r1-accuse
godot --path . --always-on-top -- --autoplay=careful --shots=/tmp/m2r1-careful --speed=2
godot --headless --path . --export-release "macOS" build/Eddington1919-macOS.zip
```

The prologue runner uses walking/aiming input, E, numbered dialogue keys and real button
clicks. It does not teleport, modify Story, emit UI signals or call gameplay interaction
handlers. Each M2 row, correction, conversation and chapter beat has a screenshot. Its JSON
receipt includes all three new Story fields and observed room draw calls. Run native bots
serially because they bring their own window forward before capturing rendered frames.

## Results

All listed headless commands, import and export exited **0**. Headless results:

| Check | Tail |
|---|---|
| import | `[ DONE ] loading_editor_layout` |
| simulation | `157 checks, 0 failures` |
| low-FPS real hold input | `3 autoplay hold checks, 0 failures` |
| M1 prologue | `267 checks, 0 failures` |
| report review | `test_report_review: 649 checks, 0 failures` |
| overlay hit targets | `test_overlay_hits: 56 checks, 0 failures` |
| plaster | `PASS: Cambridge plaster weathering is broad, soft, and low contrast` |
| M2 departure | `202 checks, 0 failures` |

The M2 checks cover all four slip outcomes, the final `slip_fix` decision (with the authored
reassurance afterwards preserved), both bond tones/farewells, authored choices as well as
spoken lines in the confession scan, montage tags, mark evaluation, row gating/readback,
both visible correction styles, reset/scene persistence, the real director sequence,
pause/log locks (including exposed checklist controls), the dated workbook, and Kit/Ashby ray targets.
They also hold pause beyond the gift display, montage fade and caption durations. Restoring only
the old always-running timing in a temporary negative control produces exactly three failures;
the production version passes. All M2 waits/tweens now freeze with the paused scene tree.

| Native prologue route | Marking | Bond / fix | Result | Captures | M1 / M2 observed draw-call maxima |
|---|---|---|---|---:|---:|
| honest | slip ✗ | close / 0 | PREP, 0 failures | 75 | 320 / 146 |
| tidy | all ✓ | warm / 1 | PREP, 0 failures | 74 | 319 / 147 |
| accuse | correct row ✗ and slip ✗ | warm / 0 | PREP, 0 failures | 76 | 319 / 147 |

All three exited **0**, retained M1's 17 matches and bias-card block, set `departure_done=true`,
consumed `from_prologue`, and needed **0 click retries**. These are maxima observed while
walking in the same native runs; they can include interface-transition frames. They show
no observed M2 draw-call increase, but are not a frame-time benchmark.
Accuse's repeated M1 mentor-review capture reuses its filename (76 captures, 75 unique files);
all M2 beat and row captures have distinct retained filenames.

```text
[PROLOGUE honest] PREP matched=17 bias_blocked=true screenshots=75 failures=[]
[PROLOGUE tidy] PREP matched=17 bias_blocked=true screenshots=74 failures=[]
[PROLOGUE accuse] PREP matched=17 bias_blocked=true screenshots=76 failures=[]
```

Native receipts: [honest](playtest/m2-departure/result_honest.json),
[tidy](playtest/m2-departure/result_tidy.json), [accuse](playtest/m2-departure/result_accuse.json).
Full per-beat screenshots remain in their `/tmp/m2r1-<route>` directories. The lead inspected
arrival/face framing, paper/readback/correction, the opened dated workbook, corridor farewell
and gift icon. A separate headless ray probe confirmed the Príncipe table center still selects
`measure`, while the loupe and workbook select their own targets.

The macOS ZIP is **60,832,046 bytes**, SHA-256
`2a3f90841d415df6331cfec583ac7eafa10f93d4d6e928c32cbc383ef5f18ffc`.
Its [package receipt](playtest/m2-departure/package-check.json) records the compiled departure
scene, remap and scripts in Godot's savepack output, tests excluded, and ZIP readback.
The export tail was:

```text
[  50% ] export | Code signing bundle
[  75% ] export | Making ZIP
[ DONE ] export
```

The final direct-1919 careful run exited **0**, reached ENDING with score **4**, evidence
`favors_e`, and **0 stuck events** (seed `52117`). Its real-input pause check held the
briefing dialogue, and “新的天空” returned to a visible title with a different seed (`16038`).
The [careful receipt](playtest/m2-departure/result_careful.json) and
[restart receipt](playtest/m2-departure/restart_careful.json) are retained; screenshots are in
`/tmp/m2r1-careful`.

```text
[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0
[BOT careful] restart run 2: seed 16038 (first run seed 52117) title_visible=true
[BOT careful] shot 11_after_restart
```

## Independent review

Oracle reviewed code and native captures through Ego-lite, then independently re-reviewed
the repaired raw source archive and overwrite fixture. Its final disposition was
**“No blocking findings.”** The final source digest is
`f9f90f35b70afda5544118ca764d89d5fd5b49ff2df51c0ed6201389d823603f`.
It verified all 29 raw source-file hashes and the aggregate digest against the
[source manifest](playtest/m2-departure/review-manifest.json).

The initial review found the pause-through-montage P2 and noted the exposed checklist
edge under history; both are repaired with regression coverage. The raw ZIP also cleared
an initial text-bundle normalization mismatch caused solely by two trailing blank lines.
The [independent response](playtest/m2-departure/oracle-review.md) preserves the reviewer’s
scope and limits: code/image inspection, no Godot execution, no human playtest, and no credit
for native reruns that were still in progress at review time. Producer command results and
receipts in this document are separate evidence. The reviewed source remained unchanged
through the final reruns.

## Limits

Kit, Ashby, the player, the gift's provenance, the room and all conversations remain fiction
or reconstruction. The loupe type/name and protagonist initials are placeholders. The dated
workbook is a text-only promise payoff; letters, reunion and a confession are outside M2.
System fonts use local fallbacks; macOS rendering is the inspected platform. Native bot
screenshots and automated checks do not establish that a human finds the scene moving or
that its normal reading time meets the target. Export validation is a build/package check,
not a human playthrough of the exported app.

The low-FPS hold suite emitted `WARNING: 2 ObjectDB instances were leaked at exit` after its
three passing checks; the M1 prologue suite emitted a similar warning for 4 instances after
267 passing checks. The M2 suite exited cleanly. Native logs contain macOS `IMKCFRunLoopWakeUpReliable` diagnostics.
Neither changed the exit status or blocked input/screenshots. There were no Godot
`SCRIPT ERROR` or `ERROR:` lines in the required validation logs.
