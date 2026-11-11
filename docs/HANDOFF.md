# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-12 08:5x JST.** Release readiness (`docs/RELEASE_READINESS.md`): A 13/14 done; A11 is partial because no human has played the exported build. The B rows wait on the Owner, B1 first.

**In flight** (ack every event). Paths: `director/` = KIOXIA `eddington-1919-cache/director/`, `<b5>` = KIOXIA `eddington/store-b5`.
- Heavy tickets #918 movie-careful, #919 keyart, #920 store-limb, queued 07:40 JST; third to fifth in the queue at 08:57 JST (behind #915–#917 of other projects), none called yet. Exit 3 means the ticket was called outside the window (Mon–Fri 09:00–14:20 JST for the movie, 09:00–14:50 JST for the other two) and ran nothing: requeue with `lead-wait run <label> -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/<script>` (`movie_careful.sh`, `keyart_046.sh`, `store_limb.sh`). Never two tickets of one kind.
- movie-careful done: `python3 director/trailer_cut.py steps` on KIOXIA `eddington/trailer-test/godot.log`, shift the starts in `director/trailer_careful_draft.edl`, one `sheet`, judge, `cut` with `CARD=<b5>/trailer/card_d1.png`, delete `careful.avi`.
- keyart done: each PNG in the log must be 3840 2160; judge `<b5>/keyart-046/sheet_keyart.jpg` (the ring through cloud, the shelter poles out of the middle); `python3 director/capsule_drafts.py <b5>/capsules-d2 <chosen totality_sky.png>`; judge its three `sheet_*.jpg`.
- store-limb done: `SET=careful-limb bash director/about_blink.sh` and look at one GIF; compare each chosen screenshot (`<b5>/upload/INDEX.md`) with its `careful-limb-<loc>` twin and remake the upload JPGs that differ only in the plate viewer.

**PRs:** none open from this session. Draft PRs (Owner 2026-11-12 JST: tidy them): the lead's call is to close #31, #38, #52, #80 (the Human Generator line; #80's branch holds all of it), #35 (c01 design drafts) and #36 (c02 blockout, no longer applies), each with its reason and with the branch kept, and to leave #15 open (Asset Factory pilot, paused by the Owner 2026-11-02 JST). The auto mode classifier refused the closing, so nothing is closed yet: see the first item under Waiting.

**Wake-ups (session crons):** `9afb262e` heartbeat at 09:13 JST (the 08:57 JST capture check ran: no event, nothing to requeue). Keep one heartbeat within 45 min of the end of each turn.

**Waiting on the Owner** (answers arrive as `@edd-lead` in the dot thread or in chat):
- Run `! bash /Volumes/KIOXIA/eddington-1919-cache/director/drafts-close-20261112.sh` (closes the six drafts above), or say which to keep. Do not retry it from the lead.
- macOS notarization: A, B or C (lead recommends A). Until then the store page lists no macOS.
- Acceptance of the title lettering and the key art once capsule drafts d2 exist; who holds the art seat (workflow review item 5).
- A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285); the classifier refused that one too.
- Owner-only: B1 Steam Direct; Screen Recording and Accessibility permissions; a blind newcomer session; a native ja or ko reader.

**Next headless work** (needs neither the Owner nor a window): after today's captures are judged, export 0.4.7 for macOS, Windows and Linux with the package check, so the build people play has #305 (brief pattern: `director/release-046.md`). No new story or play features before a blind newcomer session.
