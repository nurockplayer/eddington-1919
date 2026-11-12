# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-12 13:1x JST.** Release readiness (`docs/RELEASE_READINESS.md`): A 13/14 done; A11 is partial because no human has played the exported build. The B rows wait on the Owner, B1 first. B5 (02956da) is with the Owner for acceptance: the trailer rough cut d3 in four languages, the key art and capsules d2; details in `docs/store/STORE_PAGE.md` sections 8 and 9.

**In flight:** nothing is running (`lead-wait list` is empty, the inbox is acked). Paths: `director/` = KIOXIA `eddington-1919-cache/director/`, `<b5>` = KIOXIA `eddington/store-b5`.
- 0.4.7 is merged: PR #307 → 377dde9 (2026-11-12 11:17 JST), reviewed on codex because the oracle run failed (exit 5; noted on the PR). The macOS, Windows and Linux ZIPs and `BUILD.txt` are in KIOXIA `eddington/builds/0.4.7/`; the lead compared their SHA-256 with `BUILD.txt` (equal). The worktree `rel047` and the local branch are removed; the remote branch `release/0.4.7` is kept, as `release/0.4.6` was, so the build commit 9e0059b named in `BUILD.txt` stays reachable.
- The B5 acceptance ask is NOT in the dot thread: every `oracle-ego --dot` run since 10:12 JST times out on `chatgpt.com/dots` (the newest, a dot-ci of 11:14 JST, has no `answer.md`; harness-lead has `dot-thread-unreachable`, theirs to repair). The ask went to the Owner in chat (10:5x JST, shown again by the watchdog at 11:11 JST) with the three capsule sheets and a 720p preview of the English trailer on the Owner's device. Text: `director/owner-ask-20261112-1050.md`. On each wake-up: if the newest run with `"mode": "dot"` in `meta.json` under `~/.local/state/oracle-ego/runs/` has an `answer.md` and the Owner has not answered in chat, post it once with `lead-wait run owner-b5 -- dot-run --discuss --role edd-lead -f <that file>`; otherwise do not resend.

**Judged today, do not redo:**
- Trailer d3: `<b5>/trailer/careful_{english,japanese,koreana,tchinese}_d3.mp4`, 38.8 s each from one EDL (`director/trailer_careful.edl`); the four captures' step frames equal the first zh_TW capture's. Loudness -21.1 to -21.3 LUFS, true peak -0.5 to -1.4 dBFS, and the title card carries the coda. The lead looked at nine frames each of the English and the zh-TW cut; the Japanese and Korean cuts were not looked at; nobody has heard the sound. The capture AVIs and the silent-card d2 are deleted.
- Key art = `<b5>/keyart-046/t212/totality_sky.png`; capsules d2 in `<b5>/capsules-d2/`; upload screenshots and blink GIFs in `<b5>/upload/` (`INDEX.md`).

**PRs:** none open from this session. Draft PRs (Owner 2026-11-12 JST: tidy them): the lead's call is to close #31, #38, #52, #80 (the Human Generator line; #80's branch holds all of it), #35 (c01 design drafts) and #36 (c02 blockout, no longer applies), each with its reason and with the branch kept, and to leave #15 open (Asset Factory pilot, paused by the Owner 2026-11-02 JST). The auto mode classifier refused the closing, so nothing is closed yet: see the first item under Waiting.

**Wake-ups:** none scheduled, and none are to be made: the Owner's rule of 2026-11-12 02:1x JST (global CLAUDE.md, "Idle is not a fault") ends self-scheduled heartbeats (the last cron, `6d33d722`, was deleted at 11:14 JST). `lead-wait` events and Owner messages wake the lead.

**Waiting on the Owner** (answers arrive as `@edd-lead` in the dot thread or in chat):
- Run `! bash /Volumes/KIOXIA/eddington-1919-cache/director/drafts-close-20261112.sh` (closes the six drafts above), or say which to keep. Do not retry it from the lead.
- macOS notarization: A, B or C (lead recommends A). The Owner asked what notarization is and the lead explained it in chat (2026-11-12 13:1x JST); no pick yet. Until then the store page lists no macOS.
- B5 acceptance (see In flight): the title lettering, the key art and capsules d2, the trailer, and whether to add the 1917 prologue (lead recommends no). On "add it": one movie ticket for the prologue route (`movie_careful_l10n.sh` is the model; Mon–Fri 09:00–14:20 JST; never two movie tickets at once), extend the EDL, recut the four. Also open: who holds the art seat (workflow review item 5).
- Triage: the Owner said yes in chat (2026-11-12 13:0x JST), but the classifier refused the lead's run again, so the Owner runs `! bash /Volumes/KIOXIA/eddington-1919-cache/director/triage-20261112.sh` (closes 12 triaged issues, retitles #285; all 13 were still open at 13:0x JST and the verdicts still hold on 377dde9). Do not retry it from the lead.
- Owner-only: B1 Steam Direct; Screen Recording and Accessibility permissions; a blind newcomer session, now with the 0.4.7 build (this is what moves A11); a native ja or ko reader.

**Next headless work:** nothing is queued. No new story or play features before a blind newcomer session; with no acceptance row to move, stop and clear.
