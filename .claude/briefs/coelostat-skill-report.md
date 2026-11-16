## PR or commit

None. Read-only report at `a51e61cfe921c32d79a7311cb336954666d30118`; no files changed. No PR was opened because this brief explicitly requests only a report.

**Recommendation: use a continuous trim interaction, carrying the remaining rate error into the plates.** It makes the player responsible for the result, including partial improvement. Present its star field as an illustrative tracking diagram: the repo does not establish that this was the actual Príncipe checking procedure.

## 1. Current flow

### Holds and flags

Both drive flags start `false` in [scripts/eclipse_sim.gd:43](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/eclipse_sim.gd:43).

| Hold | Duration | Allowed when | Completion |
|---|---:|---|---|
| `drive` | 3 s | PREP; not `drive_wound` | Sets `drive_wound = true`; winding toast |
| `chronometer` | 4 s | PREP; wound, not `drive_rate_checked` | Sets `drive_rate_checked = true`; reporting-seconds/calibration toast |
| `plate_box` | 1.2 s per holder | PREP; carried + delivered below eight | Adds one carried holder |

Definitions: [main.gd:37](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/main.gd:37), eligibility `:878–888`, completion `:945–958`.

The shared hold path requires aiming at the object and holding interact. With `Settings.hold_toggle`, one press latches the hold and another cancels it. Releasing, losing the target, becoming ineligible or opening blocking UI resets progress; pausing also cancels it. The pause-closing press cannot restart a hold until released (`main.gd:828–875`).

Preparation lasts 150 active seconds. Ordinary holds consume that budget; dialogue pauses it (`main.gd:805–825`). Neither drive task gates totality: the player may start through Eddington or let the countdown expire. Carried holders are automatically delivered at totality (`:1255–1267`).

### Every flag consumer

| Consumer | Effect and source |
|---|---|
| Hold eligibility and prompts | Winding precedes checking; completed tasks stop accepting holds. `main.gd:878–885`, `:917–924` |
| Eddington readiness dialogue | Reports unwound / wound / calibrated. `main.gd:1022`; [content.gd:29](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/content.gd:29) |
| Cottingham dialogue | Selects introduction, after-winding instruction, successful-check stakes conversation or subsequent completion line. `main.gd:1024–1036`; `content.gd:42–68` |
| Objective checklist | Ticks winding and rate checking separately. `main.gd:1174–1175` |
| Totality opening | Explains omitted winding or checking. `main.gd:1292–1296` |
| Long-exposure warning | At 20 exposure seconds, names the unchecked drive when appropriate. `main.gd:1387–1389`; `content.gd:331–334` |
| Plate-viewer conditions note | Reports checked/unchecked, subject to the prologue’s conditions-card choice. `main.gd:1589`; `content.gd:121–126` |
| Cottingham’s coda | Thanks the player for reporting seconds, or discusses incomplete preparation. `content.gd:291–296` |
| Physical simulation | Chooses drift rate: checked `0.012`, wound-only `0.05`, unwound `0.075` trail units per exposure second. `eclipse_sim.gd:198–206` |
| Judgment | A checked drive excludes the “uncalibrated instrument caused the low result” explanation; feedback distinguishes long exposure from unchecked drive. [judgment.gd:103](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/judgment.gd:103), `:218–228`. The reason’s numerical text also assumes an unchecked drive at `:99`. |
| Run record and ending | Stores both flags, then reports preparation in the ending. `main.gd:1751`; [ending.gd:58](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/ending.gd:58) |

The consequence is already connected end to end:

- `develop()` computes `trail = drift_rate() × duration`; a usable plate becomes “good” only with trail below `0.35` and fog below `0.6`. Usability itself requires five stars.
- Trailing increases measurement uncertainty and introduces the game’s illustrative downward bias (`eclipse_sim.gd:239–271`).
- Rendering makes the trail’s nominal length `trail × 26` pixels, along a fixed direction: [plate_render.gd:31](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/plate_render.gd:31), `:65–76`.

For an otherwise identical 10-second exposure, the three tiers give trails `0.12 / 0.50 / 0.75`, approximately `3.12 / 13 / 19.5` rendered pixels. Calibration does not guarantee a good plate: clouds and excessive exposure still matter.

### Autoplay

[tests/autoplay_bot.gd:342](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/autoplay_bot.gd:342):

- `rushed` skips preparation and leaves the drive to Cottingham.
- Other scenarios collect eight holders, deliver them, talk to Cottingham, aim at the drive and hold E for 3.5 s.
- They then walk to the observing table, aim at the chronometer and hold E for 4.5 s (`:372–403`).
- `_hold()` injects keyboard input and waits for engine-time progress (`:107–115`).
- During totality, non-rushed bots use a 16-second exposure limit if checked, six seconds otherwise (`:457`).
- Results export both flags and each plate’s trail (`:613–615`).

The preparation route **logs** the flags; its log messages are not assertions.

### Existing assertions

| Tests | What they establish |
|---|---|
| [test_autoplay_hold.gd:27](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_autoplay_hold.gd:27) | Real aiming/input completes winding and checking at 2 FPS, then collects eight holders. `:82–221` covers winding toggle, cancellation, pause/release protection and wording. |
| [test_sim.gd:73](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_sim.gd:73) | Checked preparation produces a good clear-gap plate; unchecked preparation trails more and increases uncertainty. `:269–301` covers instrument-reason acceptance, including checked-drive long-exposure feedback. |
| [test_totality.gd:310](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_totality.gd:310) | Correct readiness text and entry into totality for every preparation state. `:631–643` covers the instrument explanation through dialogue; `:890–915` covers long-exposure warnings. |
| [test_plan_recall.gd:81](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_plan_recall.gd:81) | Viewer conditions note reflects rate checking and the prologue plan. |
| [test_principe_story.gd:44](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_principe_story.gd:44) | Checked status unlocks Cottingham’s stakes exchange; subsequent conversation uses his completion line. |
| [test_ending_snapshot.gd:13](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_ending_snapshot.gd:13), `:67–89` | Both flags belong to the immutable ending record; rebuilding the ending preserves its text. |
| [test_plate_reading.gd:85](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_plate_reading.gd:85) | Example trailing visibly elongates rendered stars. This uses teaching examples, not calibration-produced plates. |
| [test_i18n.gd:94](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_i18n.gd:94) | Exact Cottingham instructions for both winding modes. |
| [test_replay_experiment.gd:81](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/tests/test_replay_experiment.gd:81) | Completes runs using direct `_hold_complete("drive")` and `_hold_complete("chronometer")` calls. This caller must change when checking stops being a hold. |

Additional flag assignments in `test_layout_bounds.gd:64` and `test_epilogue.gd:127` are fixtures, not proof of successful preparation.

## 2. Historical check — repository sources only

**The repo does not establish how the Príncipe drive was regulated or how its rate was checked.**

What it does support:

- Cottingham attended to the driving mechanism and gave exposures, while Eddington changed dark slides. The repo’s fact-check cites the 1920 expedition report, page 314, paragraph 29: [story_factcheck_2026-11-13.md:46](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/docs/research/story_factcheck_2026-11-13.md:46).
- Cottingham was a clock and chronometer maker with extensive observatory-clock experience (`:65–70`). That supports his competence, **not a particular regulator on this instrument**.
- Cloud interference and the morning thunderstorm are documented (`:49–54`).

Unsupported by the inspected historical documents:

- The drive’s exact power source, regulator, adjustment direction or graduations.
- Checking it by calling chronometer seconds.
- A visible guide star, eyepiece or reticle used immediately before this eclipse.
- Rain causing this drive to require rewinding or rate correction.
- Particular solar/sidereal settings, tolerances or calibration durations.

The current code explicitly calls the rain/rewinding/rate-check scenario **FICTION** (`eclipse_sim.gd:199–200`). Dialogue mentions both a weight clock and winding a spring (`content.gd:45`); it cannot settle the historical mechanism.

[HISTORY_1919.md:14](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/docs/HISTORY_1919.md:14) likewise requires fictional instrument trouble and illustrative evidence to be distinguished from documented events.

For either design, use a small caption such as **“Tracking diagram — illustrative reconstruction.”** Cottingham remains responsible for the mechanism; the player observes drift and requests adjustments. Do not present the star as a documented live daytime observation or invent a detailed historical regulator.

## 3. Interaction designs

### A. Continuous trim — recommended, effort M

```text
TRACKING DIAGRAM — illustrative reconstruction
┌─────────────────────────────────┐
│              +     • →          │
│       fixed mark   star image   │
└─────────────────────────────────┘
Slower  ◀───── trim ─────▶  Faster
Observe whether it moves, then adjust.
[Record current setting]   [Leave]
```

**Play and inputs:** after winding, a fresh E/A press at the drive opens the panel. Left/right arrows or gamepad D-pad trim the rate; Shift/LT makes fine adjustments. E/Enter/A records the current setting, B leaves with it, Esc/Start pauses. Movement and camera input are suspended.

Aim for 20–35 s; cap each attempt at 45 active seconds or the remaining preparation time. Three seconds of sufficiently small drift verifies success. The observation measures **movement**, not whether the star is centred. Recentring the diagram is only a display operation.

After **10 s without reducing the measured drift**, Cottingham hints: “Watch where it was and where it is now. Try one small adjustment.” No automatic correction.

**Later failure:** retain a signed normalized residual `drive_error`, with a small success deadband. Outside it, a wound drive uses:

`drift = 0.012 + 0.038 × abs(drive_error)`

This preserves today’s best and wound-only endpoints and allows intermediate results. An unwound drive stays at `0.075`. The existing plate development and rendering then show the consequence. Error sign changes the diagram’s drift direction; plate trailing can retain its current fixed direction.

Set `drive_rate_checked` only after the stability observation succeeds. Revise unchecked wording to mean **“not verified”**, avoiding claims that every incomplete attempt necessarily produced obvious trails.

**Reduced motion:** replace travel with two stationary marks labelled “previous” and “now,” updated once per second. Show textual direction and separation; no blinking or camera motion. Use the same residual and success criterion.

**Files/state/save impact:**

- `scripts/main.gd`: replace chronometer hold dispatch; reopen checking at the existing drive hotspot; integrate input, preparation time and closure.
- New `scripts/coelostat_calibration.gd`: panel, drawing and observation.
- `scripts/eclipse_sim.gd`: residual and drift calculation.
- `scripts/content.gd`, `scripts/ending.gd`, `scripts/prompts.gd`; `locale/en.po`, `ja.po`, `ko.po`: revised instructions and outcome text.
- `main.gd:_record_run`: copy the final residual into completed-run records.
- Runtime panel state: elapsed time, observation samples, stability duration and hint progress.

There are no mid-chapter saves: [checkpoint.gd:3](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/checkpoint.gd:3). Resuming Príncipe therefore restarts calibration. Completed-run dictionaries already travel inside saved `Story.runs` ([story.gd:37](/Users/tachikoma/Developer/eddington-1919-wt/fun-audit/scripts/story.gd:37)); no checkpoint-format change is needed. Old runs retain their existing flag-based summaries.

**Tests/autoplay:** replace the chronometer input hold with visible-drift observation and trim input. Update the direct replay helper. Adapt simulation fixtures that currently set only `drive_rate_checked`. Extend hold, totality, snapshot, gamepad, reduced-motion and wording coverage.

The essential new proof is **real calibration input → real shutter exposure → rendered plate**: at equal seed, cloud and duration, partial correction must produce less trailing than an abandoned correction, and successful correction less again.

**Risks:** tuning could feel like chasing a dot; the historical reconstruction must remain explicit; existing “checked” prose and judgment logic must stay consistent with residual quality. The current bot’s binary 16/6-second exposure policy also needs adjustment for intermediate drift.

### B. Observe, click a detent, verify — effort S

```text
TRACKING DIAGRAM — illustrative reconstruction
Previous:       •
Now:               •
                 → moving
[One step slower] [Observe again] [One step faster]
```

**Play and inputs:** same entry point. Arrows/D-pad request one coarse rate step; each step produces another short observation. E/Enter/A records, B leaves, Esc/Start pauses. Start a few steps away from the correct setting without labelling the correct dial position.

Allow roughly 15–25 s, with a 30-second cap. A stationary observation lasting three seconds succeeds. After **8 s without improvement**, Cottingham says: “The gap grew. Try one step the other way.”

**Later failure:** preserve today’s three drift tiers exactly. Success sets `drive_rate_checked`; an unfinished wound drive remains `0.05`. This gives the player an earned result, but partial improvement has no lasting effect.

**Reduced motion:** the two labelled stationary samples are already the main display. Normal mode may animate between them; reduced motion omits that animation.

**Files/state/save impact:** `main.gd`, the new calibration panel, `content.gd`, `prompts.gd` and the three translation catalogs. No simulation, plate-rendering or checkpoint-format change. Only transient detent, sample, timer and hint state is added; existing flags remain the complete outcome record.

**Tests/autoplay:** replace the chronometer hold and direct replay call; assert wrong-direction correction, successful verification, timeout, pause and both input devices. Keep existing drift-tier assertions. Add one successful and one unsuccessful real input-to-plate path. Autoplay observes the samples and presses the appropriate direction instead of reading a hidden correct detent.

**Risks:** a small number of steps may feel like finding a combination; binary failure discards meaningful partial work; repeated sampling can recreate the waiting feel of the old hold.

## 4. Recommendation

Choose **A** if this audit option proceeds. It directly fulfils “the result on the plates is theirs”: leaving a slightly imperfect setting differs from abandoning a badly drifting one. It also reuses the existing exposure and plate-rendering consequences.

Choose **B** only if the lead wants the smallest implementation. It improves agency while preserving the current simulation, but offers a weaker connection between the player’s adjustments and the final image.

## Tests

Command: none — `Test: none (read-only design proposal)`.

Result: no Godot, tests, builds or web research run. Findings come from source reads and targeted searches.

## Assumptions

- Durations, tolerances, controls and state names above are proposed implementation details, not adopted behaviour.
- Both options retain winding and plate collection, relocate rate checking to the existing coelostat drive hotspot, and leave the chronometer inspectable.
- Calibration consumes preparation time; pause freezes it. On preparation expiry, close calibration with its current result and proceed to totality.
- Neither option gates totality or guarantees usable plates.
- Earlier project memory was used only for orientation; all report findings were checked against this worktree.

## Follow-ups

The lead selects an option. Before presenting specific regulator hardware or a live pre-eclipse star check as historical fact, obtain a source identifying the actual Príncipe procedure. The explicitly illustrative version can proceed without making that claim.

## Blocked

None.

cx-exec review: no open PR for this branch; skipped
