# M4 score verification — 2026-10-20

Engine: `4.7.2.stable.official.ed1daf0bf`, macOS, Apple M2 Pro, native Metal Forward+. Source/test candidate: `877739be36c2740693873f4fbfed69923ff412a9`, branch `audio/score`. No push or merge.

## Headless suites

Each command ran independently as `godot --headless --path . --script res://tests/<name>.gd`; all exits were 0. Exact result lines:

```text
test_sim: 157 checks, 0 failures
test_autoplay_hold: 3 autoplay hold checks, 0 failures
test_prologue: 271 checks, 0 failures
test_report_review: test_report_review: 649 checks, 0 failures
test_overlay_hits: test_overlay_hits: 56 checks, 0 failures
test_plaster_material: PASS: Cambridge room/corridor plaster is broad, soft, and low contrast; M1/M2 glass is smooth; departure lamp has a soft halo
test_departure: 202 checks, 0 failures
test_coda: 67 checks, 0 failures
test_replay: REPLAY PROBE: 121 checks, 0 failures
test_bridge_pause: 6 bridge pause checks, 0 failures
score cache contention: render_busy=true cached_main_ms=0.002
test_score: 84 checks, 0 failures
```

No `ERROR` or `SCRIPT ERROR` appeared in the final regression logs. Godot emitted `2 ObjectDB instances were leaked at exit` in test_coda, test_replay, and test_bridge_pause. The new score suite exits without that warning.

The score checks cover deterministic signals, global RNG preservation, headroom, seam continuity, tick-frequency rejection, Cambridge silence, F/F♯ placement, durations, isolated ConfigFile persistence, pause/Tab-held ramps, exposure duck/return, async cancellation, cached replay, and cached-stream access during concurrent synthesis. The settings test uses its own temporary path and removes it.

## Cue renders and performance

Command:

```sh
godot --headless --path . --script res://tools/render_score.gd -- --out=/private/tmp/eddington-m4-renders
```

Worker timings below measure synthesis on a Thread (thread startup/join included), with PCM file conversion outside the timed region. Levels are pre-bus mono samples; silent fraction uses 100 ms frames with RMS ≤0.001. The 1900 Hz column is Hann-windowed Goertzel tone RMS divided by windowed cue RMS. Ratios round to zero at eight decimal places.

| Cue | Duration s | Worker ms | Peak | RMS | Silent | 1900 Hz ratio |
|---|---:|---:|---:|---:|---:|---:|
| cambridge_rain | 56.000 | 1037.336 | 0.142128 | 0.026821 | 46.61% | 0.00000000 |
| departure_motif | 9.200 | 154.297 | 0.136740 | 0.041962 | 20.65% | 0.00000000 |
| totality_drone | 24.000 | 234.278 | 0.083153 | 0.027120 | 0.00% | 0.00000000 |
| totality_glass | 24.000 | 140.012 | 0.081976 | 0.030970 | 0.00% | 0.00000000 |
| totality_edge | 24.000 | 127.001 | 0.042011 | 0.019337 | 0.00% | 0.00000000 |
| coda_resolution | 16.500 | 537.225 | 0.212443 | 0.051090 | 7.88% | 0.00000000 |

All loop boundary sample deltas pass comparison with the 99th percentile internal sample delta. Cambridge has zero-ended seams; totality uses a sustained repeating region with a 50 ms overlap crossfade. Its attack happens once in the player, rather than once per wrap, and the gameplay stop fade supplies the release. At the black handoff to NIGHT, any outgoing fade still held by Tab is cancelled so no totality player survives into the unscored phase; gameplay transition timing is unchanged.

Scene measurements below instrument the added Music-bus/settings/player/worker-enqueue code in `_ready` and its `_build_audio` call, rather than reporting total scene-load time. The budget is 30 ms per scene. PCM synthesis/conversion runs on a worker; cached reads are bounded by the short dictionary mutex.

```text
careful: [SCORE READY] scene=1919 added_ms=0.941
careful: [SCORE RENDER] cue=totality_drone worker_ms=253.781
careful: [SCORE RENDER] cue=totality_glass worker_ms=161.815
careful: [SCORE RENDER] cue=totality_edge worker_ms=152.658
careful: [SCORE RENDER] cue=coda_resolution worker_ms=576.350
careful: [SCORE READY] scene=1919 added_ms=0.466
rushed: [SCORE READY] scene=1919 added_ms=0.259
rushed: [SCORE RENDER] cue=totality_drone worker_ms=256.880
rushed: [SCORE RENDER] cue=totality_glass worker_ms=169.538
rushed: [SCORE RENDER] cue=totality_edge worker_ms=150.311
rushed: [SCORE RENDER] cue=coda_resolution worker_ms=562.123
cherry: [SCORE READY] scene=1919 added_ms=0.299
cherry: [SCORE RENDER] cue=totality_drone worker_ms=257.949
cherry: [SCORE RENDER] cue=totality_glass worker_ms=167.913
cherry: [SCORE RENDER] cue=totality_edge worker_ms=150.591
cherry: [SCORE RENDER] cue=coda_resolution worker_ms=573.313
honest: [SCORE READY] scene=1919 added_ms=0.621
honest: [SCORE RENDER] cue=totality_drone worker_ms=273.054
honest: [SCORE RENDER] cue=totality_glass worker_ms=167.392
honest: [SCORE RENDER] cue=totality_edge worker_ms=154.689
honest: [SCORE READY] scene=cambridge added_ms=0.327
honest: [SCORE RENDER] cue=coda_resolution worker_ms=574.238
honest: [SCORE RENDER] cue=cambridge_rain worker_ms=1060.329
```

Across the three direct runs and all honest attempts, observed added `_ready` maxima were: 1919 0.941 ms, cambridge 0.603 ms, departure 0.443 ms. These CPU measurements include failed native journeys and do not qualify their route outcomes.

The careful restart emits no second set of render entries: its streams are reused from the static cache.

## Native routes and cue logs

Each command was launched as a separate explicit argument list, in order, with a Python subprocess watchdog (no `timeout` command). Native runs were isolated from browser operations after observing that foreground changes can interrupt held input. These are automated routes, not human playtests or listening/mix approval.

### careful

```sh
godot --path . --always-on-top -- --autoplay=careful --speed=2 --shots=/private/tmp/eddington-m4-careful
```

```text
[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0
```

Receipt: `phase_reached=ENDING`, `score=4`, `score_failures=[]`.

Full score-player cue log from this run:

```text
[SCORE] {"cue":"totality_drone","db":-30.0,"event":"request","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"request","fade":1.2}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"start","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"start","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_edge","db":-32.0,"event":"request","fade":3.0}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"start","fade":3.0}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"coda_resolution","db":-28.0,"event":"request","fade":0.6}
[SCORE] {"cue":"coda_resolution","db":-80.0,"event":"start","fade":0.6}
```

### rushed

```sh
godot --path . --always-on-top -- --autoplay=rushed --seed=515 --shots=/private/tmp/eddington-m4-rushed
```

```text
[BOT rushed] DONE ending=過早的宣告 evidence=none score=0 stuck=0
```

Receipt: `phase_reached=ENDING`, `score=0`, `score_failures=[]`.

Full score-player cue log from this run:

```text
[SCORE] {"cue":"totality_drone","db":-30.0,"event":"request","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"request","fade":1.2}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"start","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"start","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_edge","db":-32.0,"event":"request","fade":3.0}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"start","fade":3.0}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"coda_resolution","db":-28.0,"event":"request","fade":0.6}
[SCORE] {"cue":"coda_resolution","db":-80.0,"event":"start","fade":0.6}
```

### cherry

```sh
godot --path . --always-on-top -- --autoplay=cherry --seed=4242 --shots=/private/tmp/eddington-m4-cherry
```

```text
[BOT cherry] DONE ending=不完整的判斷 evidence=favors_e score=3 stuck=0
```

Receipt: `phase_reached=ENDING`, `score=3`, `score_failures=[]`.

Full score-player cue log from this run:

```text
[SCORE] {"cue":"totality_drone","db":-30.0,"event":"request","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"request","fade":1.2}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"start","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"start","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":0.4}
[SCORE] {"cue":"totality_glass","db":-34.0,"event":"layer","fade":1.2}
[SCORE] {"cue":"totality_edge","db":-32.0,"event":"request","fade":3.0}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"start","fade":3.0}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"layer","fade":1.5}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"stop","fade":1.5}
[SCORE] {"cue":"totality_drone","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"totality_glass","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"totality_edge","db":-80.0,"event":"stopped","fade":0.0}
[SCORE] {"cue":"coda_resolution","db":-28.0,"event":"request","fade":0.6}
[SCORE] {"cue":"coda_resolution","db":-80.0,"event":"start","fade":0.6}
```

### honest

```sh
godot --path . --always-on-top -- --prologue-autoplay=honest --shots=/private/tmp/eddington-m4-honest
```

**HOLD: this required native route is not qualified on the reviewed candidate.** The latest attempt failed; a fresh run needs an uninterrupted foreground window. Earlier successful results from the pre-repair candidate are not substituted.

```text
[PROLOGUE honest] INCOMPLETE matched=0 bias_blocked=false screenshots=12 failures=["button did not accept real click after 3 attempts", "score totality_drone starts=0, expected 1", "score totality_glass starts=0, expected 1", "score totality_edge starts=0, expected 1", "score coda_resolution starts=0, expected 1", "score departure_motif starts=0, expected 1", "score cue order/duck/return/totality fade contract failed", "score totality_drone missing totality fade/completion", "score totality_glass missing totality fade/completion", "score totality_edge missing totality fade/completion"]
```

Latest partial cue log:

```text
[SCORE] {"cue":"cambridge_rain","db":-30.0,"event":"request","fade":1.1}
[SCORE] {"cue":"cambridge_rain","db":-80.0,"event":"start","fade":1.1}
```

## Native retry record

The reviewed runtime source remains `877739b`. Honest retries repeatedly lost drawing or real native clicks before the coda; none is counted as PASS. The first and fourth attempts crashed on shutdown after the failed receipt; the other attempts exited 1. Display-awake and external foreground guards were ineffective. A three-line in-process screenshot handoff was tried in the test runner, but that run failed in M1 before reaching it, so the unverified adapter was removed. The prior successful honest receipt on `85ea317` is baseline evidence only. Completing this gate requires an uninterrupted foreground Godot window.

| Attempt | Process exit | Result |
|---|---:|---|
| 1 | -6 | INCOMPLETE |
| 2 | 1 | INCOMPLETE |
| 3 | 1 | INCOMPLETE |
| 4 | -6 | INCOMPLETE |
| 5 | 1 | INCOMPLETE |

Attempt 1:

```text
[PROLOGUE honest] INCOMPLETE matched=17 bias_blocked=true screenshots=75 failures=["honest route did not enter CODA after judgment", "score coda_resolution starts=0, expected 1", "score cue order/duck/return/totality fade contract failed"]
```


Attempt 2:

```text
[PROLOGUE honest] INCOMPLETE matched=17 bias_blocked=true screenshots=75 failures=["honest route did not enter CODA after judgment", "score coda_resolution starts=0, expected 1", "score cue order/duck/return/totality fade contract failed"]
```


Attempt 3:

```text
[PROLOGUE honest] INCOMPLETE matched=17 bias_blocked=true screenshots=75 failures=["honest route did not enter CODA after judgment", "score coda_resolution starts=0, expected 1", "score cue order/duck/return/totality fade contract failed"]
```


Attempt 4:

```text
[PROLOGUE honest] INCOMPLETE matched=17 bias_blocked=true screenshots=75 failures=["honest route did not enter CODA after judgment", "score coda_resolution starts=0, expected 1", "score cue order/duck/return/totality fade contract failed"]
```


Attempt 5:

```text
[PROLOGUE honest] INCOMPLETE matched=0 bias_blocked=false screenshots=12 failures=["button did not accept real click after 3 attempts", "score totality_drone starts=0, expected 1", "score totality_glass starts=0, expected 1", "score totality_edge starts=0, expected 1", "score coda_resolution starts=0, expected 1", "score departure_motif starts=0, expected 1", "score cue order/duck/return/totality fade contract failed", "score totality_drone missing totality fade/completion", "score totality_glass missing totality fade/completion", "score totality_edge missing totality fade/completion"]
```

## Review and disposition

Independent source/test review: **PASS** for `877739be36c2740693873f4fbfed69923ff412a9`, using an Oracle-generated source bundle in Ego-lite with the visible GPT-6 Pro selection. [Review conversation](https://chatgpt.com/c/6ad73bc3-5204-83e8-bec2-7ad906c630bb). Verdict: "PASS - both required P2 findings are resolved"; no remaining required fix. The review verified the Tab-held phase-exit cleanup, sustained loop seams, and new regressions; it did not execute the code or perform a listening review. The three direct 1919 native receipts above qualify their scores on the reviewed runtime; the honest native gate remains HOLD pending a foreground run. No design authority or DECISIONS document was changed. No external audio, sample, SoundFont or third-party melody was added. Temporary WAV/PNG outputs are removed after recording these measurements and receipts; source, test and textual evidence remain.
