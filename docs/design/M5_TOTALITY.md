# M5 — 1919 totality: legible and tense for a newcomer

Director spec (Opus 5.5, 2026-10-25). Scope: the first-person TOTALITY phase only (`scripts/main.gd` `_begin_totality` → `_end_totality`) and the plate viewer's per-plate line. HANDOFF next option 3.

## Problem

A newcomer is told "watch the clouds, call start when thin, stop when thick" and then gets a dense four-line HUD block and a ticking metronome. Three things are unclear:

1. **Cause → effect is invisible until the night.** The player learns only hours later (the night phase) whether their timing mattered. During totality nothing says "that exposure was mostly behind cloud".
2. **Exposure length has no felt cost.** The record says 2–20 s exposures. Nothing tells the player that 40 s is long, or that the un-rate-checked drive smears long plates (the prep choice pays off only at night).
3. **The clock is a number.** 302 s is a counter in a text block. Tension rests only on the 18 s third-contact warning and the score.

## Hard rules

- **Sim and grading are untouched.** No edits to `scripts/eclipse_sim.gd` or `scripts/judgment.gd`. Every plate the sim develops must be identical with or without M5 for the same shutter timings. Bots keep their scores (careful 4; rushed seed 515 → 0; cherry seed 4242 → 3).
- **Nothing says *when* to expose.** No cloud meter, no "now!" prompt, no callout keyed to upcoming gaps. Feedback is only about what *already happened* (hindsight) or about time and plates (facts the observers had). The score already follows this rule (M4: music never follows the clouds).
- **Score is untouched** (`scripts/audio/`).
- **Dialogue is Director-owned.** All new lines live in `scripts/content.gd` under `# --- M5 totality` and are already written. Workers call them; they do not edit or add text. If a line is missing, stop and ask.

## What changes

### A. Cottingham's hindsight read on every "停"

When a plate closes (not at third contact), Cottingham adds one line about *that* exposure, from the fraction of it that was clear: `f = p.clear / p.duration`.

| band | condition | line |
|---|---|---|
| clear | `f ≥ 0.65` | `Content.totality_read("clear")` |
| mixed | `0.30 ≤ f < 0.65` | `Content.totality_read("mixed")` |
| cloud | `f < 0.30` | `Content.totality_read("cloud")` |
| brief | `p.duration < 1.0` | `Content.totality_read("brief")` (overrides the band) |

The band key is stored on the plate dictionary as `p.sky_read` (main.gd adds it after `close_shutter`; sim untouched). Put the pure banding in a new static helper, `scripts/totality_cues.gd` (`class_name TotalityCues`, `static func sky_band(clear: float, duration: float) -> String`). The thresholds are constants there.

The night plate viewer (`ui.gd`, the detail line near `第 %d 號底片`) shows the same read as a second line: `Content.totality_read_night(p.sky_read)`. This ties the totality moment to the plate the player is judging. Plates closed by third contact (`sunlit`) have no read.

### B. Time and plate callouts (facts only)

All one-shot per run unless stated. Callouts go to a new **callout line** under the totality panel (see D) so they never overwrite the "開始／停" toast.

| trigger | line |
|---|---|
| an exposure reaches 20.0 game-s (once per plate) | `Content.totality_long(sim.drive_rate_checked)` |
| plate change finishes and exactly 1 plate is left | `Content.totality_last_plate()` |
| `t_game ≥ 200` and `plates_left ≥ 2` and not exposing and no plate has been taken since `t_game - 60` | `Content.totality_plates_left(plates_left)` |
| first 45 game-s pass with no exposure ever opened | `Content.totality_first_nudge()` |

The existing half-way glance (t = 150, historical: Eddington's own account mentions a glance half-way through to see the cloud) and the 18 s third-contact warning stay as they are, but move to the callout line.

### C. Exposure strip (HUD)

Replace the four-line text block with:

- one header line: `全食　剩餘 N 秒` (unchanged clock text, kept), plus the status (`● 曝光中 x.x 秒` / `Eddington 換片中…` / `底片就緒` / `底片用完了`) and the key hint;
- a **horizontal strip** spanning 0–302 s. A playhead moves along it. Each exposure is a filled segment from its start to its end (amber while open, muted once closed). There are **no** marks for clouds, gaps or thirds.
- **plate pips** under the strip: one small square per available plate, filled when used.

Draw it as a small custom `Control` (`scripts/totality_strip.gd`), fed from main every frame with `{t, total, segments: [[start, end], …], open_start, plates_total, plates_used}`. Keep its data shaping in `TotalityCues.strip_model(...)` so it is testable headless.

### D. Final ten seconds

In the last 10 game-seconds the header shows the remaining seconds large (e.g. `10`, `9`, …) in the third-contact warning colour. No new audio; the metronome tick already counts.

### E. Callout line and toasts

`ui.gd` gets `set_callout(text, seconds)` — a single label under the totality panel, same fade as the toast. Shutter feedback ("你：「停！」…") stays on the toast. A new callout replaces an older one; Cottingham's hindsight read (A) is appended to the shutter toast instead of using the callout, so the player reads "停 → 第 3 號 8.2 秒 → 那幾秒雲很薄" in one place.

## Tests (headless, new `tests/test_totality.gd`)

1. `TotalityCues.sky_band` — every band edge and the `brief` override.
2. `strip_model` — segments, open segment, pips, clamping at 302.
3. **Sim invariance:** run a fixed shutter script (seed 1919 and 515: open/close at fixed `t_game`) through the real `_process_totality` path and through `EclipseSim` directly; every developed plate matches on every sim key (`sky_read` excluded).
4. **Callout triggers:** each row of table B fires at its condition and only once (long-exposure: once per plate); none fires when its condition is false; the first nudge does not fire if the player exposed in the first 45 s.
5. Night viewer line present for every non-sunlit plate, absent for a sunlit one.

All existing headless suites keep their counts. Native runs (bots, screenshots) are the Director's.

## Out of scope

Visual cloud legibility in the sky shader (separate art/QA round, needs GPU verification), new audio, any change to night/judgment.
