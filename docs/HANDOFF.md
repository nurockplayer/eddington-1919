# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-12 10:2x JST.** Release readiness (`docs/RELEASE_READINESS.md`): A 13/14 done; A11 is partial because no human has played the exported build. The B rows wait on the Owner, B1 first. B5 moved today (edaac77): key art chosen, capsules d2, trailer rough cut, plate screenshots reshot; details in `docs/store/STORE_PAGE.md` sections 8 and 9.

**In flight** (ack every event). Paths: `director/` = KIOXIA `eddington-1919-cache/director/`, `<b5>` = KIOXIA `eddington/store-b5`, `<tt>` = KIOXIA `eddington/trailer-test`.
- Heavy ticket #921 movie-l10n (`lw-movie-l10n-20261112-101739`, started 10:21 JST): the careful route in en, ja, ko to `<tt>/careful_<loc>.avi` and `godot_<loc>.log`. Exit 3 = called outside Mon–Fri 09:00–14:20 JST, nothing run: requeue `lead-wait run movie-l10n -- orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful_l10n.sh`.
- On its event: its log must say `<loc>: 0 step frames differ from the zh_TW capture` for each language (else read `trailer_cut.py steps` and shift the EDL for that one). Then per language `CARD=<b5>/trailer/card_d1.png CARD_AUDIO_AT=231.0 AFADE_S=1.5 nice -n 10 python3 director/trailer_cut.py cut <tt>/careful_<loc>.avi director/trailer_careful.edl <b5>/trailer/careful_<english|japanese|koreana>_d3.mp4`; check each with `ffmpeg -i <mp4> -vn -af ebur128=peak=true -f null -` (true peak under 0 dBFS) and look at one sheet of the English cut (menus in English, card last); delete the AVIs.
- Then the zh_TW capture again (its AVI was deleted before the card-sound option existed): `lead-wait run movie-zh -- orb-test --heavy --host -- env LOCS=zh_TW bash /Volumes/KIOXIA/eddington-1919-cache/director/movie_careful_l10n.sh`; cut `careful_tchinese_d3.mp4` the same way and delete `careful_tchinese_d2.mp4` (its card is silent). Never two movie tickets at once.
- When the four cuts exist: add their numbers to STORE_PAGE.md section 9 and the B5 row, then one combined ask to the Owner in the dot thread (`lead-wait run owner-b5 -- dot-run --discuss --role edd-lead -p …`): accept the title lettering, the key art (`<b5>/capsules-d2/sheet_a_wide.jpg`, `sheet_b_tall.jpg`, `sheet_c_hero_logo.jpg`) and the trailer (nobody has heard its sound; should the 1917 prologue be added).

**Judged today, do not redo:** the EDL (`director/trailer_careful.edl`, 8 shots, 34.8 s; the capture's step frames equal the headless run's); key art = `<b5>/keyart-046/t212/totality_sky.png`; capsules d2 in `<b5>/capsules-d2/` (small capsule with the ring left of the lettering, tall ones cropped clear of the beam); upload screenshots 03, 05, 07, 09 and the four blink GIFs remade from `careful-limb-<loc>` (01 identical, 02 kept), `<b5>/upload/INDEX.md` updated.

**PRs:** none open from this session. Draft PRs (Owner 2026-11-12 JST: tidy them): the lead's call is to close #31, #38, #52, #80 (the Human Generator line; #80's branch holds all of it), #35 (c01 design drafts) and #36 (c02 blockout, no longer applies), each with its reason and with the branch kept, and to leave #15 open (Asset Factory pilot, paused by the Owner 2026-11-02 JST). The auto mode classifier refused the closing, so nothing is closed yet: see the first item under Waiting.

**Wake-ups (session crons):** `6d33d722` heartbeat at 11:14 JST. Keep one heartbeat within 45 min of the end of each turn.

**Waiting on the Owner** (answers arrive as `@edd-lead` in the dot thread or in chat):
- Run `! bash /Volumes/KIOXIA/eddington-1919-cache/director/drafts-close-20261112.sh` (closes the six drafts above), or say which to keep. Do not retry it from the lead.
- macOS notarization: A, B or C (lead recommends A). Until then the store page lists no macOS.
- Acceptance of the title lettering, the key art and the trailer (the combined ask above is not sent yet); who holds the art seat (workflow review item 5).
- A yes to run `director/triage-20261112.sh` (closes 12 triaged issues, retitles #285); the classifier refused that one too.
- Owner-only: B1 Steam Direct; Screen Recording and Accessibility permissions; a blind newcomer session; a native ja or ko reader.

**Next headless work** (needs neither the Owner nor a window): once the movie tickets have ended (a second Godot job in this repo slows them), export 0.4.7 for macOS, Windows and Linux with the package check, so the build people play has #305. The brief is written: `director/release-047.md`; ask `quota-advisor --tier routine`, cut a new worktree, send it with `lead-wait run release-047 -- <cx-exec|ds-exec …>`. No new story or play features before a blind newcomer session.
