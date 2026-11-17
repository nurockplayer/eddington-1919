# Reference research → proposals (edd-lead, 2026-11-17 23:2x JST)

Owner request 2026-11-17 22:5x JST: use the surplus Codex quota to research comparable games (design, story, mechanics, visuals, modelling, music) and bring proposals. Inputs: five Codex Sol web-research reports (`ref_{narrative,mechanics,visuals,music,market}_2026-11-17.md`) and a read-only gap audit of main 58567e8 (`~/.local/state/cx-exec/gap-audit-20261117-230901.final.md`). Decision record: #351.

## What the five reports agree on

1. **The player's own mind-change must be the climax, not a character's announcement.** Paradise Killer rebuilt its trial so the player picks the evidence; Odyssey (a science-puzzle game, 70.7% on SteamDB) is criticised for text walls and highlighted answers. → the player should judge their evidence before anyone interprets it.
2. **Two separate releases:** totality gives awe; reading the evidence gives the "aha". Do not let the spectacle certify relativity. Sound: the world thins out, a short near-silence, then music (Journey, Oppenheimer's Trinity, WoW's contrast; real eclipse accounts: birds change, insects start, it cools).
3. **Instruments must feel tactile, but must never hint at the right answer** (Obra Dinn batches its confirmation; Mars After Midnight maps a control directly to its effect). No "warmer" sound near the true value.
4. **Length does not buy reviews** (2 h games beat 15 h ones). What sinks comparable games: waiting, repeated walking, lost progress, text walls, outcomes that ignore the player's choices, and inconsistent terms across translations (a zh review of Chants of Sennaar).

## Gap audit (what the game already does)

Already done: Sobral comparison by the same chart and method (N4); score layering (Mu4); micrometer without accuracy feedback (Mu3 core); original ledger entry kept beside the October amendment (N5 core); prediction ledger, orrery, box, epilogue (moves A–E).

## Decisions

| # | Proposal | Gap (audit) | Decision | Scope |
|---|---|---|---|---|
| 1 | **Darkroom verdict before anyone speaks**: the player's 1917 bet, their readings and interval on one chart; they choose "favours 0 / 0.87″ / 1.75″ / inconclusive"; Kit and Eddington react to that choice and to the evidence. Graded only against the player's own interval, never for picking 1.75. | N2 PARTIAL: interval answer exists, no four-way verdict, Eddington interprets first | **Do.** Read-only design diagnosis first (Sol), then I pick the option. | Príncipe slice |
| 2 | **Totality soundscape**: dusk insects enter at totality (today they start at night), the drone waits ~2 s after second contact with only wind and apparatus, then enters; shutter sounds stay clear. | Mu1 PARTIAL | **Do after #329 merges** (same function, `_begin_totality`); timed with edd-art's colour script. | slice |
| 3 | **Micrometer feel**: a graduated scale the crosshair moves along, a constant tick per step (never accuracy-dependent), a micrometer step-size setting and a larger-crosshair option. | M1 PARTIAL | **Do.** Draft until edd-art accepts the screenshots. | slice |
| 4 | **Fixed terms for supports / rules out / inconclusive / can't say** in the LOCALIZATION glossary and in en/ja/ko. | K3 PARTIAL: the four concepts are rendered several ways | **Do.** | all |
| 5 | **Probable error labelled in Dyson's letter** (guardrail: 1920 errors are probable errors). | M2 sub-item: missing in `content_epilogue.gd:75` | **Do** (small). | epilogue |
| 6 | Darkroom progress survives quit/resume. | K4 PARTIAL: chapter-start checkpoints only | **Later**, after 1 changes the darkroom; then measure how long the darkroom takes in a bot run before deciding. | slice |
| 7 | Readings appear as dots while measuring; a "simulated repeat experiments" view. | M2 PARTIAL, L-size | **Later**; revisit after 1 and a blind playtest. Risk: false precision. | slice |
| 8 | Exposure timing assist (slower clock / assisted shutter). | M4 PARTIAL | **Later**, as an accessibility option before release. | slice |
| 9 | One protected free look at totality. | N3 PARTIAL | **Sent to edd-art** with the visuals report; staging is theirs (#329). | slice |
| 10 | Engraving tech: surface-attached nested hatching (tonal art maps), stability under translation, distance-faded lines, totality colour script, low-end GPU check. | — | **edd-art's call** (sent 2026-11-17 23:08 JST, ev-20261117-230838-635c). | look |
| 11 | Cambridge: an explicit "what would change your mind" agreement with Ashby (N1); prediction reason + seal (M3); box impact marker (M5); ending on a small action and a shorter October coda (26 advances today; research suggests 10–15 min) (N5). | PARTIAL | **After the Príncipe slice** (Owner plan 2026-11-13: slice first). | Cambridge |
| 12 | Commission 4–6 min of original score (motif, prep loop, totality cue, evidence coda; piano + bowed strings) and a paid Príncipe cultural adviser for island music. | — | **Not yet.** First prove the totality timing with the existing cues (proposal 2). If it works, this becomes a money question for the Owner, with a quote. | music |

## Order

1 (diagnosis now) → 3, 4, 5 in parallel now → 2 when #329 merges → 1 implementation after the diagnosis → 6/7/8 reviewed after a blind playtest.
