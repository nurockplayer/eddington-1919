# Fun plan: what makes Eddington 1919 worth playing

Living master plan and acceptance checklist, kept by edd-lead from the oracle-ego design rounds (Owner 2026-11-22 03:40 JST: one round every 50 min over story, characters, music, SFX, visuals, modelling, scenes, atmosphere). Rounds and full answers: KIOXIA `director/fun-rounds/round-NN/`. Each round's answer is weighed against the code and the Owner's decisions before anything lands here. **Needs Owner OK** marks a new feature, UI, story or scope change; nothing marked so starts before the Owner says yes.

## Direction (round 1)

Two climaxes, and both have to land:
- **Awe, at totality.** The world goes dark and the player feels they are standing inside a once-in-a-lifetime event. Carried by image, sound and timing. The Owner's test: does it feel epic?
- **Revelation, at the measurement.** The player reads their own plates and finds that the prediction they believed does not explain what they measured. Carried by hands-on play, reasoning and how the characters react.

Two threads under them (R2): **the evidence turn** (a careful observer has good reasons to trust the old theory, finds evidence that challenges it, and changes their mind without hiding the uncertainty) and **the promise kept** (who wanted to hear what the player actually saw?). The second never replaces the first.

The game does not need more mechanics that show off science. It needs the sky to feel worth waiting for, and the plate the player measured to feel strong enough to change their mind about the universe.

## Ranked items

| # | Item | Status / where | Owner of the work | Needs Owner OK |
|---|---|---|---|---|
| 1 | **Readable engraving:** cut the competing line density in sky, ground and props so the eye finds the focus, the interactables and the speakers | A′ (#415): #416 hatching cause (Sol diagnosis running), #417, #420, #421 | edd-art decides, Codex builds | no (executes the chosen style) |
| 2 | **Totality as an event:** tension builds before second contact, the light drops sharply, about 2 s of near-silence, then the corona and the music release | #411 soundscape merged c8277dc; image side waits for #416/#417; judge on the Phase-0 clip (#422) | edd-art + Codex | no for tuning; yes for any new free-look mode |
| 3 | **The player makes the discovery in the darkroom:** micrometer feel, verdict before Eddington explains | built: verdict-first #374, micrometer graduations/step tick #372, bets on the chart #376, verdict recalled in ending/coda/October #378, the optional "had you already decided?" question (`content_coda.gd` `pressed`); left: judge it on real captures (F7, F14) | edd-art judges, Codex fixes | no |
| 4 | **A working expedition camp:** instruments, plate boxes, shelter, exposure rig and darkroom kit placed where they are used | partly done (#344 darkroom props); #418/#419 darkroom figure and plate | edd-art + Codex | no |
| 5 | **Memorable people (R3: recognisable without a line of dialogue):** (a) people posed at their work: Cottingham at the regulator and clock, Eddington with the plates watching the cloud, the darkroom figure holding its tools, no model stance or A-pose; (b) portrait coverage: Cambridge maps only Ashby and Eddington, Departure has no portrait mode, Príncipe is text-framed, so Kit and Cottingham need prints in the same series (Kit's gender stays unstated); (c) reactions follow the player's evidence: after the verdict the player's own numbers hold the screen before Ashby looks at the plate | (a) feeds on #1 (#416) and #418; (b) #421 layout fixes first, then a speaker/portrait coverage matrix of main; (c) staging only | edd-art decides, Codex builds | no for (a), (b) and staging; **yes** for a new dialogue/portrait layout, new lines or the closing frame |
| 6 | **Sound that knows when to step back (R4):** no new cues or commissions; the work is how the existing ones enter and leave. (a) second contact: birds stop and insects fade in from silence with the score held 2 s (#411, built), left: surf dips too, so the gap is really quiet; (b) the 302 s totality has an arc from the existing layers (release, slow change, unresolved tension before third contact; game time only, never cloud or plate quality); (c) shutter, metronome and plate change stay audible over the score; (d) darkroom stays unscored, no cue rewards any verdict; `coda_resolution` reads as the journey ending, not as Einstein winning; (e) gramophone QA and an audio provenance audit before release | (a) mostly built c8277dc; rest not started; `docs/design/M4_SCORE.md` still states the procedural-only limit and the 40 % Cambridge silence test that D014 replaced (docs out of sync) | edd-art judges feel, Codex mixes | no for mixing; **yes** for new cues, paid commissions or a music mechanic |
| 8 | **Príncipe carries the risk of failure (R2):** 6–8 lines after the rain before the eclipse (the pledge: record honestly even with no usable plate), 2–4 lines after third contact where Eddington and Cottingham react to the sky they were too busy to watch; story_audit D2/D3, historically checked and labelled | not started | lead drafts, Codex builds, fact-check first | **yes** |
| 9 | **Fewer "pick an answer, a wiser character grades it" beats (R2):** trim repeated approval in 1917, the darkroom explanation and the October restatement; keep Newton's credibility, Mercury 43″, 2σ, the Sobral conflict and the player's own judgement | not started; overlaps #351 coda-trim proposal | lead proposes the cut list | **yes** |
| 10 | **Kit's promise answered (R2), after the slice passes:** a 45–90 s Cambridge reunion: the player says the saved `kit_first` line, Kit reads the sky record, a short silence; ends on three objects on one desk (plate, Ashby's loupe, Kit's handwritten page). Not the full D6 (no variable-star minigame, unsent letters or romance values) | mostly built: October epilogue `content_epilogue.gd` `kit_reunion` (Kit answers the stored first line, promise, bond and workbook line); left: the three-object closing frame, and judging F17 on real captures | edd-art stages; lead drafts any new line | **yes** for new lines or the closing frame |
| 7 | **The 1917 doubt pays off in 1919:** ledger, Mercury, Sobral and Ashby come back; trim the stretches a blind player finds long | CONVERSION_ARC A–E built; #351 coda-trim proposal | lead proposes, Codex builds | **yes** (story, ending, pacing) |

No new L-size features until the Príncipe slice plays clearly and is memorable.

## Acceptance checklist (targets, not current results)

| Row | Scene | Passes when | Evidence | Owner looks |
|---|---|---|---|---|
| F1 | Arrival / coelostat | every required interactable identifiable from 3 m; no moiré or noise field wider than 1/20 of the frame | Phase-0 720p stills + object list | before/after |
| F2 | Camp walk | 10 s walk plus a full turn at 60 fps shows no line crawl, detached hatching or pop-in | Phase-0 walk clip | short clip |
| F3 | Coelostat | the same surface's line count differs by at most 1 across 720p / 1080p / 1440p | Phase-0 stills + count | no |
| F4 | Dialogue | no clipped text in en / ja / zh-TW / ko at max text size; contrast ≥ 4.5:1; a portrait on every line, with the right name, in Cambridge, Departure, Príncipe and October (R3: checked by a speaker/portrait table of main); portrait, name and text read as one block and never cover the current interaction; no 3D face detail within reach | 4-locale stills, contrast check | one frame |
| F5 | Totality | Moon solid black, white corona, horizon glow and camp silhouettes clear; no grey in-between frame; stars on simulated positions | clip from 20 s before second contact, star overlay | **yes**: epic? |
| F6 | Totality audio | first score cue enters 1.8–2.5 s after second contact; in that gap the ambience sits ≥ 12 dB under the pre-contact level with no insect jump; shutter clearly audible; exposure control never blocked (R4) | clip, waveform, event timeline | **yes** |
| F7 | Darkroom | glass plate and measuring tools distinct at 720p; plate and data chart keep a photographic look (whether hatching applies there is edd-art's call) | stills + measurement clip | **yes** |
| F8 | Micrometer | the same step always sounds the same, whether or not the reading is near the right answer; careless measuring still adds error | clip + careful/careless/inconclusive runs | no |
| F9 | Verdict | 0 / 0.87″ / 1.75″ / inconclusive offered before any NPC explanation; all four paths continue and are saved | 4 automated runs + save check | no (built) |
| F10 | Performance | totality under the shelter stays ≥ 30 fps at 720p in the class estimate, 3 clean reps (Owner 2026-11-07: no Windows hardware proof needed) | forced-draw method | no |
| F12 | Príncipe prep (item 8) | the risk lines play on both the prologue and the direct-1919 route; ≤ 45 s of new mandatory dialogue; prep controls never blocked | clips of both routes + dialogue timeline | 30 s |
| F13 | After third contact (item 8) | reactions ≤ 25 s; play continues with and without a usable plate; fixed-seed measured values identical to before | both clips + value diff | no |
| F14 | Darkroom discovery | measurement and verdict come before any NPC judgement of the numbers, and the player's data stays clearly on screen ≥ 1.5 s after they confirm before any NPC verdict (R3); the 1917 prediction, the player's number and the uncertainty band are readable on the chart; all four verdicts continue and save | 4 automated runs, darkroom clip, save check | **yes** |
| F15 | "Had you already decided?" | asking or not never changes measurement, grade or telegram; no accusation of fraud in any of supports-1.75 / supports-0.87 / inconclusive | branch logs, state diff | 30 s |
| F16 | Sobral / Ashby | with an inconclusive Príncipe result, Ashby never says the player's plates proved 1.75″; both Sobral instruments are mentioned; probable error is never shown as 1σ | clean / vague / inconclusive runs + chart frames | no |
| F17 | Kit reunion (item 10) | the prologue route recalls `kit_first` and the recorded sky; both bond tones close; direct-1919 never cites a promise that never happened | 3 clips, flag diff, 4-locale frames | **yes** |
| F18 | Ending | the scientific verdict and historical notes stay reachable; the last mandatory story frame shows plate, loupe and handwritten page clearly; the player never re-types a reason already given | 720p ending frame, full-run clip | **yes** |
| F19 | People at work (item 5a) | Eddington and Cottingham each hold a clear working pose at their station; no idle A-pose and no prop clipping in any idle shot; no 3D face detail at the closest reachable distance | 3 m and closest-reach stills, a 10 s clip per figure | 10 s |
| F20 | People at totality | hidden figures never appear during the 302 s; each work call has a named speaker; exposure and plate change never covered by captions; the ~2 s silence after second contact is not broken; figures back at their posts after third contact | fixed-seed event log, 60 fps clip around both contacts | with F5/F6 |
| F21 | Totality arc (item 6b, 6c) | the 302 s plays without audible loop seams or unplanned level jumps; music ends within 1.5 s of third contact; in 5 fixed-seed exposures `totality_glass` ducks within ~0.4 s and shutter and metronome stay distinct, no clipping | full 302 s audio, event log, waveform | with F5/F6 |
| F22 | Ending cue (item 6d) | `coda_resolution` plays at most once per run and never before the player's verdict; full route resolves in October, direct route in its own ending; no win sting on any of the four verdicts | cue logs for both routes × 4 verdicts | spot check |
| F23 | Gramophone | first press plays, second stops, replay works; Cambridge score dips within 1.5 s and returns ~3 s after stop; fades on leaving; no story flag changes | `test_gramophone.gd`, event log | no |
| F24 | Audio provenance | every shipped audio file traces to a source, author or generator, a licence class and a hash; CC0 samples and the non-CC0 1915 recording listed apart | audit report from `docs/audio/SOURCES.md` + hash list | no |
| F11 | Whole game | at least 2 of 3 newcomers can state their first prediction, what they observed, and why they kept or changed it; they answer both 2σ transfer questions | blind playtest per `docs/PLAYTEST_NEWCOMER.md` | reads the result |

F11 needs people the team does not have while the Owner is away; until then the playtest bot (`docs/PLAYTEST_BOT_DRIVE.md`) only checks the route, not whether the player cares.

## Owner's ~10 min a week

2 min arrival/dialogue before-after · 3 min totality A/B with sound, second and third contact ("epic?") · 2 min darkroom and an inconclusive ending ("did I make the discovery, and did the music not answer for me?") · 2 min yes/no on queued proposals · 1 min gut reaction.

## Deferred and rejected

- Deferred until a playtest shows the need: original score commissions, more measurement visualisation, advanced exposure aids, mid-darkroom saves.
- Deferred (R2): full D6 variable-star minigame, unsent-letter interaction, D9 Eddington private letters, the microphotograph keepsake (open with the Owner).
- Rejected (R4): a countdown or percussion score for the last 18 s, a "correct answer" chord for 1.75″, new themes, island music performances.
- Rejected (R3): new playable characters, full voice acting, a second Kit reunion, an affection value system, extra character chapters.
- Rejected: high-fidelity 3D faces, a romance value system, another full style audition, a bigger island map, music that hints at the right answer, a simulation that guarantees Einstein wins.

## Round log

- R1 2026-11-22 04:50 JST, whole game. Adopted: the two-climax frame, items 1–7, checklist F1–F11. Corrected: the verdict-first UI already exists (oracle thought it was unbuilt); the real-GTX-1650 requirement was dropped because the Owner waived Windows hardware proof on 2026-11-07.
- R2 2026-11-22 05:35 JST, story. Adopted: the two threads, items 8–10, F12–F18 (all new text passes 4-locale max-size checks). Corrected: the darkroom chart, verdict recall, micrometer feel and the "had you already decided?" question are already built (#372 #374 #376 #378, `content_coda.gd` `pressed`), so oracle's items 1 and 3 became verification rows; its claim that `content_coda.gd:96,98` calls Kit "她" is wrong (those lines have no pronoun for Kit). Next rounds get a feature inventory of main so they stop proposing built work. The inventory (KIOXIA `fun-rounds/inventory.md`, 05:36 JST) also shows the Kit reunion already exists in October (`kit_reunion`), so item 10 shrank to the closing frame.
- R3 2026-11-22 06:4x JST, characters. Adopted: item 5 split into poses at work, portrait coverage and evidence-first reactions; F19–F20; F4 and F14 tightened. Folded rather than added: oracle's F19/F21 (dialogue clipping, portrait mapping) into F4, F23 into F14, F24 into F17/F18. Kept: item 8 stays the R2 lines (no Eddington–Cottingham quarrel; no invented quotes). Key trade-off: a correct working pose for Cottingham buys more character than any new portrait or line.
- R4 2026-11-22 07:2x JST, music. Adopted: item 6 rewritten (entries and exits, not new music), F6 tightened, F21–F24. Corrected: the second-contact silence oracle flagged as a risk is mostly built (#411 c8277dc: birds stop, insects fade in from −60 dB over 3 s, score held 2 s); only the surf is left. Oracle's F22 exposure-mix row folded into F21, its darkroom row into F8/F14 (already there). Noted: M4_SCORE.md is out of date against D014.
