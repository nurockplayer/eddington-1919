# Fun plan: what makes Eddington 1919 worth playing

Living master plan and acceptance checklist, kept by edd-lead from the oracle-ego design rounds (Owner 2026-11-22 03:40 JST: one round every 50 min over story, characters, music, SFX, visuals, modelling, scenes, atmosphere). Rounds and full answers: KIOXIA `director/fun-rounds/round-NN/`. Each round's answer is weighed against the code and the Owner's decisions before anything lands here. **Needs Owner OK** marks a new feature, UI, story or scope change; nothing marked so starts before the Owner says yes.

## Direction (round 1)

Two climaxes, and both have to land:
- **Awe, at totality.** The world goes dark and the player feels they are standing inside a once-in-a-lifetime event. Carried by image, sound and timing. The Owner's test: does it feel epic?
- **Revelation, at the measurement.** The player reads their own plates and finds that the prediction they believed does not explain what they measured. Carried by hands-on play, reasoning and how the characters react.

The game does not need more mechanics that show off science. It needs the sky to feel worth waiting for, and the plate the player measured to feel strong enough to change their mind about the universe.

## Ranked items

| # | Item | Status / where | Owner of the work | Needs Owner OK |
|---|---|---|---|---|
| 1 | **Readable engraving:** cut the competing line density in sky, ground and props so the eye finds the focus, the interactables and the speakers | A′ (#415): #416 hatching cause (Sol diagnosis running), #417, #420, #421 | edd-art decides, Codex builds | no (executes the chosen style) |
| 2 | **Totality as an event:** tension builds before second contact, the light drops sharply, about 2 s of near-silence, then the corona and the music release | #411 soundscape merged c8277dc; image side waits for #416/#417; judge on the Phase-0 clip (#422) | edd-art + Codex | no for tuning; yes for any new free-look mode |
| 3 | **The player makes the discovery in the darkroom:** micrometer feel, verdict before Eddington explains | verdict-first is already on main (`content.gd` key `verdict`, `judgment.gd verdict_truth`, #351 PR 1 of 3); left: micrometer tactility, ledger marks on the chart, recalling the verdict in the coda (#351 PRs 2–3) | Codex, edd-art for the look | no (decided under #351) |
| 4 | **A working expedition camp:** instruments, plate boxes, shelter, exposure rig and darkroom kit placed where they are used | partly done (#344 darkroom props); #418/#419 darkroom figure and plate | edd-art + Codex | no |
| 5 | **Memorable people:** engraved portraits, people seen at work, short lines reacting to the player's own evidence; no high-fidelity 3D faces | portrait card layout #421; reaction lines are new text | Codex, edd-art | **yes** for new lines or character beats |
| 6 | **A sound memory through the game:** the gramophone, island ambience, instrument mechanics, shutter, darkroom, the reveal | music plan A approved (3 cues + departure promise); the rest is mixing | Codex | no for mixing; **yes** for paid commissions |
| 7 | **The 1917 doubt pays off in 1919:** ledger, Mercury, Sobral and Ashby come back; trim the stretches a blind player finds long | CONVERSION_ARC A–E built; #351 coda-trim proposal | lead proposes, Codex builds | **yes** (story, ending, pacing) |

No new L-size features until the Príncipe slice plays clearly and is memorable.

## Acceptance checklist (targets, not current results)

| Row | Scene | Passes when | Evidence | Owner looks |
|---|---|---|---|---|
| F1 | Arrival / coelostat | every required interactable identifiable from 3 m; no moiré or noise field wider than 1/20 of the frame | Phase-0 720p stills + object list | before/after |
| F2 | Camp walk | 10 s walk plus a full turn at 60 fps shows no line crawl, detached hatching or pop-in | Phase-0 walk clip | short clip |
| F3 | Coelostat | the same surface's line count differs by at most 1 across 720p / 1080p / 1440p | Phase-0 stills + count | no |
| F4 | Dialogue | no clipped text in en / ja / zh-TW / ko at max text size; contrast ≥ 4.5:1; a portrait on every line; no 3D face detail within reach | 4-locale stills, contrast check | one frame |
| F5 | Totality | Moon solid black, white corona, horizon glow and camp silhouettes clear; no grey in-between frame; stars on simulated positions | clip from 20 s before second contact, star overlay | **yes**: epic? |
| F6 | Totality audio | about 2 s of near-silence after second contact before the music; shutter clearly audible; exposure control never blocked | clip, waveform, event timeline | **yes** |
| F7 | Darkroom | glass plate and measuring tools distinct at 720p; plate and data chart keep a photographic look (whether hatching applies there is edd-art's call) | stills + measurement clip | **yes** |
| F8 | Micrometer | the same step always sounds the same, whether or not the reading is near the right answer; careless measuring still adds error | clip + careful/careless/inconclusive runs | no |
| F9 | Verdict | 0 / 0.87″ / 1.75″ / inconclusive offered before any NPC explanation; all four paths continue and are saved | 4 automated runs + save check | no (built) |
| F10 | Performance | totality under the shelter stays ≥ 30 fps at 720p in the class estimate, 3 clean reps (Owner 2026-11-07: no Windows hardware proof needed) | forced-draw method | no |
| F11 | Whole game | at least 2 of 3 newcomers can state their first prediction, what they observed, and why they kept or changed it; they answer both 2σ transfer questions | blind playtest per `docs/PLAYTEST_NEWCOMER.md` | reads the result |

F11 needs people the team does not have while the Owner is away; until then the playtest bot (`docs/PLAYTEST_BOT_DRIVE.md`) only checks the route, not whether the player cares.

## Owner's ~10 min a week

2 min arrival/dialogue before-after · 3 min totality clip with sound ("epic?") · 2 min darkroom ("did I make the discovery?") · 2 min yes/no on queued proposals · 1 min gut reaction.

## Deferred and rejected

- Deferred until a playtest shows the need: original score commissions, more measurement visualisation, advanced exposure aids, mid-darkroom saves.
- Rejected: high-fidelity 3D faces, another full style audition, a bigger island map, music that hints at the right answer, a simulation that guarantees Einstein wins.

## Round log

- R1 2026-11-22 04:50 JST, whole game. Adopted: the two-climax frame, items 1–7, checklist F1–F11. Corrected: the verdict-first UI already exists (oracle thought it was unbuilt); the real-GTX-1650 requirement was dropped because the Owner waived Windows hardware proof on 2026-11-07.
