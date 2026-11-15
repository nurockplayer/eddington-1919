# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-15 18:5x JST.** Release readiness frozen (A 13/14, B on hold); listing work paused (Owner 2026-11-12). Plan = Príncipe vertical slice to shippable quality (Owner 2026-11-13; target look LiS True Colors > Tell Me Why). Art director = Fable 5.2 in edd-art (w7:pB); log `docs/design/SLICE_PRINCIPE.md`. Codex pace behind → implementation on Sol high; pull open follow-ups forward. Owner 2026-11-14: Codex quota ample.

**In flight (lead):**
- `lw-test-guard-20261115-180154` (cx-exec Sol high; brief KIOXIA `eddington/briefs/test-guard.md`; worktree `../eddington-1919-wt/test-guard`, branch `fix/test-guard`). Root fix for recurring Godot test hangs (tests quit only at the end of `_run`; a script error idles Godot forever; 2026-11-15 a hung p5-install test held eddington's only orb-test slot 2 h 42 m until the Owner killed it). TestGuard autoload: exit 70 on ERROR_TYPE_SCRIPT (sticky even after quit(0)), 900 s deadline for tests/test_*, `EDD_FAILFAST=0` opt-out. Decision on #317. Its tests queue behind edd-art's jobs in the single light slot. **On its event:** read the final report (DECISION line? suites that newly fail = hidden script errors → list as follow-up issue), check CI all-suites, then `lead-wait pr <n>`. After merge: remove worktree + branch (only once MERGED).
- Harness: lead-board `light-host-run-no-cap` → tachiko-harness#270 (ORB_TEST_TIMEOUT for light runs, default 60 min, kills the process tree, exit 124). Harness posts there when installed. Long light runs (full `tools/all_suites.sh`) will then need heavy or an explicit `ORB_TEST_TIMEOUT=`.

**edd-art (not ours to drive):** cx runs p1-matrix, p3-ridges, p5-install (resumed after the kill to fix test_surface_tiles.gd:96 null), p7-darkroom, veg-cards; each waits on its job-run in the eddington slot, one at a time outside the window.

**PRs:** #329 draft (totality staging), #322 draft (dialogue camera) — both with edd-art for art acceptance; windowed captures 2026-11-16 09:00 JST, on its acceptance comment run `lead-wait pr 322` / `lead-wait pr 329` (fresh review). #318 draft (AD), #15 draft (paused). #330 waits for #329.
**Open issues:** #1, #37, #285, #317, #330, #334. Audio: #338 merged (+6 dB, -16 LUFS); next audio step = CC0 field ambience (palm wind 384550, dusk 868748). Story D1–D8 done, D9 deferred; next story step only on an Owner reaction. Keepsake pick still with the Owner (rec. option 1 pencil cap).

**Inbox:** empty (ev-20261115-180321-6561 acked). **Wake-ups:** none (Owner rule 2026-11-12).
