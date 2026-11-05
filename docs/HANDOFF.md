# Game Director Handoff

**Windowed-run rule (Owner, 2026-10-25, in force now):** windowed Godot (`--always-on-top`, autoplay bots, `--shots`) blocks the middle of the Owner's screen. Run it only when someone must look at the screen or take screenshots: 1–2 routes before a milestone merge, at most. Schedule it only Mon–Fri 09:00–15:00 JST (Owner 2026-10-28 02:15 JST moved the start from 03:00; headless runs are fine at any time), never nights, evenings or weekends, and always add `--fixed-fps 60`. Everything else is headless: `orb-test --host -- ./tools/e2e_headless.sh` runs every autoplay route (`careful`/`rushed`/`cherry`, `prologue-autoplay=honest`/`tidy`/`accuse`) headless, one at a time, with a wall-clock cap and a result table; a single route is `orb-test --host -- godot --headless --path . --fixed-fps 60 -- <route args>`. Possible later option (not verified): a virtual display (BetterDisplay) with `--screen 1`.

**Test-run rule (Owner, 2026-10-25, all projects; see `orb-test --help`):** no test runs bare on the host. Wrap it in `orb-test`, run from the worktree root.
- Godot is GPU work, so it runs on the host, through the lock:
  - a single headless suite: `orb-test --host -- godot --headless --path . --script res://tests/<suite>.gd`;
  - a windowed screenshot run or Blender: `orb-test --heavy --host -- <cmd>`.
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

## Resume here (edd-lead, written 2026-11-04 08:0x JST)
- **Role:** this session is `edd-lead` (tachiko-harness #56, 2026-11-04 04:5x JST; "director" naming retired). Roles live in `.claude/pane-handoffs.tsv` (gitignored, local): `edd-lead` (w7:pA, nudge,resume) and `edd-characters` (w7:pB). The worktrees c02–c04g, ds-1…ds-4, hg-proto belong to edd-characters: leave them alone.
- **Standing Owner request (2026-11-04 00:3x JST):** keep pushing toward a Steam production release, not just answer "ready?"; hardware baseline = the most common Steam player hardware (Steam Hardware Survey, see `docs/SYSTEM_REQUIREMENTS.md`). One-shot heartbeat cron re-armed 45 min after every turn (crons are session-only: recreate after a restart).
- **Merged 2026-11-04:** #93 departure music (Owner OK), #129 Windows preset (A13), #130–#134 wave 7, #135 store-page draft (`docs/store/STORE_PAGE.md`), #136 Cambridge trial, #137/#138 coda leak + test deadlines, #139 ready status + empty-rack wait, #140 evidence stays during judgment, #143 player picks Kit's first words, #144 judgment dialogue never covers the chart + loupe off in report, #142 monkey routes. main = 290b883+. Bots careful 4 / rushed 0 / cherry 3 / prologue honest 4.
- **Section A:** all DONE except the Owner-gated A8 (B11 names) and A11 (a human plays the exported build, B10; also confirms the A12 targets on Windows).
- **In flight (2026-11-04 22:3x JST):** (c) The "1919 consequence for a missing core plan card" candidate is already done (checked 2026-11-04 23:2x JST: comparison → darkroom errand, far_stars → calibration recall, rules_first → rule prompt reminder; content.gd/main.gd). (d) #169 merged 2026-11-05 01:13 JST (oracle approve): critique-5 newcomer fixes — PREP objective states the purpose, darkroom described, night objective says rule first, title line names the question, 角秒 coin analogy in the 1919 briefing, telegram choices carry a one-line zh-TW gloss (`Judgment.telegram_choices()`), 2σ question names the chart marks (thick = ±1σ). Choice buttons autowrap. (e) #170 merged 2026-11-05 01:42 JST (oracle approve): critique-6 1917 fixes (aligned status names the clues; plan board 3–4 and a blocked bias card is really removed; accelerating-box light line; 複核 row placeholder + Kit objective; 0.3 角秒 scale). Owed by eye in a window: the longer aligned status line. **Running (2026-11-05 05:3x JST):** full e2e on main 46e562f passed 6/6 (careful 4, rushed 0, cherry 3, honest 4; tidy/accuse PREP as designed), 2026-11-05 05:30 JST. Out to `ds-edd-1` via `lead-wait run store-blink`: `--store-shots` also captures the blink pair `careful_store_g_blink_eclipse/oxford` (B5 row 7; branch `test/store-blink-shot`). #175 merged 05:50 JST (6d34fb8): `--store-shots` captures the blink pair; check by eye that the eclipse frame is not already Oxford (shot() waits for draw). Critique 8 (shell, ds-edd-2, report `~/.local/state/ds-exec/ds-edd-2-20261105-055037.log`) judged 05:5x JST: taken 1 title says where to start, 2 controls help in pause, 3 back to title, 4 pause destructive actions ask twice, 5 pad prompts on first screen, 7 title→1919 and departure→1919 fades, 8 music row honest; rejected 6 (right stick does scroll: `scripts/ui.gd:362-367`). Follow-ups not taken yet: settings on the title screen, look sensitivity / invert Y. Out: `ui/shell-polish-a` (1,4,5,7,8; ds-edd-1, `lead-wait run shell-a`) and `ui/shell-polish-b` (2,3; ds-edd-2, `lead-wait run shell-b`); briefs scratchpad `shell-a.md` / `shell-b.md`. #176 merged 06:41 JST (30833bf; oracle exit 4 → codex Sol approve). #177 merged 08:23 JST (oracle approve): pause menu 操作說明 + 回到標題 (two-step, all three scenes). Follow-ups: title-screen settings, dead music slider still focusable, look sensitivity / invert Y, pause menu at 4 px spacing → ScrollContainer if it grows. **Now (2026-11-05 18:0x JST):** #185 `ui/title-settings`: round 2 oracle blocker (test still wrote a file EDD_SETTINGS_PATH names) fixed by the lead in 2811ea4 (test always uses its own temp file, restores the env, checks the configured file unchanged). Head 49c8e7e passed title_settings 67/0, pause_help 23/0, gamepad 555/0, layout_bounds 3746/0. Verifying 2811ea4: `lw-title-test-r3-20261105-175106` (title_settings with a pre-existing settings file, sha before/after; `timeout 900` ends it ~18:06 JST because orb-test hangs in `docker rm -f` — OrbStack docker hung since ~17:4x JST, our stuck pids 18731/35721; killing them was denied before). Next: when it reports 0 failures and the same sha, `lead-wait pr 185 --scope scratchpad/scope-185.md --reason "round 3: lead fix for settings-file isolation"`; a 3rd-round blocker → lead fixes or overrides per policy. Then the windowed look Fri 2026-11-06 09–15 JST (title row 5 buttons, title settings, pause column at 1080, overlay toast backing). Codex session 01a1aaa1 (`lw-title-settings-fu1`) is still waiting on its stuck job; its PR body update is all that is left. **In flight (2026-11-05 13:4x JST):** #179 (8429100) and #180 (dbd37b4) merged. Windowed look b done 13:41 JST (main dbd37b4): darkroom viewer at 1080 now uses ~90% of the height — OK; 1917 toast at 720/1.2 clears the status line — OK, but its first line runs across the overlay panel border → `ui/overlay-toast-backing` out to DeepSeek ds-edd-1 (`lead-wait run toast-backing`, brief scratchpad `toast-backing.md`). Store rows 5–8 reshot: KIOXIA `/Volumes/KIOXIA/eddington/store-b5/careful/` (old set and look stills deleted; STORE_PAGE.md a9d6dc2). Next: gate the toast-backing PR (`lead-wait pr <n>`), then release 0.4.4 (same pattern as #173: bump 4 places + test_release_export, export 3 platforms one at a time via orb-test --host, KIOXIA builds/0.4.4 + BUILD.txt, Issue #1 note). Earlier: **Docker back 2026-11-05 12:49 JST** (ds-1/ds-2 suites running again in orb-test; was hung ~11:02–12:4x JST) (`docker ps` times out; our orb-test runs 9097/9104 stuck in `docker rm -f` after the suites passed; gteki runs stuck too). The two Codex runs wait in wait-handoff on jobs `overlay-toast-tests` / `viewer-1080-validation` (passed so far: overlay layout_bounds 1506/0, text_size 65/0; viewer text_size 65/0, gamepad 551/0). Owner asked to restart OrbStack; the jobs resume once docker answers. In flight: `lead-wait` jobs lw-overlay-toast-20261105-104802 and lw-viewer-1080-20261105-104802 (cx-exec ds-1 / ds-2 sessions 01a1a964-4ded-7512-a883-97e4f68abc85 / 01a1a964-4ded-7a23-abaf-7c50bf51c5a4, waiting in wait-handoff on job-run ids overlay-toast-tests / viewer-1080-validation); events land in `lead-inbox edd-lead`. Next: when docker answers and each PR opens, gate it (`lead-wait pr <n> --scope`); if docker stays hung past the Owner's reply, kill only our hung `docker rm -f orb-test-eddington-1919-9097/9104` after the restart, never others' runs. After both merge: reshoot store rows 5–8 in a window (Mon–Fri 09–15 JST) and consider 0.4.4. Heartbeat cron becead72 13:09 JST. **Windowed look done 2026-11-05 09:43–10:46 JST** (orb-test #500, main c31dca2; careful 1080 + store shots, careful 720/1.2, prologue honest 720/1.2; all three reached ENDING, score 4). Lead verdicts: ending at 720/1.2 fits (one button row, hint and scroll clear) — OK; title at 1080 and 720/1.2 with the #176 names and note — OK (a faint world name label shows through the dim title backdrop: minor polish, not briefed); departure checklist legend at 720/1.2 — OK; blink pair differs (eclipse crop vs Oxford) — OK as a pair or two-frame GIF, weak as a single still; **1917 overlay at 720/1.2: the arrow_tilted feedback toast's second line draws over the aligned status line** → `fix/overlay-toast-overlap` (Codex terra, ds-1, `lead-wait run overlay-toast`); **darkroom viewer at 1080p uses only the top ~60% of the screen (fixed 460 px plate, 420 px chart)** → `ui/viewer-fills-1080` (Codex terra, ds-2, `lead-wait run viewer-1080`). Briefs in scratchpad `overlay-toast.md` / `viewer-1080.md`. Store candidates `careful_store_*` (incl. new g pair) copied to KIOXIA `store-b5/careful/`; the rest deleted. Reshoot store rows 5–8 after viewer-1080 merges (next window). Not seen by eye: pause menu / 操作說明 panel (no bot still). Earlier: DeepSeek `ds-edd-1` ending-clarity (ds-exec session e0eea5ca-0961-42ac-ba80-fd3e922d66c7, log `~/.local/state/ds-exec/ds-edd-1-20261105-020447.log`, background task bnztcrv4z). Next: read its final report, open the PR if it did not, gate with `gate.sh <pr> <scope>` (copy now in scratchpad `/private/tmp/claude-501/-Users-tachikoma-Developer-eddington-1919/7cbd3d32-4ef2-4985-aac6-61626f1d467c/scratchpad/gate.sh`; write a scope file of accepted trade-offs first), then a 0.4.3 build only if the Owner has not started on 0.4.2. Heartbeat one-shot cron 69262de0 at 02:51 JST (re-arm 45 min after every turn). No other workers, no orb-test jobs of ours. (g) critique 7 (departure checklist, coda, ending) judged 2026-11-05 02:1x JST; out to `ds-edd-1` (branch `narrative/ending-clarity`, brief scratchpad `ending-clarity.md`): checklist legend says ✓ = matches; one dim line of 1919 history on the ending first screen; 「底片匣一共」 instead of 「可用底片」; 機率誤差 explained; replay buttons and hint say what a replay is. Not taken: credits AUTHOR placeholder (Owner B11), workbook/coda objective wording nits. (f) #171 merged 2026-11-05 01:58 JST: 0.4.2 playtest builds on KIOXIA builds/0.4.2 (BUILD.txt, commit 5c22ffe, SHA-256 checked by the lead; supersedes 0.4.1); Issue #1 told to play 0.4.2. Next: windowed look 2026-11-05 09–15 JST (blink #156, store rows 7/4/9, 4-column grid, the longer 1917 aligned status line, two-line-free telegram choices at 1.2 text). (a) #167 merged 2026-11-04 23:14 JST (oracle approve, scope = accepted trade-offs): Linux zip ships `Eddington1919.x86_64` + `Eddington1919.pck`; the 0.4.1 Linux zip on KIOXIA still has the old names (re-export only for the next build). (b) Monkey pass 2026-11-04 22:47 JST: 11/12; seed 1106 fixed by #168 (merged 2026-11-05 00:10 JST; oracle exit 4 → codex Sol approve): monkey `walk()` retry detours round the Cambridge table via the east lane; replays 1106/1109–1111 stuck 0. Follow-up: a future target west of the table with |z| < 1.05 could still graze it (no such call site).
- **Earlier in flight (2026-11-04 22:1x JST):** one light run, no worker: monkey pass `EDD_SETTINGS_PATH=/Volumes/KIOXIA/eddington/tmp-settings-monkey.cfg orb-test --host -- ./tools/monkey_headless.sh 12 1104 mixed` on main 2cd7087, started 22:02 JST; output `/private/tmp/claude-501/-Users-tachikoma-Developer-eddington-1919/1dfbaf4d-d976-4422-83a5-9db0957e8b8a/tasks/b47okh5bx.output` (if gone, rerun the command). Next: read it; any stall or missing ENDING → brief a fix with the seed. Merged since 21:0x JST: #165 layout-bounds suite (Deck 16:10, 720p, large text; 12-plate viewer fix, grid 4 columns), #166 0.4.1 playtest builds (macOS/Windows/Linux, `/Volumes/KIOXIA/eddington/builds/0.4.1/` with BUILD.txt; supersedes 0.4.0), uid commits 2cd7087/bf19e6d. Owner asked on Issue #1 (2026-11-04 21:16 JST): A11 play 0.4.1 start → credits; B7 checkpoints yes/no; B2 Linux/Deck. Next candidates after the monkey pass: cleaner Linux binary name (the PCK is `Eddington1919-0.4.pck` because get_basename() strips `.1-Linux`), a 1919 consequence for a missing core plan card, B5 store copy polish. Owed windowed look (Mon–Fri 09–15 JST, 2026-11-05): does the #156 blink jump read by eye; shoot store row 7 (blink); re-shoot rows 4 and 9; check the 4-column thumbnail grid looks right. Notes: cx-exec runs sometimes stall after a completed command (check log mtime, TaskStop, resume or finish by hand); GitHub SSH refused intermittently on 2026-11-04 evening, retry works; new test files need their `.uid` committed (run import, commit). Gate script: scratchpad `gate.sh <pr> [scope]` (scratchpad may be gone after a restart: it marks ready, review-bundle [--scope], review-run oracle with exit-75 wait, codex fallback, review-gate up to 3×). Codex models: terra default, luna easy, sol only when needed, astra only with Owner approval.
- **Next:** critique-2 item 2, "replay as an experiment" (compare with the previous run on the ending; touches `_show_ending`/ui ending, so after #141). Windowed look (Mon–Fri 09–15 JST, `--fixed-fps 60`): #133 reference plates/loupe, #134 telegram tableau, #140/#144 report layout, #98 whiskers; then store screenshots from the B5 shot list. test_score handoff budget is 7500 ms and main measured 6642–7369 ms at load ~15: widen or make it load-proof. Monkey follow-ups below.
- **Windowed look 2026-11-04 10:4x JST (edd-lead, renders on KIOXIA `/Volumes/KIOXIA/eddington/store-b5/`, INDEX.md there):** #133 reference overlay, #98 whiskers, #140/#144 (five-reason dialogue leaves the chart visible) all read fine. Weak: palm crowns are 8 flat planks and read as windmills/asterisks at totality (store row 4, the capsule moment) → w9d `art/palm-fronds`; loupe opens on the eclipsed sun → w9e; ending telegram tableau is mostly empty black (store row 8 weak, design pass owed); Kit/people close-ups (row 2) are the edd-characters lane. Store candidates: row 1 lightbox and rows 6–7 (reference plates, measured 2σ) are usable now.
- **Waiting on the Owner:** section B decisions (B1–B11 minus B2); A11/B10 playtest of the exported build; B11 names (A8); SFX WAVs `~/Desktop/eddington-sfx/`.
- **Worker habits to brief against:** Codex adds `--heavy` to e2e and writes to host `/tmp`; every brief forbids both. A merge that adds scripts needs `godot --headless --import` in the main checkout before suites (else they hang). Tests must not leave `user://settings.cfg` changed.
- **Shared settings.cfg (fixed by #145; found in #140):** tests and headless runs accept an absolute `EDD_SETTINGS_PATH`; e2e creates and cleans up its own worktree-local settings file unless an override is already set. Run single suites with `EDD_SETTINGS_PATH="$PWD/.godot/test-settings.cfg" orb-test --host -- godot --headless --path . --script res://tests/<suite>.gd`, choosing a different file for each concurrent run. `orb-test --host` preserves the environment. The shipped default remains `user://settings.cfg`; tests must leave it untouched.
- **Monkey routes (#142, merged 2026-11-04 07:5x JST):** `tools/monkey_headless.sh [count] [seed] [route]`, on demand, not in CI. Open: seed 12 prologue timed out at 540 s / 810 s on a host at load ~15 while still progressing; rerun `orb-test --host -- ./tools/monkey_headless.sh 1 12 prologue` on a quiet host. Review minors: `stuck_events` counts all failures (tests/prologue_bot.gd:835); runner accepts PREP as a prologue pass (tools/monkey_headless.sh:64), should require ENDING.
- **Review flow:** from the main checkout: `review-bundle <pr>` → `review-run --provider oracle` (loop on 75; exit 5 → `--provider codex`, say so in the PR) → `review-gate <pr>` (rerun once on "Auto merge is not allowed").
- **Cleanup:** remove a worktree or branch only after `gh pr view <n> --json state` says MERGED.

## Improvement program (Owner 2026-11-02 16:5x JST: 「從遊戲、音效、配樂、劇情、遊戲性、解謎各種角度持續完善遊戲」)

This lifts the "no new features before the playtest" hold. A fresh Fable design critique (2026-11-02 17:00 JST) ranked the weak spots: prologue choices return only as text, the night viewer gave away the answer key, the judgment is a 2×2 dressed as 4×4, the workbook page ignored the run, plan board/checklist are flavour, Príncipe is nearly silent, music sits off the emotional beats.

Wave 1 (2026-11-02 17:04 JST):
- #83 workbook page records the run's sky (director, own PR).
- cx-exec Sol, briefs in the session scratchpad: C `feat/viewer-reading` (ds-1: note hides quality counts until 量測, per-plate star count, quality after 量測); E `feat/totality-sfx` (ds-2: shutter open/close, plate-change foley, third-contact glint, night insects, `_sfx_log`); B `feat/rules-first` (cx-3: a rule is written before the viewer opens, `sim.rule_id`, Eddington holds the player to it in `_selection_lines`, scores unchanged, bot picks the rule).

Wave 1 merged 2026-11-02 (all through review-gate): #86 light-box foley, #87 Príncipe shutter/plate-change/third-contact/night insects, #85 rule written before measuring, #84 viewer hides quality until 量測, #83 workbook records the run's sky (3 review rounds: it may claim only what the exposures' bands saw, and a plate change only if one was made). ChatGPT stalled 17:46–18:10 JST; #83–#87 got codex fallback reviews, #83/#84's last heads got oracle approves. SFX WAVs for the Owner: `~/Desktop/eddington-sfx/` (raw level; in game −4…−26 dB). Still owed: a windowed look (Mon–Fri 09–15 JST) that plate images show trail/fog well enough now that the counts are hidden (#84).
Waves 2–3 merged 2026-11-02 18:4x–19:3x JST: #88 telegram reasons quote the player's value ± σ (grading unchanged), #89 Príncipe day surf + birds that fall quiet over 6 s at totality, #92 phase-wiring test for it, #90 darkroom viewer foley (glass plate, pencil, micrometer screw), #91 footsteps (wood in Cambridge/departure, earth at Príncipe; 7 steps per 3 s walking). Bots unchanged: careful 4 / rushed 0 / cherry 3, prologue honest 4.
Wave 4: draft #93 `departure_promise`, a 24 s one-shot under the departure sky promise (harmonium D–A fifth, viola A3 then D4 only, three high piano notes; no F#, no full motif). It stops at the montage. **Needs the Owner's ear (D014)**: `~/Desktop/eddington-music/departure_promise.wav`. Keep it draft until the Owner OKs.
Reviews: oracle-ego false stalls were fixed in oracle-ego #5 (2026-11-02 19:4x JST). New fallback rule (tachiko-harness #44): fix or restart ego-lite first, then codex (gpt-6.1-sol), sonnet last.
Wave 5 (Fable-ranked, merged 2026-11-02 20:1x–22:1x JST):
- #94: the darkroom remembers the 1917 plan board (comparison plate and far-star calibration lines).
- #95: the 150 s glance waits for thick cloud.
- #96: Kit's star-chart answer returns in the 1919 close, weighed against the telegram.
- #97: the direct ending gets the lamp-out beat.
- #98: the chart draws 2σ whiskers, and the note shows the 2σ range and Eddington's criterion. **Look at it windowed** (Mon–Fri 09–15 JST).
- #99/#100/#101: the 1917 rain eases to −30 dB in daylight and stops after the trial, even when the reader is fast; tests follow-up.
Bots unchanged: careful 4, rushed 0, cherry 3, prologue honest 4.
Lesson: delete a worker branch only after its PR shows MERGED. A remote delete closed #99; it was restored at the same sha and reopened.
Next from Fable's list: all five are done. Open: an ObjectDB leak cleanup, a composed darkroom-night cue (needs the Owner's ear), and a new design pass.
Wave 6 (depth, Fable-ranked; merged 2026-11-02 22:2x – 2026-11-03 00:4x JST):
- #102: the 1919 rule prompt recalls the player's 1917 exam answer (q1; `Story.exam`).
- #104: the `conditions` plan card adds the drive's state to each darkroom plate note.
- #103: the plan advises splitting a clear window of 14 s or more into two short plates (`Judgment.SPLIT_MIN_S`). Judgment says when good plates corroborate, each within its own 2σ of the good-only mean, and cautions on a single good plate.
- #105: a fifth telegram reason, 「數值偏低，可能是儀器，不是星」. It is right only when the drive is unchecked, the evidence is favors_half or ambiguous, the mean trail is ≥ 0.35 and the value is < 1.75″. Every wrong case has its own true line. No bot route picks it; test_totality drives it through the real judgment path.
- #106 follow-up: when nothing is measured.
Oracle rounds caught 4 real logic bugs in #103/#105. Scores unchanged: careful 4, rushed 0, cherry 3, honest 4.
w8a: test_coda samples simulated tween progress, checks paused properties across frames, and awaits completion instead of wall-clock fade deadlines.
w8a: the 1919 scene now stops ambient audio and its held cinematic/audio tweens on exit, as Cambridge already does for audio. Historical ObjectDB leak noise did not reproduce on Godot 4.7.2: verbose totality, text_size, plate_reading, coda, careful autoplay and ordinary game exit all reported zero leaked instances before the cleanup; before/after counts are in the PR. The full validation did reproduce a WAV/playback pair in test_gamepad after it freed UI and quit immediately; its teardown now drains AudioServer like test_coda.
Full e2e on main fd0a02a, 2026-11-03 00:47 JST (Owner one-off heavy authorization; run light, ticket #140 cancelled): all 6 routes pass, 4/0/3/honest 4.
Wave 7 (Codex gpt-6-astra critique, 2026-11-03 00:50 JST; cx-exec Sol dispatched 00:5x JST, briefs in the session scratchpad): A `feat/coda-honest` (coda no longer says "only cloud grey" or praises a fit-0 telegram when usable plates went unmeasured), B `feat/interval-read` (one ungraded question: what does your 2σ range contain? before the telegram; bot answers it), C `feat/split-advice` (the 14 s split advice becomes "shoot short, change, shoot again if still clear"). Merged 2026-11-03 01:0x–01:26 JST: #107 (C), #108 (A), #109 (B; 3 oracle rounds: rounding vs exact classification, and "neither contained" contradicting the ambiguous reaction → `Judgment.interval_bounds`/`interval_holds_neither`). Follow-up D `fix/viewer-interval` (cx-exec Terra, 01:3x JST): darkroom note uses `Judgment.interval_bounds` so both ranges match at edges. Workers keep defaulting to `--heavy` and host `/tmp`; briefs now forbid both.
Rejected from the critique: fading the 1917 rain at daylight (#99/#100 chose −30 dB on purpose); a recovery task for a missing comparison card (larger, later).
Next candidates: the daylight interlude cue in 1917, a 1919 consequence for a missing core plan card, the ObjectDB leak cleanup, and the windowed look for #84 (Mon–Fri 09–15 JST).

Wave 2 candidates (after wave 1 merges): data-driven judgment reasons citing the player's own value ± σ (judgment.gd REASONS/_reason_line); Príncipe day ambience (surf, birds that fall quiet before totality and return after); 1917 light-box and footstep foley; daylight interlude ducks the rain cue (director.gd `_interlude`/`_coda`, mind `_gramophone_end`); new composed cues for the departure promise and the darkroom night (needs Owner listening, WAVs on Desktop); a plan-board consequence in 1919 for a missing core card. Rejected: re-scarcing plates (history: 16 plates in 302 s).

## Director backlog (edd-director) | 2026-10-30 09:29 JST

Characters (HG / c01–c04) are owned by the session eddington-1919-6c. edd-director stays off them.

Decoration round 2 is done: no Director PR is open.
- Integration run of all seven open branches (orb-test #27, 2026-10-30 07:36 JST): GREEN. Every suite and all 6 e2e routes passed.
- Windowed look 2026-10-30 09:07 JST (16 stills, sent to the Owner).
- Merged: #61 darkroom lantern, #65 window rain, #66 palm sway, #41 night sky, #40 lamp dust, #53 diamond ring.
  - #40 got a fix after oracle: `visibility_aabb` covers the drift volume.
  - #53 got a fix after the windowed look: the tween's darkness eases back as `1 - v^2`, so the Moon is black and the sky dark at the diamond. A test checks darkness > 0.9 at the peak.
- #50 shadow bands: closed, not merged.
  - The windowed look showed zebra stripes. The look was softened, but oracle then found the cloud gate keeps them at zero in every real run: the cloud bank covers both last-sliver moments.
  - That matches the record (clouded Príncipe), so they stay out. See the PR comment.
- Re-shoot of the totality view on main (diamond ring after the fix): orb-test #39, queued 2026-10-30 09:11 JST. The script waits for 09:00 and skips after 15:00 JST. Stills go in the scratchpad `look3/`; delete them after judging.

Follow-ups, all closed: lens reset (`_frame_speaker`), test_score flake (#43), coda sky (covered by #41), bridge_pause leak (#64).
- bot 「完成計畫」 flake: #55 logs the cause on a miss; no miss seen since.

Windowed look 3 (orb-test #39, ran 2026-10-30 ~14:00 JST, 13 stills, sent to the Owner):
- #68 orrery: reads well and the arms turn. Merged 2026-10-30 14:35 JST.
- Diamond ring after #53's fix: the Moon is black and the bead burns. Good.
- #67 fireflies: 5 cm sprites showed as single dim pixels. f34f36c makes them 16 cm, x2.2 over-bright, with longer blinks, plus a test (15/0). Oracle re-review is running; the PR stays a draft until a windowed look.

New draft #69: shooting stars on the night after (meteors). The test passes 14/0. Oracle review started 2026-10-30 15:50 JST.

#70 (Issue #37 loop 1, the orrery tells of Mercury's 43″) merged 2026-10-30 20:30 JST as e9ae232. It passed an oracle approve after a hotspot ray fix, and an integration run of #67, #69 and #70 (orb-test #48): GREEN, 22 suites and 6 e2e routes. #71 merged 2026-10-30 23:30 JST as bc436fd: once the player has examined the orrery, the mentor gives Mercury a fair hearing in two lines of the Dyson scene. e2e GREEN, prologue 278/0. Merged 2026-10-31 04:30 JST: #72, loop 2 (Eddington's closed box in the exam, 5 lines + 1 choice, 68e8f25), and #73, loop 3 (on departure night Ashby works the box again with light; no real box could show it, f9f6ab9).
- Both were fact-checked by Sonnet: it is Einstein's own chest, pulled by a rope (1917 book); "lift" is avoided; the box gives no number, so 1.75″ stays with the full theory.
- e2e GREEN, and each PR got an oracle approve after a minor test fix.
- Loop 4 (eclipse predictions 0 / 0.87 / 1.75) was already in content.gd. Loop 5 merged 2026-10-31 11:45 JST as #74 (6f00d94). In the Príncipe coda, after the loupe, plate 14's residual (if it was found; read from Story.clues), Eddington's box and tonight's small numbers come back; none of them is called proof, and "no numbers is still a record".
- e2e: the single `prologue honest` route, the only one that reaches the coda, ran light because the heavy queue was stuck behind a 7.5 h job.
- All five #37 loops now exist in their smallest form. All are proposals; the next step is the Owner's reaction.

New draft #75 (2026-10-31 13:00 JST): the departure-night sash shows the real north sky of 1919-03-07 21:00 GMT (Cassiopeia, Polaris, the Plough, with the pointers aimed at Polaris). Oracle approved head 6a5419c after a test fix (magnitude drives size and strength).

State 2026-10-31 16:30 JST: nothing of edd-director is running. The 3 drafts #67, #69 and #75 all have an oracle approve on their current heads and wait only for the Monday windowed look. For each good one: `gh pr ready`, then `review-gate` (rerun once on "auto merge not allowed"). All 5 loops of #37 are merged as proposals and await the Owner's reaction.

Monday 2026-11-02 re-shoot (night + departure groups: #67 fireflies, #69 meteors, #75 north sky; the stills `night_meteor` and `departure_window_stars`):
- A session cron fires at 08:37 JST. Light prep: `orb-test --host -- bash <scratchpad>/look_prep.sh`, which merges main + art/fireflies + art/night-meteors + art/departure-north-sky and imports. Then the heavy shoot: `orb-test --heavy --host -- bash <scratchpad>/windowed_r3.sh <scratchpad>/look3`.
- The shoot waits for 09:00 JST, quits after 15:00 JST, and deletes the worktree. If the session is gone, run both steps by hand.

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
- **Automated routes:** headless by default: `orb-test --host -- ./tools/e2e_headless.sh` (all six routes) or `orb-test --host -- godot --headless --path . --fixed-fps 60 -- --prologue-autoplay=honest|tidy|accuse`. Add `--shots=DIR` (windowed) only for screenshots.
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
  - E2E (default): `orb-test --host -- ./tools/e2e_headless.sh` — every autoplay route, headless, one Godot at a time, table + non-zero exit on failure.
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

## Music plan A (edd-director) | 2026-10-31 19:20 JST

#76 merged on 2026-10-31. The Owner listened to the three cues and approved them. `cambridge_rain`, `departure_motif` and `coda_resolution` now play composed, sample-rendered OGGs (`assets/music/`). The totality layers stay synthesized, and the synthesis is the fallback when an OGG is missing. Decision: [D014](DECISIONS.md).
- Levels are matched to the old synthesis RMS: −38.5 / −38.5 / −34 dB (`Score.SAMPLED_DB`).
- Suites passed headless: test_score 105/0, test_departure 220/0, test_coda 73/0, and honest prologue autoplay reached ENDING with clean cue checks. The oracle review approved (0 blockers).
- **Not run yet:** the full e2e (heavy window closed on the weekend). Run it Monday with the #67/#69/#75 integration run. Not verified: in-context listening against the rain bed (−38.5 dB may be too quiet; ask the Owner after a windowed run).
- To re-render: `tools/music/setup_libs.sh` (libraries on KIOXIA `soundfonts/`), then `render_cambridge.sh` or `render_cue.sh <cue>`. Rendering is Python (`sfz_render.py`); sfizz was dropped. Follow-ups: #77 (pin the libraries, strict OGG checks, SFZ last-section bug).
- The Owner listens from WAV copies in `~/Desktop/eddington-music/` (macOS cannot play OGG).
- #78 merged 2026-10-31 (closes #77): libraries pinned, `check_cue.py --strict` gates renders (per-channel peak), SFZ EOF fix; cambridge loop re-rendered at peak 0.495 (−0.03 dB).
- Music round 2 = draft PR #79 `feat/gramophone` (worktree ds-2): a 1915 Victor record ("Keep the Home-Fires Burning", LoC jukebox-15093, rights cleared, Sonnet fact-checked text) on a table-top gramophone by the east wall of the 1917 room; the score ducks while it plays. Suites: gramophone 55/0, prologue 280/0, departure 220/0, score 105/0, honest ENDING. **Monday 2026-11-02 09:00+ JST windowed look** (placement at (3.95,0,−0.25), silhouette, spin, record level −16 dB vs rain) → then review-gate (oracle approved head 246e9c4 on 2026-10-31 20:13 JST; its remaining major — real audio fade/stop on the montage — is exactly what the windowed look must hear). Spec: docs/design/GRAMOPHONE.md. Owner may comment on the 77 s trim (WAV on Desktop).
- 2026-10-31 20:50 JST: the Monday shoot now covers the gramophone. `look_prep.sh` also merges `feat/gramophone` (merge-tree dry run: clean) and applies `gramophone_shots.patch` (two stills, `study_gramophone` placement + `study_gramophone_disc`, verified headless: view ready). `windowed_r3.sh` runs `--only=study,night,departure`. The patch lives in the scratchpad only, so PR #79's approved head 246e9c4 stays put. The fade/stop on the montage still needs ears in a played run, not stills.
- 2026-11-02 04:40 JST (edd-director af055252, back in herdr w7:pA): two reboots (2026-11-01 ~12:20 JST and 2026-11-02 ~03:35 JST) lost the session crons and the scratchpad scripts. Rebuilt them on KIOXIA `eddington-1919-cache/director/` (`look_prep.sh`, `windowed_r4.sh`, `monday_chain.sh`; the gramophone stills are now an in-script edit of the temp tree, no patch file). Prep ran 04:34 JST: tree `/private/tmp/edd-look-r4` = main + #67 + #69 + #75 + #79, import ok, 16 views ready headless. Detached `monday_chain.sh` (log `monday_chain.log`) queues the heavy shoot at 08:45 JST → stills in `director/look4/` (one-off: delete after judging), then the characters lane's `c04_windowed_r4.sh` (its own chain died in the reboot). If the chain is gone: run `orb-test --heavy --host -- bash $D/windowed_r4.sh $D/look4` by hand (rerun `look_prep.sh` first if `/private/tmp/edd-look-r4` is missing).
- Sessions: kept edd-director (w7:pA) and the characters lead (w7:pB). Closed the idle Asset Factory pane (b1d5a931, idle since 2026-10-25, waiting only on the Owner's Meshy approval for #15); resume with `claude --resume b1d5a931-5898-43ff-81f5-32c41e6ed600` from `.claude/worktrees/asset-factory-eddington-pilot-1822c7` when the Owner approves.
- 2026-11-02 09:45 JST: Monday look done (09:00 JST, 15 stills, judged by the director, originals deleted). Merged through review-gate: #67 fireflies, #75 north sky, #79 gramophone (its open major was answered by a windowed CoreAudio measurement: the Master peak goes from -43.6 dB on rain alone to -32.3 dB with the record; the player is mid-fade at 0.4 s after `_montage()` and stopped at 0.8 s; details in a PR comment), #69 meteors (conflicted with #67 in main.gd / look_shots.gd, fixed as the union in eec39bb, new oracle approve; its major about the shader uniform test is covered by the `night_meteor` still). Full e2e on main d3bb69d: all 6 routes passed (orb-test #102).
- **v0.2 playtest build** for the Owner: `~/Desktop/eddington-v0.2/Eddington1919-v0.2-macOS.zip` (main d3bb69d, exported headless; the exported app boots headless with 0 errors) plus `試玩重點.md`, which says what to look at: the #37 loops, the music and gramophone, the decorations. Next director step = turn the Owner's playtest reactions into the next round. Until they come: no new features. Small follow-ups: none queued.
- 2026-11-02 10:52 JST: the #69 follow-up is done. #81 + #82 (de49933) make `tests/test_night_meteors.gd` check that every lit frame's `meteor_head`/`meteor_tail` uniforms match the meteor (0 stale frames); revert-checked (no head push, no tail push, first meteor only: all fail). Oracle approved both. Gotcha: run suites as `--script res://tests/<suite>.gd`; `-s tests/<suite>.gd` printed results and then hung at quit. No Owner comments on #37/#1 since the v0.2 build; still waiting on the playtest.
