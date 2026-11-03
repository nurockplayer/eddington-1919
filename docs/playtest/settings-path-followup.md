# Score settings-path follow-up

Recorded 2026-11-04 JST for PR #145, starting at `d9fc9ac`.

## Original A/B failure

Recovered these exact lines from cx-exec session
`01a1a339-d174-78b0-b769-9bfe2aaac88b`:

```text
FAIL: real _end_totality reaches NIGHT while Tab log stays open
FAIL: real Tab-held totality handoff completes within 7500 ms (8536 ms)
FAIL: totality_drone layer is stopped at NIGHT black handoff
FAIL: totality_drone AudioStreamPlayer is freed at NIGHT black handoff
FAIL: totality_glass layer is stopped at NIGHT black handoff
FAIL: totality_glass AudioStreamPlayer is freed at NIGHT black handoff
FAIL: totality_edge layer is stopped at NIGHT black handoff
FAIL: totality_edge AudioStreamPlayer is freed at NIGHT black handoff
```

The same run printed `handoff_ms=8536 setup_ms=10049 phase=TOTALITY`
and `test_score: 116 checks, 8 failures`.

These are one transition deadline miss and its consequences. The test holds Tab
open, freezing the outgoing audio fades. `_end_totality()` awaits a three-second
tween, a 1.5-second timer, then `_begin_night()` awaits a 1.2-second fade before
setting NIGHT and stopping all three cues immediately. At the failed deadline,
that point had not been reached, so the phase check, timing check, three stopped
layer checks and three freed player checks failed together. None of the eight
failures concerns music enablement or volume. The precise cause of that run's
wall-clock delay is not established.

Music enablement only mutes the Music bus; it does not skip cue starts or the
handoff. Both settings readers default to full volume with music enabled when
the override file is absent. No game code, settings defaults, or timing budgets
were changed for this follow-up.

## Reproduction and validation

The reproduction runs all three score processes serially in one call:

```sh
orb-test --host -- python3 -u .godot/w8g-followup/reproduce.py
```

The local orchestration deletes its worktree-local override before runs one and
three and reruns the same path for run two. Contrary to the brief's assumption,
`test_score` does not create the override file: its music-toggle check writes and
removes a separate `<override>.test_score` fixture. Run two therefore also
started missing. Final validation explicitly includes a pre-existing file.

The requested final validation runs score twice, settings once, and e2e once,
serially in one call:

```sh
orb-test --host -- python3 -u .godot/w8g-followup/validate.py
```

The two score inputs are a fresh missing absolute override and an existing
absolute override with music disabled, all volumes zero, low quality,
fullscreen enabled and large text. `test_settings` then uses that existing file.
E2E starts with `EDD_SETTINGS_PATH` unset, exercising the script's private fresh
settings path. The orchestration records every `FAIL:` line and checks that the
existing file's bytes are preserved. Both scripts and raw logs are temporary
worktree-local evidence; the results below are the durable record.

| Reproduction run | Override before / after | Handoff | Result | `FAIL:` lines |
| --- | --- | ---: | --- | --- |
| Missing | absent / absent | 7,327 ms | 116 checks, 0 failures | none |
| Same path again | absent / absent | 7,135 ms | 116 checks, 0 failures | none |
| Fresh missing | absent / absent | 7,436 ms | 116 checks, 0 failures | none |

The three-run orchestration exited 0. The missing/default-settings hypothesis
did not reproduce a failure.

| Final suite | Input | Handoff | Last suite result | `FAIL:` lines |
| --- | --- | ---: | --- | --- |
| Score 1 | missing override | 6,973 ms | `test_score: 116 checks, 0 failures` | none |
| Score 2 | existing muted override | 7,118 ms | `test_score: 116 checks, 0 failures` | none |
| Settings | same existing override | n/a | `test_settings: 96 checks, 0 failures` | none |

The existing settings bytes were unchanged after both score and settings.
Both final score processes printed the one-ObjectDB-instance teardown warning
also seen in all four prior A/B runs, including main. That warning is a separate
follow-up.

E2E's last result line was `all 6 routes passed` (exit 0):

| Route | Phase | Score | Stuck | Cue checks |
| --- | --- | ---: | --- | --- |
| careful | ENDING | 4 | 0 | pass |
| rushed | ENDING | 0 | 0 | n/a |
| cherry | ENDING | 3 | 0 | n/a |
| prologue honest | ENDING | 4 | n/a | pass |
| prologue tidy | PREP | -1 | n/a | n/a |
| prologue accuse | PREP | -1 | n/a | n/a |

The final orchestration exited 0 with `validation: PASS`. The shared
`user://settings.cfg` bytes and modification time were unchanged across the
whole final validation call. No settings-isolation failure was reproduced.

## Decision

The original eight failures all occurred at the delayed Tab-held handoff; fresh
missing and deliberately non-default existing settings now pass. Leave the game,
timing budget, suites and e2e script unchanged. The original run's extra
wall-clock delay and the ObjectDB teardown warning remain follow-ups.
