# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-12 11:1x JST.** Release readiness (`docs/RELEASE_READINESS.md`): A 13/14 done; A11 is partial because no human has played the exported build. The B rows wait on the Owner, B1 first. B5 (02956da) is with the Owner for acceptance: the trailer rough cut d3 in four languages, the key art and capsules d2; details in `docs/store/STORE_PAGE.md` sections 8 and 9.

**In flight** (ack every event). Paths: `director/` = KIOXIA `eddington-1919-cache/director/`, `<b5>` = KIOXIA `eddington/store-b5`.
- `lw-pr-307-20261112-111353` (started 11:13 JST): review and gate of PR #307 `release: 0.4.7 playtest builds` (head 2beeedb, branch `release/0.4.7`, worktree `eddington-1919-wt/rel047`). The lead read the diff (0.4.6 → 0.4.7 in `project.godot`, `export_presets.cfg` and `tests/test_release_export.gd`, plus the A11 row, which stays PARTIAL) and compared the three ZIPs in KIOXIA `eddington/builds/0.4.7/` with `BUILD.txt`: the SHA-256 values are equal. On its event: once the PR state is MERGED, `git pull`, then remove the worktree and the branch; a blocker goes back with `cx-exec --resume 01a1cd76-76df-7462-99d5-31c89ee30d6b <worktree> <file>`.
- The release-047 run (event acked) ended `failed` only because cx-exec's rerun of the `Test:` line was sent to dot and came back exit 70 (`dot-run exited 5 without a result`, the outage below). The same test on the host passed (55 checks, 0 failures), the e2e passed all 6 routes, and the three exports ended `Release package checked`. The worktree's `build/` (duplicates of the KIOXIA ZIPs, same hashes) is deleted. Not reported again: harness-lead has `dot-thread-unreachable` from today.
- The B5 acceptance ask is NOT in the dot thread: every `oracle-ego --dot` run since 10:12 JST times out on `chatgpt.com/dots` (the newest, a dot-ci of 11:06 JST, has no `answer.md`). The ask went to the Owner in chat (10:5x JST, repeated on screen by the watchdog at 11:11 JST) with the three capsule sheets and a 720p preview of the English trailer on the Owner's device. Text: `director/owner-ask-20261112-1050.md`. On each wake-up: if the newest run with `"mode": "dot"` in `meta.json` under `~/.local/state/oracle-ego/runs/` has an `answer.md` and the Owner has not answered in chat, post it once with `lead-wait run owner-b5 -- dot-run --discuss --role edd-lead -f <that file>`; otherwise do not resend.

**Judged today, do not redo:**
- Trailer d3: `<b5>/trailer/careful_{english,japanese,koreana,tchinese}_d3.mp4`, 38.8 s each from one EDL (`director/trailer_careful.edl`); the four captures' step frames equal the first zh_TW capture's. Loudness -21.1 to -21.3 LUFS, true peak -0.5 to -1.4 dBFS, and the title card carries the coda. The lead looked at nine frames each of the English and the zh-TW cut; the Japanese and Korean cuts were not looked at; nobody has heard the sound. The capture AVIs and the silent-card d2 are deleted.
- Key art = `<b5>/keyart-046/t212/totality_sky.png`; capsules d2 in `<b5>/capsules-d2/`; upload screenshots and blink GIFs in `<b5>/upload/` (`INDEX.md`).

**PRs:** #307 open, in the gate (above). Draft PRs (Owner 2026-11-12 JST: tidy them): the lead's call is to close #31, #38, #52, #80 (the Human Generator line; #80's branch holds all of it), #35 (c01 design drafts) and #36 (c02 blockout, no longer applies), each with its reason and with the branch kept, and to leave #15 open (Asset Factory pilot, paused by the Owner 2026-11-02 JST). The auto mode classifier refused the closing, so nothing is closed yet: see the first item under Waiting.

**Wake-ups:** none scheduled, and none are to be made. The heartbeat cron `6d33d722` was deleted at 11:14 JST: the Owner's rule of 2026-11-12 02:1x JST (global CLAUDE.md, "Idle is not a fault") ends self-scheduled heartbeats. `lead-wait` events and Owner messages wake the lead.

**Waiting on the Owner** (answers arrive as `@edd-lead` in the dot thread or in chat):
- Run `! bash /Volumes/KIOXIA/eddington-1919-cache/director/drafts-close-20261112.sh` (closes the six drafts above), or say which to keep. Do not retry it from the lead.
- macOS notarization: A, B or C (lead recommends A). Until then the store page lists no macOS.
- B5 acceptance (see In flight): the title lettering, the key art and capsules d2, the trailer, and whether to add the 1917 prologue (lead recommends no). On "add it": one movie ticket for the prologue route (`movie_careful_l10n.sh` is the model; Mon–Fri 09:00–14:20 JST; never two movie tickets at once), extend the EDL, recut the four. Also open: who holds the art seat (workflow review item 5).
- A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285); the classifier refused that one too.
- Owner-only: B1 Steam Direct; Screen Recording and Accessibility permissions; a blind newcomer session with the 0.4.7 build; a native ja or ko reader.

**Next headless work:** nothing is queued behind PR #307. No new story or play features before a blind newcomer session; with no acceptance row to move, stop and clear.
