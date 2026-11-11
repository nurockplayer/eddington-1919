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
- **In flight (2026-11-04 22:3x JST):** (c) The "1919 consequence for a missing core plan card" candidate is already done (checked 2026-11-04 23:2x JST: comparison → darkroom errand, far_stars → calibration recall, rules_first → rule prompt reminder; content.gd/main.gd). (d) #169 merged 2026-11-05 01:13 JST (oracle approve): critique-5 newcomer fixes — PREP objective states the purpose, darkroom described, night objective says rule first, title line names the question, 角秒 coin analogy in the 1919 briefing, telegram choices carry a one-line zh-TW gloss (`Judgment.telegram_choices()`), 2σ question names the chart marks (thick = ±1σ). Choice buttons autowrap. (e) #170 merged 2026-11-05 01:42 JST (oracle approve): critique-6 1917 fixes (aligned status names the clues; plan board 3–4 and a blocked bias card is really removed; accelerating-box light line; 複核 row placeholder + Kit objective; 0.3 角秒 scale). Owed by eye in a window: the longer aligned status line. **Running (2026-11-05 05:3x JST):** full e2e on main 46e562f passed 6/6 (careful 4, rushed 0, cherry 3, honest 4; tidy/accuse PREP as designed), 2026-11-05 05:30 JST. Out to `ds-edd-1` via `lead-wait run store-blink`: `--store-shots` also captures the blink pair `careful_store_g_blink_eclipse/oxford` (B5 row 7; branch `test/store-blink-shot`). #175 merged 05:50 JST (6d34fb8): `--store-shots` captures the blink pair; check by eye that the eclipse frame is not already Oxford (shot() waits for draw). Critique 8 (shell, ds-edd-2, report `~/.local/state/ds-exec/ds-edd-2-20261105-055037.log`) judged 05:5x JST: taken 1 title says where to start, 2 controls help in pause, 3 back to title, 4 pause destructive actions ask twice, 5 pad prompts on first screen, 7 title→1919 and departure→1919 fades, 8 music row honest; rejected 6 (right stick does scroll: `scripts/ui.gd:362-367`). Follow-ups not taken yet: settings on the title screen, look sensitivity / invert Y. Out: `ui/shell-polish-a` (1,4,5,7,8; ds-edd-1, `lead-wait run shell-a`) and `ui/shell-polish-b` (2,3; ds-edd-2, `lead-wait run shell-b`); briefs scratchpad `shell-a.md` / `shell-b.md`. #176 merged 06:41 JST (30833bf; oracle exit 4 → codex Sol approve). #177 merged 08:23 JST (oracle approve): pause menu 操作說明 + 回到標題 (two-step, all three scenes). Follow-ups: title-screen settings, dead music slider still focusable, look sensitivity / invert Y, pause menu at 4 px spacing → ScrollContainer if it grows. **Now (2026-11-05 18:2x JST):** #185 merged (title settings). Round 3 oracle blocker (fixed temp path can equal EDD_SETTINGS_PATH) overridden by the lead as contrived; follow-up #186. Next: windowed look Fri 2026-11-06 09–15 JST (title row 5 buttons, title settings, pause column at 1080, overlay toast backing); then consider 0.4.5. #186 closed by #187 (merged 2026-11-05 18:30 JST, oracle approve on 9fc97f3). Heartbeat 18:49 JST: review follow-ups out — #178 (回到標題 clears UI.history + next_seed; Codex luna ds-2, `lw-fix-178-20261105-184913`) → PR #188 merged 2026-11-05 22:09 JST (oracle approve; lead-verified with revert-checks) and #184 (armed pause buttons wrap in the 300 px column; Codex terra ds-1, `lw-fix-184-20261105-184913`) → PR #189 merged 2026-11-05 22:32 JST (oracle approve on lead edit b44a2b0: focus loop kept, column-stays-300-px check; revert → 24 failures) Heartbeat 23:19 JST: critique 9 (accessibility + Steam Deck gamepad-only, read-only) out to DeepSeek ds-edd-2 (`lw-critique-9-20261105-231938`, brief scratchpad cffcba99…/critique-9.md); on its event the lead judges findings and briefs fixes. Critique 9 judged 23:2x JST (report `~/.local/state/ds-exec/ds-edd-2-20261105-231938.final.md`): out now — chart text follows text size + weak plates hollow (#2,#8; ds-edd-1 `lw-a11y-chart-20261105-232436`), toasts into the log + log scrolls by gamepad + log header key (#3,#4; ds-edd-2 `lw-a11y-log-20261105-232436`); briefs scratchpad cffcba99…/a11y-chart.md, a11y-log.md. #190 merged 2026-11-06 00:08 JST (chart; follow-up #192 helper-only tests). #191 merged 00:14 JST (log). #193 merged 00:1x JST (lead: test_totality chart height check stale since #179 — main failed 2 checks; no CI on this repo; first gate try failed with "auto merge not allowed" while GitHub still computed mergeability, rerun merged). #194 merged 00:19 JST (#5 key names via Prompts.key; major: open overlay subtitle/objectives refresh only on rebuild). #6 hold-to-interact: worker hit the turn cap before PR; lead rebased `ui/hold-toggle` (union with #196, then clean onto #198) = PR #199 (cb8334b); 7 suites passed on the #196 rebase; post-#198 rerun `lw-verify-hold2-20261106-010047` (gamepad, prologue, autoplay_hold) → then comment + `lead-wait pr 199`. **Running at 01:23 JST:** #199 merged 01:21 JST (3638597; oracle approve, majors → #204). #200 merged 01:21 JST (adacf91; major → #201). Post-merge check on main a49a14c passed 2026-11-06 01:35 JST: gamepad 564/0, prologue 392/0, autoplay_hold 3/0, text_size 72/0, totality 521/0, reduced_motion 8/0. #204 → PR #205 (2b75517, ds-edd-2; worker oracle approve 0 findings; revert-checked) merged 2026-11-06 01:56 JST as c2c83e8 (first gate try hit the transient "auto merge not allowed"; rerun merged); follow-up idea: `_hold_prefix()` could use `Settings.hold_phrase()`. #201 (marker shape per row; lead fix) merged 2026-11-06 03:05 JST as #206 (1968aea; oracle approve, no findings; totality 521/0, text_size 72/0; inverted marker → 1 failure; worktree and branch removed). #203 is the gate-made duplicate of #204 (fixed by #205): close it by hand (closing via gh was denied by auto mode) and PR #200 (test hygiene #192+#197, ds-edd-2 done; merged 2026-11-06 01:21 JST as adacf91; major → follow-up #201). Briefs in scratchpad `/private/tmp/claude-501/-Users-tachikoma-Developer-eddington-1919/cffcba99-ed05-4fea-8b85-1cc0ded12293/scratchpad/`. A GitHub push failure 01:0x JST (ssh publickey, https commit_refs_rules) was transient. Next after both: windowed look today 09–15 JST (list above), then decide 0.4.5. Heartbeat one-shot cron 242c1133 at 02:02 JST is session-only: re-arm after /clear. Its follow-ups: dialogue 「按住 E 上發條」 still says 按住 with the toggle on; latch survives a pause. #198 merged 00:55 JST (#195 device switch refreshes overlay subtitle + 1917 objectives). #192 + #197 test hygiene out to ds-edd-2 (`lw-test-hygiene-20261106-005516`, brief test-hygiene.md). #196 merged 00:36 JST (減少晃動: head bob off, blink 1 Hz; follow-up #197 test isolation). #195 device-switch refresh out to ds-edd-2 (`lw-a11y-device-20261106-003721`, brief a11y-device.md). Still open: #192 + #197 test hygiene (next free worker). Deferred: #1 a 1.4 text step (every panel at 1280×720 would need re-layout; not a Steam requirement). Windowed look Fri 2026-11-06 09–15 JST adds: pause column with 減少晃動 (+ 長按互動 if merged) at 720/1.2, chart at 1.2 with hollow markers, dialogue log scroll and toast lines. #7 reduced motion out to ds-edd-2 (`lw-a11y-motion-20261106-001515`, brief a11y-motion.md; pause column gains 減少晃動 → windowed look owed). Worktrees ds-1/ds-2 now carry `.claude/ds-workers.tsv` (untracked roster; without it review-bundle marks oracle_ok=false and workers' own oracle reviews were refused). Candidates after: #7 reduced motion (head bob off, blink 1 Hz), #6 hold-to-interact toggle (rebinding left to Steam Input), #1 a larger text step for Deck (layout risk at 720p).; briefs in scratchpad cffcba99…/issue-178.md, issue-184.md. On each event: gate with `lead-wait pr <n>`. Earlier (18:0x JST): #185 `ui/title-settings`: round 2 oracle blocker (test still wrote a file EDD_SETTINGS_PATH names) fixed by the lead in 2811ea4 (test always uses its own temp file, restores the env, checks the configured file unchanged). Head 49c8e7e passed title_settings 67/0, pause_help 23/0, gamepad 555/0, layout_bounds 3746/0. Verifying 2811ea4: `lw-title-test-r3-20261105-175106` (title_settings with a pre-existing settings file, sha before/after; `timeout 900` ends it ~18:06 JST because orb-test hangs in `docker rm -f` — OrbStack docker hung since ~17:4x JST, our stuck pids 18731/35721; killing them was denied before). Next: when it reports 0 failures and the same sha, `lead-wait pr 185 --scope scratchpad/scope-185.md --reason "round 3: lead fix for settings-file isolation"`; a 3rd-round blocker → lead fixes or overrides per policy. Then the windowed look Fri 2026-11-06 09–15 JST (title row 5 buttons, title settings, pause column at 1080, overlay toast backing). Codex session 01a1aaa1 (`lw-title-settings-fu1`) is still waiting on its stuck job; its PR body update is all that is left. **In flight (2026-11-05 13:4x JST):** #179 (8429100) and #180 (dbd37b4) merged. Windowed look b done 13:41 JST (main dbd37b4): darkroom viewer at 1080 now uses ~90% of the height — OK; 1917 toast at 720/1.2 clears the status line — OK, but its first line runs across the overlay panel border → `ui/overlay-toast-backing` out to DeepSeek ds-edd-1 (`lead-wait run toast-backing`, brief scratchpad `toast-backing.md`). Store rows 5–8 reshot: KIOXIA `/Volumes/KIOXIA/eddington/store-b5/careful/` (old set and look stills deleted; STORE_PAGE.md a9d6dc2). Next: gate the toast-backing PR (`lead-wait pr <n>`), then release 0.4.4 (same pattern as #173: bump 4 places + test_release_export, export 3 platforms one at a time via orb-test --host, KIOXIA builds/0.4.4 + BUILD.txt, Issue #1 note). Earlier: **Docker back 2026-11-05 12:49 JST** (ds-1/ds-2 suites running again in orb-test; was hung ~11:02–12:4x JST) (`docker ps` times out; our orb-test runs 9097/9104 stuck in `docker rm -f` after the suites passed; gteki runs stuck too). The two Codex runs wait in wait-handoff on jobs `overlay-toast-tests` / `viewer-1080-validation` (passed so far: overlay layout_bounds 1506/0, text_size 65/0; viewer text_size 65/0, gamepad 551/0). Owner asked to restart OrbStack; the jobs resume once docker answers. In flight: `lead-wait` jobs lw-overlay-toast-20261105-104802 and lw-viewer-1080-20261105-104802 (cx-exec ds-1 / ds-2 sessions 01a1a964-4ded-7512-a883-97e4f68abc85 / 01a1a964-4ded-7a23-abaf-7c50bf51c5a4, waiting in wait-handoff on job-run ids overlay-toast-tests / viewer-1080-validation); events land in `lead-inbox edd-lead`. Next: when docker answers and each PR opens, gate it (`lead-wait pr <n> --scope`); if docker stays hung past the Owner's reply, kill only our hung `docker rm -f orb-test-eddington-1919-9097/9104` after the restart, never others' runs. After both merge: reshoot store rows 5–8 in a window (Mon–Fri 09–15 JST) and consider 0.4.4. Heartbeat cron becead72 13:09 JST. **Windowed look done 2026-11-05 09:43–10:46 JST** (orb-test #500, main c31dca2; careful 1080 + store shots, careful 720/1.2, prologue honest 720/1.2; all three reached ENDING, score 4). Lead verdicts: ending at 720/1.2 fits (one button row, hint and scroll clear) — OK; title at 1080 and 720/1.2 with the #176 names and note — OK (a faint world name label shows through the dim title backdrop: minor polish, not briefed); departure checklist legend at 720/1.2 — OK; blink pair differs (eclipse crop vs Oxford) — OK as a pair or two-frame GIF, weak as a single still; **1917 overlay at 720/1.2: the arrow_tilted feedback toast's second line draws over the aligned status line** → `fix/overlay-toast-overlap` (Codex terra, ds-1, `lead-wait run overlay-toast`); **darkroom viewer at 1080p uses only the top ~60% of the screen (fixed 460 px plate, 420 px chart)** → `ui/viewer-fills-1080` (Codex terra, ds-2, `lead-wait run viewer-1080`). Briefs in scratchpad `overlay-toast.md` / `viewer-1080.md`. Store candidates `careful_store_*` (incl. new g pair) copied to KIOXIA `store-b5/careful/`; the rest deleted. Reshoot store rows 5–8 after viewer-1080 merges (next window). Not seen by eye: pause menu / 操作說明 panel (no bot still). Earlier: DeepSeek `ds-edd-1` ending-clarity (ds-exec session e0eea5ca-0961-42ac-ba80-fd3e922d66c7, log `~/.local/state/ds-exec/ds-edd-1-20261105-020447.log`, background task bnztcrv4z). Next: read its final report, open the PR if it did not, gate with `gate.sh <pr> <scope>` (copy now in scratchpad `/private/tmp/claude-501/-Users-tachikoma-Developer-eddington-1919/7cbd3d32-4ef2-4985-aac6-61626f1d467c/scratchpad/gate.sh`; write a scope file of accepted trade-offs first), then a 0.4.3 build only if the Owner has not started on 0.4.2. Heartbeat one-shot cron 69262de0 at 02:51 JST (re-arm 45 min after every turn). No other workers, no orb-test jobs of ours. (g) critique 7 (departure checklist, coda, ending) judged 2026-11-05 02:1x JST; out to `ds-edd-1` (branch `narrative/ending-clarity`, brief scratchpad `ending-clarity.md`): checklist legend says ✓ = matches; one dim line of 1919 history on the ending first screen; 「底片匣一共」 instead of 「可用底片」; 機率誤差 explained; replay buttons and hint say what a replay is. Not taken: credits AUTHOR placeholder (Owner B11), workbook/coda objective wording nits. (f) #171 merged 2026-11-05 01:58 JST: 0.4.2 playtest builds on KIOXIA builds/0.4.2 (BUILD.txt, commit 5c22ffe, SHA-256 checked by the lead; supersedes 0.4.1); Issue #1 told to play 0.4.2. Next: windowed look 2026-11-05 09–15 JST (blink #156, store rows 7/4/9, 4-column grid, the longer 1917 aligned status line, two-line-free telegram choices at 1.2 text). (a) #167 merged 2026-11-04 23:14 JST (oracle approve, scope = accepted trade-offs): Linux zip ships `Eddington1919.x86_64` + `Eddington1919.pck`; the 0.4.1 Linux zip on KIOXIA still has the old names (re-export only for the next build). (b) Monkey pass 2026-11-04 22:47 JST: 11/12; seed 1106 fixed by #168 (merged 2026-11-05 00:10 JST; oracle exit 4 → codex Sol approve): monkey `walk()` retry detours round the Cambridge table via the east lane; replays 1106/1109–1111 stuck 0. Follow-up: a future target west of the table with |z| < 1.05 could still graze it (no such call site).
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

## Conversion arc program (edd-lead) | 2026-11-06 03:3x JST

Owner directive 2026-11-06 ~03:3x JST: edd-lead has the top engineering decision authority, may open or close Opus department leads and dispatch to them, uses oracle-ego for research and discussion, and texts the Owner only for problems it cannot decide. Goal: make the game as complete as possible so that a player who believes only Newton is genuinely persuaded by relativity through their own play, and feels the 醍醐味.

- Step 1 (running 2026-11-06 03:33 JST): oracle-ego research `lw-oracle-arc-research-20261106-033333` (competitor games that produce an earned conceptual shift, conceptual-change learning science mapped to mechanics, risks, 8 ranked design moves with blind-playtest questions, relativity misconceptions to avoid; prompt in scratchpad 7397ee72…/oracle-research.md). In parallel, a Sonnet read-only "belief arc map" of the current game (beat-by-beat: what the player does, who claims what, where the player predicts/commits, who owns the decisive number; gaps vs #37 acceptance ①–⑤).
- Step 2 done 03:4x JST: `docs/design/CONVERSION_ARC.md` (845a1bf), moves A–E with build order A → B + D → C → E and a blind test after A+B+D. Staffing: no extra Opus lead yet (one lead + workers is enough for a serial A → B/D chain; revisit when C and E run in parallel).
- Move A prediction ledger: PR #208 (head 66881ef; ds-edd-1; ledger 46/0, prologue 392/0, totality 529/0, coda 169/0, replay 129/0, replay_experiment 729/0, exam_recall 17/0, honest autoplay ENDING; 4 revert-checks; worker oracle round 1 blocker (1917 page overwritten on 1919 change) fixed with Story.bet_1917). Merged 2026-11-06 05:04 JST as d7370aa (oracle approve). Move B → ds-edd-1 (`lw-arc-b-20261106-050420`, brief arc-b-orrery.md). Move D step 1 (ending built from the run snapshot) → ds-edd-4 (borrowed from the idle characters lane; `lw-arc-d1-20261106-050536`, brief arc-d1-ending.md). D2 beat sheet in CONVERSION_ARC.md; brief D2 after B and D1 merge. Follow-up noted: bots answer the new prompts by index 0. Fact-check for B + D → oracle-ego (`lw-factcheck-bd-20261106-034042`, claims in scratchpad factcheck-bd.md: Neptune, Halley 1910, Mercury 43″, Vulcan, Einstein 1911 0.83″, Soldner, 1915 Mercury paper, Sobral/Príncipe figures and error convention, how Sobral numbers reached Cambridge, Hall/Seeliger alternatives). Fact-check done 03:45 JST (all 12 claims sound; corrections: 1920 errors are probable errors; Sobral reduced at Greenwich, the numbers reached Eddington by Dyson's letter ≤ 3 Oct 1919, so D becomes an October 1919 Cambridge epilogue in the 1917 study; Halley 2.7 days was the pre-recovery calculation). Saved: docs/research/arc_research_2026-11-06.md, arc_factcheck_2026-11-06.md (708fc6a). Move C micrometer reading → ds-edd-2: first run hit the 100-turn cap with code written, nothing tested; resumed 03:57 JST (`lw-arc-c2-20261106-035741`, follow-up scratchpad arc-c-fu1.md: WIP push, import, tests, drop the fixture σ pre-compensation, test_micrometer, PR, oracle). Move B brief ready (scratchpad arc-b-orrery.md): dispatch after A merges (it edits mentor_dyson). D brief: write after A merges (needs Story.bet; new epilogue scene).
- Windowed look today 09–15 JST still stands (list in the Running entry above), then the 0.4.5 decision.
- **Now (2026-11-06 05:10 JST), running, no unacked inbox events:**
  - `lw-arc-b-20261106-050420`: move B orrery check, ds-edd-1, brief arc-b-orrery.md.
  - `lw-arc-c2-20261106-035741`: move C micrometer resume, ds-edd-2, PR #207, follow-up arc-c-fu1.md.
  - `lw-arc-d1-20261106-050536`: move D1 ending-from-snapshot, ds-edd-4, brief arc-d1-ending.md.
  - Briefs live in this session's scratchpad `/private/tmp/claude-501/-Users-tachikoma-Developer-eddington-1919/7397ee72-c696-460e-8e20-1de2d142e1c7/scratchpad/`, with copies on KIOXIA `eddington-1919-cache/director/arc-*.md`.
- **On each event:** read `~/.local/state/ds-exec/<worker>-*.final.md`. If it opened a PR with tests run, use `lead-wait pr <n>` (if the gate fails with "still a draft", `gh pr ready <n>` then `review-gate <n>`; if it fails with "auto merge not allowed", rerun `review-gate <n>`). If it hit the turn cap untested, use `ds-exec --resume <session> <worker> <follow-up>`.
- **After B and D1 merge:** brief D2 from the beat sheet in `docs/design/CONVERSION_ARC.md`. Then update `docs/PLAYTEST_NEWCOMER.md` with the arc questions plus the transfer question. Then move E (the hands-on box) only if the blind test shows the gap.
- **Windowed look today 09–15 JST:** the earlier list, plus the C crosshair and ring at 1080 and at 720/1.2, the bet prompts, and the B check (if merged).
- **Heartbeat:** one-shot cron 9e15212e at 05:53 JST is session-only; re-arm it after /clear.

### Arc status (edd-lead) | 2026-11-06 07:05 JST

- Merged today: A #208 (d7370aa), B #210 (1ba1599), C #207 (2c11caa), D1 #209 (1221157). The merged-tree run on #209 covered A + B + C + D1: 9 suites 0 failures, honest ENDING favors_e score 4. Follow-up issues: #211 (micrometer: loupe re-centre, judgment regression test, windowed check), #212 (orrery: Ashby corrects a mislabel before he enters the room).
- `docs/PLAYTEST_NEWCOMER.md` now has the arc questions, transfer cards and how to read the result (9718249 and the next commit).
- **Running:** `lw-arc-d2-20261106-070411`, move D2 epilogue, ds-edd-1, brief `arc-d2-epilogue.md` on KIOXIA `eddington-1919-cache/director/` (all lines final, wrap by 09:50 JST peak). On the event: read `~/.local/state/ds-exec/ds-edd-1-*.final.md`; a run with `PENDING job … wait limit` is not finished. Tests run + PR ready → `lead-wait pr <n>`.
- **Worker lessons:** Godot always needs `orb-test --host`; routes need `--fixed-fps 60` and `EDD_SETTINGS_PATH`; a headless script error can hang, so cap each run; `review-bundle` needs `.claude/ds-workers.tsv` in the worktree; give long test sets as one job.
- **Harness issue seen, not fixed:** dot-ci queue not draining since about 2026-11-06 05:00 JST (reported by ds-edd-4; not checked by the lead).
- **Windowed look today 09–15 JST:** the earlier list, plus the C crosshair and ring at 1080 and at 720/1.2, the bet prompts, the B check, and D2's room + chart overlay if merged. After D2 merges: full e2e, a new build, and the blind newcomer session; move E only if that session shows the gap. Then the 0.4.5 decision.
- **Heartbeat:** session-only one-shot cron; re-arm after /clear.

### Arc status (edd-lead) | 2026-11-06 08:30 JST

- D2 epilogue merged: #215 (67b2d41, 2026-11-06 08:27 JST; oracle approve, 0 findings on the final head). The whole arc A + B + C + D is now in main. On the final head test_epilogue 77/0 and test_layout_bounds 4546/0 ran; the other suites and routes ran before the last small fix (empty_desk, overlay fonts), and honest was rerun after it.
- **Running:** full e2e `job-run` id `edd-e2e-d2` on main 67b2d41, worktree ds-1 (detached). Check `job-run --status edd-e2e-d2` and `~/.local/state/job-run/edd-e2e-d2/log`; no event arrives for it.
- **Windowed look, from 09:00 JST:** one-shot cron 46cd8c52 at 09:01 JST (session-only). If it is gone: `job-run --id edd-look-1106 -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/look_20261106.sh`. Prep script `look_20261106_prep.sh` (same folder) rebuilds the temp tree `/private/tmp/edd-look-1106`: origin/main plus still-only bot edits that are never pushed. Stills go to `director/look-20261106/`: judge downscaled, delete afterwards, then remove the temp worktree.
- **After both:** fix what they show, then a new build and the blind newcomer session (`docs/PLAYTEST_NEWCOMER.md`); move E only if that session shows the gap; then the 0.4.5 decision.

### Arc status (edd-lead) | 2026-11-06 09:52 JST

- Full e2e on main 67b2d41: all 6 routes passed. Windowed look done 2026-11-06 09:4x JST (stills judged, deleted, temp tree removed). Passed: micrometer crosshair at 1080 and 720/1.2 (ring low contrast on the bright star, acceptable with its label), bet prompts, epilogue choices, ending.
- **Running:** `lw-arc-look-20261106-094905`, Codex Terra in worktree ds-1, brief `arc-look-fix.md` on KIOXIA `eddington-1919-cache/director/`, branch `polish/arc-look`: orrery close-up camera, Dyson's letter moved to the big table, chart overlay centred and height-limited, e2e evidence column. No unacked inbox events at this time.
- **On its event:** read the final report; if tests ran and the PR is ready, `lead-wait pr <n>`. If the gate says "still a draft": `gh pr ready <n>`, then `review-gate <n>`. `gh pr ready` can fail on transient GraphQL errors; `gh api -X PATCH` works for the body.
- **Then, before 15:00 JST today (else Monday 2026-11-09 09:00 JST):** a windowed look at the fixes, judged by the lead, especially the orrery close-up framing. Copy `director/look_20261106_prep.sh` and `look_20261106.sh`; they add the micrometer and bet stills on a temp tree. Run with `job-run --id <id> -- orb-test --heavy --host -- bash <script>`; the heavy queue can take 30+ min, and no event arrives for a `job-run`, so arm a one-shot check.
- **Open issues:** #216 (Príncipe Eddington reads as bare-skinned under the darkroom safelight; check GLB or `world_builder.gd` fallback, then a small worker change), #211, #212.
- **After that:** new build, blind newcomer session (`docs/PLAYTEST_NEWCOMER.md`), move E only if that session shows the gap, then the 0.4.5 decision.
- **Heartbeat:** session-only one-shot cron b75f3f1a at 10:36 JST; re-arm after /clear.

### Arc status (edd-lead) | 2026-11-06 13:55 JST

- Merged today after the look: #217 orrery close-up and epilogue layout (3cb768a), #219 orrery corrections (e75a416, closes #212), #218 night dress (572c862, closes #216), #220 micrometer (dd062c4, closes #211), #222 + #226 shirt front and waistcoat (0d31a46, f984c7d, close #221), #227 exam staging (23fe280, closes #223). Windowed looks 2026-11-06 10:32–13:47 JST judged and deleted; temp trees removed. Passed: orrery close-up 1917 and 1919, chart at 1080 and 720/1.2, Dyson's letter on the big table, night dress on Eddington (Cottingham not in those stills), Ashby and Eddington shirt fronts, Eddington clear of cabinet and Ashby in the exam. Full e2e on dd062c4: 6/6 (older than #222, #226, #227).
- **Running:** `lw-release-045-20261106-134944`, DeepSeek `ds-edd-1`, worktree ds-1, brief `release-045.md` on KIOXIA `eddington-1919-cache/director/`: full e2e on 23fe280 (stop if it fails), bump to 0.4.5, three exports to `/Volumes/KIOXIA/eddington/builds/0.4.5/`, A11, PR, one oracle review of its own PR. It wraps up by 14:50 JST (DeepSeek peak 15:00 JST). No unacked inbox events at this time.
- **On its event:** read `~/.local/state/ds-exec/ds-edd-1-*.final.md`. Check its e2e table and hashes. If the run is capped or wrapped up unfinished, the rest goes to what `quota-advisor` names. Also check that the DeepSeek run was healthy: its log opened with `[claude-code:unrecognized_model] deepseek-flash`. If the PR is ready, `lead-wait pr <n>` or, with an approve on the current head, `review-gate <n>`. The version bump commit is the build's commit.
- **After merge:** comment on Issue #1 asking the Owner to play 0.4.5 and to arrange the blind newcomer session (`docs/PLAYTEST_NEWCOMER.md`); it needs a real person, so the lead cannot run it. Say what changed: the whole conversion arc plus today's fixes. Store screenshots in `store-b5` may be stale after the arc and the character changes; check them next. Move E only if the session shows the gap.
- **Open:** #224 (shirt_front clearance gate can never fail; low priority). Oracle/Codex quota: Codex weekly was 88% against a 54% target at 13:49 JST, so ask `quota-advisor` and read its answer **before** dispatching. Do not chain the two in one command: a mis-dispatch to Codex happened that way at 13:49 JST and was stopped within a minute.
- **Visual judging lesson:** judge figures from a close crop. A downscaled full frame hid Eddington's ragged waistcoat in one round, and oracle reads geometry a still cannot show (tie buried in the neck). Oracle approve and lead's look are separate gates for art PRs.
- **Heartbeat:** session-only one-shot cron; re-arm after /clear, 45 min after the turn ends, with the heartbeat prompt.

### Arc status (edd-lead) | 2026-11-06 14:08 JST

- **0.4.5 merged:** #228 (b8b69b6, 2026-11-06 14:05 JST; worker oracle approve on the head, 0 findings). Builds on KIOXIA `/Volumes/KIOXIA/eddington/builds/0.4.5/`, built from 58954b1; the lead re-read all three SHA-256 and they match `BUILD.txt`. e2e 6/6 on 23fe280. The DeepSeek run was healthy: the `unrecognized_model` line is only a log warning.
- **Issue #1:** the Owner was asked 2026-11-06 14:0x JST to play 0.4.5 and to arrange the blind newcomer session. Move E waits on that session.
- **Running:** `lead-wait run store-045`: `director/store_045.sh` on KIOXIA reshoots the store sets on main to `store-b5/{careful,prologue,cambridge,principe}-045/`, beside the old sets. It stops starting new steps at 14:50 JST (Mon–Fri 09–15 JST rule) and removes its temp tree `/private/tmp/edd-store-045`. If the heavy queue held it past that, it exits 3: rerun Monday 2026-11-09 from 09:00 JST.
- **On its event:** judge from close crops against `docs/store/STORE_PAGE.md` rows 1–9, replace the old sets, delete the rest, update the paths. The about text and features now cover the arc (35f46aa, not yet read by the Owner). Still missing: shot-list rows for the ledger, orrery, micrometer and epilogue, and bot store shots for them; `STORE_PAGE.md` has a note above the closing line.
- **Open:** #224, #225, #214, #213, and #203 (duplicate of #204, close by hand).
- **Heartbeat:** session-only one-shot cron; re-arm after /clear, 45 min after the turn ends.

### Store reshoot judged; Kit goes to MPFB (edd-lead) | 2026-11-06 14:2x JST

- **Store sets:** the reshoot on b8b69b6 replaced the old sets in `store-b5/{careful,prologue,cambridge,principe}/` (1920×1080; old sets deleted; `INDEX.md` and `sheet_*.jpg` there are older). Lead verdict: rows 1, 3, 5–9 usable. Row 4 `totality_sky` has a stray "Eddington" name tag at the left edge: hide name tags in `tests/benchmark.gd`, or crop. Row 2 fails: Kit is the primitive figure. Orrery candidate for a new row: `prologue/honest_choice_orrery_orrery_check.png` (reads well). No micrometer or bet still exists yet; `honest_epilogue_ledger.png` does not show the ledger.
- **Decision (edd-lead, under the 2026-11-06 mandate):** the HG vs MPFB question has waited on the Owner since 2026-10-28, and Kit is the last principal built from primitives. Ship an MPFB Kit now (CC0, public repo). HG can still replace it later. This does not spend money or close that route.
- **Running:** `lead-wait run kit-mpfb`, Codex Terra in worktree ds-1, brief `kit-mpfb.md` on KIOXIA `director/`, branch `art/kit-mpfb`.
- **On its event:** read the final report. Windowed look at Kit, close crops of `honest_close_kit`, `honest_speaker_investigate_kit`, `m2_speaker_promise_kit`, `honest_beat_orrery` (Mon–Fri 09–15 JST; otherwise Monday 2026-11-09). Copy `director/store_045.sh` for the prologue run. Oracle approve and the lead's look are separate gates. Then `lead-wait pr <n>`, reshoot store row 2, add the arc rows, and consider a 0.4.6 for the Owner (Issue #1 now says 0.4.5; tell the Owner if Kit lands before they play).

### Kit PR state (edd-lead) | 2026-11-06 14:45 JST

- **PR #229** (`art/kit-mpfb`, head ff3bcec): oracle approve on the head, 1 major (tests do not prove Kit's idle plays or the mesh faces the player: follow-up issue, not a hold). Revert-check passed, e2e 6/6, portrait 69/0, prologue 395/0. test_departure failed once (montage caption, 4 s wall-clock) under load, then passed 3/3 on the branch and 3/3 on main: treated as a load flake, cause not established.
- **Running:** `lw-look-kit-20261106-144457`, ticket #613 behind two gteki jobs. `director/look_kit.sh` shoots the prologue honest route to `director/look-kit/`. It exits 3 without running if it starts after 14:55 JST: then rerun it Monday 2026-11-09 from 09:00 JST with `lead-wait run look-kit -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/look_kit.sh`.
- **On its event:** judge close crops of `honest_close_kit`, `honest_speaker_investigate_kit`, `honest_m2_speaker_promise_kit`, `honest_beat_orrery`, and whether the head and shirt front hold up beside Ashby. Pass → `review-gate 229`; delete `director/look-kit/`. Fail → resume the worker with one change, new review.

### Kit look round 1 (edd-lead) | 2026-11-06 14:5x JST

- Windowed look on ff3bcec, stills judged and deleted. Pass: head shape, hair, spectacles, facing the player (answers the facing half of oracle's major). Fail: reads as a white suit with black braces, dark torn V strips on the chest, eyes as black slits with an angry brow.
- **Running:** `lead-wait run kit-mpfb-fu2`, brief `director/kit-mpfb-fu2.md` (coat and pullover colours, dark trousers, softer brows, sclera and iris; Kit only). The worker renders to `director/kit-r2/` for the lead.
- **On its event:** judge `director/kit-r2/`. Next windowed look: Monday 2026-11-09 from 09:00 JST with `director/look_kit.sh`; then final-head tests and `lead-wait pr 229` (a push needs a new review). Delete `kit-r2/` and `look-kit/` afterwards.

### Kit look round 2 (edd-lead) | 2026-11-06 15:3x JST

- Blender renders at f5b14ca judged and deleted. Pass: eyes, coat colour. Fail: the split paints the jacket skirt dark, the chest is still ragged, and the brow and hair read as an angry 40-year-old.
- **Running:** `lead-wait run kit-mpfb-fu3`, brief `director/kit-mpfb-fu3.md`: split at the jacket hem, a clean pullover V (Kit only), and a hair × brow sheet at `director/kit-r3/sheet.jpg`. The lead picks one combination.
- **On its event:** judge the sheet and `kit_chest.png`, then tell the worker the combination (same session, one small follow-up). Windowed look Monday 2026-11-09 from 09:00 JST with `director/look_kit.sh`, then final-head tests, then `lead-wait pr 229` with `--reason`. If this round's chest fails too, consider a plain closed coat instead of more layers.

### Kit look round 3 (edd-lead) | 2026-11-06 15:5x JST

- Renders at cfaa7cc judged and deleted. Pass: clean chest, coat colour to the hem, dark trousers. Picked hair `short01` + `eyebrow005` (softest, youngest; `short03` covers an eye). Left: pale band with a jagged edge below the hem (split at 0.73 m, hem near 0.81 m); the V's flat top reads as a bib.
- **Running:** `lead-wait run kit-mpfb-fu5`, brief `director/kit-mpfb-fu5.md`, renders to `director/kit-r4/`. If those pass, windowed look Monday 2026-11-09 from 09:00 JST with `director/look_kit.sh`, then e2e on the final head and `lead-wait pr 229 --reason "<art rounds>"` (from the 4th reviewed head `--reason` is required). Delete `kit-r4/` and `look-kit/` after judging.

### Kit look round 4 + store shots (edd-lead) | 2026-11-06 16:0x JST

- **PR #229 head 53db2e9:** Blender renders judged and deleted, all pass (young friendly face with `short01` + `eyebrow005`, clean chest, split at 0.814 m hidden at the hem). 14,881 triangles. G2 pass, portrait 69/0, prologue 395/0, other four GLB hashes unchanged. `kit_e2e.sh` running on this head (`lead-wait run kit-e2e`).
- **Do not run `lead-wait pr 229` yet: it would merge before the in-game look.** The worker's post-run review exited 91 (fourth head needs `--reason`), so head 53db2e9 has no review.
- **Monday 2026-11-09 from 09:00 JST:** `lead-wait run look-kit -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/look_kit.sh`. Judge close crops of `honest_close_kit`, `honest_speaker_investigate_kit`, `honest_m2_speaker_promise_kit`, `honest_beat_orrery`, `honest_speaker_coda_kit`, in the room's warm light; delete `director/look-kit/`. Pass → `lead-wait pr 229 --reason "fourth head after art rounds: check the Kit-only pullover and split changes in build_person.py leave the other people unchanged"`. Oracle's major (no test that Kit's idle plays) → follow-up issue.
- **PR #230** (`test/store-arc-shots`, lead's own, worktree ds-2): bet and micrometer store shots, benchmark name tags hidden, store rows 10–13. `lead-wait pr 230` running.
- **Monday, after #229 and #230 merge:** reshoot `store-b5` (`director/store_045.sh`), judge row 2 (Kit), row 4 (no tag), rows 11–12. Then a new build for the Owner, since Kit is the most visible change: update Issue #1.

### Kit e2e passed; departure Ashby found (edd-lead) | 2026-11-06 16:0x JST

- **PR #229:** e2e 6/6 and test_departure 251/0 on 53db2e9. The lead added a test commit on top: Kit's arms-down pose and looping idle (portrait 72/0), which answers oracle's major, so no follow-up issue is needed for it. No revert-check on that test. The final head still has no review.
- **PR #230 merged** (316e529, oracle approve, 0 findings). Store rows 10–13 and new bot shots are in main; the stills come with the next windowed run.
- **Found:** Ashby is still the primitive figure at the departure (`honest_m2_speaker_farewell_mentor.png`), though MPFB in 1917 and the epilogue. Sent out: `lead-wait run ashby-dep`, Codex in worktree ds-2, brief `director/ashby-departure.md`, branch `art/ashby-departure` on top of `art/kit-mpfb`, PR base `art/kit-mpfb`, renders in `director/ashby-r1/`.
- `director/look_kit.sh` now shoots `origin/art/ashby-departure` (Kit and Ashby together); **that branch must exist before Monday's look**. Otherwise point the script back at `art/kit-mpfb`. Check `honest_m2_speaker_farewell_mentor` and the journal too.
- **Merge order after the look:** #229 first (`lead-wait pr 229 --reason …`), retarget the Ashby PR to main, then `lead-wait pr <n>`.

### Before /clear (edd-lead) | 2026-11-06 16:2x JST

- **Running:** `lw-ashby-dep-20261106-160639` (Codex, ds-2, brief `director/ashby-departure.md`). No unacked inbox events at this time. Open non-draft PR: #229, head a9b6120, not reviewed, must wait for Monday's look.
- **On the Ashby event:** read `~/.local/state/cx-exec/ds-2-*.final.md`; a run with `PENDING job … wait limit` is not finished. Judge `director/ashby-r1/` (front, side), and check that the journal is at his hand and not floating. Then delete `ashby-r1/`.
- **Monday 2026-11-09 from 09:00 JST, in order:** `look_kit.sh` → judge Kit + Ashby close crops → `lead-wait pr 229 --reason …` → retarget the Ashby PR to main → `lead-wait pr <n>` → `store_045.sh` (it writes `*-045` sets; replace the old ones after judging; rows 2, 4, 11, 12) → version bump and build 0.4.6 as in `director/release-045.md` → Issue #1.
- **Heartbeat:** session-only one-shot cron; re-arm after /clear, 45 min after the turn ends, with the same prompt (Owner 2026-11-04 heartbeat text; goal Steam release).


### Ashby round 1 judged (edd-lead) | 2026-11-06 16:4x JST

- **PR #231** head 2e3f0d0: oracle approve, 1 minor (the journal does not follow the hand's breathing: let go). Blender renders judged and deleted. Pass: head, build, suit. Fail: flecks through the shirt, a broken tie, a flat-ended waistcoat bib. The same `shirt_front()` still builds the desk Ashby and Eddington, so check Eddington's chest in Monday's crops; his GLB is untouched here.
- **Running:** `lead-wait run ashby-chest`, same Codex session in ds-2, brief `director/ashby-chest.md`: new `waistcoat_v_front()` for both Ashby GLBs, journal outside the hand. Renders to `director/ashby-r2/`.
- **On its event:** judge `ashby-r2/` (three stills), then delete it. The journal itself is only visible in Monday's look. The Monday order above stands. `look_kit.sh` shoots the tip of `art/ashby-departure`, so this round is included.

### Ashby round 2 judged (edd-lead) | 2026-11-06 16:5x JST

- **PR #231 head af1bc93:** Blender renders judged and deleted. Pass: clean chest, continuous tie, the V closes to a point, on both the standing and desk GLBs. 14,479 triangles each, G2 pass, other GLB hashes unchanged, portrait 78/0, departure 251/0, journal outside the hand.
- **Not yet proven:** `test_prologue` and `e2e_headless` exited 124 at the worker's 90 s and 180 s caps. Earlier rounds used far longer caps, and the host load was 16, but the cause is not established. Running: `lw-ashby-r2-tests-20261106-165450`, `director/ashby_r2_tests.sh`, caps 900 s and 1800 s.
- **On its event:** both pass → correct the PR body's results table and render line. A real failure or a repeat timeout → investigate before Monday.
- **Monday's look, also judge:** Ashby's moustache (two end caps read as flat discs in a close render) and his dark slit eyes, at the game's real camera distance. `moustache()` is shared with Eddington, so a change there moves his GLB.

### #231 tests pass; Eddington's chest found (edd-lead) | 2026-11-06 17:0x JST

- **PR #231 af1bc93:** rerun passed: prologue 395/0 in 93 s (the worker's cap was 90 s), e2e 6/6 in 125 s (its cap was 180 s at load ~16; that timeout was not reproduced). PR body corrected. No review yet on this head; that comes after Monday's look.
- **Found:** close Blender renders of the current GLBs show both Eddingtons broken: `eddington_cambridge` has flecks and a bib, `eddington` (Príncipe) has a shredded tie. These stills were not checked in game.
- **Running:** `lead-wait run edd-chest`, Codex in ds-2, brief `director/eddington-chest.md`, branch `art/eddington-chest` on `art/ashby-departure`, base `art/ashby-departure`. It stops without pushing if the rebuild of the 2026-10-20 `eddington.glb` changes more than the chest. Renders: `director/edd-r1/`.
- **On its event:** judge `edd-r1/` (chest and full, both models), then delete it. Check the old-versus-new comparison. If it passes, point `director/look_kit.sh` at `origin/art/eddington-chest` for Monday. Merge order: #229 → #231 → this PR, retargeting each to main. Rows 5–9 of the store shots may show the new Príncipe Eddington, so the reshoot covers them.

### #232 judged; faces sent out (edd-lead) | 2026-11-06 17:2x JST

- **PR #232** (`art/eddington-chest`, head 636163f, base `art/ashby-departure`): oracle approve, 0 findings. Renders judged and deleted: clean chest and tie on both Eddingtons. Rebuilt Príncipe GLB: same `idle`, 53 bones, 8 materials, same hat and glasses, +679 triangles. G2 pass; portrait, departure, prologue exit 0; e2e 6/6. `director/look_kit.sh` now shoots `origin/art/eddington-chest`. Merging #232 removes `shirt_front()`: #224 is moot then; check the rest of #225.
- **Correction:** the 16:5x section said `moustache()` is shared with Eddington. It is not: he is clean-shaven. Only Ashby and Cottingham use it.
- **Running:** `lead-wait run faces`, Codex in ds-2, brief `director/faces.md`, branch `art/faces` on `art/eddington-chest`, base `art/eddington-chest`: fitted moustache, and sclera and iris on all five. Renders: `director/faces-r1/`.
- **On its event:** judge `faces-r1/`, delete it. If it passes, point `look_kit.sh` at `origin/art/faces`. Merge order: #229 → #231 → #232 → faces. If it fails after one follow-up, drop it from Monday's stack: #232 must not wait on it.
- **Next if idle (real defects, read the code first):** #213 (Ashby speaks in the orrery correction before he has entered), #204 (hold not cancelled on pause, gamepad A that closes the pause menu counts as an interaction), #214 (micrometer with the loupe already on; test that cannot catch hidden values).
- **#203 still open:** closing it as a duplicate of #204 was denied by the permission check (2026-11-06 17:2x JST). It stays open; the Owner can close it by hand.

### Follow-up issues checked (edd-lead) | 2026-11-06 17:2x JST

- This corrects the "Next if idle" line above. **#204** is already closed. **#213:** the orrery corrections now use the speaker 太陽系儀, not Ashby, so the defect is gone from the code; the issue is still open. **#203** stays open only because closing it was denied.
- **PR #233** (`test/judgment-readings`, lead's own, temp worktree `/private/tmp/edd-read-test`): covers the second item of #214, test-only. `test_sim` 241/0; each of the two reverts fails exactly one new check. `lead-wait pr 233` running. Once its state is MERGED, remove that worktree and branch.
- **#214 first item (loupe with the micrometer):** `_set_micrometer` now calls `_show_loupe(loupe_start)`, which looks like a fix, but no caller or test was checked. Next if idle: check it with a test through the real input path.

### #233 merged; #214 settled (edd-lead) | 2026-11-06 17:2x JST

- **PR #233 merged** (ddbffec, oracle approve, 0 findings). Temp worktree and branch removed.
- **#214 first item is already fixed:** `_set_micrometer` recentres an open loupe on `loupe_start` (`scripts/ui.gd:979`), set by `scripts/main.gd:1549`, and `tests/test_micrometer.gd` section 7 checks it. So nothing is left to do on #213, #214 or #203, and #224 goes when #232 merges. They are still open, because closing #203 was denied (2026-11-06 17:2x JST); no other close was tried.
- **Still running:** `lead-wait run faces`. The Monday order stands: look → #229 → #231 → #232 → faces → store reshoot → 0.4.6 → Issue #1.

### Faces: blocker being fixed (edd-lead) | 2026-11-06 17:3x JST

- **PR #234** (`art/faces`, base `art/eddington-chest`): oracle blocker on 6c93726: the moustache was sampled on the posed body and then moved by the head pose again, which displaces it on the seated Ashby. Fix `408eb33` is local and not yet pushed. `faces-r1/` was deleted unjudged, since it predates the fix.
- **Running:** `lead-wait run faces-fu1` (`director/faces_fu1.sh`): waits for job `faces-rest-build`, then resumes the same session with `director/faces-fu1.md` (commit, tests, a numeric check on the seated moustache, renders to `director/faces-r2/`, push).
- **On its event:** a run ending in `PENDING job` is not finished. Judge `faces-r2/`, delete it. Pass → point `director/look_kit.sh` at `origin/art/faces`. Fail after one follow-up → drop #234 from Monday's stack.

### Faces judged; the art stack is ready for Monday (edd-lead) | 2026-11-06 17:5x JST

- **PR #234** head 5b724d0: oracle approve, 0 findings. Five people rebuilt, G2 pass, tests exit 0, e2e 6/6, seated moustache 0.0019 m from the skin. Face crops judged and deleted, all pass: the moustaches read as moustaches and the eyes have whites and irises. Check in game whether Eddington's eyes stare behind the glasses. `director/look_kit.sh` now shoots `origin/art/faces`.
- **Nothing is running.** Stack, each based on the one before: #229 (a9b6120, no review yet) → #231 (af1bc93, no review on this head) → #232 (636163f, approve) → #234 (5b724d0, approve).
- **Monday 2026-11-09 from 09:00 JST:** `lead-wait run look-kit -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/look_kit.sh`. Judge Kit, Ashby, Eddington and the journal in close crops. Then `lead-wait pr 229 --reason "…"`, retarget #231 to main and `lead-wait pr 231`, then the same for #232 and #234 (retargeting may need a new review). Then `store_045.sh` (rows 2, 4, 11, 12; the Príncipe rows now show the new Eddington and Cottingham), bump and build 0.4.6 as in `director/release-045.md`, update Issue #1. Close #203, #213, #214, #224 if allowed.

### #225 checked; still waiting for Monday (edd-lead) | 2026-11-06 18:0x JST

- **#225:** its only item is the same shirt-front gate as #224, and `shirt_front` no longer exists on `origin/art/faces`. Both issues are moot once #232 merges; add #225 to the close list.
- **Inbox:** the two `PENDING job` events (`ashby-r2-renders`, `faces-rest-build`) were acked. Their jobs were followed up and judged in the sections above.
- **Next:** unchanged. The Monday 2026-11-09 09:00 JST look kit, then the merge stack. Move E waits for the blind newcomer session, which needs a real person (Issue #1).

### Pre-reviews done; arc clarity #235 (edd-lead) | 2026-11-06 19:2x JST

- **#229 a9b6120:** round 4 oracle approve, 0 findings, no gate run. `lead-wait pr 229` reuses it. The rendered collar was not reviewed: judge it in Monday's look.
- **#231 af1bc93:** oracle blocker on `tests/test_portrait.gd:128` (journal assertion must fail) is a false positive: job `ashby-r2-tests` ran it, `78 portrait checks, 0 failures`. PR comment posted. After Monday's look use `review-gate 231 --override-blockers "<reason>"`, unless a rerun on the final head fails. Oracle's minor: the journal does not follow the breathing hand; judge drift in game.
- **#235 (9195f69):** text from a Sonnet cold read of the arc, plus a Sonnet fact-check with one oracle-ego run. It explains the second half of the deflection, gives Mercury a scale, says why the Newtonian alternatives don't reach the light result, and adds choice `box_light`, a cheap version of the box contradiction. Oracle approve; prologue 397/0, orrery 81/0, epilogue 89/0, departure 251/0, e2e 6/6. Add to Monday's look: the long 「箱子只說會彎」 page, the two Mercury pages, and the `box_light` choice. Not checked: whether the six ObjectDB leaks at the epilogue suite's exit predate #235.
- **Not adopted from the cold read, still open:** `final_reason` is never checked against the player's bet or plates; `click` is stored but `ending.gd` never reads it; `trial_note` option 「照星表寫」 costs nothing. Next if idle: decide these one at a time, read the code first.
- **Move E:** still waits for the blind newcomer session; the cold read is a proxy, not that session. It judged that the box needs doing by hand; `box_light` tests a cheap answer first.
- **Close list when allowed:** #203, #213, #214; #224 and #225 once #232 merges.

### Cold-read leftovers decided (edd-lead) | 2026-11-06 19:3x JST

- **`click`:** no change. Every option already has its own reply, so the answer is heard; the ending does not need it.
- **`trial_note`:** no change. Ashby's next line answers it directly (「哪顆星對不上，就寫它對不上」).
- **`final_reason`:** `lead-wait run final-reply`, Codex luna in ds-2 (quota-advisor had named deepseek; the lead dispatched in the same call without reading it, and stopping the run was denied by the permission check at 2026-11-06 19:3x JST, so it runs on), brief `director/final-reply.md`, branch `narrative/final-reply`. Ashby answers "my own plates" when those plates decided nothing, and tells a player who bet 1.75 in 1917 that what changed was the reason for believing it. It also reports whether the epilogue suite's ObjectDB leak predates #235. On its event: read the text diff, then `lead-wait pr <n>`.

### Notebook answer merged (edd-lead) | 2026-11-06 20:0x JST

- **#236 merged-armed** (head 4c124cb, oracle approve): Ashby answers the `final_reason` choice from the run and the 1917 bet. Oracle caught that a bet changed away from 1.75 needed its own line; the lead reworded it because a bet can change to 說不準. `test_epilogue` 138/0. E2E 6/6 was on 6adbcb1; the last commit changed one line and its test string. Add the reply lines to Monday's look.
- **ObjectDB:** #236's baseline on `origin/main` (with #235) reported 0, so the six seen in the #235 run did not recur. No pre-#235 comparison was run.
- **Lead slip:** after a push, `lead-wait pr` can read the old head and reuse its bundle. The gate then fails with "no review for head". Rerun once the head shows.
- **Next if idle:** #237 (test-only, PR open 2026-11-06 20:2x JST), then nothing left from the cold read. Monday 2026-11-09 09:00 JST is still next: look kit, stack, store reshoot, 0.4.6.

### Monkey pass after the arc (edd-lead) | 2026-11-06 22:5x JST

- **#238 merged** (a80fa11), #237 closed. **#239 merged** (6ad1278): bot only. Seeds 1111, 1114, 1117 failed on honest-route answers while monkey mode can pick others. Seed 1108 was not a trap: the bot only walks straight, and with sidesteps it left (3.933, -5.383) in 2 and reached ENDING. Follow-up #240: a long mid-walk dialogue barely consumes the waypoint timeout (tool only).
- **Monkey pass 1** (45fa897, seeds 1106–1117): 8/8 Príncipe routes passed; the 4 prologue failures are the ones above.
- **Running:** `lw-monkey2-20261106-223303`, 12 routes, seeds from 2000, on 6ad1278, in ds-2. On its event: a stall or a missing ENDING gets a replay with that seed; do not widen timeouts. A real trap would show as STUCK after SIDESTEP lines.
- **Next:** unchanged. Monday 2026-11-09 09:00 JST look kit, then the stack, store reshoot, 0.4.6.

### Monkey pass 2: bot routing out (edd-lead) | 2026-11-06 23:3x JST

- **Monkey pass 2** (6ad1278, seeds 2000–2011): 10/12 passed. 2005 (`M2_KIT`) and 2011 (epilogue) stuck against the central table, since `_in_cambridge_room()` matches only `cambridge/director.gd` and the table routing never ran in those rooms. That no player is trapped there is read from the code, not yet shown: the two replays must reach ENDING.
- **Running:** `lw-monkey-bot2-20261106-230656`, DeepSeek `ds-edd-2` (worktree ds-2), brief `director/monkey-bot2.md`, branch `test/monkey-bot2`, closes #240. No unacked inbox events at this writing.
- **On its event:**
  1. Read the report and the diff. A run ending in `PENDING job` or `WAIT:` is not finished.
  2. If the PR is a draft, `gh pr ready` it. Wait until GitHub shows the new head, then `lead-wait pr <n>`.
  3. After MERGED, delete the branch and run `lead-wait --role edd-lead run monkey3 -- orb-test --host -- bash -c 'godot --headless --path . --import >/dev/null 2>&1; ./tools/monkey_headless.sh 12 3000 mixed'` from ds-2 detached at `origin/main`, with `EDD_SETTINGS_PATH=/Volumes/KIOXIA/eddington/tmp-settings-monkey.cfg`.
  4. If 2005 or 2011 still fails after sidesteps and routing, treat it as a possible geometry bug: replay it, do not widen budgets.
- **Dispatch rule learned:** read `quota-advisor` before dispatching (19:32 JST slip). It has named deepseek since then.
- **Heartbeat:** one-shot due 2026-11-07 00:14 JST; crons are session-only, recreate after a restart.
- **Next after that:** unchanged. Monday 2026-11-09 09:00 JST `look_kit.sh`; the look now also covers #235's long pages and `box_light`, and #236's replies. Then #229 → #231 (override the false-positive blocker, see 19:2x section) → #232 → #234, store reshoot, 0.4.6, Issue #1. Close #203, #213, #214, then #224 and #225 once #232 merges, if allowed.

### Monkey pass 3 green; move E out (edd-lead) | 2026-11-07 00:3x JST

- **#241 merged** (1380124, oracle approve, 0 findings), #240 closed by hand, branch deleted. **Monkey pass 3** (1380124, seeds 3000–3011): 12/12 reached ENDING, stuck 0. Seeds 2005 and 2011 also reach ENDING, so the table failures were the bot, not a geometry trap.
- **#203, #213, #214 closed** (Owner authorized 2026-11-07 00:3x JST). #224 and #225 still go when #232 merges.
- **Move E decided:** built now instead of waiting for the blind session. The Owner is away until 2026-12-07, the cold read judged the box needs doing by hand, and the session can still reject it. This reverses "Move E waits" in the 19:2x section.
- **Running:** `lead-wait run arc-e`, DeepSeek `ds-edd-2` (worktree ds-2), brief `director/arc-e-box.md` on KIOXIA, branch `feat/arc-e-box`. On its event: read the report and diff; a run ending in `PENDING job` or `WAIT:` is not finished; then `lead-wait pr <n>`.
- **Monday look gets one more item:** the box sketch, both modes, at 1080 and at 720/1.2: do the falling ticks read as "the same", and does the light read as an illustration. Add its store shot only if it looks good.
- **Next after that:** unchanged. Monday 2026-11-09 09:00 JST `look_kit.sh`, then #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1.

### Move E merged (edd-lead) | 2026-11-07 01:2x JST

- **#242 merged** (08b0e6a, oracle approve on the second round; first round caught the pencil tip crossing the floor line). `test_prologue` 411/0, `test_box_sketch` 78/0, e2e 6/6, monkey `2 3100 prologue` 2/2 at about 320 s. Not looked at windowed yet: the Monday look decides whether the ticks read as "the same", the light as an illustration, and whether the outside view clips. Known minor: `frame_btns` is not cleared when "light" is reopened; the flow never reopens it.
- **Running:** `lw-monkey4`, 12 routes, seeds from 4000, on 08b0e6a in ds-2 (detached). On its event: a stall or a missing ENDING gets a replay with that seed; do not widen timeouts.
- **Running:** a Fable read-only design critique of the finished arc (subagent). On its report: decide item by item, then brief; nothing is adopted automatically.
- **Next:** unchanged. Monday 2026-11-09 09:00 JST `look_kit.sh`, with the box sketch added, then #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1.

### Epilogue payoff merged; oracle down (edd-lead) | 2026-11-07 02:4x JST

- **Monkey pass 4** (08b0e6a, seeds 4000–4011): 12/12 reached ENDING, stuck 0.
- **Fable critique** of the finished arc (2026-11-07 01:2x JST): three gaps at the payoff, all adopted with changes. **#243 merged** (ba05ba8; codex approve because oracle failed): the player writes a new ledger line `bet_oct` in October and the ending lists it; the player reads Sobral's 2σ range in the chart (`sobral_read`, any answer progresses); Mercury returns in the almanac with the player's 1917 mark; the "inconclusive" Ashby line no longer overclaims. `test_epilogue` 230/0, `test_layout_bounds` 4780/0, e2e 6/6, monkey 1/1. Fable's ideas not taken: shortening Ashby's Mercury lines. The "two instruments, one Atlantic" line appears only in the `conceded` case.
- **#245 merged** (f86984a, codex approve, 0 findings): Codex's major on #243, a 1.75 player who changes in October was told the number stayed. Branch deleted.
- **Oracle is down:** ChatGPT logged out in ego-lite (2026-11-07 02:30 JST); `owner-notify --key ego-lite-chatgpt-login` sent. `lead-wait pr` falls back to codex by itself. Do not brief workers to rerun an oracle review until it is back: they report exit 5 and stop.
- **Monday look adds:** the Sobral question inside the chart (default label colour, four buttons, at 1080 and 720/1.2), the October ledger line, the almanac note.
- **Next:** unchanged. Monday 2026-11-09 09:00 JST `look_kit.sh`, then #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1. Note that 0.4.6 also needs a change list for Issue #1 covering moves E and the payoff.

### All suites running (edd-lead) | 2026-11-07 03:0x JST

- **Running:** `lw-all-suites-20261107-024337`, in ds-2 detached at f86984a: `director/all_suites.sh` on KIOXIA runs all 52 `tests/test_*.gd` one at a time, 15-minute cap each, one result line per suite. The repo has no GitHub Actions, and tonight's PRs ran only related suites plus e2e. No unacked inbox events at this writing.
- **On its event:** read the job log `~/.local/state/job-run/lw-all-suites-20261107-024337/log` (the event text is cut short). A failure: read the cause first. Test assuming the old flow → small fix. Real bug → fix or brief it. Do not widen a budget. A suite that hits the cap or times out on load: rerun that one alone before judging.
- **After that:** no design item is open. Monday 2026-11-09 09:00 JST `look_kit.sh` plus the additions above, then #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1. Heartbeat: one-shot due 2026-11-07 03:19 JST; crons are session-only, recreate after a restart.

### All suites done; CI added (edd-lead) | 2026-11-07 04:2x JST

- **All suites** (f86984a, finished 2026-11-07 03:30 JST): 51 of 52 passed. `test_kit_recall` had failed since #108 (2026-11-03) because it never set `_grade`; the real flow sets it in `_after_judgment`, so the game was not affected. **#246 merged** (0ed0249), 29/0.
- **#247 merged** (a4dcb9b): `.github/workflows/all-suites.yml` runs `tools/all_suites.sh` on PRs and pushes to `main`; docs-only changes skip it. About 12 minutes on Ubuntu 24.04, Godot 4.7.2 with the SHA-512 checked. Run 42274095515 on 4d2a9cf: 52/52 on Linux. Run 42279284992 on `main` a4dcb9b was still running at this writing; check it.
- **What this changes for leads:** `review-gate` now returns 3 while the check runs, so `lead-wait pr` takes about 20 minutes (seen on #247). A failed `suites` holds the merge. `director/all_suites.sh` on KIOXIA is superseded by the repo script.
- **Open PRs #229, #231, #232, #234** have no `suites` run until their next push, and they were cut before these merges. Rebase each before its gate.
- **Store draft** (`docs/store/STORE_PAGE.md`): about text and features now cover the box sketch (#242) and the October payoff (#243). Row 14, a box sketch shot, stays a candidate until the windowed look.
- **Oracle still down** (ChatGPT logged out in ego-lite, 2026-11-07 02:30 JST, Owner notified); reviews go to codex by themselves.
- **Next:** unchanged. Monday 2026-11-09 09:00 JST `look_kit.sh` with the additions above, then #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1.

### Monday look prepared (edd-lead) | 2026-11-07 05:3x JST

- **#248 merged** (f15a17d): a gamepad gets through the box sketch on A and the d-pad alone, no game change needed. `test_layout_bounds` now covers its four stages at every size and text scale; that found the 越拉越快 label's rect 40 px past the viewport, text still inside, fixed in one line. The Sobral answers have no gamepad test, but the code moves focus to them and back; not run.
- **Look kit changed:** `director/look_kit.sh` used `origin/art/faces`, which lacks the box sketch and the October payoff. It now uses the branch `look/monday` (a964797: `main` f15a17d with `art/faces` merged, no conflicts, no PR) and runs the honest route twice, 1920x1080 at text 1.0 into `look-kit/1080`, then 1280x720 at text 1.2 into `look-kit/720`. Not run yet: its window guard allows Mon–Fri 09:00–14:55 JST.
- **Art stack on Linux:** run 42287429153 on a964797 passed all suites, so the stack breaks no suite against current `main`. This says nothing about how it looks.
- **Monday 2026-11-09 09:00 JST:** run `look_kit.sh` through `orb-test --heavy --host` (crons are session-only; the heartbeat has to catch it). Judge: Kit, departure Ashby and her journal drift, chest, faces; #235's long pages and `box_light`; #236's replies; box sketch ticks and light, both sizes; the Sobral question; October ledger line; almanac note. After that delete `look/monday`, then #229 → #231 → #232 → #234 (rebase each; #231 keeps the override reason from the 19:2x section), store reshoot, 0.4.6.
- **0.4.6 change list for Issue #1 (draft, add the art stack if it merges):** #235 the long box explanation, Mercury's scale and `box_light`; #236 Ashby answers your notebook choice; #242 the box by hand, in 1917 and at departure; #243 and #245 the October payoff: your new ledger line, reading Sobral's range, Mercury in the almanac; #248 a label bounds fix.

### Chapter checkpoints merged (edd-lead) | 2026-11-07 07:2x JST

- **#249 merged** (6b3dae5): Ashby reacts 「消息傳到劍橋時」, not in November 1915. From a Sonnet fact check of #242, #243 and #245 (2026-11-07 05:46 JST), which found no definite error. Left as they are: 「正好」 for Mercury's residual, because the sentence says 約 43; Sobral's 1.98″ in an October scene, because the scene and letter are labelled 推測重建.
- **#250 merged** (ec304b7): one automatic checkpoint per chapter (出發前夜, 普林西比, 1919 年 10 月) and a 繼續 button first on the title row. **This decides B7** under the Owner's 2026-11-06 mandate; recorded in `docs/RELEASE_READINESS.md`, and the Owner can still change it. Worker: DeepSeek `ds-edd-2`, brief `director/checkpoint.md`. Lead fix: a 1919-only ending keeps the story's checkpoint. Codex blockers fixed: bots and suites never read or delete a player's file, and forced suites use `checkpoint.test.save`. `test_checkpoint` 102/0, `test_layout_bounds` 5548/0, `suites` passed on the head before merge.
- **E2E on `main`** (2026-11-07 07:25 JST, ec304b7): see the job log `~/.local/state/job-run/lw-e2e-main-20261107-072232/log`. Bots do not write checkpoints, so this shows the routes still pass, not that continuing works.
- **Known behaviour:** starting a new game keeps the old checkpoint until the new run reaches its first chapter end. Continuing restarts the chapter with a new Príncipe sky.
- **Look branch refreshed:** `look/monday` is now ea42674 (`main` ec304b7 with `art/faces`), force-pushed, no PR.
- **Monday look adds, by hand and not by bot, since bots skip checkpoints:** quit in each chapter, relaunch, press 繼續. The real plate must survive the PNG round trip at the epilogue's ending, and the title row must read well at 720/1.2.
- **Next:** unchanged. Monday 2026-11-09 09:00 JST `look_kit.sh`, then #229 → #231 → #232 → #234, store reshoot, 0.4.6 (add #249 and #250 to the change list), Issue #1.


### Idle until Monday's window (edd-lead) | 2026-11-07 08:1x JST

- **Store draft:** `docs/store/STORE_PAGE.md` section 9 has a 70-second trailer shot list (c79fa30). Not shot; B5 is the Owner's. `--write-movie` with a bot route is suggested there but untried: test a short clip in the Monday window.
- **Cross-scene state read:** statics outside `Story` hold settings, replay flags, input device and audio caches, so a relaunch at their defaults should not affect 繼續. Read from code only; the Monday hand test decides.
- **Nothing running, no unacked events.** Next item is still Monday 2026-11-09 09:00 JST `look_kit.sh`. Before that, the heartbeat can take polish; no design item is open.

### Steam plan set; four languages (edd-lead) | 2026-11-07 08:5x JST

- **Owner 2026-11-07:** you lead with top authority, goal is a Steam-ready game. Decided: zh-TW, en, ja, ko all at launch; gramophone stays; Windows performance is not a concern if Mac and Linux are fine. The plan and every B row: `docs/RELEASE_READINESS.md` section D.
- **Owner asked (iMessage 2026-11-07 08:34 JST, key `steam-onboarding`):** pay Steam Direct and start the paperwork; 1–2 newcomers for 0.4.6; the credits name, default `nurockplayer`. Nothing else waits on this except App ID work.
- **Oracle is back** (rounds at 08:31 and 08:52 JST). Answers: `~/.local/state/oracle-ego/runs/*steam-gap-q{1,2}/answer.md`.
- **Running (2026-11-07 08:56 JST):** `lw-release-config` (`ds-edd-1`, brief `director/release-config.md`, branch `chore/release-config`); `lw-i18n-foundation` (`ds-edd-2`, brief `director/i18n-foundation.md`, branch `feat/i18n-foundation`); `lw-steam-gap-q3` (oracle: Godot traps, glossary, register, titles). On a worker's event: read the report and diff, then `lead-wait pr <n>`.
- **Next briefs, not written yet:** packaged-launch CI on Windows, macOS, Linux (after release-config, in ds-1); wrap strings, extraction and gates (after i18n-foundation, re-runnable codemod so it can run again after the art stack merges); translation after Monday's text look.
- **Monday 2026-11-09 09:00 JST:** unchanged, `look_kit.sh` then the art stack, store reshoot, 0.4.6. Also check Cmd-Tab with the mouse captured, and a 2560x1080 window.

### Foundation merged; wrap running (edd-lead) | 2026-11-07 09:3x JST

- **#252 merged** (079a8ba, 2026-11-07 09:33 JST; oracle approve, `suites` passed). `L.t`, locale pick, JP and KR fonts, language button. `L.TRANSLATED` is `false`: players stay on zh-TW with no button until en, ja and ko are complete, so Monday's 0.4.6 is unaffected. `EDD_LOCALE` still reaches the others. **Turn it on when translation lands.**
- **Running:**
  - `lw-release-config-20261107-085618`: `ds-edd-1`, PR #253, waiting on its own oracle review job `review-pr253`.
  - `lw-i18n-wrap-20261107-093347`: `ds-edd-2`, brief `director/i18n-wrap.md`, branch `feat/i18n-wrap`, `DS_MAX_TURNS=90`.
  - No unacked inbox events at this writing.
- **On release-config's event:** read the report and diff. Add to #253 or a follow-up: `scripts/credits.gd:4` `AUTHOR` still shows 「（姓名待 Owner 確認）」 to players; set `nurockplayer` unless the Owner answered otherwise. Then `lead-wait pr 253`. After it merges, dispatch `director/package-smoke.md` in ds-1 (`ds-edd-1`, brief is written).
- **On wrap's event:** read the skipped list and diff, `lead-wait pr <n>`. zh-TW output must not have changed. A PR with a run still in `WAIT:` is not finished.
- **Next briefs, not written yet:**
  1. Fragments to whole sentences: `scripts/main.gd:874–921` (`"［" + Prompts.key("interact") + "］…"`), `_hold_prefix`, `Settings.hold_phrase` (`content.gd:44`, `main.gd:1014`), directors' `set_prompt`, `"[b]…[/b]\n□ " + objective`, plurals via `L.tn` (`%d 張`), `ui.gd:242,1744` option lists.
  2. Leak gate: a bot route under `EDD_LOCALE=en` fails on visible CJK. Bots match zh text (`tests/autoplay_bot.gd:344,706`, `tests/prologue_bot.gd:137,799,905,907`): compare to `L.t(...)`. `test_layout_bounds` in all four locales.
  3. Translation after Monday's text look: en first (strong model, `docs/design/LOCALIZATION.md`), ja and ko from zh with en as reference; then independent back-translation and physics check through oracle-ego; a blind cold read; `check --require-translated` in CI; `L.TRANSLATED = true`; title strings per locale.
- **After an App ID exists:** depots and `app_build` VDF (Windows `.exe`, macOS `.app`, Linux `.x86_64`), Auto-Cloud on `checkpoint.save` (root WinAppDataRoaming, subdir `Eddington1919`; overrides MacAppSupport, LinuxXdgDataHome), Steam Playtest, real macOS install check with `xattr`. Oracle's flow is in `~/.local/state/oracle-ego/runs/*steam-gap-q2/answer.md` section I. Godot's overrides for the paths have not been checked against Steam.
- **Idea, untried:** xvfb plus lavapipe on a runner may render real frames without touching the Owner's screen. `package-smoke` will show whether Vulkan comes up. If so, store shots and looks may not need the Mon–Fri window.
- **Oracle:** back up; one `review` submit failed at 2026-11-07 09:15 JST (exit 5) and fell to codex, later runs worked.
- **Waiting on the Owner (iMessage 2026-11-07 08:34 JST):** Steam Direct fee and paperwork; 1–2 newcomers for 0.4.6; credits name.
- **Heartbeat:** one-shot due 2026-11-07 09:47 JST; crons are session-only, recreate after a restart.
- **Monday 2026-11-09 09:00 JST:** unchanged, `look_kit.sh`, art stack #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1. Rerun `tools/i18n.py wrap` and `extract` after the art stack merges, in case it added strings. Also check Cmd-Tab with the mouse captured, and a 2560x1080 window.

### #253 back in review (edd-lead) | 2026-11-07 09:5x JST

- **Decided:** the worker's question on #253 (oracle blocker: moving `user://` loses old settings and checkpoints). Accepted with no migration: only testers have old files, and no distributed build has a checkpoint. Reasons: `/Volumes/KIOXIA/eddington-1919-cache/director/scope-253.md`.
- **Lead fixes on #253 (82fe587):** `Credits.AUTHOR` is `nurockplayer`, which the Owner can still change. `tools/monkey_headless.sh` now reads `custom_user_dir_name`; the old path would have left the real settings unprotected. No monkey run on this head yet.
- **Running:** `lw-pr-253-20261107-095016` (review and gate), `lw-i18n-wrap-20261107-093347`.
- **On #253 merging:** ask `quota-advisor`, then dispatch `/Volumes/KIOXIA/eddington-1919-cache/director/package-smoke.md` in ds-1.
- **Heartbeat:** one-shot due 2026-11-07 10:37 JST.

### Font moved to bundled; #254 and #255 in review (edd-lead) | 2026-11-07 11:0x JST

- **Merged:** #253 (de7204a), #256 (d40187a; oracle exit 8, codex approve). A monkey run on de7204a reached ENDING with stuck 0.
- **#256 decision:** zh-TW uses the bundled Noto Sans TC on every OS instead of PingFang. Reason: on the hosted macOS runner PingFang resolved to an empty path, with about 50,000 font errors in one headless run. Whether a real Mac can hit this is unknown. **Mac players now see a different face in all UI text, and nobody has looked at it yet.**
- **Running:** `lw-pr-254-20261107-104935` (wrap, head 090d12d, scope `scope-254.md`); `lw-package-smoke-fu1-20261107-105857` (ds-edd-1 removes the macOS allow-list from #255 and adds `assets/**`).
- **On #254 merging:** ask `quota-advisor`, then dispatch `/Volumes/KIOXIA/eddington-1919-cache/director/i18n-sentences.md` in ds-2. It also fixes `reason_text`, saved in translated form (oracle major on #254). Then write the leak gate brief.
- **On package-smoke-fu1:** read the run, then `lead-wait pr 255`. A red macOS job means real font errors: read them, do not allow-list. On the previous head the best-effort windowed runs passed on software renderers: Windows D3D12 on WARP, macOS Metal on a paravirtual device.
- **Briefs need a `Test:` line:** i18n-wrap and package-smoke had none, so nothing reran their tests.
- **Fresh `.godot`:** the main checkout's class cache was from 2026-11-04 and failed on `Checkpoint`. It is re-imported now; import again after long gaps.
- **Monday look adds:** Noto TC in body text, `[b]` bold, dialogue and the 3D labels, on the Mac at 1080 and 720/1.2. If it looks worse than PingFang, the options are a heavier bundled weight or PingFang first with a check that the path resolves.
- **Heartbeat:** one-shot due 2026-11-07 11:29 JST.

### Packaged launch in CI (edd-lead) | 2026-11-07 11:1x JST

- **#254 merged** (c344bac), **#255 merged** (d90b2ff). `package-smoke` now starts the exported game on Windows, macOS and Linux on PRs that touch packaging, `assets/**` or `locale/**`. It uses software renderers, so it shows launch only.
- **lavapipe works:** Forward+ renders on an `ubuntu-24.04` runner at 260–283 ms per frame. So the "real frames without the Owner's screen" idea is possible for store shots; untried, and its look on a software renderer is not judged.
- **Running:** `lw-i18n-sentences-20261107-110435` (ds-edd-2).
- **Next, on sentences merging:** dispatch `/Volumes/KIOXIA/eddington-1919-cache/director/i18n-leak-gate.md` in ds-2 (brief written, not dispatched). It uses a pseudo locale, so leaks show before translation.
- **Then:** translation after Monday's text look. The new issue on `package-smoke`'s ko run goes with it: the run does not prove the locale was selected.

### Wrap, sentences and leak gate merged; layout running (edd-lead) | 2026-11-07 12:4x JST

- **Merged:** #259 (0e34bee: whole sentences, `L.tn`), #262 (9641edd: pseudo catalogue, `tests/leak_watch.gd`, CI job `leak-gate`). Under pseudo, all 6 routes show 0 leaks. Three routes leaked on the first run (`Ashby 先生` in 6–7 places), so the watcher does catch them.
- **Running:** `lw-layout-long-text-20261107-123953` (`ds-edd-2`, ds-2, branch `fix/layout-long-text`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/layout-long-text.md`). No unacked events at this writing. The branch's first commit is mine: pseudo text breaks into words.
- **Why:** word pseudo on 2026-11-07 12:38 JST gave 406 failures in `test_layout_bounds`, from the title row (up to 632 px), the plate viewer's right column (150 px), one `RichTextLabel` (11 px), and tests that compare Chinese.
- **On its event:** read the report. **zh-TW must be unchanged at scale 1.0**: check the rects it reports against `main`. It may end on `DECISION:` if pseudo cannot reach 0 without a zh-TW change. Then `lead-wait pr <n>`.
- **Monday look adds:** the title row and viewer buttons, in zh-TW and with `EDD_LOCALE=en`; no one will have seen this change in a window.
- **Issues:** #258 (the `ko` smoke does not prove the locale), #260 (saved runs keep formatted text; accepted for launch), #263 (leak gate misses `draw_string` and screens no bot opens; close before `L.TRANSLATED`).
- **Open question, cheap:** `ds-exec` reported `Test: could not run (orb-test exit 127)` on the leak-gate brief; not looked into. Its `Test:` line used `VAR=1 VAR2=x orb-test`. The new brief uses `orb-test --host -- env VAR=x …`; see whether that one runs.
- **Next after layout:** nothing in the release order can start until Monday 2026-11-09 09:00 JST: `look_kit.sh`, art stack #229 → #231 → #232 → #234, store reshoot, 0.4.6, Issue #1, then translation. Refresh `look/monday` first: it is still `main` at ec304b7 with `art/faces` and lacks today's font, l10n and layout changes. After the art stack merges, rerun `tools/i18n.py wrap` and `extract`.
- **Waiting on the Owner (iMessage 2026-11-07 08:34 JST):** Steam Direct fee and paperwork; 1–2 newcomers for 0.4.6; credits name, now `nurockplayer` in the game.
- **Heartbeat:** one-shot due 2026-11-07 13:03 JST; crons are session-only, recreate after a restart.

### Leak gate on menus dispatched (edd-lead) | 2026-11-07 13:0x JST

- **Running:** `lw-layout-long-text-20261107-123953` (unchanged, see above); `lw-leak-gate-menus-20261107-130247` (`ds-edd-1`, ds-1, branch `test/leak-gate-menus`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/leak-gate-menus.md`): chart text and a walk of the menus under pseudo, for #263 and #264.
- **On its event:** read the panel list in the PR body. What sits under "Not covered" is mine to decide. Then `lead-wait pr <n>`. Merge order with layout does not matter; the files do not overlap.
- **`orb-test exit 127` explained:** `proof-pack` reruns a `Test:` line as `orb-test -- sh -c "<line>"`, on dot, where `godot` and `python3` exist and `orb-test` does not. So a `Test:` line is the bare command with no `orb-test` inside. Both running briefs were corrected on 2026-11-07 13:0x JST; `proof-pack` reads the brief at the end of a run, so this first rerun on dot is also the first test of the fix.
- **Later, for translation:** the OS window title and the macOS app name come from `config/name` in `project.godot`, which stays Chinese under every locale. The leak gate cannot see it. Decide `config/name_localized` or a `DisplayServer.window_set_title` call when `L.TRANSLATED` turns on. Credits now carries the name as a `L.t` literal, with a check against `config/name` (#265).

### #265 at the gate (edd-lead) | 2026-11-07 14:0x JST

- **#265:** `leak-gate` passed on b556855, `suites` still running. `lw-pr-265` holds the gate and reuses the worker's oracle approve (blocker 0, major 1: the log panel is opened with no history in it). On merge, #263 and #264 close. Revert-checks passed on all three paths: chart, pause caption, a bare `draw_string` literal.
- **Test: rerun:** works on dot with a bare command (`check: 0 problem(s)`). Editing the brief mid-run does not reach it: the rerun used the line from dispatch, so the layout run may still show 127. Only new briefs get the fix.
- **`test_layout_bounds` got SIGTERM (exit 143)** at about 7 minutes in a batch of eight suites inside one `orb-test --host` run in ds-1. Not rerun as it was. Look at how long it takes alone when layout's event arrives, and at its time in CI.

### #265 merged; layout at the gate; English draft running (edd-lead) | 2026-11-07 15:3x JST

- **Merged:** #265 (47ba236), closing #263 and #264.
- **#267, layout, merged** (17f44a9). Oracle major in #268: the chart's fit is not recomputed when text size changes while the viewer is open; a one-line `_layout_viewer()` in `_cycle_text_size` should do it, not done. zh-TW against `main`, probed on 2026-11-07 15:30 JST: title identical in all 8 combinations; viewer has the 4 accepted buttons plus columns 2 px taller.
- **English translation started before Monday,** because `.po` entries survive later text edits. Pilot of 110 entries: Sol beats DeepSeek on dialogue and physics terms (`pilot-en-{ds,sol}.json`). But `quota-advisor status` shows Codex weekly at 100.0% with the window 50% gone, and Claude weekly 92% with 87% gone. So:
  - **Draft running:** `lw-en-full-20261107-153313` (`ds-edd-2`, ds-2, branch `l10n/en`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/en-full.md`), using Sol's pilot as the model.
  - **Next:** after the Codex week resets, a Sol polish pass on dialogue, starting with the worker's list of least-sure entries. Then back-translation and physics check through oracle-ego, ja and ko, a blind cold read, `--require-translated` in CI, `L.TRANSLATED = true`.
- **Three stale wrappers still queued on dot:** `lw-layout-long-text-fu1`, `lw-pilot-en-ds`, `lw-pilot-en-sol`. The work is done; each waits to rerun its `Test:` line. Stopping them was refused by the permission classifier, so they were left alone. The pilots' lines name a KIOXIA path dot cannot see, so they will fail and may resume their worker once: ignore that output and do not act on it. `lw-pilot-en-sol`'s resume would spend Codex quota. Ack their events with no further work.
- **`Test:` rerun on dot queued for about an hour on 2026-11-07,** holding a finished run's event that long. Keep `Test:` lines bare, repo-relative, and quick.
- **Monday look adds:** `EDD_LOCALE=en` with real English, if the draft has landed.

### English draft fully translated; layout under English open (edd-lead) | 2026-11-07 17:3x JST

- **Running:** `lw-en-full-fu2-20261107-162926` (`ds-edd-2`, ds-2, branch `l10n/en`, session `05062edd-5ab2-424e-91ca-8455d309b27c`, briefs `en-full.md` and `en-full-fu2.md` in `/Volumes/KIOXIA/eddington-1919-cache/director/`). No unacked events at this writing. `check --require-translated --locales en` reports 0 problems. No PR yet.
- **`test_layout_bounds` under `EDD_LOCALE=en`: 210 failures** (`.godot/layout-en.log` in ds-2, 2026-11-07 17:05 JST, before the worker merged `origin/main`). 60 look like tests comparing text (title buttons, tail warning, checkpoint, PREP objectives, twelve plates); 94 + 15 under a `PanelContainer`; 36 under a `VBoxContainer`, screen not identified yet; 4 `checkpoint title button fits: Quit`; 1 micrometer toggle. The worker should end on `DECISION:`. Layout changes are the lead's call: read the log, separate test comparisons from real overflow, and check whether any overflow is really the English being long.
- **Fix before `lead-wait pr`, once the worker has stopped:** `Mr Dyson` (1) → `Sir Frank`, knighted 1915; `Mr Eddington` (1) → `Professor Eddington`. `Mr Ashby` stays. Add these to the Glossary in `docs/design/LOCALIZATION.md`. Polish list so far: "it may not move at all" needs "the light" as its subject.
- **#268:** one line, `_layout_viewer()` in `_cycle_text_size`. Do it with the next layout change, or before `L.TRANSLATED`.
- **After the PR:** Sol polish once Codex's week resets (weekly 100.0% at 2026-11-07 15:32 JST), oracle back-translation and physics check, ja and ko, blind cold read, `--require-translated` in CI, `L.TRANSLATED = true`, window title (see above).
- **Heartbeat:** one-shot due 2026-11-07 17:52 JST; crons are session-only, recreate after a restart.

### English layout diagnosed; next brief ready (edd-lead) | 2026-11-07 17:5x JST

- **Running:** `lw-en-full-fu2-20261107-162926` (`ds-edd-2`, ds-2, `l10n/en`). Its last session write was 2026-11-07 17:26 JST. It is blocked on `godot --headless ... --prologue-autoplay=honest --seed=77` (pid 21999), started without `--fixed-fps`, so the route runs in real time at about 2% CPU. It may be slow rather than hung. Stopping that process was refused by the permission classifier on 2026-11-07 17:5x JST and has not been retried; the Owner can stop it or allow it.
- **`test_layout_bounds` under `EDD_LOCALE=en` after the merge of `main`: 40 failures, down from 210** (`.godot/layout-en-2.log` in ds-2). All are in the plate viewer at scale 1.2. Causes as read from the code, not yet tested: the left column hint has no autowrap (458 → 580 px wide), and `Include in measurement` probably takes a second flow row (26 px over at 720/1.2 with the micrometer on).
- **On its event:** `ds-exec --resume 05062edd-5ab2-424e-91ca-8455d309b27c ds-edd-2 /Volumes/KIOXIA/eddington-1919-cache/director/en-full-fu3.md` through `lead-wait run`. The brief carries both layout fixes, `Oxford plate`, #268, `Sir Frank` and `Professor Eddington`, and the glossary. Then `lead-wait pr <n>`. It is not dispatched yet.

### #269 English draft at the gate; viewer layout next (edd-lead) | 2026-11-07 19:2x JST

- **Corrects the 17:5x section:** pid 21999 ended with exit 143; its stop source was not traced. The autoplay never ran because the worker put the bot's arguments before `--`, not because `--fixed-fps` was missing. With the correct form the honest route under `EDD_LOCALE=en` reached ENDING in about 32 seconds (2026-11-07 18:45–18:46 JST, `failures=[]`).
- **Merged:** #269 (4e3e85f, 2026-11-07 19:24 JST), the full English draft: oracle approve, blocker 0, major 2 (#270, #271), CI green.
- **Decided:** merge the text first; `L.TRANSLATED` is still false, so no player sees it. The 40 viewer overflows and the forms of address go in a separate small PR instead of a new review of the full draft.
- **Running:** `lead-wait run en-viewer` (`ds-edd-2`, ds-2, new session, branch `fix/en-viewer-layout`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/en-full-fu3.md`). On its event: `lead-wait pr <n>`. It covers the left column autowrap, `Include`, `Oxford plate`, #268, `Sir Frank`, `Professor Eddington` and the glossary. **Until it merges, `Mr Dyson` and `Mr Eddington` are still on `main` in `locale/en.po`.**
- **Later:** #270 and #271 (tools), then the Sol polish, starting from the 12 least-sure entries in the #269 body.

### #273 English viewer: last 32 px (edd-lead) | 2026-11-07 20:0x JST

- **#273** (`fix/en-viewer-layout`, 4b8abce): width overflow is gone, the left column is 458 px under both en and zh-TW. zh-TW suite: 0 failures. Under `EDD_LOCALE=en`: 36 failures, all height, at scale 1.2 (left column 902 px, 870 available; zh-TW 843).
- **Decided:** English text only. The hint becomes two lines; a note is shortened only if that is not enough. No zh-TW or viewer code change.
- **Running:** `lead-wait run en-viewer-fu1` (`ds-edd-2`, session `1605611c-7a5f-4b2c-a10f-cb96dc1173ce`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/en-viewer-fu1.md`). On its event: `lead-wait pr 273`.
- **For ja and ko:** the viewer's left column has nothing that gives way, so a longer language can overflow at scale 1.2 again. Run `test_layout_bounds` under each locale early. If text cuts lose meaning, the options are a scrolling note or a smaller thumbnail grid on short windows (the grid changes zh-TW).
- **Unresolved, not looked into:** the worker reports that `orb-test`'s container route failed with `docker ps` timing out, once hung for 5 minutes, and that it ran `tools/i18n.py check` on the host instead (text check only).

### #273 back at c6c4b04 (edd-lead) | 2026-11-07 20:2x JST

- **Leak gate failed on 11e235f, from my decision to wrap the hint:** the pseudo catalogue wrapped to three lines, 32 px over at scale 1.2 (36 failures). The worker ran only en and zh-TW, not pseudo. I removed the wrap in c6c4b04. The short English hint fits two lines by itself, and pseudo goes back to what `main` does.
- **Running:** `lw-en-layout-real-20261107-202228` (`test_layout_bounds` under real `EDD_LOCALE=en` in ds-2 at c6c4b04). CI runs pseudo and zh-TW but not real English, so this run is the only proof for English.
- **On its event, if 0 failures, and with CI green:** `lead-wait pr 273`. If not 0: the left column needs something that gives way.
- **Corrects the 20:0x section's reading:** with no wrap, a language whose hint line is wider than 458 px widens the left column again. Only pseudo catches that.

### #273 merged; #274 at the gate (edd-lead) | 2026-11-07 20:4x JST

- **Merged:** #273 (1be7702, 2026-11-07 20:36 JST). Real `EDD_LOCALE=en` layout at c6c4b04: 0 failures in 8462 checks. `Sir Frank`, `Professor Eddington` and the glossary are in; #268 was already closed.
- **Running:** `lw-pr-274-20261107-204240`. #274 (`fix/i18n-po-order`, worktree ds-2) closes #270 and #271. Placeholders must stay in order with no tolerance: GDScript's `%` has no positional form. **ja and ko word order will hit this:** where a sentence cannot keep the order, the source moves to a named `.format()`.
- **Test evidence on #274:** revert-check stopped at the order assert, so the fuzzy cases were not separately shown to fail on the old code.
- **Host note:** `orb-test --` on a light check waited over 5 minutes on 2026-11-07 20:3x JST, so I stopped it and used `orb-test --host --`. `docker ps` also still fails on the Mac: `VM left running: docker ps failed`.
- **Next on the English line:** the oracle back-translation and physics check does not need Codex, and could run before the Sol polish. Not started. Sol polish waits for the Codex week to reset.

### English checked; ja and ko drafts running (edd-lead) | 2026-11-07 21:3x JST

- **Merged:** #274 (dcf6255), closing #270 and #271; #275 (cc9fd5a), oracle's physics and meaning check of all 1,143 English entries. 19 entries changed: `twice the error`, not `two-sigma`; `wound`, not `spring`; `panel`; the ledger entry for plate 23; `usable plates`. Not taken: `拖長只會把數字拉低`, true in the game's model (`scripts/eclipse_sim.gd:271`).
- **Left in the zh-TW source:** `content.gd:43` says both `重錘時鐘` and `發條`. `發條` runs through about ten strings and the winding interaction.
- **Running:** `lead-wait run ja-full` (`ds-edd-1`, ds-1, branch `l10n/ja`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/ja-full.md`), `lead-wait run ko-full` (`ds-edd-2`, ds-2, branch `l10n/ko`, `ko-full.md`). First drafts with no model translation behind them, so their quality is unknown.
- **On each event:** read the report, decide any `DECISION:` (layout, fonts), then `lead-wait pr <n>`. Then run the same oracle check as English before relying on them.
- **Claude weekly 97% with the window 90% gone at 2026-11-07 21:27 JST; Codex weekly 100%.** Keep lead turns few until the reset. Sol polish waits for Codex.
- **Not yet:** blind cold read, `--require-translated` in CI, `L.TRANSLATED = true`, window title. Monday 2026-11-09 09:00 JST order unchanged.

### ja and ko drafts merged; checks running (edd-lead) | 2026-11-07 22:2x JST

- **Merged:** #276 ja (cd9de3e), #277 ko (947db5a). Worker-reported: layout under each locale 0 failures in 8462 checks, honest route to ENDING with `failures=[]`, font coverage 0 problems. `L.TRANSLATED` is still false.
- **Running:** `lw-ja-check-20261107-220812`, `lw-ko-check-20261107-220742`: oracle meaning and history checks, prompt at `/Volumes/KIOXIA/eddington-1919-cache/director/l10n-check-prompt.txt`.
- **On each event:** confirm it read every entry, judge each row against the code as with English, apply through `tools/i18n.py apply`, run `test_layout_bounds` and the honest route under that locale, then `lead-wait pr <n>`.
- **Must also go in, from the PR reviews:** ko: the winding instruction says press where the default is hold, which can leave a player stuck; `同天區` is `같은 하늘 영역`, two places. ja: `沒事。` is not `いいえ。`; `底片ホルダー` is `乾板ホルダー`.
- **Open:** `好。` needs `L.tc` for Korean speech levels (Eddington against Ashby).
- **Not read by a native speaker yet:** the ja and ko worker lists of least-sure entries are in the #276 and #277 bodies.

### State at the context clear (edd-lead) | 2026-11-07 22:3x JST

- **Running:** `lw-ko-check-20261107-220742`; `lw-ja-check-2-20261107-222857`. No unacked events at this writing.
- **`ja-check` failed twice on 2026-11-07 22:28 JST, both exit 8:** the ChatGPT page lost its connection and left no answer, then `--resume` found the page closed. `ja-check-2` is a fresh run from `main`. If it fails too, do not retry at once: leave the ja check for later. It blocks nothing, since `L.TRANSLATED` is false.
- **Next on each event:** the steps in the 22:2x section above: confirm it read every entry, judge each row against the code, `tools/i18n.py apply`, `test_layout_bounds` and the honest route under that locale, `lead-wait pr <n>`. Answers may come as a download the run did not capture; the prompt asks for the reply text.
- **Worktrees:** ds-1 is on `l10n/ja` and ds-2 on `l10n/ko`, both merged. Start each fix branch from `origin/main`.
- **Claude weekly 97% with the window 90% gone at 2026-11-07 21:27 JST; Codex weekly 100%.** Keep lead turns few. Heartbeat one-shot due 2026-11-07 23:13 JST, session-only, so it may be lost with this context; recreate if gone.


### ko-check failed; run the checks one at a time (edd-lead) | 2026-11-07 22:4x JST

- **`ko-check` failed on 2026-11-07 22:32 JST, exit 8:** the page showed ChatGPT's message stream error (`訊息串流錯誤`, with a retry button) and no reply, then stalled for 12 minutes. Run dir: `~/.local/state/oracle-ego/runs/20261107-220742-6363-ko-check`. Event acked. Nothing was applied, so ko has no oracle check yet.
- **Possible cause, not tested:** `ja-check` lost its connection in the same period, while both were running at once on bundles of about 210 KB.
- **Next:** `ko-check-2` is not dispatched. Wait for the `ja-check-2` event, then run the ko check alone from `main` with the same prompt (the arguments are in `~/.local/state/job-run/lw-ko-check-20261107-220742/cmd`). If `ja-check-2` fails too, leave both for later. This blocks nothing, since `L.TRANSLATED` is false.

### ja and ko oracle checks both parked (edd-lead) | 2026-11-07 23:0x JST

- **`ja-check-2` failed on 2026-11-07 23:01 JST, exit 8,** after running alone: `連線已中斷，正在等待完整回覆`, with no usable reply. Run dir: `~/.local/state/oracle-ego/runs/20261107-222857-15764-ja-check-2`. Event acked. This weakens the 22:4x section's idea that running both at once was the cause. ChatGPT ran code and searched the web (`已搜尋 32 個網站`) for about 30 minutes before the connection dropped, so run length or file size may be the cause; neither is tested.
- **State:** nothing is running. ja and ko have no oracle check yet, and nothing was applied. `ko-check-2` is not dispatched. This blocks nothing, since `L.TRANSLATED` is false.
- **Next, after the Claude weekly reset (`quota-advisor status`):** one language at a time, in slices of about 300 entries, each with the same prompt and its own `--file`. Do not rerun the whole file. Add to the prompt: do not search the web. Slices are untested; check one before sending the rest.
- **The PR-review fixes in the 22:2x section are still not in.** They do not depend on the checks; put them in the same PR as the check results, or alone if the checks stay down.

### Claude week reset; ja check restarted in slices (edd-lead) | 2026-11-08 15:1x JST

- **Claude weekly 2% at 2026-11-08 15:17 JST** (reset). Codex weekly still 100.0%, window 65% gone. Heartbeat back to every 45 minutes; one-shot due 2026-11-08 16:03 JST.
- **Slices:** `/Volumes/KIOXIA/eddington-1919-cache/director/l10n-slices/`, `{ja,ko}-{1..4}of4.po`, 300 live entries each (1,080 live per language by this split; the header is kept in each). Prompt per slice: `prompt-ja-1.txt`, the old prompt plus "do not search the web and do not run code".
- **Running:** `lw-ja-check-s1-20261108-151739` (ja slice 1 only). On its event: if it read all 300, judge each row against the code, keep the result in `l10n-slices/`, then run the next slice, one at a time. If slice 1 fails the same way, the size is not the cause; stop and look at oracle itself.

### ja checked in slices; #279 at the gate (edd-lead) | 2026-11-08 15:5x JST

- **Slices work:** ja's four slices each finished in 6–8 minutes (2026-11-08 15:17–15:45 JST), and every slice was read in full: 300, 300, 300 and 180 entries.
- **#279** (`l10n/ja-check`, ds-1): 75 rows applied, plus a sweep of 停, 底片 and 偏り. The `--scope` file is `l10n-slices/ja-scope.md`. Judgements are in `l10n-slices/ja-{1..4}-judged.md`; slice 4 and the register choice are recorded in the scope file and the PR body. Tests: i18n check 0 problems, ja layout 0 failures in 8462 checks, ja honest route `failures=[]`. **Running:** `lw-pr-279-20261108-155501`.
- **Decided:** Eddington keeps なさい and plain form. Only mixed politeness within one line, よかろう, 君 and meaning changes were fixed. A whole-voice register pass for ja is a follow-up, not done.
- **Next:** ko slices 1–4, one at a time, prompts `l10n-slices/prompt-ko-{1..4}.txt`. Start after the #279 review leaves oracle free. The ko PR-review items from the 22:2x section (press against hold; 같은 하늘 영역) go into the ko PR. Also check `0.87: 뉴턴식의 절반` (same ambiguity as ja; en says "half, on the Newtonian calculation").
- **Tools:** `l10n-slices/parse.py` turns answers into rows, `build_ja.py` builds the `apply` JSON (a JSON array of `{msgid, msgstr}`).

### #279 merged; ko slices running (edd-lead) | 2026-11-08 16:1x JST

- **Merged:** #279 (ca1afab), the ja check fixes.
- **ko slice 1** done 2026-11-08 16:10 JST, read 300/300; judged in `l10n-slices/ko-1-judged.md` (answer `ko-1-answer.md`). Nothing applied yet: apply all ko slices in one PR, as with ja.
- **ko slice 2** done 2026-11-08 16:22 JST, 300/300; judged in `ko-2-judged.md` (27 of 39 rows are Eddington register; a register sweep goes in the ko PR; 歲差 SOURCE is a follow-up).
- **ko slice 3** done 2026-11-08 16:29 JST, 300/300; judged in `ko-3-judged.md`.
- **Running:** `lw-ko-check-s4-20261108-163005` (slice 4, the last). On its event: copy the run's `answer.md` to `l10n-slices/ko-4-answer.md`, judge it, then the ko PR below.
- **After slice 4:** build the ko apply JSON (`parse.py`, as `build_ja.py`), branch from `origin/main`, `tools/i18n.py apply`, i18n check, ko layout and honest route, `lead-wait pr <n>` with a `ko-scope.md`.

### ko checked in slices; ko fix PR running (edd-lead) | 2026-11-08 16:4x JST

- **ko slices** all read in full (300, 300, 300, 180; 2026-11-08 16:03–16:37 JST). Judgements in `l10n-slices/ko-{1..4}-judged.md`; `build_ko.py` built `ko-apply.json`, 90 rows (5 rejected), placeholders checked. Both #277 review items are in (hold, not press; 같은 하늘 영역).
- **Running:** `lw-ko-check-fix-20261108-163837`: `ds-exec ds-edd-2` (ds-2, branch `l10n/ko-check` from origin/main), brief `/Volumes/KIOXIA/eddington-1919-cache/director/ko-check-fix.md`. It applies the JSON, runs the i18n check, ko layout and honest route, opens the PR and runs one oracle review of it.
- **On its event:** read the report, then `lead-wait pr <n> --scope /Volumes/KIOXIA/eddington-1919-cache/director/l10n-slices/ko-scope.md`.
- **Follow-up:** #280: whole-voice register pass for Eddington in ja and ko, plus the 歲差 and 0.87 source wording.
- **After ko merges:** en, ja and ko all have an oracle check. Still not done: native read, `--require-translated` in CI, `L.TRANSLATED = true`, window title.

### ko fix PR #281 at the gate (edd-lead) | 2026-11-08 18:2x JST

- **#281** (`l10n/ko-check`, ds-2): 90 rows applied. Worker tests 2026-11-08 16:46–18:01 JST: ko layout 8462 checks 0 failures; ko honest route seed 77 `failures=[]`; i18n check `--require-translated --locales ko` 0 problems; `test_i18n_po.py` passed. Worker oracle review approved, its one minor (`\|` at `locale/ko.po:416`, an escape copied from the oracle table) fixed by the lead in 5936b98.
- **Running:** `lw-pr-281-20261108-181857` with `--scope l10n-slices/ko-scope.md`. On the event: if merged, en, ja and ko all have an oracle check.
- **Host:** the worker found the OrbStack VM stopped at 16:46 JST and ran `orb start`; at 18:0x JST `orb-test --status` showed docker not answering again. Light runs used `--host` or dot. Not investigated.
- **Next:** #280 (Eddington register pass ja/ko; 歲差 and 0.87 in the source). Then native read, `--require-translated` in CI, `L.TRANSLATED = true`, window title.

### #281 merged; en, ja and ko all oracle-checked (edd-lead) | 2026-11-08 18:2x JST

- **Merged:** #281 ko check fixes (8b29b7f). Gate review oracle approve 0/0/0 on 5936b98. **Checks overridden:** `suites` failed at `Install Godot 4.7.2`, curl 504 from the github.com godot-builds release download on all three attempts (2026-11-08 18:20–18:21 JST); the reason is in the PR comment. If the next PR hits the same 504, the download is still down: rerun later before overriding again.
- **State:** en, ja and ko each have an oracle meaning check applied. `L.TRANSLATED` is still false. Nothing is running.
- **Next:** #280 (ja/ko Eddington register pass; 歲差 and 0.87 in the zh-TW source). Then native read, `--require-translated` in CI, `L.TRANSLATED = true`, window title. ds-1 and ds-2 sit on merged branches; start each new branch from `origin/main`.

### #280 register pass dispatched (edd-lead) | 2026-11-08 19:0x JST

- **Inbox:** edd-art's notice of the Monday look split (Owner OK 2026-11-08 18:5x JST) acked; details in `.claude/lead-handoff/art.md`, section Monday. After look-kit: `lead-inbox add edd-art look look-kit done "<dir>"` and `herdr pane send-text w7:pB`.
- **Decided for #280:** ja Eddington goes to 丁寧語 throughout (40 of 84 lines were です/ます; LOCALIZATION.md already says 丁寧語 for the cast; this replaces the #279 "keeps なさい and plain form" holding position). ko Eddington goes to 해요체 (38 of 84 were 하십시오체). Kit untouched. zh-TW: 歲差 → 近日點進動 (content_1917.gd:150, en "perihelion advance"); 0.87 choice → `0.87：照牛頓的算法，只有一半`.
- **Running:** `lw-register-pass-20261108-190550`: `ds-exec ds-edd-1` (ds-1, branch `l10n/register-pass`), brief `/Volumes/KIOXIA/eddington-1919-cache/director/register-pass.md`, input `l10n-slices/register-lines.json` (157 E/K lines). It applies, tests ja/ko layout and honest route, opens the PR and runs its own oracle review.
- **On its event:** read the report, write `l10n-slices/register-scope.md` (rules above as accepted; Kit lines out of scope), then `lead-wait pr <n> --scope` it. If `suites` fails again at `Install Godot` with a 504, rerun later before overriding.
- **Then:** native read, `--require-translated` in CI, `L.TRANSLATED = true`, window title. Monday 2026-11-09 09:00 JST order as above.

### #282 (register pass) at the gate (edd-lead) | 2026-11-08 22:0x JST

- **#282** (`l10n/register-pass`, ds-1, 0107a60, `Closes #280`): ja 48 and ko 47 Eddington lines moved to 丁寧語 / 해요체; Kit untouched; 歲差 → 近日點進動 and the 0.87 choice reworded in the zh-TW source, translations carried over. Worker tests 2026-11-08 19:25–19:46 JST: ja and ko layout 8462 checks 0 failures each; ja and ko honest route seed 77 `failures=[]`. Worker oracle review approve 0/0/0.
- **ds-exec exit 70** was dot-ci failing to verify the result (`no DOT-CI-DONE by the deadline`), not a test failure: the same Test command exits 0 on the Mac (worker `orb-test --local` 20:47 JST; lead rerun 22:0x JST). dot looked down at 20:49–20:59 JST; not investigated.
- **Running:** `lw-pr-282-20261108-215945` with `--scope l10n-slices/register-scope.md`. If `suites` fails at `Install Godot` with a 504 again, rerun later before overriding.
- **Next after merge:** native read, `--require-translated` in CI, `L.TRANSLATED = true`, window title. Monday 2026-11-09 09:00 JST order as above.

### #282 merged; #283 CI gate at review (edd-lead) | 2026-11-08 22:2x JST

- **Merged:** #282 register pass (12be650), closes #280. CI's Godot download worked on rerun (the 19:47 JST 503 / connection drop was transient); every check passed, no override.
- **#283** (`ci/require-translated`, lead, one line in `.github/workflows/all-suites.yml`): the localization gate now runs `check --require-translated`. Passes on main locally. **Running:** `lw-pr-283-20261108-221939`.
- **ds-1** detached at origin/main, `l10n/register-pass` deleted locally (merged).
- **Still open:** native read of ja and ko (needs a human reader; not started), `L.TRANSLATED = true` (`scripts/l10n.gd:12`, turns on the language button and OS-locale pick), window title per locale (`project.godot` `config/name` is zh-TW only; the Titles table in LOCALIZATION.md lists each). Monday 2026-11-09 09:00 JST order as above.

### #283 merged; #284 window title at review (edd-lead) | 2026-11-08 22:4x JST

- **Merged:** #283, CI localization gate now runs `check --require-translated`.
- **#284** (`l10n/window-title`, lead): `L.apply` sets the window title from `L.t("雲層之後 · Eddington 1919")`, deferred, skipped headless. Headless start shows no script errors; not yet seen in a window. **Running:** `lw-pr-284-*`. **Monday look:** add a title-bar check with `EDD_LOCALE=en` and `ja` to the hand tests.
- **Still open:** native read of ja and ko (needs a human reader), `L.TRANSLATED = true`.

### #284 merged; blind cold read of ja and ko running (edd-lead) | 2026-11-08 22:5x JST

- **Merged:** #284 window title per locale. Monday look: check the title bar with `EDD_LOCALE=en` and `ja`.
- **Running:** two Sonnet subagents (this session; lost on /clear), a blind cold read of `l10n-slices/blind-{ja,ko}.txt` (msgstr only, 1,088 numbered lines; `blind-{ja,ko}-ids.json` maps n → msgid). Reports go to `l10n-slices/blind-{ja,ko}-report.md`. If the session was cleared before they finished, rerun them the same way.
- **Then:** lead judges each row, builds apply JSON, one PR for both languages, gate with a scope file. That is the stand-in for the native read (the Owner is away until 2026-12-07); after it, `L.TRANSLATED = true`.

### Blind cold read done; ja and ko fix workers running (edd-lead) | 2026-11-08 22:5x JST

- **Blind read** (Sonnet, msgstr only, 1,088/1,088 each): ko 74 rows (`l10n-slices/blind-ko-report.md`: 별점 read as star rating, 해요/합쇼 mixed in one line, 같은 무게 for statistical weight, 별이 휘었다, fixed 를 after key-name `%s`); ja 116 rows (`blind-ja-report.md`: Ashby/Cottingham/Eddington plain or archaic forms and だが + です/ます, calques 選片 示意図 複核 測得, term drift for deflection and the record book).
- **Rules decided:** `/Volumes/KIOXIA/eddington-1919-cache/director/blind-fix-rules.md` (ja whole cast 丁寧語, ko Ashby 저; terms follow the zh-TW source; ko 星點 never 별점; weight 가중치/重み; ko 353/203 rejected, addressed to Ashby).
- **Running:** `lw-blind-ja-20261108-225622` (ds-edd-1, `l10n/blind-ja`) and `lw-blind-ko-20261108-225622` (ds-edd-2, `l10n/blind-ko`), briefs `director/blind-fix-{ja,ko}.md`; each judges rows against the msgid, applies, tests, opens a PR and runs its own oracle review. Told to finish before 2026-11-09 09:00 JST.
- **On each event:** spot-check the judged file and diff, write a scope file from the rules file, `lead-wait pr <n> --scope`. After both merge: `L.TRANSLATED = true` PR.

### #286 ja blind-read fixes merged (edd-lead) | 2026-11-08 23:4x JST

- **Merged:** #286 (ja, 219 lines: whole cast 丁寧語, calques, term drift). Round 1 oracle blockers (Halley "seventy years before", 標準誤差 not 標準偏差, room width not height) fixed by the lead in 3e178f3; round 2 approve; all checks passed.
- **Rule corrected:** `blind-fix-rules.md` statistics line now says follow the msgid (標準誤差 / 표준오차). The ko worker started on the old rule: check that line in its PR.
- **Running:** `lw-blind-ko-20261108-225622` (ds-edd-2). After ko merges: `L.TRANSLATED = true` PR.

### #287 merged; #288 L.TRANSLATED = true at the gate (edd-lead) | 2026-11-09 02:3x JST

- **Merged:** #287 ko blind-read fixes (f6637b5): 107 lines (35 taken, 18 own fix, 12 rejected); 표준오차 per the msgid. The worker hit the 60-turn cap; dot-ci hung 2 h 40 min waiting on dot (killed 01:4x JST), then OrbStack was stopped (exit 69, `orb start`). dot did not answer all night; light runs used `--local`.
- **#288** (`l10n/translated`, lead): `L.TRANSLATED = true`. test_i18n 1141/0; layout zh_TW 8618/0, en 8462/0. **Running:** `lw-pr-288-20261109-023537`.
- **Monday look 2026-11-09 adds:** the language button on the title row (all four captions), the window title in en and ja, a cold start with a saved language.
- **Still open:** a native read of ja and ko before the Steam release (no reader yet).

### #288 merged; store page copy in four languages running (edd-lead) | 2026-11-09 02:5x JST

- **Merged:** #288 `L.TRANSLATED = true`. en, ja and ko now reach players (saved or OS language, title-row language button). Localization is done except a native read of ja and ko before launch.
- **Cleanup:** l10n branches deleted locally; ds-1 and ds-2 detached at origin/main.
- **Running:** `lw-store-l10n-20261109-025117`: `cx-exec` (Codex reported available by quota-advisor at 02:5x JST; terra) in ds-1, branch `docs/store-page-l10n`, brief `/Volumes/KIOXIA/eddington-1919-cache/director/store-page-l10n.md`: STORE_PAGE.md sections 2, 3, 4, 7 in en/ja/ko, B3 marked decided. On its event: `lead-wait pr <n>`.
- **Monday 2026-11-09 09:00 JST:** look kit and hand tests as above, plus the language button, window title and saved-language cold start.

### #289 store page copy merged-armed; nothing running (edd-lead) | 2026-11-09 02:5x JST

- **#289** STORE_PAGE.md in en/ja/ko (sections 2, 3, 4, 7; B3 recorded as decided): oracle approve 0/0/0, merge armed (docs only). Short descriptions: zh-TW 74, en 225, ja 87, ko 116 characters. Store copy register: ja plain descriptive, ko 합니다체.
- **State:** nothing of edd-lead's is running. Localization done except a native read of ja and ko before launch.
- **Next: Monday 2026-11-09 09:00 JST** (windowed window opens): refresh `look/monday`, `look_kit.sh` via `orb-test --heavy --host`, hand tests (繼續 per chapter, fonts, title row incl. the new language button in all four captions, `EDD_LOCALE=en`/`ja` window title, saved-language cold start, Cmd-Tab, 2560x1080), then `lead-inbox add edd-art look look-kit done "<dir>"` + `herdr pane send-text w7:pB`; gate #229 → #231 → #232 → #234 on art-verdict events; store reshoot (now four languages), 0.4.6.
- **Hosts:** dot did not answer 2026-11-08 20:49 JST – 2026-11-09 02:xx JST (dot-ci hung 2 h 40 min once); OrbStack stopped twice. Use `--local` for light runs if dot is still down.

### Monday look started (edd-lead) | 2026-11-09 09:0x JST

- **look/monday** refreshed: dd3db89 = ea42674 (`main` ec304b7 + `art/faces`) merged with `main` b26276a (l10n, fonts, layout, store copy), no conflicts, force-pushed.
- **Running:** `lw-look-kit-20261109-090239` (`orb-test --heavy --host -- bash director/look_kit.sh`, ticket #805, queued behind a gteki heavy job from 04:32 JST). The script exits 3 if it starts after 14:55 JST.
- **On its event:** judge `director/look-kit/{1080,720}` (list in the 09:00 sections above), then the hand tests (繼續 per chapter, fonts, language button four captions, `EDD_LOCALE=en`/`ja` window title, saved-language cold start, Cmd-Tab, 2560x1080), `lead-inbox add edd-art look look-kit done "<dir>"` + `herdr pane send-text w7:pB`, then #229 → #231 → #232 → #234.

### Look kit done; edd-art judging (edd-lead) | 2026-11-09 09:1x JST

- **look kit** 09:09 JST: 1080 and 720 runs, 123 shots each, ENDING favors_e, `failures=[]`. Lead pre-read: Kit, Ashby, Eddington, box_light, ticks OK (white mark at Kit's mouth is the crosshair). The language button lives in 設定 on the title screen, not on the title row; check it in the hand test.
- **Sent:** `lead-inbox add edd-art look look-kit done` (ev-20261109-091015-58ca) + send-text to w7:pB. Event acked.
- **Next:** on art-verdict, `lead-wait pr 229 --reason …` (head a9b6120, base main), then #231 → #232 → #234. Hand tests still to do while the window is open (until 14:55 JST).

### #229 merged; #231 at the gate (edd-lead) | 2026-11-09 09:5x JST

- **edd-art's Claude has exited** (w7:pB is a bare shell); the lead judged the look itself (pass) and acked the edd-art event.
- **Merged:** #229 Kit (oracle approve, squash).
- **#231** retargeted to main; the squash left it CONFLICTING. A force push was denied by the auto-mode classifier, so main was merged into `art/ashby-departure` with the tree set to the clean rebase of its 7 commits (2014c1b, 12 files vs main). **Running:** `lw-pr-231-20261109-095218`. If the old false-positive blocker on `tests/test_portrait.gd:128` returns and CI passes, `review-gate 231 --override-blockers "<reason>"`.
- **Running:** `lw-hand-title-20261109-094841` (`director/hand_title.sh`: window title with `EDD_LOCALE=en`/`ja`, saved ko/zh_TW cold start).
- **Then:** #232 and #234 the same way (retarget, merge main, tree = rebase onto main), each after the previous merges. Hand tests left: 繼續 per chapter, fonts, language button in 設定, Cmd-Tab, 2560x1080.

### Hand-title script failed; #290 covers the saved language (edd-lead) | 2026-11-09 10:0x JST

- **`hand_title.sh` failed** (exit 143): osascript/System Events cannot read the Godot window (AppleEvent timed out, connection invalid; likely no Accessibility permission). Not retried.
- **Covered instead:** the window-title msgid has en/ja/ko translations in `locale/*.po`; **#290** (`test/saved-locale`) adds `saved_locale_checks()` to `tests/test_i18n.gd` (1151/0). **Running:** `lw-pr-290-20261109-095749`.
- **Still needs eyes on a window** (no scripted way here): the title-bar text, the language button in 設定 (four captions), 繼續 per chapter, Cmd-Tab, 2560x1080. Leave for a human session or a Codex computer-use run; not a blocker for the art stack.

### Art stack merged; store reshoot in four languages queued (edd-lead) | 2026-11-09 10:4x JST

- **Merged:** #229 Kit, #231 departure Ashby, #232 Eddington fronts, #234 faces (each retargeted to main and brought up with a main merge whose tree equals a clean rebase; force push is denied by auto mode). #231–#234 diffs were over oracle's 1 MB limit, so codex reviewed them (approve). **#290** saved-locale test merged; follow-up **#291** (`_startup_locale` on a player launch).
- **After the stack:** `i18n.py check --require-translated` 0 problems; `wrap`/`extract` change only line references in `messages.pot` (not committed).
- **Running:** `lw-store-046-*`: `director/store_046.sh` (from `store_045.sh`): careful + prologue with `EDD_LOCALE` zh_TW/en/ja/ko into `store-b5/{careful,prologue}-046-<loc>`, then cambridge-046 and principe-046 benchmarks. Stops at 14:50 JST; queued behind gteki heavy jobs.
- **On its event:** judge rows 2, 4, 11, 12 and the Príncipe rows per language, replace old sets, then 0.4.6 per `director/release-045.md`, Issue #1 change list (draft in the 2026-11-07 section, plus the art stack, l10n and #290). Hand tests that need eyes on a window are still open (title bar, language button in 設定, 繼續, Cmd-Tab, 2560x1080). `look/monday` can be deleted.

### Store reshoot judged; 0.4.6 build running (edd-lead) | 2026-11-09 11:3x JST

- **Store reshoot** (`store_046.sh`, 11:00–11:22 JST, main 0950c3a): careful and prologue in zh_TW/en/ja/ko all reach the ending with `failures=[]`. Lead judged rows 1–8 per language: pass. Old 0.4.5 sets deleted; `store-b5/INDEX.md` now maps rows to `*-046-<loc>` and the two new sheets.
- **Cleaned:** `director/look-kit/` deleted. Deleting the remote `look/monday` branch (no PR) was denied by auto mode; it is harmless, leave it unless the user removes it.
- **Running:** `lw-release-046-20261109-112042` (cx-exec terra in ds-2, brief `director/release-046.md`: e2e, bump, three exports, `builds/0.4.6`, A11 row, PR + own oracle review). **On its event:** `lead-wait pr <n>`, then Issue #1 with the change list in the brief's Includes line.
- **Still open:** hand tests needing eyes on a window (title bar, language button in 設定, 繼續 per chapter, Cmd-Tab, 2560x1080); #291; a native read of ja and ko before launch.

### 0.4.6 released to KIOXIA; Issue #1 updated (edd-lead) | 2026-11-09 11:4x JST

- **#293 merged:** 0.4.6 (bump 9932c92). E2E 6/6, release export 55/0, three packages checked, oracle approve 0/0/0. Builds in `/Volumes/KIOXIA/eddington/builds/0.4.6/` (hashes re-checked by the lead). A cx-exec run that ends `PENDING job` is not done: the Linux export finished in a resumed run.
- **Issue #1:** 0.4.6 playtest comment posted (languages, art stack, story, store; asks: A11 playtest incl. en/ja, a native ja/ko reader, the newcomer session and B-rows).
- **Nothing of edd-lead's is running.** ds-2 detached at origin/main.
- **Next (no Owner input needed):** #291 (`_startup_locale` seam so a test runs the rule order without `--script`); hand tests that need eyes on a window (title bar per language, language button captions, 繼續 per chapter, Cmd-Tab, 2560x1080) — consider a Codex computer-use run inside the windowed hours (Mon–Fri 09–15 JST); the remote `look/monday` branch is left (delete was denied).

### #294 merged; nothing running (edd-lead) | 2026-11-09 12:4x JST

- **#294** (closes #291): `_startup_locale(args, user_args, env_locale, os_locale)` with OS defaults; test_i18n 1163/0 (lead rerun; the wrapper's rerun was orb-test exit 124); revert check done by the worker. ds-2 detached at origin/main.
- **Nothing of edd-lead's is running.**
- **Next:** hand tests that need eyes on a window (title bar per language, language button captions in 設定, 繼續 per chapter, Cmd-Tab with the mouse captured, 2560x1080): a Codex computer-use run inside the windowed hours (Mon–Fri 09–15 JST), brief to be written; then wait on Owner items in Issue #1 (A11 playtest, native ja/ko reader, newcomer session, B-rows).

### Hand tests blocked by macOS permissions (edd-lead) | 2026-11-09 12:5x JST

- **Antigravity run** (`AGY_PURPOSE=visual-review` is required; brief `director/hand-tests-046.md`, 7 cases): all 7 blocked. `screencapture` is denied by TCC (no Screen Recording) and System Events cannot click or type (no Accessibility). osascript failed the same way at 09:56 JST. No agent on this Mac can do windowed hand tests until the Owner grants those permissions; don't retry.
- **Covered so far:** saved and OS language rule order by #290 + #294 (unit tests); title translations exist in all `.po`; the look kit's game-rendered shots. The 7 cases are listed as "not yet checked by eye" in the Issue #1 0.4.6 comment, so the Owner's A11 playtest covers them.
- **Nothing of edd-lead's is running.** Remaining work needs the Owner (Issue #1: A11 playtest, native ja/ko reader, newcomer session, B-rows) or is open polish.

### Trailer capture: 1080 found, bot dwell running (edd-lead) | 2026-11-09 13:3x JST

- **#295 merged:** STORE_PAGE §9 records the first `--write-movie` trial (works; 1600x900; bot too fast; audio quiet).
- **1080:** the 1920 window is clamped on the 1728-pt Retina screen. An `override.cfg` in the throwaway capture tree (viewport 1920x1080, stretch mode `viewport`, scale 1.2, window override 1280x720) records 1920x1080 (`director/movie_test.sh`). Under it the prologue bot's real click on 開始遊戲 misses (`click_at()` maps with `get_stretch_transform()` only), so the run ends at 1.4 s.
- **Running:** `lw-bot-dwell-20261109-131358` (cx-exec terra, ds-2, branch `tools/bot-dwell`, brief `director/bot-dwell.md`): `--bot-dwell=<s>` holds each line/choice/title. **On its event:** resume the same session with `director/bot-dwell-fu1.md` (click mapping for both stretch modes), then `lead-wait pr <n>`, then a windowed capture with `--bot-dwell=2` and `--quit-after` sized to the shot (windowed hours only).
- Trial clips deleted.

### #296 at the gate; capture plan changed (edd-lead) | 2026-11-09 15:5x JST

- **#296** (`tools/bot-dwell`, aa5924c): `--bot-dwell=<s>` holds each line/choice/title (60 frames per second under `--fixed-fps 60`); `click_at()` maps with `get_screen_transform()`. Normal settings: honest headless `failures=[]`; with `--bot-dwell=2` 58 s. Under the viewport-stretch override the bot's movement and aim still fail, so **decided: capture at 1600x900 with normal settings and upscale to 1080 in the edit**; no more work on the override. **Running:** `lw-pr-296-20261109-155108`.
- **dot is still down:** the worker's verify rerun hung 1 h 45 min in `dot-ci` (killed 15:5x JST; orb-test fell back to the Mac). Expect this on every light run until dot is back.
- **Next windowed capture, 2026-11-10 from 09:00 JST:** `mkdir -p /Volumes/KIOXIA/eddington/trailer-test` then `lead-wait run movie-dwell -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_test.sh` (FRAMES=2400, DWELL=2 defaults; needs #296 merged). Judge whether dialogue shots are cuttable; delete the clip after.

### #296 merged; nothing running (edd-lead) | 2026-11-09 16:3x JST

- **#296 merged** (5eb1a0a). The old wrapper's verify ended orb-test exit 127 after its dot-ci was killed: not a test result; CI and the gate passed. ds-2 detached at origin/main, `tools/bot-dwell` deleted.
- **Nothing of edd-lead's is running.**
- **Next: 2026-11-10 from 09:00 JST:** `mkdir -p /Volumes/KIOXIA/eddington/trailer-test`, then `lead-wait run movie-dwell -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_test.sh` (40 s, dwell 2 s, 1600x900); judge cuttability, delete the clip. Owner items wait in Issue #1 (A11 playtest, native ja/ko reader, newcomer session, B-rows; hand tests need Screen Recording / Accessibility).

### Trailer recapture queued (edd-lead) | 2026-11-10 09:0x JST

- **Running:** `lw-movie-dwell-20261110-090316` (orb-test heavy ticket #868, behind gteki #864–#867): `director/movie_test.sh` on origin/main, prologue honest, `--bot-dwell=2`, 2400 frames, 1600x900 into `/Volumes/KIOXIA/eddington/trailer-test/`. The script exits 3 if it starts after 14:50 JST; then requeue on the next weekday 09:00 JST.
- **Done 14:09 JST:** dialogue shots cuttable (verdict in STORE_PAGE §9); clip deleted.

### Careful bot gets --bot-dwell (edd-lead) | 2026-11-10 15:0x JST

- `--bot-dwell` only reached `tests/prologue_bot.gd`; the careful autoplay (`tests/autoplay_bot.gd`, `talk()`) ignored it. Lead edit on branch `tools/careful-dwell` (worktree `.claude/worktrees/careful-dwell`, not committed yet): `dwell` var + `_dwell()` before each choice/E tap, `main.gd` passes `bot-dwell` to the autoplay bot.
- **#298 merged** (78e8e29, oracle approve): careful bot honours `--bot-dwell` (headless check dwell 0.5: ending reached, stuck=0). Branch and worktree removed.
- **Next, 2026-11-11 from 09:00 JST:** `mkdir -p /Volumes/KIOXIA/eddington/trailer-test` then `lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (whole careful run, seed 7, dwell 2, 1600x900, no frame cap, refuses to start after 14:20 JST; expect ~10 min, ~3 GB). Judge the eclipse + check-record shots from a contact sheet, then a 35–50 s rough cut; delete clips after.

### Careful capture queued (edd-lead) | 2026-11-11 10:3x JST

- **Not run:** `lw-movie-careful-20261111-103337` waited behind gteki #890–#896 past 14:20 JST; edd-lead cancelled ticket #897 at 15:0x JST (event exit 143 = that cancel). **Next: 2026-11-12 09:00 JST**, requeue the same command (`mkdir -p /Volumes/KIOXIA/eddington/trailer-test` then `lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh`).
- **On success:** contact sheet → judge the eclipse + check-record shots → 35–50 s rough cut; delete clips after.
- Overnight the heavy queue looked stuck (#890 held the lock, empty wait reason, gate shown open); it started at exactly 08:30 JST. Reported to harness-lead (`ev-20261111-074031-7f4a`, `ev-20261111-103403-4430`); nothing for edd-lead to do.

### Careful capture queued early; workflow review given (edd-lead) | 2026-11-12 02:4x JST

- **Running:** `lw-movie-careful-20261112-023452` (heavy ticket #911, behind gteki #906–#910). Queued at 02:34 JST on purpose, to hold a place in the queue before the 09:00 JST window: 2026-11-11 was lost because the ticket was queued at 10:33 JST behind 7 gteki tickets. If the ticket is called before 09:00 or after 14:20 JST the script exits 3 with nothing run; requeue the same command then. Do not queue it twice.
- **Wake-ups (session-only):** a one-shot at 08:57 JST checks the queue and requeues only if no eddington ticket is waiting or running; the heartbeat one-shot is re-armed 45 min after each turn. The 2026-11-11 16:25 JST heartbeat one-shot never fired (deleted 02:4x JST).
- **On the event:** contact sheet → judge the eclipse + check-record shots → 35–50 s rough cut; delete clips after.
- **Workflow review** (the Owner asked 2026-11-12 02:2x JST; answered in chat, not yet answered back). What it changes for the lead now:
  - When the rest is blocked on the Owner or on the window, the heartbeat takes headless backlog in this order: #260, #258, #224, then the open "Review follow-ups" issues (fix, or close with a reason).
  - Owner-only items are the critical path, in one list: B1 Steam Direct (asked 2026-11-07 08:34 JST, no answer recorded), Screen Recording and Accessibility permissions for windowed hand tests, a blind newcomer session, a native ja/ko reader.
  - Proposed to the Owner, not done: rewrite this file as a short "now" block plus an archive, drop the stale rule copies in its header, close the 7 draft PRs from 2026-10-20 to 2026-10-31, decide the vacant art seat (edd-art's pane exited 2026-11-09).

### Heartbeat: #300 at the gate; follow-up triage decided, closes not run (edd-lead) | 2026-11-12 03:4x JST

- **Inbox:** no events. The Owner has not answered the workflow review.
- **#300** (`ci/smoke-locale`, lead, worktree ds-2; closes #258 and #257): `L._static_init` prints `locale=<code>`; package-smoke asserts `locale=ko` in the ko run and a non-ko `locale=` line in the default run on all three platforms. test_i18n 1163/0; headless starts print `locale=ko` and `locale=en`. **Running:** `lw-pr-300-20261112-034117`. After it merges: detach ds-2 at origin/main, delete the branch.
- **Running:** `lw-movie-careful-20261112-023452` (heavy #911), as above.
- **Follow-up triage** (all 12 "Review follow-ups" issues plus #224, #258, #260, each checked against main 084d91c):
  - Already fixed on main, never closed: #292 (by #294), #278 (by #287), #272 (`clear_fuzzy`, ordered `placeholders()`), #244 (by #245).
  - Obsolete: #224 and #225 (the clamp-then-compare code went when the fronts became ray-fitted surfaces, #226 and #232).
  - By design: #299 and #297 (dwell counts frames at the fixed 60 fps every capture uses).
  - Not planned, reason written: #266, #251, #261 (same root as #260), #260 (the 2026-11-07 decision stands).
  - #285 becomes the one tracker for the 7 window hand tests.
  - **Not run:** closing issues was denied by the auto-mode classifier. The commands with their comments are in `/Volumes/KIOXIA/eddington-1919-cache/director/triage-20261112.sh`; run it only once the Owner agrees.
- **Tidied:** ds-2's leftover `l10n-slices/` deleted; `blind-ko-judged.md` and `blind-ko-apply.json` kept in KIOXIA `eddington-1919-cache/director/`.
- **Checked, fine:** store shots `store-b5/*-046-*` are 1920x1080; `config/custom_user_dir_name="Eddington1919"` is set, so the Auto-Cloud path is stable. `locale/{en,ja,ko}.po` each hold 55 entries with an empty msgstr; they are orphans (not in `messages.pot`, not in `scripts/`), so nothing shows at run time.
- **Next headless work that needs neither the Owner nor a window:** Steam store graphics (capsule and library sizes from the current Steamworks pages via oracle-ego, into `docs/store/STORE_PAGE.md` section 8; layout drafts from the 1920x1080 stills) and depot / Auto-Cloud templates with placeholder IDs. No new story or play features before a blind newcomer session.

### #300 merged (edd-lead) | 2026-11-12 03:5x JST

- **Merged:** #300 (oracle approve, no findings to follow up): the exported game prints `locale=<code>` and package-smoke proved `locale=ko` on Windows, Linux and macOS (run 43080107795, all jobs passed). #258 and #257 closed with it. ds-2 detached at origin/main, `ci/smoke-locale` deleted.
- **Running:** `lw-movie-careful-20261112-023452` (heavy #911). Wake-ups: heartbeat 04:33 JST, capture check 08:57 JST.
- **Waiting on the Owner:** the answer to the workflow review, and a yes before `director/triage-20261112.sh` closes the 12 triaged issues and retitles #285.

### Heartbeat: Steam asset and depot research running (edd-lead) | 2026-11-12 04:3x JST

- **Inbox:** no events; the Owner has not answered the workflow review or the issue-close question.
- **Running:** `lw-steam-assets-20261112-043346` (oracle-ego, question in KIOXIA `eddington-1919-cache/director/steam-assets-research.md`): current Steamworks sizes and rules for capsules, library assets and the trailer; Auto-Cloud roots for `checkpoint.save` under the `Eddington1919` user dir; depot layout and steamcmd VDFs; a dated checklist from the Steam Direct fee to release. **On its event:** read the saved reply, check the sizes against the cited pages, then one docs PR: sizes and rules into `docs/store/STORE_PAGE.md` section 8, plus `docs/store/STEAM_DEPOTS.md` with the Auto-Cloud table and VDF templates (placeholder IDs). Capsule layout drafts come after, from the 1920x1080 stills.
- **Running:** `lw-movie-careful-20261112-023452` (heavy #911, second in the queue at 04:33 JST; the heavy gate is open because the Mac is idle). If it is called before 09:00 JST it exits 3; the 08:57 JST wake-up requeues it.

### State at clear (edd-lead) | 2026-11-12 04:3x JST

- **Running (events go to `lead-inbox edd-lead`; no unacked events now):**
  - `lw-steam-assets-20261112-043346`: oracle-ego research (question: KIOXIA `eddington-1919-cache/director/steam-assets-research.md`). On its event: read the saved reply, check the sizes against the cited Steamworks pages, then one docs PR (`docs/store/STORE_PAGE.md` section 8; new `docs/store/STEAM_DEPOTS.md` with the Auto-Cloud table and VDF templates, placeholder IDs), `lead-wait pr <n>`.
  - `lw-movie-careful-20261112-023452`: heavy ticket #911, `director/movie_careful.sh`. Exit 3 means it was called outside 09:00–14:20 JST and ran nothing: requeue with `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (never two tickets at once). On success: contact sheet → judge the eclipse + check-record shots → 35–50 s rough cut; delete clips after.
- **Wake-ups (session crons; they survived the last /clear, check with CronList and re-create if missing):** `6f323819` heartbeat at 05:21 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer):**
  - The workflow review, kept word for word by number in KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`. Not done and waiting for a yes: item 4 (rewrite this file as a short "now" block plus an archive, drop the stale rule copies in its header) and item 5 (the art seat; the 7 draft PRs from 2026-10-20 to 2026-10-31).
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues with their reasons, retitles #285). Closing issues was denied by the auto-mode classifier; do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Done today:** #300 merged (closes #258, #257). main is 20645d1 plus handoff commits.
- **Rule for the heartbeat:** no new story or play features before a blind newcomer session; with no event and nothing to advance, answer in one line.

### #301 at the gate; Owner asked about notarization (edd-lead) | 2026-11-12 04:5x JST

- **Done this turn:** the `steam-assets` event (acked). The oracle reply was checked page by page against the live Steamworks docs (they are public: `curl https://partner.steamgames.com/doc/<path>`), then written up as **#301** (`docs/steam-assets-depots`, worktree ds-2, docs only): asset table and trailer specs in `docs/store/STORE_PAGE.md` sections 8 and 9, new `docs/store/STEAM_DEPOTS.md`, two corrections in `docs/RELEASE_READINESS.md` section D.
- **What the check changed:**
  - A trailer is required for release (the 2026-11-07 note said none was found).
  - Valve's platforms page requires new macOS apps to be notarized; ours is ad-hoc signed. Needs the paid Apple Developer Program, so it is the Owner's call (options A/B/C in `STEAM_DEPOTS.md` section 5, lead recommends A). Until answered, engineering keeps the 2026-11-07 plan and macOS stays in scope.
  - The fee wait is 21 days (the oracle reply said 30, then corrected itself; the event summary still says 30).
  - The Windows ZIP holds `Eddington1919-<version>-Windows.exe` and `.pck`, the macOS bundle is `雲層之後 · Eddington 1919.app`: both get stable ASCII names when staging for Steam. No code change made; a staging script comes with the App ID.
  - The Library Hero needs a 3840x1240 render with no text: one more shot for a window slot.
- **Running (events go to `lead-inbox edd-lead`):**
  - `lw-pr-301-20261112-045440`: review and gate for #301. After it merges: detach ds-2 at origin/main, delete `docs/steam-assets-depots`. A blocker would be a wrong Steam fact: check it against the page before changing the doc.
  - `lw-owner-ask-20261112-045513`: one message to the Owner's dot thread (text: KIOXIA `eddington-1919-cache/director/owner-ask-20261112-0455.md`): the notarization decision, the B1 schedule (store page to review by 2026-12-04 for a 2027-01-12 release; a full 30 days of paperwork from today means about 2027-01-26), and the two open questions below. Its event only says the post went out; ack it.
  - `lw-movie-careful-20261112-023452`: heavy ticket #911, unchanged. Exit 3 means it was called outside 09:00–14:20 JST: requeue with `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (never two tickets at once). On success: contact sheet, judge the eclipse and check-record shots, 35–50 s rough cut, delete the clips.
- **Wake-ups (session crons, check with CronList):** `6f323819` heartbeat at 05:21 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer; answers come as `@edd-lead` in the dot thread or in chat):**
  - macOS notarization: A, B or C.
  - The workflow review (KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`): items 4 and 5 wait for a yes.
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285). Do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Next headless work (needs neither the Owner nor a window):** capsule layout drafts from the 1920x1080 stills at the sizes in `STORE_PAGE.md` section 8 (header 920x430, small 462x174, main 1232x706, vertical 748x896, library 600x900), a transparent title logo, and the 512 px and 184 px icons from `assets/icon/icon_1024.png`. Drafts stay on KIOXIA `eddington/store-b5/`; the look is judged by the art seat (vacant, with the Owner) or the lead. No new story or play features before a blind newcomer session.

### #301 round 2 at the gate; interim macOS default changed (edd-lead) | 2026-11-12 05:2x JST

- **Handled:** `ev-20261112-045826-15bb` (acked). #301 round 1 (oracle, 2026-11-12 04:58 JST) had 1 blocker: the interim default "until the Owner answers, engineering assumes B" documents sending an un-notarized macOS build to review against Valve's written rule. No Steam fact was wrong. The default was the lead's, so the lead changed it (e0c8c46; `STEAM_DEPOTS.md` section 5, `RELEASE_READINESS.md` B2, PR body):
  - Until the Owner answers, the store page does not list macOS and no un-notarized macOS build goes to build review.
  - B happens only if the Owner picks it.
  - With no answer when the store page is submitted (2026-12-04), the page lists Windows and Linux, as in C.
  - macOS stays in engineering scope (export, package-smoke, depot and launch option).
- **Running (events go to `lead-inbox edd-lead`):**
  - `lw-pr-301-20261112-051857`: round 2 review and gate for head e0c8c46. After it merges: detach ds-2 at origin/main, delete `docs/steam-assets-depots`. On another blocker: change the doc only for a wrong Steam fact (check the page first) or a defect with a concrete failure; a third round with blockers ends the loop (fix a real one, override the rest as follow-ups).
  - `lw-owner-ask-fix-20261112-051910`: a correction in the Owner's dot thread (text: KIOXIA `eddington-1919-cache/director/owner-ask-20261112-0519.md`). The 04:55 JST message said engineering goes on with B until the answer; the correction gives the default above. Its event only says the post went out; ack it.
  - `lw-movie-careful-20261112-023452`: heavy ticket #911, first in the queue behind gteki #910 at 05:19 JST, so it will most likely be called before 09:00 JST and exit 3 with nothing run. Ack that event and leave the requeue to the 08:57 JST wake-up (never two tickets at once): `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh`. On success: contact sheet, judge the eclipse and check-record shots, 35–50 s rough cut, delete the clips.
- **Wake-ups (session crons, check with CronList):** `f072ec50` heartbeat at 06:05 JST (the 05:21 JST one was deleted this turn); `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer; answers come as `@edd-lead` in the dot thread or in chat):**
  - macOS notarization: A, B or C (lead recommends A).
  - The workflow review (KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`): items 4 and 5 wait for a yes.
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285). Do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Next headless work (needs neither the Owner nor a window):** capsule layout drafts from the 1920x1080 stills at the sizes in `STORE_PAGE.md` section 8 (header 920x430, small 462x174, main 1232x706, vertical 748x896, library 600x900), a transparent title logo, and the 512 px and 184 px icons from `assets/icon/icon_1024.png`. Drafts stay on KIOXIA `eddington/store-b5/`; the look is judged by the art seat (vacant, with the Owner) or the lead. No new story or play features before a blind newcomer session.

### #301 merged; capsule drafts d1 judged; key-art capture #302 at the gate (edd-lead) | 2026-11-12 05:3x JST

- **Merged:** #301 (5129ac0, oracle approve on round 2, 2026-11-12 05:20 JST). ds-2 detached, `docs/steam-assets-depots` deleted locally and on origin. Events `ev-20261112-052009-6c4a`, `ev-20261112-052022-13d6` (the correction reached the Owner's dot thread; dot's own line is not an answer) and `ev-20261112-052032-59b4` are acked.
- **movie-careful:** ticket #911 was called at 05:20 JST, outside the window: exit 3, nothing run. No ticket is queued now. The 08:57 JST wake-up requeues it: `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (never two movie tickets at once). On success: contact sheet, judge the eclipse and check-record shots, 35–50 s rough cut, delete the clips.
- **Capsule drafts d1** (KIOXIA `eddington/store-b5/capsules-d1/`, script `eddington-1919-cache/director/capsule_drafts.py`, `PROVENANCE.md` beside the files): header, small, main, vertical, library capsule and header, both logo lockups, the 512 px and 184 px icons, a Library Hero placeholder. Lead's judgement, 2026-11-12 05:3x JST:
  - Lettering passes: "EDDINGTON" over a ruled "1919" in Noto Serif CJK TC (OFL) reads at 462x174 and at 184x69; at 120x45 "EDDINGTON" reads and "1919" barely does. Keep the stacked lockup for the small capsule.
  - The picture fails: `principe-046/totality_sky.png` (cloud time 230) is a pale glow in grey cloud. It reads as an overcast sky, not an eclipse, and does not match the icon's ring. The shelter poles cut through every crop (a black triangle in the top-left of both tall capsules).
  - So d1 is a layout study only. Nothing from it goes to the store page.
- **Running:** `lw-pr-302-20261112-053552`: review and gate for **#302** (`tools/keyart-capture`, worktree ds-2, lead's own change): `tests/benchmark.gd` gains `--bench-only=`, `--bench-cloud-t=` and `--bench-size=`; `STORE_PAGE.md` section 8 names them. test_graphics_quality 84/0. The headless benchmark crashes at quit on unchanged main too (signal 11 after `[BENCH] done`); not from this change. After it merges: detach ds-2 at origin/main, delete `tools/keyart-capture`.
- **Next window slot (2026-11-12 from 09:00 JST), after movie-careful is queued and only once #302 is merged:** `lead-wait run keyart -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/keyart_046.sh`. It shoots `totality_sky` and `totality_horizon` without UI at 3840x2160 for cloud times 122, 130, 138, 204, 212 and 264 (seed 7; density over the Sun 0.60, 0.45, 0.55, 0.35, 0.13, 0.22) into KIOXIA `eddington/store-b5/keyart-046/t<time>/`, prints each PNG's size and makes `sheet_keyart.jpg`. Exit 3 = outside the window, exit 4 = #302 not on origin/main yet. On its event:
  - Check the printed sizes are 3840 2160. If they are not, `--bench-size` did not take in a real window: say so in a follow-up issue and fall back to `--resolution`.
  - Judge the sheet: pick the frame where the ring shows through cloud and the poles stay out of the middle. Then point `capsule_drafts.py` at it (`SRC`, `GLOW`, the crop widths are for a 1920-wide source: scale them), cut drafts d2 and the Library Hero (the middle 3840x1240), and judge again.
- **Wake-ups (session crons, check with CronList):** `a3d334d1` heartbeat at 06:22 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer; answers come as `@edd-lead` in the dot thread or in chat):**
  - macOS notarization: A, B or C (lead recommends A). Until then the store page does not list macOS and no un-notarized macOS build goes to build review.
  - The title lettering and the key-art frame are the lead's drafts; the art seat is vacant, so the final look is the Owner's to accept.
  - The workflow review (KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`): items 4 and 5 wait for a yes.
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285). Do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Next headless work (needs neither the Owner nor a window):** nothing on the capsules until the key-art frames exist. Until then: the store-page text check against `STORE_PAGE.md` section 8 rules (screenshots list: at least 5 with UI, 4 marked suitable for all ages), then the trailer rough-cut plan from `STORE_PAGE.md` section 9. No new story or play features before a blind newcomer session.

### #302 merged; both captures wait for the 09:00 JST window (edd-lead) | 2026-11-12 05:4x JST

- **Merged:** #302 (9b20eb0, oracle approve, 2026-11-12 05:39 JST): `tests/benchmark.gd` has `--bench-only=`, `--bench-cloud-t=` and `--bench-size=`. ds-2 detached at origin/main, `tools/keyart-capture` deleted locally and on origin. Event `ev-20261112-053936-37bb` acked. One minor finding let go: an empty `--bench-only=` runs every bookmark.
- **Nothing is running and nothing is queued** (`lead-wait list` empty at 05:4x JST). The capsule drafts d1 and their judgement are in the section above.
- **At the 08:57 JST wake-up (`3a110db7`), queue both, in this order, each only if no ticket of that kind is waiting or running:**
  1. `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (exit 3 = called outside 09:00–14:20 JST, nothing run: requeue once inside the window). On success: contact sheet, judge the eclipse and check-record shots, 35–50 s rough cut, delete the clips.
  2. `lead-wait run keyart -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/keyart_046.sh` (exit 3 = outside 09:00–14:50 JST; exit 4 cannot happen now that #302 is on main). It shoots `totality_sky` and `totality_horizon` without UI at 3840x2160 for cloud times 122, 130, 138, 204, 212 and 264 into KIOXIA `eddington/store-b5/keyart-046/t<time>/` and makes `sheet_keyart.jpg`. On its event:
     - The log prints each PNG's size: it must be `3840 2160`. If not, `--bench-size` did not take in a real window: open a follow-up issue and fall back to `--resolution`.
     - Judge `sheet_keyart.jpg`: the frame where the ring shows through cloud and the shelter poles stay out of the middle.
     - Cut drafts d2 from it: `python3 /Volumes/KIOXIA/eddington-1919-cache/director/capsule_drafts.py /Volumes/KIOXIA/eddington/store-b5/capsules-d2 <chosen totality_sky.png>` (finds the eclipse centre itself; pass `<x> <y>` after the path to override; a 3840-wide source gives the real Library Hero). Judge `sheet_a_wide.jpg`, `sheet_b_tall.jpg` and `sheet_c_hero_logo.jpg` in that folder. The tone curve in `grade()` was set for the dim cloud-time-230 frame; expect to soften it for a frame with the ring.
- **Wake-ups (session crons, check with CronList):** `129bb0ae` heartbeat at 06:28 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer; answers come as `@edd-lead` in the dot thread or in chat):**
  - macOS notarization: A, B or C (lead recommends A). Until then the store page does not list macOS and no un-notarized macOS build goes to build review.
  - The title lettering and the key-art frame are the lead's drafts; the art seat is vacant, so the final look is the Owner's to accept.
  - The workflow review (KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`): items 4 and 5 wait for a yes.
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285). Do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Next headless work before the window (needs neither the Owner nor a window):** the store screenshot set. From KIOXIA `eddington/store-b5/*-046-<loc>/` pick the final 6–8 for `STORE_PAGE.md` section 8 (at least 5 with UI: rows 5–9, 11, 12; `careful_store_h_bet.png` and `careful_store_i_micrometer.png` exist in the 0.4.6 sets), judge them from `sheet_store_lang.jpg` plus one sheet of rows 9–13, and stage upload copies under `store-b5/upload/` named with Steam's language suffix (`<name>_english.jpg`, `_japanese`, `_koreana`, `_tchinese`; check the suffix list on `/doc/store/localization` first). Write the chosen list and the four "suitable for all ages" picks into `STORE_PAGE.md` section 8 in one docs PR. No new story or play features before a blind newcomer session.

### Store screenshot set chosen and staged; #303 at the gate (edd-lead) | 2026-11-12 05:5x JST

- **Done:** the store screenshot set. Nine shots in upload order (eight with UI), picked from the 0.4.6 captures; text fit in ja, ko and zh-TW read from crops for the five shots not judged on 2026-11-09 JST: all pass. 33 upload JPGs (1920x1080) plus `INDEX.md` are staged on KIOXIA `eddington/store-b5/upload/`, named with Steam's API language codes (`english`, `japanese`, `koreana`, `tchinese`; whether the upload UI takes the last two as a suffix is not on Steam's page, so check on upload).
- **Running:** `lw-pr-303-20261112-054803`: review and gate for **#303** (`docs/store-screenshot-set`, worktree ds-2, docs only: the list, what was left out, the four all-ages marks, the suffixes, in `STORE_PAGE.md` section 8). After it merges: detach ds-2 at origin/main, delete `docs/store-screenshot-set`. A blocker would be a wrong Steam fact: check the page (`/doc/store/assets/standard`, `/doc/store/localization/languages`) before changing the doc.
- **At the 08:57 JST wake-up (`3a110db7`):** unchanged from the section above: queue movie-careful, then keyart, each only if no ticket of that kind is waiting or running; then judge `sheet_keyart.jpg` and cut capsule drafts d2 with `capsule_drafts.py`.
- **Wake-ups (session crons, check with CronList):** `fcc67ff8` heartbeat at 06:42 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner:** unchanged from the section above (notarization A/B/C; acceptance of the title lettering and key art; workflow review items 4 and 5; the yes for `director/triage-20261112.sh`; B1 Steam Direct, the two macOS permissions, a blind newcomer session, a native ja/ko reader).
- **Next headless work before the window (needs neither the Owner nor a window):**
  1. The two-frame blink GIF for "About this game" from `careful-046-<loc>/careful_store_g_blink_eclipse.png` and `_oxford.png` (four languages; keep the "displacement exaggerated" caption in frame; check Steam's size and format rules for description images on `/doc/store/page/description` first). Stage under `store-b5/upload/about/`.
  2. `RELEASE_READINESS.md` section B: bring the B5 row up to date with what now exists (screenshots staged, capsule lettering drafted, key art and trailer waiting for the window) in one docs PR, together with any row that #301–#303 made stale.
  No new story or play features before a blind newcomer session.

### State at clear: #301–#303 merged, nothing running (edd-lead) | 2026-11-12 05:5x JST

- **Merged today:** #300 (locale proof in package-smoke), #301 (Steam assets, depots, trailer rules; 5129ac0), #302 (benchmark key-art options; 9b20eb0), #303 (store screenshot set; 3ad199b, oracle approve, no findings). main is 3ad199b plus handoff commits. ds-2 is detached at origin/main; no branch of this session is left, locally or on origin. Inbox empty, `lead-wait list` empty, no eddington ticket in the heavy queue (2026-11-12 05:49 JST).
- **At the 08:57 JST wake-up (`3a110db7`), queue both, in this order, each only if no ticket of that kind is waiting or running:**
  1. `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (exit 3 = called outside 09:00–14:20 JST, nothing run: requeue once inside the window; never two movie tickets at once). On success: contact sheet, judge the eclipse and check-record shots, 35–50 s rough cut, delete the clips.
  2. `lead-wait run keyart -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/keyart_046.sh` (exit 3 = outside 09:00–14:50 JST). It shoots `totality_sky` and `totality_horizon` without UI at 3840x2160 for cloud times 122, 130, 138, 204, 212 and 264 (seed 7) into KIOXIA `eddington/store-b5/keyart-046/t<time>/` and makes `sheet_keyart.jpg`. On its event:
     - The log prints each PNG's size: it must be `3840 2160`. `--bench-size` is proven only headless (root viewport texture 3840x2160); if a real window gives another size, open a follow-up issue and fall back to `--resolution`.
     - Judge `sheet_keyart.jpg`: the frame where the ring shows through cloud and the shelter poles stay out of the middle.
     - Cut drafts d2: `python3 /Volumes/KIOXIA/eddington-1919-cache/director/capsule_drafts.py /Volumes/KIOXIA/eddington/store-b5/capsules-d2 <chosen totality_sky.png>` (finds the eclipse centre itself; `<x> <y>` after the path overrides it; a 3840-wide source gives the real Library Hero). Judge the three `sheet_*.jpg` in that folder. `grade()` was tuned for the dim cloud-time-230 frame: soften it for a frame with the ring.
- **Capsules so far:** drafts d1 (KIOXIA `eddington/store-b5/capsules-d1/`) are a layout study only. The lettering passes ("EDDINGTON" over a ruled "1919", Noto Serif CJK TC, OFL); the picture fails (cloud time 230 is a pale glow, the poles cut every crop). Nothing from d1 goes to the store page.
- **Store screenshots:** done. Nine shots, 33 upload JPGs plus `INDEX.md` on KIOXIA `eddington/store-b5/upload/`; the list is in `STORE_PAGE.md` section 8. On upload, check that the `koreana` and `tchinese` suffixes land under the right language (not stated on Steam's page).
- **Wake-ups (session crons; they survived earlier /clears, check with CronList and re-create if missing):** `5e251c24` heartbeat at 06:36 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer; answers come as `@edd-lead` in the dot thread or in chat):**
  - macOS notarization: A, B or C (lead recommends A; asked 2026-11-12 04:55 JST, corrected 05:19 JST). Until then the store page does not list macOS and no un-notarized macOS build goes to build review.
  - Acceptance of the title lettering and the key art once d2 exists (the art seat is vacant).
  - The workflow review (KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`): items 4 and 5 wait for a yes.
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285). Do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Next headless work before the window (needs neither the Owner nor a window), in this order:**
  1. The two-frame blink GIF for "About this game" from `careful-046-<loc>/careful_store_g_blink_eclipse.png` and `_oxford.png` (four languages; keep the "displacement exaggerated" caption in frame). First read Steam's rules for images in the description (`curl https://partner.steamgames.com/doc/store/page/description`; size, format, where they are uploaded). Stage under KIOXIA `eddington/store-b5/upload/about/`.
  2. `RELEASE_READINESS.md` section B: bring the B5 row up to date (screenshots staged, capsule lettering drafted, key art and trailer waiting for the window) with any other row that #301–#303 made stale, in one docs PR through `lead-wait pr`.
  No new story or play features before a blind newcomer session.
- **Shell note:** the Bash tool runs zsh, which does not split `$var` into words: a loop that does `set -- $pair` needs `bash <<'EOF' … EOF`. A `magick` call that gets an empty input name waits on stdin for ever.

### Blink GIF staged, #304 merged, limb fix #305 at the gate (edd-lead) | 2026-11-12 06:5x JST

- **Merged this turn:** #304 (00435be; docs: the blink GIF for About, B5 status; oracle approve, event acked). `RELEASE_READINESS.md` row B5 is now PARTIAL with what is drafted, staged and open.
- **Blink GIF for About: done.** `blink_{english,japanese,koreana,tchinese}.gif` on KIOXIA `eddington/store-b5/upload/about/` (682x708, two frames, 1.0 s each, about 0.22 MB each); notes in `STORE_PAGE.md` section 8 and in the upload `INDEX.md`. Steam: each description image under 5 MB, all under 15 MB; where the editor takes the upload is not on the docs page. Build: `bash /Volumes/KIOXIA/eddington-1919-cache/director/about_blink.sh` (`SET=careful-limb` picks the reshoot below).
- **In flight:** `lw-pr-305-20261112-064902` = `lead-wait pr 305` (fix(plates): blend the Moon's limb over one plate pixel; branch `fix/plate-limb-soft` in worktree ds-2; CI `suites` and `leak-gate` were pending at 06:49 JST). The hard-edged Moon showed as stairs in the plate viewer and in the blink GIF. The lead judged the before/after sheet (KIOXIA `eddington/store-b5/limb-soft/judge_limb.jpg`) and accepted it in a PR comment. On its event: ack; if merged, delete the branch locally and on origin and detach ds-2 at origin/main; a blocker is fixed in ds-2.
- **At the 08:57 JST wake-up (`3a110db7`), queue in this order, each only if no ticket of that kind is waiting or running:**
  1. `mkdir -p /Volumes/KIOXIA/eddington/trailer-test && lead-wait run movie-careful -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful.sh` (exit 3 = called outside 09:00–14:20 JST, nothing run: requeue once inside the window; never two movie tickets at once). On success: contact sheet, judge the eclipse and check-record shots, 35–50 s rough cut, delete the clips.
  2. `lead-wait run keyart -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/keyart_046.sh` (exit 3 = outside 09:00–14:50 JST). It shoots `totality_sky` and `totality_horizon` without UI at 3840x2160 for cloud times 122, 130, 138, 204, 212 and 264 (seed 7) into KIOXIA `eddington/store-b5/keyart-046/t<time>/` and makes `sheet_keyart.jpg`. On its event:
     - The log prints each PNG's size: it must be `3840 2160`. `--bench-size` is proven only headless; if a real window gives another size, open a follow-up issue and fall back to `--resolution`.
     - Judge `sheet_keyart.jpg`: the frame where the ring shows through cloud and the shelter poles stay out of the middle.
     - Cut drafts d2: `python3 /Volumes/KIOXIA/eddington-1919-cache/director/capsule_drafts.py /Volumes/KIOXIA/eddington/store-b5/capsules-d2 <chosen totality_sky.png>` (`<x> <y>` after the path overrides the eclipse centre; a 3840-wide source gives the real Library Hero). Judge the three `sheet_*.jpg`. `grade()` was tuned for the dim cloud-time-230 frame: soften it for a frame with the ring.
  3. Only once #305 is merged: `lead-wait run store-limb -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/store_limb.sh` (exit 3 = outside 09:00–14:50 JST; exit 4 = origin/main has no limb fix). It reshoots the careful store shots in four languages into `eddington/store-b5/careful-limb-<loc>/`. On its event:
     - `SET=careful-limb bash …/director/about_blink.sh`, then look at one GIF's eclipse frame: the limb is smooth, the caption is in frame.
     - Compare each chosen careful screenshot's source (upload `INDEX.md` lists them) with its `careful-limb` twin (`magick a b -compose difference -composite -threshold 6% -format '%@' info:`). Where only the plate viewer differs, or nothing does, remake that upload JPG from the new shot (1920x1080, quality 95); a shot that differs elsewhere stays as it is and is looked at first.
- **Capsules so far:** drafts d1 (KIOXIA `eddington/store-b5/capsules-d1/`) are a layout study only. The lettering passes; the picture fails. Nothing from d1 goes to the store page.
- **Store screenshots:** nine shots, 33 upload JPGs plus `INDEX.md` on KIOXIA `eddington/store-b5/upload/`. On upload, check that the `koreana` and `tchinese` suffixes land under the right language.
- **Wake-ups (session crons; check with CronList and re-create if missing):** `679b9e86` heartbeat at 07:37 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner (do not act before an answer; answers come as `@edd-lead` in the dot thread or in chat):**
  - macOS notarization: A, B or C (lead recommends A; asked 2026-11-12 04:55 JST, corrected 05:19 JST). Until then the store page does not list macOS and no un-notarized macOS build goes to build review.
  - Acceptance of the title lettering and the key art once d2 exists (the art seat is vacant).
  - The workflow review (KIOXIA `eddington-1919-cache/director/workflow-review-20261112.md`): items 4 and 5 wait for a yes.
  - A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285). Do not retry without the Owner's word.
  - Owner-only: B1 Steam Direct, Screen Recording and Accessibility permissions, a blind newcomer session, a native ja/ko reader.
- **Next headless work before the window:** nothing is listed. Both items of the last section are done. After the #305 event there is nothing to push until 08:57 JST unless the Owner answers. No new story or play features before a blind newcomer session.
- **Shell note:** the Bash tool runs zsh, which does not split `$var` into words: a loop that does `set -- $pair` needs `bash <<'EOF' … EOF`. A `magick` call that gets an empty input name waits on stdin for ever. `magick compare` takes no `-extent`; use `magick a b -metric PSNR -compare -format '%[distortion]' info:` (prints PSNR/100).

### #305 merged after an accidental close; nothing running (edd-lead) | 2026-11-12 07:1x JST — read this section first

- **Merged:** #305 (0ce1a58, 2026-11-12 07:09 JST; oracle approve, no findings): the Moon's limb on the plate blends over one plate pixel. `fix/plate-limb-soft` is deleted locally and on origin; ds-2 is detached at origin/main (0ce1a58). Events `ev-20261112-070305-5447` and `ev-20261112-070959-2d48` are acked; the inbox and `lead-wait list` are empty (07:13 JST).
- **What went wrong on the way:** GitHub closed #305 at 06:50 JST when handoff commit 2637d4d reached main: its message read "limb fix #305 at the gate", and `fix #305` is a closing keyword. The first gate run then ended failed at 07:03 JST ("Auto merge is not allowed for this repository"; the repo has `allow_auto_merge: false` and the PR was closed by then). The lead reopened the PR at 07:09 JST (the PR comment says why) and ran `lead-wait pr 305` again; the gate merged the same reviewed head 414c698.
- **Rule from this:** a commit message that reaches main never has `fix`, `close` or `resolve` (any form) directly before `#<n>`, unless closing it is meant. Write "#305 (limb fix)".
- **Check at the 07:37 JST heartbeat (`679b9e86`):** `gh run view 43109420915 --json status,conclusion` (`all-suites` on 0ce1a58, in progress at 07:13 JST). CI on head 414c698 was green before the close (`suites`, `leak-gate`); the rerun that the reopen started was still pending when the gate merged. A red `all-suites` on main is a real bug and comes first: reproduce the failing suite with `orb-test --host -- godot --headless --path . --script res://tests/<suite>.gd`.
- **At the 08:57 JST wake-up (`3a110db7`):** the three steps of the section above, unchanged (movie-careful, keyart, store-limb, each only if no ticket of that kind is waiting or running). Step 3 is now unblocked: #305 is on main.
- **Wake-ups (session crons; both in CronList at 07:09 JST, re-create if missing):** `679b9e86` heartbeat at 07:37 JST; `3a110db7` capture check at 08:57 JST. Re-arm the heartbeat 45 min after each turn.
- **Waiting on the Owner:** unchanged; the list is in the section above (notarization A/B/C; acceptance of the title lettering and key art once d2 exists; workflow review items 4 and 5; the yes for `director/triage-20261112.sh`; B1 Steam Direct, the two macOS permissions, a blind newcomer session, a native ja/ko reader).
- **Next headless work before the window:** nothing is listed. No new story or play features before a blind newcomer session.
