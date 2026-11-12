# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-12 10:5x JST.** Release readiness (`docs/RELEASE_READINESS.md`): A 13/14 done; A11 is partial because no human has played the exported build. The B rows wait on the Owner, B1 first. B5 moved today (02956da): the trailer rough cut d3 exists in four languages and, with the key art and capsules d2, is with the Owner for acceptance; details in `docs/store/STORE_PAGE.md` sections 8 and 9.

**In flight** (ack every event). Paths: `director/` = KIOXIA `eddington-1919-cache/director/`, `<b5>` = KIOXIA `eddington/store-b5`.
- `lw-release-047-20261112-105414` (run release-047, started 10:54 JST): Codex Terra through cx-exec in the worktree `eddington-1919-wt/rel047` (detached at 02956da), brief `director/release-047.md`: full e2e, bump to 0.4.7, macOS, Windows and Linux exports with the package check, ZIPs and `BUILD.txt` to KIOXIA `eddington/builds/0.4.7/`, row A11, one PR. On its event: read the final report (`~/.local/state/cx-exec/rel047-*.final.md`), compare `shasum -a 256` of the three ZIPs with `BUILD.txt`, then `lead-wait pr <n>`. A `DECISION:` line is answered with `cx-exec --resume <id> <worktree> <file>`. Remove the worktree and branch only after the PR state is MERGED.
- `lw-owner-b5-20261112-105545` (run owner-b5, started 10:55 JST): the combined acceptance ask in the dot thread, text in `director/owner-ask-20261112-1050.md`. The first try at 10:54 JST ended with exit 5 before anything was posted (ego-lite timed out opening the dot thread, before the script fills the composer), so this is the only copy. On `done`: ack. On another failure: read the run's `ego.log`; if it stopped before `page.fill` nothing was posted, so send it again at the next heartbeat, not at once. The three capsule sheets and a 720p preview of the English trailer also went to the Owner's device (SendUserFile, 10:53 JST).

**Judged today, do not redo:**
- Trailer d3: `<b5>/trailer/careful_{english,japanese,koreana,tchinese}_d3.mp4`, 38.8 s each from one EDL (`director/trailer_careful.edl`); the four captures' step frames equal the first zh_TW capture's. Loudness -21.1 to -21.3 LUFS, true peak -0.5 to -1.4 dBFS, and the title card carries the coda. The lead looked at nine frames each of the English and the zh-TW cut; the Japanese and Korean cuts were not looked at; nobody has heard the sound. The capture AVIs and the silent-card d2 are deleted.
- Key art = `<b5>/keyart-046/t212/totality_sky.png`; capsules d2 in `<b5>/capsules-d2/`; upload screenshots and blink GIFs in `<b5>/upload/` (`INDEX.md`).

**PRs:** none open from this session; release-047 will open one. Draft PRs (Owner 2026-11-12 JST: tidy them): the lead's call is to close #31, #38, #52, #80 (the Human Generator line; #80's branch holds all of it), #35 (c01 design drafts) and #36 (c02 blockout, no longer applies), each with its reason and with the branch kept, and to leave #15 open (Asset Factory pilot, paused by the Owner 2026-11-02 JST). The auto mode classifier refused the closing, so nothing is closed yet: see the first item under Waiting.

**Wake-ups (session crons):** `6d33d722` heartbeat at 11:14 JST. Keep one heartbeat within 45 min of the end of each turn.

**Waiting on the Owner** (answers arrive as `@edd-lead` in the dot thread or in chat):
- Run `! bash /Volumes/KIOXIA/eddington-1919-cache/director/drafts-close-20261112.sh` (closes the six drafts above), or say which to keep. Do not retry it from the lead.
- macOS notarization: A, B or C (lead recommends A). Until then the store page lists no macOS.
- B5 acceptance (the ask is being posted, see In flight): the title lettering, the key art and capsules d2, the trailer, and whether to add the 1917 prologue (lead recommends no). On "add it": one movie ticket for the prologue route (`movie_careful_l10n.sh` is the model; Mon–Fri 09:00–14:20 JST; never two movie tickets at once, and not while release-047 runs Godot), extend the EDL, recut the four. Also open: who holds the art seat (workflow review item 5).
- A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285); the classifier refused that one too.
- Owner-only: B1 Steam Direct; Screen Recording and Accessibility permissions; a blind newcomer session; a native ja or ko reader.

**Next headless work:** nothing is queued behind release-047. No new story or play features before a blind newcomer session; with no acceptance row to move, stop and clear.
