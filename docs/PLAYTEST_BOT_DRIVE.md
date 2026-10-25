# v0.1 bot hold and plate-feedback verification

**Default E2E is now headless (2026-10-25):** `tools/e2e_headless.sh` runs all six routes
(`--autoplay=careful|rushed|cherry`, `--prologue-autoplay=honest|tidy|accuse`) with
`godot --headless --path . --fixed-fps 60`, one Godot at a time, and prints a result table.
A single route is `godot --headless --path . --fixed-fps 60 -- <route args>`. The
`--always-on-top --shots=DIR` runs recorded below are the historical screenshot runs and are
no longer the default; use them only when someone must look at the screen or capture frames
(Owner's windowed-run rule in [HANDOFF](HANDOFF.md)).

2026-10-20 JST · Godot 4.7.2.stable.official.ed1daf0bf · macOS / Apple M2 Pro / Metal Forward+.
Worktree: `eddington-1919-wt/fix-sol`, branch `fix/v01-bot-drive`, base `aa730ef`.

## Root cause and repair

The bot's `_hold()` used `_wait()`, whose timer ignores time scale and follows wall time.
The game accumulates `delta` for holds in `main.gd`. At low rendering rates, capped
physics catch-up lets wall time outrun that game clock, so E can be released too soon.
Without winding, the chronometer hold is disallowed; both false flags follow from one failure.

An isolated real-scene probe, aimed at the drive, reproduced the original timer behavior
at 2 FPS with `Engine.time_scale = 2`:

```text
TIMING aim=drive
TIMING real_s=3.499 process_s=1.99106 frames=8 hold_t=1.85212933333333 drive_wound=false
```

`_hold()` now waits on a game-time `SceneTreeTimer`, preserving its nominal wall-time
budget at the chosen speed via `sec * Engine.time_scale`. Other bot pacing remains as before.
Real player rays hit both existing targets from the intended standing positions, and the
rendered coelostat screenshot shows the drive box under the crosshair with its winding
prompt. No scene, collider, player reach, or game hold-duration changes were needed.

The original graphical seed 96734 succeeded under normal frame rates before this fix.
The failure reproduction is the controlled low-FPS case above, not a claim that the seed
alone always reproduces the Director's failure.

For telegram `none`, Eddington retains the clear-star line only if a usable `good` plate
exists. With only usable `poor` plates he says:

> 沒有結果？你手上還有可量的底片，只是星像拖長或被雲霧蓋住；不是什麼都沒留下。

`tests/test_sim.gd` covers both cases. Scoring is unchanged.

The initial code review caught a shared-helper regression: waiting only 10.2 game
seconds at speed 2 could collect 7/8 holders at 12 FPS because each pickup discards
overshoot. Preserving the original speed-adjusted time budget fixes this; the regression
now includes the plate-box input path and collects 8/8.

The careful bot deliberately includes only `quality == "good"` plates in `_night()`.
A plate is usable at five stars, but can still be `poor` because of fog or trailing.
Thus `included []` when only poor plates are usable is the existing strategy and is retained.

## Verification

All commands ran in the specified worktree. No `timeout` command was used.

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/test_sim.gd
godot --headless --path . --script res://tests/test_autoplay_hold.gd
```

Output tails (all exit 0):

```text
[ DONE ] loading_editor_layout
157 checks, 0 failures

drive at 2 FPS, speed=2: reachable=true completed=true
chronometer at 2 FPS, speed=2: reachable=true completed=true
plate holders carried=8/8
plate_box at 12 FPS, speed=2: reachable=true completed=true
3 autoplay hold checks, 0 failures
```

The new hold regression instantiates the real main scene, aims through the actual
player ray, sends E through the bot's input primitive, and checks both simulation flags
and all eight extra plate holders.
It stops audio and lets its thread settle before scene teardown; the final run has no
ObjectDB warning.

Three serial graphical runs used this command (screenshot runs, not the default E2E), replacing
SEED with 7, 96734 and 23068:

```sh
godot --path . --always-on-top -- --autoplay=careful --shots="$PWD/build/v01-bot-drive/careful-SEED" --seed=SEED --speed=2
```

| Seed | Drive wound | Rate checked | Evidence | Score | Stuck | Restart seed |
| --- | --- | --- | --- | --- | --- | --- |
| 7 | true | true | favors_e | 4 | 0 | 1274 |
| 96734 | true | true | favors_e | 4 | 0 | 47542 |
| 23068 | true | true | favors_e | 4 | 0 | 26427 |

Each reached `ENDING` / 「雲層之後的希望」, delivered all eight extra holders, and returned
to a visible title screen after 「新的天空」. None used a movement teleport, title fallback,
or phase timeout. Each log ends with:

```text
[BOT careful] DONE ending=雲層之後的希望 evidence=favors_e score=4 stuck=0
[BOT careful] restart run 2: seed ... (first run seed ...) title_visible=true
[BOT careful] shot 11_after_restart
```

Full logs, screenshots, result/restart JSON, the before-fix timing probe and source hashes
are local ignored artifacts under `build/v01-bot-drive/`. They are not included in this
commit. Graphical logs contain a macOS IMK mach-port message; no Godot script/engine
error or warning was found in the final checks.

## Independent review

Oracle CLI 0.21.1 rendered the source bundles, delivered through Ego-lite to the
UI-selected GPT-6 / Pro reviewer. The original plate-pickup finding was reproduced
and repaired. The final review of the updated source hashes returned
**No blocking findings.** [Review conversation](https://chatgpt.com/c/6ad67fd5-f994-83e8-a757-8194da5d01d2).
The reviewer performed a static source review; the Godot runs were executed locally
by the implementation lane. The review snapshot and source hashes are retained locally.

These are automated input runs and rendered captures, not a human usability playtest.
