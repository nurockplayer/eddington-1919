# M3 — Príncipe coda and totality legibility

**Director addendum:**
- gpt-6-astra independent review of `a14b89a`: REQUEST CHANGES, with one P2. A workbook written at night still had to be reopened before the loupe would unlock.
- Fixed in the following commit, with a regression in `test_coda` (60/0) that fails on the old code.
- astra also traced the careful run's 9 holders (instead of 12) to bot input-timing variance, not a sim change. Two repeat runs collected 12, with the same exposure count, selection, score and ending (recorded timings differ slightly).

Godot **4.7.2.stable.official.ed1daf0bf**, macOS / Apple M2 Pro, branch `m3/coda`,
starting at `8a1cc48` (Director content/spec on merged M1+M2 main `7733d6d`).
Implementation commit: `9b6952dbf5b843152b911e1696bbbfc23557345c`.
**No human playtest is claimed.** Native runs below use generated mouse/key input and
rendered viewport captures. Reading time, emotional pacing and historical acceptance
remain for the Director and human players.

## Behavior

A main-scene entry with `Story.from_prologue` caches that origin before consuming the
one-shot flag. After the existing telegram judgment/reaction, it enters CODA instead of
showing the ending. Eddington and Cottingham leave the room, including their collision
bodies. The lamp stays lit. If the workbook is unwritten, the player must aim at and use
the highlighted workbook (`principe_workbook(bond_tone)`). A page already written at night
rereads automatically (`workbook_again()`, fix `fc2b6d2`). Then the player uses the brass loupe.
The loupe uses the cached `_grade.fit` and `_grade.clean` from the ending's single
`Judgment.grade` call, plus whether the final included plates yield a measured value.
Ashby's answer leads to Kit's tone-dependent close, lamp/safelight out, a pause and fade,
then the ending. Camera turns ease over 0.6 seconds. Objectives identify the next prop.
Coda input excludes the viewer and old NPC interactions. Esc stops camera/fade timing;
Tab holds the camera/lamp/fade while the log is open. Closing overlays restores input.

Direct 1919 entry skips CODA. Simulation, judgment, existing test_sim and all
Director-owned dialogue files are byte unchanged. Ending titles, telegrams, reasons,
responses and evidence retain their original values. The shared ending presentation now
puts response before the three evidence bullets and moves the unchanged history and
fiction note behind 「歷史上發生了什麼」. Existing replay/new-sky/quit buttons remain.
At 1600×900, a generated response with all selection-warning types was also
checked: collapsed content height **648 px**, available scroll viewport **740 px**.
Only the expanded historical record may need scrolling.

The sky shader uses jittered Gaussian points instead of bright square cells. A single
local cloud-density visibility factor and common compositing path attenuate background
stars, field stars and corona. The factor keeps about 87% visibility at density 0.45
before cloud compositing and reaches zero at density 0.80. Totality base/cloud colors
are modestly darker. No exposure, cloud-simulation, selection or scoring data changed.

## Reproduce

Run from `/Users/tachikoma/Developer/eddington-1919-wt/m2-sol` (no `timeout` command):

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/test_sim.gd
godot --headless --path . --script res://tests/test_autoplay_hold.gd
godot --headless --path . --script res://tests/test_prologue.gd
godot --headless --path . --script res://tests/test_report_review.gd
godot --headless --path . --script res://tests/test_overlay_hits.gd
godot --headless --path . --script res://tests/test_plaster_material.gd
godot --headless --path . --script res://tests/test_departure.gd
godot --headless --path . --script res://tests/test_coda.gd
godot --path . --always-on-top --script res://tests/test_bridge_pause.gd
godot --path . --always-on-top -- --prologue-autoplay=honest --seed=1919 --shots=/tmp/m3r1-honest
godot --path . --always-on-top -- --prologue-autoplay=tidy --shots=/tmp/m3r1-tidy
godot --path . --always-on-top -- --prologue-autoplay=accuse --shots=/tmp/m3r1-accuse
godot --path . --always-on-top -- --autoplay=careful --seed=1919 --shots=/tmp/m3r1-careful --speed=2
godot --path . --always-on-top -- --autoplay=rushed --seed=515 --shots=/tmp/m3r1-rushed --speed=2
godot --path . --always-on-top -- --autoplay=cherry --seed=4242 --shots=/tmp/m3r1-cherry --speed=2
godot --headless --path . --export-release macOS build/Eddington1919-macOS.zip
```

Native runs are serial because each real game window takes foreground ownership for
captures. Honest continues through 1919 using a passive helper from the careful bot:
mouse-motion aiming, W movement, E/Space, dialogue keys and real UI button clicks,
with no teleport or gameplay-handler fallback in that mode. It waits for each arrival
transition to finish before interacting. Tidy and accuse retain their existing PREP
stop contract; their coda endings are covered by headless branch tests rather than
claimed as native end-to-end runs. Honest and standalone careful pin seed 1919 to make
the before/after sky comparable. Standalone careful/rushed/cherry retain their prior
bot movement/restart behavior, including any existing fallback; receipts report stuck
counts separately.

## Check tails

Final results and native receipts follow. Logs and full
screenshots live under `/tmp/m3-logs` and the named shot directories on this Mac.

All eight headless suites exited **0**, with no script errors.

| Check | Exit | Tail |
|---|---:|---|
| import | 0 | `[ DONE ] loading_editor_layout` |
| test_sim | 0 | `157 checks, 0 failures` |
| test_autoplay_hold | 0 | `3 autoplay hold checks, 0 failures` |
| test_prologue | 0 | `267 checks, 0 failures` |
| test_report_review | 0 | `test_report_review: 649 checks, 0 failures` |
| test_overlay_hits | 0 | `test_overlay_hits: 56 checks, 0 failures` |
| test_plaster_material | 0 | `PASS: Cambridge room/corridor plaster is broad, soft, and low contrast; M1/M2 glass is smooth; departure lamp has a soft halo` |
| test_departure | 0 | `202 checks, 0 failures` |
| test_coda | 0 | `59 checks, 0 failures` |
| windowed bridge pause | 0 | `6 bridge pause checks, 0 failures` |
| macOS export | 0 | `[ DONE ] export` |

The coda suite holds a lit lamp and screen fade beyond the entire transition duration
under both Tab log and Esc, verifies the scene remains in CODA while held, and verifies
the ending and extinguished lamps after resuming. It also tests all 12
fit/clean/measured combinations, both Kit tones, new/repeated workbook behavior,
interaction order, cached origin consumption, and direct-entry continuity reset.

All six native route commands exited **0**.

| Route | Exit | Tail |
|---|---:|---|
| honest | 0 | `[PROLOGUE honest] ENDING matched=17 bias_blocked=true screenshots=86 failures=[]` |
| tidy | 0 | `[PROLOGUE tidy] PREP matched=17 bias_blocked=true screenshots=74 failures=[]` |
| accuse | 0 | `[PROLOGUE accuse] PREP matched=17 bias_blocked=true screenshots=76 failures=[]` |
| careful | 0 | `[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0` |
| rushed | 0 | `[BOT rushed] DONE ending=過早的宣告 evidence=ambiguous score=0 stuck=0` |
| cherry | 0 | `[BOT cherry] DONE ending=不完整的判斷 evidence=favors_e score=3 stuck=0` |

Honest receipt: score **4**; `workbook`, `loupe`, `kit_close`, `lamp_out` and
`complete` are all true. Its final real interaction IDs are `departure_workbook` then
`mentor_loupe`. Careful also exercised 「新的天空」: the restarted title is visible
and its seed differs. All standalone receipts report zero stuck events.

A durable copy of the machine receipts is in
[results.json](playtest/m3-coda/results.json).


## Visual comparison

The before captures were freshly rendered from archived starting HEAD `8a1cc48`,
not inferred from earlier milestone documentation. Before and after careful use seed
1919 and speed 2; rushed uses seed 515 and speed 2. Screenshot times can differ by a
few rendered frames because these are real-time input runs. The careful baseline
carried eight extra holders (12 available); the final run carried five (9 available).
Both made four exposures, selected plates 1/2/4 and reached the same score-4 ending.
Unused holder counts reflect input timing rather than changed simulation code.

| Frame | Before | After |
|---|---|---|
| careful 05_totality_start | [before](/tmp/m3-before-careful/careful_05_totality_start.png) | [after](/tmp/m3r1-careful/careful_05_totality_start.png) |
| careful 06_totality_mid | [before](/tmp/m3-before-careful/careful_06_totality_mid.png) | [after](/tmp/m3r1-careful/careful_06_totality_mid.png) |
| careful 06b_totality_gap_open | [before](/tmp/m3-before-careful/careful_06b_totality_gap_open.png) | [after](/tmp/m3r1-careful/careful_06b_totality_gap_open.png) |
| rushed 05_totality_start | [before](/tmp/m3-before-rushed/rushed_05_totality_start.png) | [after](/tmp/m3r1-rushed/rushed_05_totality_start.png) |
| rushed 06_totality_mid | [before](/tmp/m3-before-rushed/rushed_06_totality_mid.png) | [after](/tmp/m3r1-rushed/rushed_06_totality_mid.png) |
| Ending first view | [before](/tmp/m3-before-careful/careful_10_ending.png) | [after](/tmp/m3r1-careful/careful_10_ending.png) |
| Expanded history | [before](/tmp/m3-before-careful/careful_10_ending.png) | [after](/tmp/m3r1-careful/careful_10b_ending_history.png) |

Careful 05/06 now hide field stars at the clouded Sun; clear areas retain small soft
points. In 06b the corona ring and field stars are immediately visible together,
without the old bright square background cells. Rushed 05/06 likewise attenuate
stars according to local cloud. There is no rushed 06b capture: its fixed exposures
use every plate before a gap-triggered opening occurs.

The baseline has no coda-stage screenshot because it went directly from reaction to
ending. [Baseline darkroom context](/tmp/m3-before-careful/careful_07_darkroom.png) and
[baseline ending](/tmp/m3-before-careful/careful_10_ending.png) show that earlier route;
they are direct-entry context, not claimed as a matched prologue coda state. The actual
new prologue coda captures are:

- Opening: [honest_coda_opening_dialogue.png](/tmp/m3r1-honest/honest_coda_opening_dialogue.png)
- Workbook required action: [honest_coda_workbook.png](/tmp/m3r1-honest/honest_coda_workbook.png)
- Workbook dialogue: [honest_coda_workbook_dialogue.png](/tmp/m3r1-honest/honest_coda_workbook_dialogue.png)
- Loupe required action: [honest_coda_loupe.png](/tmp/m3r1-honest/honest_coda_loupe.png)
- Ashby sequence: [honest_coda_ashby_response.png](/tmp/m3r1-honest/honest_coda_ashby_response.png)
- Kit close: [honest_coda_kit_close.png](/tmp/m3r1-honest/honest_coda_kit_close.png)
- Lamp out: [honest_coda_lamp_out.png](/tmp/m3r1-honest/honest_coda_lamp_out.png)
- Coda ending: [honest_ending.png](/tmp/m3r1-honest/honest_ending.png)
- Coda expanded history: [honest_ending_history.png](/tmp/m3r1-honest/honest_ending_history.png)


## Review and limits

Oracle via Ego-lite / ChatGPT UI Pro returned **“No blocking findings.”** for
implementation commit `9b6952dbf5b843152b911e1696bbbfc23557345c` and raw-source digest
`b7b2bb734e8a7be769336b7f27f22454f6ffe497880cd5bc6a88b4b390acf6f7`.
It independently verified all 47 source hashes, all 50 evidence entries, the 23 original
PNGs, all requested before/after pairs, coda/ending visuals and the supplied execution
receipts. It did **not** rerun Godot. The completed
[review response](playtest/m3-coda/oracle-review.md),
[source manifest](playtest/m3-coda/source-manifest.json) and
[evidence manifest](playtest/m3-coda/evidence-manifest.json) are retained here.
Only documentation/receipts were added after the reviewed implementation; all 47
technical files were checked against the committed source and manifest again.


The first honest attempt was deliberately stopped at totality (exit -15), before any
completion claim: inspection found a bot arrival wait race, and its first sky capture
showed an overly faint gap corona. The bot waits now include transition completion;
the final visibility curve above preserves the gap. That interrupted attempt is kept
separately in `/tmp/m3-aborted-honest` and is not pass evidence.

Honest’s two optional helper viewer captures (08/09) were skipped when the window
did not draw. All required coda and ending captures above were rendered successfully;
standalone careful supplies both viewer captures.

Godot may report ObjectDB teardown warnings in automated scripts (also observed in the
baseline careful run). macOS may emit an IMK mach-port message. Final logs distinguish
these from script errors, assertion failures and route failures. The exported ZIP is
an automated export check (SHA-256 `27fc527b845bd8672110841190a876a8495e976f7a3f0c7119d7d996375795ac`); no exported-app human playtest or notarization is claimed.
