# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-16 02:5x JST.** Release readiness frozen (A 13/14, B on hold); listing work paused (Owner 2026-11-12). Plan = Príncipe vertical slice to shippable quality (Owner 2026-11-13; target look LiS True Colors > Tell Me Why). Art director = Fable 5.2 in edd-art (w7:pB); log `docs/design/SLICE_PRINCIPE.md`. Pace 2026-11-15 19:05 JST: Codex on (48%/58%), Claude on → no pull-forward; Owner 2026-11-14: Codex quota ample.

**In flight (lead):** none.
- #343 test guard merged 2026-11-15 19:04 JST (824ba9c): exit 70 on script error, 900 s deadline for tests/test_*, `EDD_FAILFAST=0` opt-out; 2,506 checks green, no hidden script errors surfaced. Worktree/branch removed. Oracle major → #347 (child runs in test_test_guard need an outer `timeout`); small, do it when pace is behind or a slot is idle.
- Harness: light orb-test runs now capped at 60 min (tachiko-harness#271, topic closed 2026-11-15 20:03 JST); `ORB_TEST_TIMEOUT=<min>` raises it, 0 disables. Long light runs (full `tools/all_suites.sh`) go heavy or set it explicitly in the `Test:` line.
- Owner rule 2026-11-16 02:50 JST: iPad + S23U both off the AXT1800 = Owner out → Mac hardware free until either reconnects. Handed to harness-lead (lead-board `owner-away-presence-axt1800`: owner-presence + orb-test gate). When it ships, windowed Godot may also run while away.

**edd-art (not ours to drive):** cx runs p1-matrix, p3-ridges, p5-install, p7-darkroom, veg-cards; each waits on its job-run in the eddington slot, one at a time outside the window.

**PRs:** #329 draft (totality staging), #322 draft (dialogue camera) — both with edd-art for art acceptance; windowed captures 2026-11-16 09:00 JST, on its acceptance comment run `lead-wait pr 322` / `lead-wait pr 329` (fresh review). #318 draft (AD), #15 draft (paused). #330 waits for #329.
**Open issues:** #1, #37, #285, #317 (decision log), #330, #334, #347. Audio: next step = CC0 field ambience (palm wind 384550, dusk 868748). Story D1–D8 done, D9 deferred; next story step only on an Owner reaction. Keepsake pick still with the Owner (rec. option 1 pencil cap).

**Inbox:** empty (ev-20261115-200329-3a96 acked). **Wake-ups:** none (Owner rule 2026-11-12).
