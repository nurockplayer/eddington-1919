# The expedition journey

26 November 2026 JST · Scope B + interludes · [Owner decision, #316](https://github.com/nurockplayer/eddington-1919/issues/316#issuecomment-7167979143)

Five playable chapters and six short interludes add roughly 70–100 minutes. The fictional assistant from Cambridge leads the journey. Sobral is a playable archival reconstruction. Kit and Ashby carry the personal story through separation, letters and reunion. Fictional colleague Edmund Rook puts their work under public pressure. See [Journey arcs](JOURNEY_ARCS.md) for the fictional beats and existing scene handoffs. The documented relationships supply their own stakes: Eddington writing home, Dyson backing his work, Cottingham keeping the instruments running, and scientists arguing over whether collaboration can survive the war. The Príncipe slice remains the first delivery. Design and scripts can proceed in parallel with it. Wiring begins after slice acceptance. Moves: none.

**Provenance.** Section numbers below refer to the [expedition dossier](../research/expedition_journey_2026-11-26.md). `HISTORICAL_RECORD` covers the cited action, finding or document. Use attributed paraphrases unless the brief verifies a quotation against its source. `RECONSTRUCTION` covers staging, compressed time and simulated apparatus. `INVENTED-FICTIONAL` covers the assistant, Kit, Ashby and Rook. `INFERENCE` covers design readings and estimates. Label those distinctions on player-facing documents and simulations where they affect what the player can take as evidence. Historical dates follow the local calendar in the sources.

**Research sources.** [Society and Influenza, 1918–1920](../research/society_1918_1920.md) · [Sobral expedition](../research/sobral_1919.md)

## Chapter order

| Order | Chapter or interlude | Place and time | Conversion and emotional handoff |
|---|---|---|---|
| 1 | Existing Cambridge 1917 prologue | Cambridge, October 1917 | Trust Newton's successes and write a prediction. Let the absent assistants register as a loss. |
| 2 | **Tribunal** | Cambridge, June–July 1918 | Put Eddington's right to state his conscience beside the practical case for keeping the observatory working. |
| 3 | I1 · Armistice | Britain, November 1918 into early 1919 | The war ends. Grief, rationing and exclusions continue into peacetime. |
| 4 | Existing M2 departure | Cambridge, March 1919 | Keep Kit's promise about the sky and Ashby's charge to keep an honest record. |
| 5 | **The Madeira wait** | Liverpool and Lisbon in the opening records, Funchal from 14 March to 9 April 1919 | Two teams go separate ways with the same question. The blank time between sailings makes the distance felt. |
| 6 | I2 · The onward passage | Cape Verde to Santo António, April 1919 | Leave the waiting room behind and land on Príncipe on 23 April. |
| 7 | **The weeks at Sundy** | Príncipe, 23 April to 28 May 1919 | Learn what the equipment can establish and what the sky can still take away. |
| 8 | Existing Príncipe slice | Roça Sundy, 29 May 1919 | Watch the sky and make the exposure decisions. |
| 9 | Existing darkroom and Sundy coda | Sundy, after the eclipse | Test with the player's plates and write a proportionate telegram. Keep the coda's intimate close at the worktable. |
| 10 | I3 · Two cables | June 1919, as printed in Britain | Two weather reports arrive. Sobral's clearer sky opens a second line of evidence and the archive chapter. |
| 11 | **[Sobral](journey/SOBRAL.md)** | Sobral, 29 May to 22 July 1919 | Rewind from the cables to the clear opening at totality. Inspect the focus fault and the sharper 4-inch plates, then match a July reference. |
| 12 | I4 · Homeward and across Europe | June–September 1919 | Return with different kinds of evidence. News reaches families and travels through neutral channels before the public verdict. |
| 13 | Existing October epilogue | Cambridge, October 1919 | Compare the two Sobral sets with the player's simulated result. Revisit the prediction, evidence weights and the Mercury residual with Ashby. |
| 14 | **The joint meeting** | Burlington House, London, 6 November 1919 | Put the result and its limits on the same page. The public recognition is the climax. |
| 15 | I5 · In print → I6 · Replies → existing ending review | November 1919 to August 1920, then the player's run review | See the result become news, and see how differently the news travels. End on the player's own recorded reason. |

The ending review is the run summary that currently follows the October epilogue on the full story path. Sundy still ends with its own coda before the return to Cambridge. [Sundy handoff](../../scripts/main.gd) · [October ending handoff](../../scripts/cambridge/epilogue_director.gd)

## Playable chapters

### 1. Tribunal

**Setting.** Cambridge Observatory and two document-led hearing scenes, 14 June and 11 July 1918. **Player verbs.** Read, sort, cite. **One mechanic.** Assemble a reference packet by matching extracts to three headings: observatory duties, statement of conscience, and terms of the ruling. The player works on the observatory's copy. The recorded decisions play in order on every route.

**Conversion and feeling.** Extend trust from familiar predictions to the people and institutions that make a test possible. Ashby can distrust the theory and still keep the observations viable. Kit stays with the work as the institution debates whether Eddington can stay with it.

1. `HISTORICAL_RECORD` · Put the observatory's wartime staffing loss beside the 1916 occupational exemption, which kept Eddington working while his conscience case was deferred. Dossier §1, Cambridge Observatory/ObsA1/iii/123–124 and the tribunal chronology in Dolan.
2. `HISTORICAL_RECORD` · Read the exchange of positions over contact with enemy-country scientists. Turner invokes wartime atrocities, Larmor favours suspension, and Eddington distinguishes states from individual colleagues. Use attributed paraphrase for the hostility in all four locales. Dossier §§2–3, Stanley pp. 59–70 and Royal Society MS/603/3/4.
3. `INVENTED-FICTIONAL` · Kit and the assistant separate two assertions in the packet. A shortage of observatory staff explains a work exemption. It cannot speak for someone else's conscience.
4. `HISTORICAL_RECORD` · The 14 June appeal overturns the exemption and defers call-up to 1 August. When Eddington raises his conscientious objection, the chair rules it outside the question before the tribunal. Dossier §§1, 4, *Cambridge Daily News*, 14 June.
5. `RECONSTRUCTION` · Use a desk and reported proceedings to move from the appeal through the procedural delay to rehearing. Leave the private negotiations offstage.
6. `HISTORICAL_RECORD` · Dyson's letter supports Eddington's observing qualifications. In July the tribunal hears his refusal and his willingness to do alternative work, then grants twelve months on condition he continues his present work, with the eclipse cited. Keep the work condition and the conscience grounds legible. Dossier §1, *Cambridge Daily News*, 28 June and 12 July.
7. `INVENTED-FICTIONAL` · Ashby makes room for the packet beside the prediction ledger. The player can see his 0.87″ still there. His commitment is to the test and the people doing it.

### 2. The Madeira wait

**Setting.** Funchal, principally Hotel Bella Vista and a dockside desk, 14 March–9 April 1919. Liverpool and Lisbon appear in the opening papers. **Player verbs.** Read, match, route. **One mechanic.** Match the assistant's copies of the equipment and observing checklists to the two fixed routes. Label the papers as reconstructed working copies. The task follows the split from one common plan to independent observations.

**Conversion and feeling.** Carry the prediction into the logistics that could make it testable at two sites. The first empty seat after the teams split makes impatience and separation concrete. Practical help arrives from people whom the British team has just met.

1. `HISTORICAL_RECORD` · Trace *Anselm* from Liverpool on 8 March through Frederico Oom's 12 March reception in Lisbon to Funchal on 14 March. Dossier §§1–2, expedition report §§8–9, 26 and Trinity EDDN/A/4/2.
2. `HISTORICAL_RECORD` · Use the farewell lunch and split described in the family letter. Crommelin and Davidson continue toward Brazil on *Anselm*. Eddington and Cottingham wait in Funchal for almost four weeks. Dossier §§1, 4, Trinity EDDN/A/4/2 and EDDN/C/1/3.
3. `RECONSTRUCTION` · Set the routing task at the hotel worktable after the split. The player sees which team owns each checklist. The exposure papers retain the same prediction question on both routes. Show the known onward itinerary on a separately dated archive map so the assistant does not foretell the Brazil team's movements.
4. `INVENTED-FICTIONAL` · The assistant records the Funchal sky in Kit's workbook and leaves space for a later reply. In a separate letter, the assistant asks about Kit's work and admits to missing their company.
5. `HISTORICAL_RECORD` · Show the plentiful sugar through Eddington's letter alongside Britain's continuing rationing. His wish to get on with the journey comes from the same letter. Dossier §§3–4, Trinity EDDN/A/4/2 and the cited Hansard rationing figures.
6. `HISTORICAL_RECORD` · The papers show the visa errand, a local editor's help and Eddington's written revision of his first impression. Attribute his account to the letter. The editor's private motives stay open. Dossier §4, Trinity EDDN/A/4/5.
7. `HISTORICAL_RECORD` · Transfer luggage by lighter and depart on *Portugal* on 9 April. Close on the Príncipe folder going aboard while the Sobral folder has already gone ahead. Dossier §1, Trinity EDDN/A/4/5 and expedition report §26. The folders are `RECONSTRUCTION`.

### 3. The weeks at Sundy

**Setting.** Santo António and Roça Sundy, 23 April–28 May 1919. **Player verbs.** Compare, mark, log. **One mechanic.** Compare two simulated check exposures against the same reference marks and log whether the drive check can be used, must be repeated, or has too few visible stars for a judgment. Reuse plate comparison, with a short clear night and then a clouded attempt. This is a rehearsal for the existing test. The historical site choice, eclipse weather and slice state are fixed outside this exercise.

**Conversion and feeling.** Doubt becomes specific. The instrument may drift, a check may be unreadable, and the clearest nights say little about eclipse afternoon. Give the last clear star field time to settle, then cut to the clouded daylight before the slice.

1. `HISTORICAL_RECORD` · Land at Santo António on 23 April. Map the two candidate sites and the 26 April choice of Sundy's open northwest outlook. Credit Vasconcelos, Carneiro and Grageira for documented assistance. The assistant reads the choice after the fact. Dossier §§1–2, expedition report §§26–28.
2. `HISTORICAL_RECORD` · On the 28 April equipment move, show where the track ends and porters take the loads through the forest. Frame the handoff so the work is visible and intelligible. The record leaves the porters unnamed. Dossier §§1–3, expedition report §§27–28 and the Simões, Soares and Carolino labour study.
3. `HISTORICAL_RECORD` · Separate the help Carneiro supplied from the plantation system that made the labour available to him. A short attributed note explains coercion and barriers to return in colonial cocoa contract labour. Wright and Lewis are credited as cable-station employees who interpreted. Individual workers' origins, terms and motives stay open. Dossier §§2–3, Trinity EDDN/A/4/7 and the labour study.
4. `HISTORICAL_RECORD` · The party returns to port from 6–13 May to limit the mirror's exposure to humidity. On its return show the coelostat, weight pit and horizontal tube on the fixed setup, with Cottingham responsible for the drive. Dossier §§1–2, expedition report §§28–31 and Trinity EDDN/C/1/3.
5. `HISTORICAL_RECORD` · Night checks begin on 16 May. Identify the Arcturus check field separately from the Oxford eclipse-field comparison. Read the contrast between often clear nights and cloudy days in the account of the gravana. Dossier §1, expedition report §§28–31 and Trinity EDDN/A/4/9.
6. `RECONSTRUCTION` · Play the repeated check and record its limits before the result matters. Label the positions and any exaggerated displacement as simulation. A failed check records a reason to repeat, with no inference about the size of the deflection.
7. `INVENTED-FICTIONAL` · The assistant turns from the completed check to the notebook space Kit asked them to fill. Below the plain observation of the clouds, the assistant answers the letter Kit sent from Cambridge. Hand off to the existing 29 May scene.

### 4. Sobral

**Setting.** Jockey Club racecourse and darkroom, Sobral, from the eclipse on 29 May through the July return. **Player verbs.** Inspect, match, log. **One mechanic.** Compare plates and file an evidence note. Diagnose the diffuse astrograph images, identify the sharper 4-inch series, and pair the same field and instrument for a July reference. The historical exposure and reduction records are fixed.

**Conversion and feeling.** The clear opening and completed exposures bring relief after Sundy. The darkroom reveals why more stars can still make a weaker measurement. In July, the same field and a recovered focus let the player see what a good reference can establish and why the eclipse scale remains uncertain. See the [chapter script](journey/SOBRAL.md) for the documented Brazilian work, English copy and all comparison outcomes.

### 5. The joint meeting

**Setting.** Burlington House, London, 6 November 1919. **Player verbs.** Compare, annotate, explain. **One mechanic.** Use the same fixed chart twice to attach evidence to objections. For precision and scale, bring forward the separate plate series and the focus problem. For the need for another test, mark which question the eclipse chart can address and which still needs independent evidence. The assistant makes notes from the meeting account. The public discussion follows the record.

**Conversion and feeling.** The October epilogue lets Ashby revise in private and the player name a reason. London puts that reason under public pressure and lets the independent observations carry the release. A player with unreadable or inconclusive plates still reaches the meeting and can cite the strongest historical evidence or retain a reservation. Keep the player's simulated point visibly separate from the historical chart.

1. `INVENTED-FICTIONAL` · On the way into the scene, Kit recalls their shared notebook and Ashby opens the prediction page. Use the result-dependent October reaction, including a reasoned holdout.
2. `HISTORICAL_RECORD` · The Royal Society and Royal Astronomical Society meet jointly under J. J. Thomson. Announce the two principal results: Sobral 4-inch 1.98″ ± 0.12″ and Príncipe 1.61″ ± 0.30″, both with probable errors. Dossier §1, *The Observatory* 42, pp. 389–398 and expedition report §V. [Contemporary meeting report in *Nature*](https://www.nature.com/articles/104280a0)
3. `HISTORICAL_RECORD` · Preserve the Sobral astrographic result near 0.93″ and the focus and scale issue. Distinguish the instrument's blur from the player's own observation quality. The later full report also presents a scale treatment giving about 1.52″. Dossier §§1, 5, expedition report §§22–25, 37.
4. `RECONSTRUCTION` · On the assistant's chart, annotate the precision objection using the independent series and the uncertainty attached to each. Keep the astrographic point visible with the scale issue beside it. Use explicit probable-error labels or a stated conversion if the reused chart draws standard deviations.
5. `HISTORICAL_RECORD` · Newall acknowledges that the Einstein effect holds the day and keeps open another interpretation, raising an extended solar atmosphere. Dossier §4, *The Observatory* 42, p. 395. [Contemporary quotation in *PASP* 32, p. 73](https://adsabs.harvard.edu/pdf/1920PASP...32...71.)
6. `HISTORICAL_RECORD` · Give Silberstein's solar redshift objection its own beat. It asks for an independent test of the theory. The eclipse exposures concern the deflection of light. Dossier §§1–2, *The Observatory* 42, pp. 396–397.
7. `RECONSTRUCTION` · Return to the same chart for the second annotation. Hold the two useful observations together on screen after the objection has been read. Give the comparison a quiet pause before the player advances. The pause and the chart belong to the staging. Leave the room's actual display method and audience reaction unspecified.
8. `INVENTED-FICTIONAL` · Let Ashby point to the agreement across two sites and Kit see the assistant's reason or reservation beside the old prediction. The redshift question remains open. Leave a beat of quiet before the first newspaper. The intended scale comes from work that took years, travelled across borders and can now be publicly challenged. The Owner's question for the scene is “Does it feel epic?”

## Interludes

Use one paper view with read and advance controls. Present sources as archival inserts where the assistant's access is undocumented. A dated document gives the date of writing or publication. It does not establish delivery. [Society and Influenza](../research/society_1918_1920.md) §§1–3 supplies the society records. Society insert placements below are `INFERENCE`. The linked scripts give the final copy, source and four-locale notes.

| Insert | Form and placement | Material and source | Lines × 4 |
|---|---|---|---|
| I1 · Armistice | Clipping, Tribunal → M2 | `HISTORICAL_RECORD` Armistice, demobilisation and continuing rationing. Carry the local wartime loss forward without inventing a family's reaction. Dossier §§1, 3, UK Parliament Armistice history and Hansard. Add the [Cambridge school closure and obituary, demobilisation protests and the franchise and election papers](journey/TRIBUNAL.md#i1--armistice). | 21 × 4 = 84 |
| I2 · The onward passage | Letter and route slip, Madeira → Sundy | `HISTORICAL_RECORD` *Portugal* calls at São Vicente and Santiago before landing on 23 April. A family letter written on 14 March arrives when Eddington reaches the island. `RECONSTRUCTION` Route slip design. Dossier §§1–2, expedition report §26 and Trinity EDDN/A/4/5, A/4/7. Add the [1918 Cabo Verde influenza record](journey/MADEIRA.md#i2--the-onward-passage) against the two Cabo Verde calls. | 11 × 4 = 44 |
| I3 · Two cables | Paired telegrams and a captioned clipping, after the Sundy coda | `HISTORICAL_RECORD` Pair “Through cloud, hopeful” with the published Sobral cable. Use publication dates and source wording, with dispatch time and addressee left open. The Sobral side traces the journey through Pará, the wait that allowed a trip to Manaus, and the steamer to Camocim and rail to Sobral. Credit the hosts and interpreter, and Morize's Observatório Nacional team for its own corona and spectroscopy programme. Dossier §§1–4, *Nature* 103, pp. 265–266, *The Observatory* 42, p. 256, expedition report §§9–10 and MAST's *O Eclipse de Sobral*. Add the [Belém and Sobral press page](journey/SUNDY.md#i3--two-cables) after the Brazilian expedition credit. | 16 × 4 = 64 |
| I4 · Homeward and across Europe | Letters, telegram and report extracts, Sobral → October epilogue | `HISTORICAL_RECORD` The shipping dispute sends the Príncipe pair home early on *Zaire*. Retain the June letter's mixture of tentative evidence, delight for the Brazil team and strawberries at home. The Príncipe pair reaches Liverpool on 14 July. The Sobral team stays through the July comparison exposures and reaches Greenwich on 25 August. Show the earlier recorded focus trouble and Greenwich's later reduction. The July research council in Brussels keeps the defeated Central Powers excluded. In September, Lorentz cables the tentative result and Einstein writes to his mother. Dossier §§1, 3–4, Trinity EDDN/A/4/9, expedition report §§12–25, 29, 35, Sobral notebook RGO 8/166, the Brussels proceedings and *Collected Papers of Albert Einstein* vol. 9, docs. 108, 113. Add the [July employment record, Liverpool police-strike report and August Belém interview](journey/LONDON.md#i4--homeward-and-across-europe). | 23 × 4 = 92 |
| I5 · In print | Clippings, London → I6 | `HISTORICAL_RECORD` Put the 7 November London and 10 November New York headlines alongside the circumscribed finding. Britain's 11 November two-minute silence gives the public news its post-war setting. Dossier §§1, 3, *The Times*, p. 12, *The New York Times* and UK Parliament Armistice history. `INVENTED-FICTIONAL` Rook's column occupies its own labelled page. Add the [Brazilian, Portuguese, German and further American coverage, Robinson’s diagram and Einstein’s own explanation](journey/LONDON.md#i5--in-print). | 25 × 4 = 100 |
| I6 · Replies | Letters and clippings, I5 → ending review | `HISTORICAL_RECORD` Eddington writes Einstein on 1 December hoping for renewed contact. The RAS medal vote also shows the limits of reconciliation. Close the historical inserts with Einstein's August 1920 public response to the Berlin rally. Attribute his account of the antisemitic and nationalist motives to him. Dossier §§1–3, Einstein Archives ALS 9-260, RAS Council Minutes and *Berliner Tageblatt*, 27 August, pp. 1–2. Add the [French translation, December professions Act, Japanese astronomy journal and American cartoon](journey/LONDON.md#i6--replies) before the Berlin reply. | 20 × 4 = 80 |

**Sobral brief handoff · INFERENCE.** At the arrival papers, reuse [I3-17](journey/SUNDY.md#i3--two-cables) as the local press context, with its four-locale notes and archival label. `HISTORICAL_RECORD` *A Lucta* · Sobral · 23 April 1919. “Carnaval versus Grippe”. The date is the issue date, one week before the British team reached Sobral. [Society dossier §1, Sobral issue reference and expedition report §§9–10](../research/society_1918_1920.md#1-influenza-along-the-journey)

## Size and reuse

`INFERENCE` estimates count unique visible source lines, including dialogue branches, prompts, labels and documents. Each ships in English, Japanese, Traditional Chinese and Korean (en/ja/zh-TW/ko). Use the existing source strings and locale catalogues. [Locale directory](../../locale/)

| Chapter | Scenes | Lines × 4 | Added play | Reuse and new staging |
|---|---:|---:|---:|---|
| Tribunal | 3 | 86 × 4 = 344 | 12–17 min | Reuse the [Cambridge room](../../scenes/cambridge.tscn), [plan-board interactions](../../scripts/cambridge/plan_board.gd) and [report sheet](../../scripts/cambridge/report_sheet.gd). Render the hearings through document views in the room. |
| M2 departure papers | Existing montage | 2 × 4 = 8 | Within existing transition | Reuse I1’s archival paper for the [Cambridge headline and Employment Exchange counts](M2_DEPARTURE.md#full-journey-departure-papers). |
| Madeira | 3 | 84 × 4 = 336 | 13–18 min | Reuse [departure props](../../scripts/cambridge/departure_props.gd), [checklist](../../scripts/cambridge/departure_checklist.gd) and [dialogue portraits](../../scripts/cambridge/dialogue_portrait.gd). Stage the hotel desk and dockside as compact settings. Trace the route on paper. |
| Sundy weeks | 4 | 97 × 4 = 388 | 18–25 min | Reuse the [Sundy scene](../../scenes/main.tscn), [plate renderer](../../scripts/plate_render.gd) and [comparison overlay](../../scripts/cambridge/overlay_viewer.gd). Santo António and the track break can be small staged transitions. Keep rehearsal measurements local to the chapter. |
| Sobral | 3 | 54 × 4 = 216 | 7–10 min | Reuse the Príncipe sky, shelter, optics and darkroom plate viewer. Stage the Sobral grandstand and separate instrument stations. The count includes the replacement I3 exit line. |
| Joint meeting | 3 | 102 × 4 = 408 | 14–21 min | Reuse the [October chart format](../../scripts/cambridge/epilogue_chart.gd), [report sheet](../../scripts/cambridge/report_sheet.gd) and [existing ending review](../../scripts/ending.gd). Scope a single abstracted meeting room with the chart in the foreground. |
| October epilogue changes | Existing scenes | 7 × 4 = 28 | Within existing scenes | Revise Kit’s envelope exchange, add Ashby’s apology and show the [observatory staffing paper](journey/LONDON.md#october--reunion-and-reckoning). |
| Interludes | 6 short inserts | 116 × 4 = 464 | 7–12 min | Reuse the [report-sheet presentation](../../scripts/cambridge/report_sheet.gd) and [dialogue UI](../../scripts/ui.gd), with one treatment for letters, cables and clippings. |
| **Total** | **16 playable scenes + 6 inserts** | **548 × 4 = 2,192** | **71–103 min** | Estimates exclude new voice recording and art effort. |

## Lines we do not cross

- Keep documented speech and conduct attributable. The assistant, Kit and Ashby carry invented choices, conversations and intimacy. Eddington's affection is available in the family letters. The letters give no basis for a romance, a claim about his sexuality or an invented feud. Einstein stays off the expedition route. (Dossier §§2, 4, 8.)
- Stage refusal and stigma through the tribunal record and attributed debate. In all four languages paraphrase the slurs and preserve who was excluded and by whom. Keep the 1916 exemption, June reversal and July rehearing distinct. The rescue-by-phone or release-from-prison story has no contemporary support in the dossier. (Dossier §§1, 3, 5, 8.)
- Show the people who moved, built, interpreted and hosted through their documented tasks. Give coercion plain language and attribute claims to their scope. Leave individual contracts, names and motives open where the record does. Island-wide sleeping-sickness controls may appear as sourced context. A named person's illness or a particular inspection at Sundy requires evidence. Keep Sobral's Brazilian team visible as a scientific expedition in its own right. (Dossier §§2–3, 8.)
- Identify antisemitism through sourced attacks and Einstein's response. Keep it distinct from technical objections, including Silberstein's. The late anecdote about only three people understanding relativity stays outside the dramatized meeting. Give rivals the arguments the record attributes to them. (Dossier §§2–3, 5, 8.)
- Present 0.87″ as the Newtonian-style comparison used by the expedition. Keep both Sobral reductions visible and describe why scale affected their weight. The full report published the disputed readings. Keep the player's chart separate, label historical probable errors, and let an inconclusive personal run reach the ending. (Dossier §5 and [Conversion arc](CONVERSION_ARC.md).)
- Distinguish an observation-day cable, a preliminary plate measurement and a public result. Leave the alleged 3 June diary declaration out of the script. Use the traceable June letter for Eddington's preliminary account. Leave the original cable's dispatch date and addressee, the final return ship name and any unverified meeting reaction unspecified. (Dossier §§1, 4–6.)

## Corrections owed

These are follow-up content or reference corrections identified by dossier §6. The scene briefs carry the dependencies where they touch them.

| Current file:line | Correction owed |
|---|---|
| [`scripts/main.gd:1143`](../../scripts/main.gd#L1143) | The Sundy hotspot identifies the pier builders as plantation workers. The report records purpose-built piers and labour from the plantation. Attribute the known work and leave the builders' identity open. |
| [`scripts/content.gd:132`](../../scripts/content.gd#L132), [`:174`](../../scripts/content.gd#L174) | The Oxford comparison plate text says “the same telescope.” Specify reuse of the Oxford objective with the island's horizontal tube and coelostat. See expedition report §IV. |
| [`scripts/content.gd:141`](../../scripts/content.gd#L141) | The island darkroom compresses development and measurement into one playable episode. Mark the simulation's compression where the historic plates are discussed. X was measured on Príncipe. W was developed and measured after the return to England. See expedition report §35. |
| [`scripts/ending.gd:79`](../../scripts/ending.gd#L79) | The historical block names Dyson as the cable's recipient. Attribute the wording to the June 1919 publication in *Nature* and leave the original addressee open. Keep the player's fictional draft distinguishable from that publication. |
| [`docs/HISTORY_1919.md:44`](../HISTORY_1919.md#L44) | Credit José P. S. Lemos as the author of *Shadow of the Moon and general relativity* (2019). |

The 29 May title card dates the playable observation day. I2 supplies the distinct 23 April landing. The cloud timing and plate-count variations are simulated play, and the route already presents 0.87″ as Newtonian-style. [Departure card](../../scripts/cambridge/content_departure.gd#L159) · [Prediction ledger](../../scripts/cambridge/content_1917.gd#L367)

## Later scene briefs

Dispatch one writing brief per chapter in journey order. Each brief delivers the scene sequence, the action and all outcomes for its mechanic, dialogue and document copy with per-beat sources, four-locale string notes, staging and asset reuse, and the exact entry and exit into adjacent scenes. Include the assigned interludes and their final copy. Scene briefs can reach script-ready form before slice acceptance. Integration follows acceptance.

| Brief | Assigned interludes | Required handoff and acceptance case |
|---|---|---|
| Tribunal | I1 | Deliver the packet, extracts and June/July rulings. A player can explain the difference between occupational exemption and conscientious objection. Sorting the packet leaves the historical decision fixed and hands off to M2 with the 1917 prediction intact. |
| Madeira | I2 | Deliver both route-checklist copies and the separation and waiting beats. A player can trace the shared departure, split at Funchal, onward ship and 23 April landing. Keep Kit's workbook thread consistent with M2. |
| Sundy weeks | I3 | Deliver the setup, porters' handoff, comparison exercise and cloudy daylight transition. A player can tell an instrument check from a sky limitation, then reach the existing observation-day opening. I3 follows the existing darkroom and coda and distinguishes the published cables from the player's draft. Carry the Sundy and plate corrections as dependencies for subsequent content briefs. |
| [Sobral](journey/SOBRAL.md) | — | Enter from I3's paired cables and exit to I4. A player can distinguish cloud from poor focus, explain why the 4-inch series carried the strongest result, and select a July reference from the same field and instrument. Every route preserves both Sobral series and the Príncipe run for October. |
| Joint meeting | I4, I5 and I6 | Deliver the two chart annotations and the narrative beats around them. Walk the route from I4 through the October epilogue to London, then into print and the ending review. Test the script with a strong personal result and with an inconclusive one. In both, the player can explain a reason or reservation in their own words, and the last public exchange has room for the Owner to judge the release. |
