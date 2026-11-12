# Handoff: current state (edd-lead)

Overwritten every turn, never appended to; 30 lines at most. Rules live in the global CLAUDE.md only. History: `git log -p docs/HANDOFF.md`; before 2026-11-12 JST, `docs/HANDOFF_ARCHIVE.md` (frozen, not read at session start).

**Written 2026-11-13 02:5x JST.** Listing work paused (Owner 2026-11-12 13:3x JST, memory `eddington-store-paused-1112`). **Owner verdict 2026-11-13 02:4x JST: characters, environments and atmosphere are all crude, the music has severe noise, nothing makes you want to play.** Release readiness is frozen (A 13/14, B on hold).

**Audio diagnosis (lead, 2026-11-13 02:4x JST):** the noise is most likely the always-on ambience bed `audio_amb` (`scripts/main.gd` ~598–612): a brown-noise random walk plus single-sample 0.5 impulses (~9 clicks/s at 22050 Hz), looped every 4 s with no seam fix, at volume_db -20 on SFX. Measured in-game RMS: bed ≈ -40 dBFS, while the sampled music plays at -38.5 dB (`Score.SAMPLED_DB`), ≈ -65 dBFS RMS in the first 20 s of `cambridge_rain`, so the bed sits about 25 dB above the music. The four music OGGs themselves are clean (peak -7.6 to -8.8 dBFS, no clipping). Other procedural noise SFX: insects hiss, surf, steps, UI ticks (main.gd 440–600, player.gd 49, ui.gd 1201+). A/B clips sent to the Owner (scratchpad `A_ingame_mix.m4a`, `B_music_only.m4a`); asked whether A is the noise they hear.

**In flight:** nothing (`lead-wait list` empty, inbox acked).

**Waiting on the Owner (asked in chat 2026-11-13 02:5x JST):**
1. Is clip A the noise? On yes: one brief: drop the procedural bed and impulses, rebalance music vs SFX, then replace the procedural ambience with CC0 field recordings (provenance in `docs/audio/SOURCES.md`).
2. Visual direction: (1, lead's pick) one vertical slice, the Príncipe totality, raised to shippable quality before anything else, in a stylised period look (toned photo/print, the same family as the portraits) that the pipeline can do well; art-director seat chosen by audition on that slice; (2) stay realistic, buy assets / Meshy / HG; (3) 2D illustrated with 3D only for the eclipse. Also asked for a reference game for the look (memory: the 10-27 target was Tell Me Why / LiS True Colors).

**PRs:** none open; #15 draft (paused). Issues: #1, #37, #285. edd-art (w7:pB) idle since 2026-11-08; its handoff `.claude/lead-handoff/art.md`.

**Wake-ups:** none (Owner rule 2026-11-12). Nothing else to do until the Owner answers: stop and clear.
