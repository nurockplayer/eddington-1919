# Game Director Handoff

**Windowed-run rule (Owner, 2026-10-25, in force now):** windowed Godot (`--always-on-top`, autoplay bots, `--shots`) blocks the middle of the Owner's screen. Run it only when someone must look at the screen or take screenshots: 1–2 routes before a milestone merge, at most. Schedule it only Mon–Fri 09:00–15:00 JST (Owner 2026-10-28 02:15 JST moved the start from 03:00; headless runs are fine at any time), never nights, evenings or weekends, and always add `--fixed-fps 60`. Everything else is headless: `orb-test --heavy --host -- ./tools/e2e_headless.sh` runs every autoplay route (`careful`/`rushed`/`cherry`, `prologue-autoplay=honest`/`tidy`/`accuse`) headless, one at a time, with a wall-clock cap and a result table; a single route is `orb-test --host -- godot --headless --path . --fixed-fps 60 -- <route args>`. Possible later option (not verified): a virtual display (BetterDisplay) with `--screen 1`.

**Test-run rule (Owner, 2026-10-25, all projects; see `orb-test --help`):** no test runs bare on the host. Wrap it in `orb-test`, run from the worktree root.
- Godot is GPU work, so it runs on the host, through the lock:
  - a single headless suite: `orb-test --host -- godot --headless --path . --script res://tests/<suite>.gd`;
  - all suites, `orb-test --heavy --host -- ./tools/e2e_headless.sh`, a windowed screenshot run or Blender: `orb-test --heavy --host -- <cmd>`.
- `--heavy` queues for the one host-wide heavy lock. It starts only Mon–Fri 05:00–15:00 JST or after 45 min of keyboard/mouse idle (orb-test gate, seen 2026-10-29 03:07 JST), then checks `memory_pressure` ≥20%.
- Python runs in the container: `orb-test --image python:3.12-slim -- python3 -I art/pipeline/test_budget.py`.
- `tools/e2e_headless.sh` takes no lock of its own; orb-test holds it.
- Every worker brief states this rule explicitly. The DS base prompt still says lockf.

**DeepSeek dispatch (Owner, 2026-10-26, all projects):** dispatch by default with `ds-exec <worker> <brief file>`, run in the background from inside the repo. It uses the same roster, `.claude/ds-workers.tsv`.
- It is one-shot and headless (`claude -p`, no MCP) and exits when the task ends.
- It denies, rather than prompts for, any action that needs permission, and lists those actions under **Blocked** in its report. The lead then allows them or reassigns the task.
- Logs go to `~/.local/state/ds-exec/`.
- Use `ds-restart` (a herdr tab) only for interactive tasks. Close an idle DS tab after hand-off with `herdr pane close <pane>`.
- One task per worker worktree at a time: never an open DS tab plus a `ds-exec` run on the same worker.

**Leads think, workers execute (Owner, 2026-10-26, all projects; replaces "DeepSeek briefs are pre-digested").** This applies to every worker: DeepSeek, Codex Sol/Luna and Haiku subagents. Understanding the problem, finding the code and deciding the change is the lead's job. A worker starts with an empty context and only carries out its brief. Cost is context × calls: the median DS session on 2026-10-25/26 made about 140 tool calls at about 90k tokens each, mostly searching for code.
- The brief gives the answer, not just the goal: files and line ranges or functions, the intended change (a diff sketch where possible), and the exact `orb-test` command. The worker edits; it does not survey the codebase.
- One brief, one change; split anything bigger.
- Never point a worker at large or generated files (run JSON, images, `build/`, long logs). Give `grep`, `jq` or `sed -n` ranges in the brief instead.
- Judgement stays with the lead, or goes to Sol as a scoped question. Research goes to `oracle-ego`. A data regeneration or long run goes out as the exact command to run.
- `ds-exec` caps a run at 40 turns (`DS_MAX_TURNS`). Raise the cap only with the reason written in the brief. Hitting the cap means the brief was too big. Usage: `~/.local/state/ds-exec/usage.tsv`.
- Always run `quota-advisor --tier ...` first. After the Codex weekly reset (2026-10-26 12:00 JST) it says PRIME, so Codex goes first.

**Codex default worker (Owner, 2026-10-26 19:0x JST):** plain `codex exec` now runs gpt-6-luna at high effort (set in `~/.codex/config.toml`).
- Add `-m gpt-6.1-sol` only when the lead judges a task complex enough.
- Ask `quota-advisor --tier routine` by default, and `--tier hard` only for complex tasks.
- The Codex review fallback always passes `-m gpt-6.1-sol` explicitly.

**Time-zone rule (Owner, 2026-10-26, all projects):** every written time carries its zone, like a PostgreSQL timestamptz: `2026-10-26 01:40 JST` or `2026-10-26T01:40+09:00`, never a bare `01:40`.
- It applies to reports, PRs, commits, this handoff, worker briefs and logs.
- Rules and reports stay in JST.
- Tool output without a zone (containers and CI print UTC) must be converted, or labelled with its zone, before it is quoted.
- Get the current time from the host: `date "+%F %H:%M %Z"`.

**One-off data rule (Owner, 2026-10-26, all projects):** one-off data is deleted when the run ends, by default. This covers containers, volumes (named node_modules or pnpm store caches included), images built for the run, test DBs, traces and scratch output.
- For this project that means:
  - verify clones and worktrees;
  - `build/` exports and `--shots` directories;
  - Codex and oracle logs;
  - WAV renders, bot JSON results and art `_raw/` PNGs.
- When a task ends, `git worktree remove` every clean worktree that is merged or pushed.
- Evidence goes into the PR or the Issue, or into the repo under `docs/` or `art/validation/`. Never leave it in an outside temp location.
- Keeping anything for reuse needs the Owner's approval first. Record what was approved, why, and where it lives.
- `orb-test` never uses a Docker cache volume.
- **Where approved reusable caches go:** on `/Volumes/KIOXIA`, or `/private/tmp` when KIOXIA is not mounted (cleared at reboot). Never in Docker volumes or on the Mac SSD; copy to the SSD only when a job really needs it. Approvals are recorded in `~/.local/state/orb-test/approved-caches`.
- orb-test's pnpm and corepack download cache is approved. It mounts from `/Volumes/KIOXIA/orb-test-cache` by default; `--no-cache` skips it.
- **MPFB:**
  - The whole MPFB cache is Owner-approved (2026-10-26 02:18 JST): the isolated `blender_user` install plus the download zips in `dl/`. `art/pipeline/setup_mpfb.sh` keeps it at `/Volumes/KIOXIA/eddington-1919-cache/mpfb`, or at `/private/tmp/eddington-1919-cache/mpfb` when KIOXIA is not mounted (that copy is rebuilt after a reboot). `E1919_MPFB_CACHE` overrides the location.
- `orb-test --status` shows the lock holder and the queue.

**M4 score — 2026-10-20:** `audio/score` implements the [Director’s original procedural score](design/M4_SCORE.md): Cambridge rain, departure motif, restrained totality layers and the coda resolution, plus a saved pause-menu music toggle. All sound is synthesized in GDScript; no external audio assets. Verification and cue/performance measurements: [M4_VERIFICATION](M4_VERIFICATION.md). 84 score checks and all existing suites pass; direct native bots retain 4/0/3. The honest native ENDING/coda gate passed in a Director foreground run (all score cue checks clean, `coda_resolution` once). Astra review: no regressions. Not verified: human listening in context.

## Director backlog (edd-director) | 2026-10-29 17:35 JST

Characters (HG / c01–c03) are owned by the session eddington-1919-6c. edd-director stays off them.

Open PRs (all pass their headless suites):
- Windowed look 2026-10-29 11:54 JST (15 stills). Merged after it: #39 globe + Taurus chart, #44 title meteors, #46 title Taurus figure, #49 sun crescents (codex review; oracle timed out on its 123 KB bundle; hand-merged, override comment), #57 departure window stars.
- #40 lamp dust: read as white snow; warmer, alpha 0.4. Re-shoot pending.
- #41 Príncipe night sky: Milky Way barely visible; stars wider and brighter, band x2.4. Re-shoot pending.
- #50 shadow bands: invisible, the plane was under the dirt (y 0.01 < 0.02); lifted to 0.04, alpha 0.16. Now based on main. Re-shoot pending.
- #53 diamond ring: still shows a flat grey sky, cause not found (cloud over Sun was thin). Draft.
- Second windowed run (#40 #41 #50 #53): not reached on 2026-10-29 (the heavy queue sat behind a 5.5 h gteki bench); ticket cancelled 17:28 JST, re-armed for 2026-10-30 09:07 JST (`windowed_r2.sh`, one run, all four branches).
- #53: headless ray probe 2026-10-29 13:40 JST found no mesh between the eye and the Sun (alt 56°), so the grey is the sky shader at the values shot; the re-shoot uses the tween's peak values plus a wide still.

Before merge:
- Heavy set + e2e for all eight open branches, in one integration worktree: queued 2026-10-29 03:07 JST under `orb-test --heavy --host`; it starts when the gate opens (05:00 JST, or 45 min idle).
- Windowed look at #39–#41 and #44: 09:00–15:00 JST, one run of `tools/look_shots.gd` (#45) on an integration worktree (main + #39 #40 #41 #44 + #45): `orb-test --heavy --host -- godot --path . --fixed-fps 60 --always-on-top -s tools/look_shots.gd -- --out=$PWD/build/look`. 8 stills; delete `build/look` after.

Next items:
- bot 「完成計畫」 real-click flake: #55 merged c7aa61f (2026-10-29 06:35 JST). The bot now waits for the button to enable and logs `disabled=` and the hovered control on a miss. Confirm in the 09:00 JST windowed run; if it still misses, the log names the cause.
- Lens reset on an unframed speaker: already in `director.gd` `_frame_speaker` (returns to 55° when the speaker is hidden or a voice). test_score wall-clock flake: #43 times only the handoff. Both closed.
- Coda sky: the coda plays in the darkroom under the same sky at `night = 1`, so the Príncipe night dome (#41) covers it; no separate item.
- bridge_pause teardown leak: #56 merged 8af22f9 (2026-10-29 06:45 JST). Cambridge director stops its players in `_exit_tree`; the same in departure_director made test_prologue leak 4, so not done there.

Working rule (Owner 2026-10-28): never idle. An hourly heartbeat picks the next item. A question to the Owner never blocks other items.

## Director sprint status — M1 prologue, M2 departure night, M3 Príncipe coda | 2026-10-20 JST (Opus 5.5)

**State:** M1 (PR #9, `96fd598`) and M2 (PR #10, `7733d6d`) are merged and verified on fresh clones. M3 (branch `m3/coda`) goes to `main` via PR. All three are part of the 72-hour Director sprint (Issue #1).

- **Play:** `godot --path .` → 「序章　劍橋，1917」 (about 12–18 min, target; not measured with a human). It flows into the unchanged 1919 slice. 「普林西比，1919」 still starts the slice directly.
- **What the player does:**
  - Find why a 1915 tracing does not match its plate: it was mirrored and rotated. One residual stays honestly unresolved.
  - Have Kit check independently.
  - Write a report: the "fraud" option is offered and challenged; revision is always possible.
  - Hear Dyson's 1917 proposal and answer Eddington's two questions.
  - Build a fair test plan: core / helpful / bias cards.
  - Take on the trial task (the Hyades list), then Kit's evening coda (the childhood star-map echo) and a tagged history/fiction montage.
- **Ownership:**
  - Dialogue: Director, `scripts/cambridge/content_1917.gd`.
  - Names are placeholders in `cast.gd` (Kit, Ashby 先生).
  - Code: gpt-6.1-sol in 3 rounds.
  - Review: gpt-6-astra (independent, read-only). astra-6-gps was not accessible; nothing is claimed for it.
- **History/fiction:** see the M1 table in [PROVENANCE](PROVENANCE.md) and the "Fact-check applied" section of [the M1 spec](design/M1_CAMBRIDGE_PROLOGUE.md).
- **Tests:** see [M1_VERIFICATION](M1_VERIFICATION.md).
- **Automated routes:** headless by default: `orb-test --heavy --host -- ./tools/e2e_headless.sh` (all six routes) or `orb-test --host -- godot --headless --path . --fixed-fps 60 -- --prologue-autoplay=honest|tidy|accuse`. Add `--shots=DIR` (windowed) only for screenshots.
- **Not done / open:**
  - No human playtest yet. Run [PLAYTEST_NEWCOMER](PLAYTEST_NEWCOMER.md) and post the results to Issue #1. This is the most valuable next input.
  - The childhood keepsake/microimage is untouched. Its canon is open and must not be invented.
  - Figures are primitive. MPFB people still need the Owner's OK.
- **M2, the departure night (March 1919, about 6–9 min target):**
  - The M1 montage now ends on the 1918 bridge, then `scenes/departure.tscn` loads (`scripts/cambridge/departure_director.gd`, checklist modal, props).
  - Last shared check with Kit: the player's own transcription slip, struck through and initialled or overwritten (`Story.slip_fix`).
  - Bond choice → `Story.bond_tone`, which only colours later lines.
  - Sky promise with a blank workbook page.
  - Ashby's farewell and gift: `Cast.MENTOR_GIFT`, a placeholder.
  - Montage → 1919 PREP.
  - 1919 hooks are cosmetic: a loupe prop in the darkroom and an optional night workbook page.
  - Dialogue: `content_departure.gd`, owned by the Director. Verification: [M2_VERIFICATION](M2_VERIFICATION.md).
- **M3, the Príncipe coda ([spec](design/M3_CODA.md)):**
  - For prologue players only. After Eddington's response to the telegram, the player is alone in the darkroom. They write the workbook page (or reread it if already written), then pick up Ashby's loupe. `ContentCoda.ashby_answer` reflects on the same grade used by the ending. `kit_close(bond_tone)` follows, the lamp goes out, then the ending.
  - The ending screen leads with the telegram, the response and the evidence. History sits behind 「歷史上發生了什麼」.
  - Totality sky: round stars that cloud now hides. Cosmetic only.
  - Verification: [M3_VERIFICATION](M3_VERIFICATION.md).
- **Next options, in value order:**
  1. A human playtest of M1+M2.
  2. People/figure quality (needs the Owner's OK for MPFB).
  3. The 1919 core: make the first-person totality more legible and tense for newcomers, informed by the playtest.
  4. Later narrative (letters, reunion), once the Owner settles the keepsake canon.
- **Resume recipe:**
  - Worktrees live under `~/Developer/eddington-1919-wt/`.
  - Codex runs with `codex exec -m <model> --dangerously-bypass-approvals-and-sandbox -C <wt> -o <out> "<prompt>" < /dev/null`, in at most 3 parallel jobs.
  - E2E (default): `orb-test --heavy --host -- ./tools/e2e_headless.sh` — every autoplay route, headless, one Godot at a time, table + non-zero exit on failure.
  - Windowed Godot runs need `--always-on-top` and are only for looking at the screen or taking screenshots.
  - There is no `timeout` command on this Mac.

## Current production handoff | 2026-10-20 JST

**Source of truth:** [Notion 《雲層之後》 Narrative Bible — §0 quick handoff, §§1–7 decisions](https://app.notion.com/p/3fed7d8b390781ac848acc2d293ebbde) defines **approved vs proposed** story. [GitHub Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1) is the live Opus Game Director decision, evidence and milestone log. This section **supersedes prior v0.1-only scope**, without claiming any new playable work has been shipped.

**Owner product goal:** Use the current intensive Opus + Codex development window to move the **single** 1919 eclipse historical adventure toward a game players are excited to start, engrossed in, and remember afterward. A completed commercial release in 72 hours is **not** guaranteed. Don't produce extra historical games, build a generalized RPG platform, or turn the prologue into a science lecture.

**Directed team:** **Opus 5.5** final game/story direction and integration; collaborate with **gpt-6.1-sol** on bounded coding tasks and Owner-requested **astra-6-gps** on independent challenge/review where the exact model is accessible. **Do not claim unavailable workers ran**; record substitutes. Use as many clean parallel worktrees as useful, not concurrency for its own sake. Every meaningful merge must be reviewed, verified in *merged* `main`, and handed off.

**Already approved story constraints (details and status in Notion):**
- 1915–1919 narrative begins with a respectful **Newtonian tradition vs general relativity** debate, Dyson's 1919 eclipse plan, and Eddington's involvement; includes Cambridge preparation, eclipse, plate analysis and the documented November 1919 announcement. Preserve real contributions of Dyson, Cottingham, Eddington, Sobral and local workers.
- Fictional protagonist craves recognition and fears the expedition may prove inconclusive. Two fictional childhood friends were accused of inventing mismatched star observations and bullied; observational error does not make them liars. The protagonist's Newtonian mentor is respected, supports departure and gifts a cherished measuring tool.
- **First new playable milestone:** novice-friendly 1917 Cambridge records mystery, comparing an apparently misaligned star field, tracing a mundane observation/calibration problem, retaining the original notes and reporting uncertainty. Mentor then recommends protagonist; Eddington assesses the care taken, entrusts a real preparation task (not immediate expedition membership). Three-way discussion is rational but tense; player should help plan a scientifically fair observation. Wartime logistics are background texture through characters, letters and work, not an unrelated minigame. **No prior physics knowledge required.**
- Warm, capable fictional same-age peer is introduced before real precision-mechanism expert Cottingham. Peer has an independent career in Cambridge; later reunion via shared work, optional unsent letter and understated acknowledgement of unequal opportunity. Optional romantic route: intense affection before departure *without confession*, quiet mutual confirmation **only near ending**. Full, equally moving platonic route. Both promise to share the skies they see.
- Player's evidence judgments must arise from actions and records, never from romance flags. Finale echoes the Cambridge worktable with original eclipse evidence and mentor's inherited instrument. Scientific findings do not depend on invented sentimental artifacts.

**Important unresolved canon:** Owner desires an old object worn/carried since childhood with a historically plausible microscopic image, revealed in Cambridge near the end, tied to the childhood star-chart accusation. **The maker, carrier, manufacture, unseen mechanism, written message and precise romantic staging are still open.** The last suggestion (childhood friend note + adult microphotography) was **not accepted**. Use a reversible placeholder if needed; do not lock the reveal, exact character names/genders, or specific dialogue before Owner picks them.

**Engineering baseline right now:** `main` is the merged v0.1 Godot 4.7.2 3D playable slice (below). [Art PR #3](https://github.com/nurockplayer/eddington-1919/pull/3) targets `main`; [art PR #4](https://github.com/nurockplayer/eddington-1919/pull/4) is stacked **on #3**, not on `main`. Treat those as *unmerged* until verified and integrated; plan review/merge order accordingly. No human blind playtest has been recorded. Begin with an honest play/run and prioritize the most important gameplay/narrative weakness. In parallel, recruit an unbriefed player as soon as feasible for a real newcomer usability check.

**Reporting rhythm:** After each meaningful milestone, post working commit/PR, how to play and reproduce, actual Godot testing, known historical/fictional boundaries, remaining issues and the next highest-value step to [Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1). New sessions start from current `main`, issue comments and this file. This handoff itself does **not** launch an Opus/agent process.

---

**Implementation baseline (2026-10-19 JST): v0.1 playable slice delivered**. The complete loop is verified by automated real-input runs. **There has been no human playtest yet.**

## Current verified state (v0.1)
- **Build.** Godot **4.7.2.stable**.
  - Run: `godot --path .`
  - Export: `godot --headless --path . --export-release "macOS" build/Eddington1919-macOS.zip`
  - Tests: `orb-test --host -- godot --headless --path . --script res://tests/test_sim.gd`
  - Autoplay: `godot --path . --always-on-top -- --autoplay=careful|rushed|cherry --shots=DIR [--seed=N] [--speed=2]`
- **Play.** About 6–10 min, first person.
  - **Prep:** brief with Eddington, fetch plate holders, wind and rate-check the coelostat drive with Cottingham.
  - **Totality:** call exposures through a drifting cloud field (302 s compressed ×2.5).
  - **Night:** developed plates show stars, fog and trailing from what you did. You choose plates *before* the values appear, then measure.
  - **Judgment:** pick a telegram and a reason. Eddington reacts to calibration and selection integrity.
  - **End:** the historical epilogue, then replay with the same or a new sky.
- **Evidence:** [docs/PLAYTEST.md](PLAYTEST.md) (screenshots and bot JSON in `docs/playtest/`); history and fiction labels in [docs/PROVENANCE.md](PROVENANCE.md); design decision [D006](DECISIONS.md).
- **Code map.**
  - `scripts/eclipse_sim.gd`: shared state and model.
  - `scripts/judgment.gd`: grading and Eddington's lines.
  - `scripts/main.gd`: phase flow.
  - `scripts/world_builder.gd`: procedural site.
  - `scripts/ui.gd` and `scripts/chart.gd`: HUD, dialogue, plate viewer, endings.
  - `shaders/eclipse_sky.gdshader`: sky that shares the cloud texture with the sim.
  - `tests/`: logic tests and the autoplay bot.

## Visual system (art pipeline, 2026-10-19)
- **Read [art/BIBLE.md](../art/BIBLE.md)** (style rules) **and [art/PIPELINE.md](../art/PIPELINE.md)** (generate → choose → Blender/Tripo → Godot gates → feed back) before making any art.
- **Decision record:** [D007](DECISIONS.md). **Log:** [art/LOG.md](../art/LOG.md).
- **Generate concept images:** `python3 art/pipeline/gen.py --run rNN-x --styles E_diorama_plate_grade --subject <subject> --gens gpt --n 2` (GPT via Codex, about 1 min per image).
- **In-game visual benchmark:** `godot --path . --always-on-top -- --benchmark=$PWD/art/validation/g4-<label> --seed=7`, then compare against `art/validation/g4-baseline-v0.1` with `art/pipeline/compare.py`.
- **Lookdev:** `godot --path . --always-on-top res://scenes/lookdev.tscn -- --capture=$PWD/art/validation/g3-<label>`.
- **Performance claims:** `art/pipeline/baseline.sh` and `perf_summary.py` with at least 3 repetitions, metrics kept separate ([perf-r04](../art/validation/perf-r04/README.md)).
- **Generators:**
  - GPT via Codex is the working generator. "dot" is ChatGPT's personal assistant, not a CLI (Owner, 2026-10-20), so the GPT flow stays.
  - Tripo needs `TRIPO_API_KEY` and is not blocking.
  - Gemini needs paid image quota.
- **Owner tone (2026-10-20):** Diorama + Plate Grade is provisionally adopted. Push toward historical weight, cinematic light, suspense and emotion; avoid a toy-like read (BIBLE §2).



## Previous v0.1 playtest priority — still unfulfilled
The previous immediate next step was **a human playtest of v0.1** (about 15 minutes) using the five questions in [PLAYTEST.md](PLAYTEST.md). This remains an **important quality gate**, though product scope has now expanded per the 2026-10-20 checkpoint: Opus should balance this early test with a real playable Cambridge narrative opening, not wait for an entire game before testing or promise that a simulated run counts as a human.

## Canonical GitHub reporting entry

**[Issue #1 — Game Director Handoff](https://github.com/nurockplayer/eddington-1919/issues/1)**. Opus 5.5 should use it to record meaningful progress, playable builds and handoffs. A link to a commit/PR and honest playtest evidence matter more than a long status report.

### Read first (in this order)
1. [README](../README.md) — short owner direction and repo separation.
2. [Decisions](DECISIONS.md) — hard constraints and freedom.
3. [History and provenance](HISTORY_1919.md) — what can/cannot be claimed about 1919.
4. [Issue #1](https://github.com/nurockplayer/eddington-1919/issues/1) and its *latest* comments — the live director handoff.
5. [Earlier Notion slice concept](https://app.notion.com/p/3fdd7d8b39078183a159e6bd58fc0b7e) — optional inspiration, not a binding 2D/Hub specification.

## Model delegation authorization (Owner, 2026-10-19 JST)

Opus 5.5 is the **Game Director and final integrator**. The Owner explicitly authorizes Opus to use **gpt-6-astra, gpt-6.1-sol, sonnet-5.5, and haiku-5.5** as additional collaborating models/agents where the execution environment actually provides access. Opus may select, combine, parallelize, or skip any of them according to the task, cost and demonstrated capability. **No fixed model-to-role mapping, mandatory consultation, or rigid agent workflow is imposed.**

Keep independently edited scopes clear, review integrated outcomes, and record material delegation/verification in the normal GitHub Handoff. Do not claim a model was invoked or a review completed unless it actually happened. Lack of access to one optional model should not block the gameplay milestone.

## Original v0.1 acceptance (historical baseline, superseded as product objective)

A **replayable Godot-native, solo 3D short scene**. Player moves/examines/interacts in a believable expedition environment, takes at least one meaningful observation-related action with a visible consequence, reviews available evidence and makes a judgment that another character/the world reacts to.

- **Minimum acceptance:** exact Godot version + launch command, actual runnable project/build, complete interaction path and restart, different reaction for a relevant alternate action or judgment, plus test/play evidence.
- **Not acceptance:** beautiful screenshots, a read-only history presentation, walking without a meaningful task, build green alone.
- **No need yet:** complete historical site, polished assets, full Hub, four-player networking, login, MMO infrastructure, content management system or elaborate reusable RPG foundation.
- **Autonomy:** Opus chooses player mechanics, camera, scripts, art, test approach, parallel task boundaries and feasible length; preserve the **playable action/evidence/judgment loop** and historical respect.

## How to report

At a meaningful milestone or before stopping, leave a compact comment on Issue #1:

`What actually works · commit/PR/build · how to launch/play · observed test results (incl. real gameplay) · historical/asset caveats · next highest-value step · owner/worker`.

Update this file with the latest verified state, link to playable scene/build and unfinished work. New sessions should read issue/latest main/handoff before editing. After merging a PR, re-run and verify the actual merged game before announcing completion.

## Separation from current work
- **Godot work here**: Eddington 1919 3D adventure slice.
- **Existing Web work elsewhere**: [unnamed-disease](https://github.com/nurockplayer/unnamed-disease) continues with the active Opus workstream, not interrupted by this new 3D request.
- Do not claim collaboration, ownership transfer, delegated agent runs or a build that has not actually occurred.

## History
- 2026-10-19: the reference pack was written. Opus then built v0.1 (plan, delivery and evidence are in Issue #1).
  - **Fact check:** a Sonnet 5.5 subagent checked the history used in the game.
  - **Review:** Codex (gpt-6-astra) ran a fresh, read-only review; its findings were fixed in `f107a85`.
  - **Not used:** gpt-6.1-sol, gpt-6-luna and haiku-5.5 were not used.
