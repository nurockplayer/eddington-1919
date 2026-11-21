# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-21 20:50 JST.** Slice acceptance **7/9 on main** (met 1, 3, 4, 5, 6, 7, 9; open 2 = Owner hasn't watched the clips, 8). Row 9 re-measured on 198877e 2026-11-20 12:19 JST: holds, 56.2 fps class estimate. Release readiness frozen (A 13/14, B on hold); listing paused (Owner 2026-11-12). Plan = Príncipe vertical slice (Owner 2026-11-13), style = engraving. Art director = Fable 5.2 in edd-art (w7:pB); art log `docs/design/SLICE_PRINCIPE.md`.

**Lead in flight (2026-11-21 20:46 JST, Owner: Codex surplus, use Claude before reset ~11-22 13:45 JST):** lead-wait runs lw-cx-chart-label (#382, draft→edd-art), lw-cx-layout-720p (#381, draft→edd-art), lw-cx-glossary (#373, Luna), lw-cx-look-gates (#384+#346), lw-cx-evidence-gates (#397+#399), lw-cx-silent-skips (#394+#370+#334); worktrees eddington-1919-wt/<name>, briefs .claude/briefs/<name>.md. On each event: check acceptance, then `lead-wait pr <n>` for non-visual PRs. edd-art told budget is open (msg 20:48 JST); it pruned KIOXIA to 20 GB free and runs menus-page (row 8 item 5), #344/#341/#349/#329 rebases. Row 8 face clause reworded (lead decision 21:00 JST, reach = measured collider minimum); edd-art scores it. Asked the Owner in chat: watch row 2 clips, playtest.

**edd-art owns (not ours to drive):**
- Row 5: #392 MERGED 198877e 2026-11-20 JST (accepted at 9ca8e73).
- Row 8: #393 MERGED 49e611d 2026-11-20 04:42 JST (darkroom by day, night lantern on bench, prompt lower). #398 MERGED 46469e8 2026-11-21 04:19 JST (toast clears panel and corona, item 5b). Still open: menus, #344 props, face clause.
- On an art-accept comment on a draft: `lead-wait pr <n>` (fresh review).

**Open draft PRs:** #356 coelostat-trim (oracle approve b3d6eb2, waits AD view), #349 ridgelines, #344 darkroom props, #341 vegetation cards, #329 totality staging (art acceptance pending; #330 waits for it), #15 (paused by Owner).
**Open issues:** #394, #384, #382, #381, #373, #370, #351, #346, #345, #334, #330, #285, #317/#316 (decision logs), #37, #1.

**Pace 2026-11-20 05:45 JST:** Codex behind (14% vs 42% target). Owner rule 2026-11-18: act as if Claude `ahead` → no pull-forward by the lead; implementation that does go out = `cx-exec -m gpt-6.1-sol --effort high`, reading >4 calls = read-only Sol diagnosis.

**Standing:** dot paused (only the Owner resumes) → Godot tests via GitHub CI `suites`; Test lines `tachi-run --dot-only --` (exit 69 = paused). Revert checks pending dot (`_verdict_class`, rate-limit). Owner asks in dot thread (info only, not blocking): `lw-dot-row2-clips-main`, `lw-dot-third-contact-clip`, `lw-owner-playtest-eclipse` (only an Owner `@edd-lead` reply counts). Keepsake pick with the Owner (rec. pencil cap). Queued after #329: totality soundscape (proposal 2, `_begin_totality` in main.gd). Story next step only on an Owner reaction. **Wake-ups:** none.
