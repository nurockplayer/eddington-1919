# Tribunal and I1 · Armistice

Script-ready English copy for [The expedition journey](../JOURNEY.md). Cambridge, June–July 1918, followed by Britain from November 1918 into early 1919. Moves: none. Wire into the full story after Príncipe slice acceptance.

T and I numbers identify player-visible English strings. Speaker names reuse the existing cast labels. Provenance tags and source keys beside each line are production notes. On paper, distinguish historical summaries, reported speech and the reconstructed packet with the visible labels below. Historical dates use the local calendar. Each numbered row is one string and may wrap.

## Entry and staging

**Entry · RECONSTRUCTION, existing M1.** Enter at the black fade in [the 1917 director’s `_montage()`](../../../scripts/cambridge/director.gd#L601), after Kit’s coda has committed `Story.kit_choice` and `Story.want`. Keep the first two existing [M1 montage cards](../../../scripts/cambridge/content_1917.gd#L629), in order: the November 1917 expedition decision and the assistant’s submitted lists. Replace the third card, the short Armistice caption, with this chapter followed by I1. Fade up on T01. Defer the existing departure checkpoint and scene change until I12. Carry the rest of M1 state through the new pages.

**Room · RECONSTRUCTION, existing Cambridge assets.** All three scenes use [Cambridge](../../../scenes/cambridge.tscn) and its [room builder](../../../scripts/cambridge/room_builder.gd). Stage scene 1 at the workbench with the empty copyist desk in the sightline, scene 2 at the same bench with the appeal clipping in focus, and scene 3 with the July page followed by the sortable packet and ledger. Keep Kit and Ashby in their existing [cast](../../../scripts/cambridge/cast.gd) and use [existing portraits](../../../scripts/cambridge/dialogue_portrait.gd) and [dialogue UI](../../../scripts/ui.gd). The empty desk recalls M1’s fictional copyist and gives the sourced deaths a visual echo. Keep the prop’s unsigned letter closed. The two deaths belong to the historical Observatory staff, with no claim that the fictional copyist is either man.

**Paper · RECONSTRUCTION.** Use [report-sheet presentation](../../../scripts/cambridge/report_sheet.gd) for archival inserts and [plan-board selection and keyboard focus](../../../scripts/cambridge/plan_board.gd) for sorting. A hearing is a dated paper view with the same room behind it. Historical figures appear in the text. There are no courtroom models, actors or hearing audio. Use page turns and room tone for the cuts. Keep document text still and readable until the player advances, including with reduced motion. T22 is the shared page-advance control. Show T08 or T27 as appropriate on archival paper, and T07 on the reconstructed packet. Sources are reproduced as labelled summaries or short reported quotations. The desk arrangement supplies no evidence of when the papers reached the assistant.

## Scene 1 · Two claims

**Sequence · RECONSTRUCTION.** June 1918, before the appeal page. Kit opens the desk packet. Read the work case and the first conscience slip side by side, then the earlier dispute about contact across enemy lines. Lay the two slips apart for T19–T21. The player will file them once all the records are on the desk.

| ID | Display or speaker | English copy | Provenance |
|---|---|---|---|
| T01 | Card | Cambridge Observatory · June 1918 | RECONSTRUCTION · setting per J |
| T02 | Kit | Leave the ledger open. I need the other half of the bench. | INVENTED-FICTIONAL · J, M1 |
| T03 | Kit | I’m putting together our reference copy. Will you help me keep the grounds straight? | INVENTED-FICTIONAL · J |
| T04 | Heading | Observatory duties | RECONSTRUCTION · J |
| T05 | Heading | Statement of conscience | RECONSTRUCTION · J |
| T06 | Heading | Terms of the ruling | RECONSTRUCTION · J |
| T07 | Packet label | Observatory reference copy · Reconstructed | RECONSTRUCTION · J |
| T08 | Paper label | Historical record · Summary | RECONSTRUCTION · J |
| T09 | D1 · Title | Observatory staffing · Syndicate minutes, 1917–18 | HISTORICAL_RECORD · S |
| T10 | D1 · Body | The first assistant died in the explosion aboard HMS Vanguard. The second was killed in action in France. The Syndicate recorded Eddington as the sole remaining member of its scientific staff. | HISTORICAL_RECORD · S, paraphrase |
| T11 | D2 · Title | The University’s case · 1916 and May 1918 | HISTORICAL_RECORD · U |
| T12 | D2 · Body | In 1916 the University secured a conditional exemption so Eddington could maintain the Observatory’s work. In May 1918 Professor Newall made the case for keeping the observations going. The Borough Tribunal granted three months. | HISTORICAL_RECORD · U, paraphrase |
| T13 | C1 · Title | A separate application · Eddington’s account of 1916 | HISTORICAL_RECORD · A |
| T14 | C1 · Body | Eddington applied personally on conscientious grounds. The University’s case was taken first, and his personal claim was put aside when the work exemption was granted. | HISTORICAL_RECORD · A, B, paraphrase |
| T15 | Context title | Contact with colleagues in enemy countries · 1916 | HISTORICAL_RECORD · W |
| T16 | Context slip | Writing anonymously in The Observatory, Herbert Hall Turner invoked wartime atrocities and held German scientists responsible for endorsing their army’s actions. He opposed resuming scientific relations. | HISTORICAL_RECORD · W, attributed paraphrase |
| T17 | Context slip | Joseph Larmor favoured suspending scientific relations with colleagues in enemy countries. | HISTORICAL_RECORD · W, attributed paraphrase |
| T18 | Context slip | Eddington argued that the actions of a state and the conduct of individual colleagues should be judged separately. He wrote to Larmor to clarify his position on scientific relations. | HISTORICAL_RECORD · W, attributed paraphrase |
| T19 | Kit | The University asked to keep its astronomer at work. That’s an occupational exemption. | INVENTED-FICTIONAL · reading of U and A |
| T20 | Kit | Eddington asked to be excused from military service because it went against his conscience. That’s conscientious objection. | INVENTED-FICTIONAL · reading of A, B and L |
| T21 | Kit | An empty desk explains why the Observatory needs him. Only he can tell them what he can do in good conscience. | INVENTED-FICTIONAL · J, S |
| T22 | Control | Continue | RECONSTRUCTION · J |
| T23 | Kit | The May exemption was appealed. Here’s the report. | INVENTED-FICTIONAL · U, A |
| T24 | Action | Read the June appeal | RECONSTRUCTION · J |

T19–T21 are on every route. Hold both titles in view while Kit gives the distinction. Turner's, Larmor’s and Eddington’s three slips stay together as context. They do not enter the sorting tray. They show a professional disagreement with consequences for colleagues, without treating Turner’s accusation as an established fact or turning the dispute into evidence at the tribunal.

## Scene 2 · The appeal and the adjournment

**Sequence · RECONSTRUCTION.** T25 opens the June appeal, then T26–T35 run in order. Give the two speech lines the same plain paper treatment. Leave a page advance between the chair’s response and the ruling. Place the London committee note alongside the June record only after the decision, with its separate dateline. T40 opens the 27 June paper. No private meeting is shown. End on the procedural question and advance straight to the July paper.

| ID | Display or speaker | English copy | Provenance |
|---|---|---|---|
| T25 | Page title | County Hall, Cambridge · Appeal Tribunal · 14 June 1918 | HISTORICAL_RECORD · A |
| T26 | Appeal summary | The National Service Representative appealed the May exemption. The chair suggested that Eddington’s abilities could be of greater use to the Government in prosecuting the war. | HISTORICAL_RECORD · A, attributed paraphrase |
| T27 | Paper label | Historical record · Reported speech | RECONSTRUCTION · J |
| T28 | Attribution | Cambridge Daily News · 14 June 1918, p. 3 | HISTORICAL_RECORD · A |
| T29 | Reported speaker | Professor Eddington | HISTORICAL_RECORD · A |
| T30 | Reported quotation | “I am conscientious objector.” | HISTORICAL_RECORD · A, verbatim in the cited transcription |
| T31 | Reported speaker | Chair of the Appeal Tribunal | HISTORICAL_RECORD · A |
| T32 | Reported quotation | “That question is not before us.” | HISTORICAL_RECORD · A, verbatim in the cited transcription |
| T33 | R1 · Title | Appeal ruling · 14 June 1918 | HISTORICAL_RECORD · A |
| T34 | R1 · Body | Appeal allowed. The occupational exemption was overturned. Eddington was to be called up no earlier than 1 August 1918. The tribunal did not consider his conscientious objection. | HISTORICAL_RECORD · A, paraphrase |
| T35 | Kit | They struck out the work exemption. His claim of conscience is still waiting to be heard. | INVENTED-FICTIONAL · reading of A |
| T36 | Context title | London · Eclipse committee minutes · 14 June 1918 | HISTORICAL_RECORD · E |
| T37 | Context slip | A subcommittee provisionally put Eddington and Cottingham together as one of the observing parties. | HISTORICAL_RECORD · E, paraphrase |
| T38 | C2 · Title | Personal statement · Reported on 28 June 1918 | HISTORICAL_RECORD · B |
| T39 | C2 · Body | Eddington grounded his objection to war in his Christian faith. He said his country and its opponents could be moved by the same patriotism and religious duty, and that joining in the killing would violate his understanding of that faith. | HISTORICAL_RECORD · B, attributed paraphrase |
| T40 | Page title | Guildhall, Cambridge · Borough Tribunal · 27 June 1918 | HISTORICAL_RECORD · B |
| T41 | Procedural summary | The National Service Representative challenged whether a new application could be heard after the appeal. Eddington said his personal claim had been adjourned until it was needed. | HISTORICAL_RECORD · B, attributed paraphrase |
| T42 | R2 · Title | Adjournment · 27 June 1918 | HISTORICAL_RECORD · B |
| T43 | R2 · Body | The tribunal adjourned until 11 July to give Eddington time to seek permission from the Ministry of National Service for the tribunal to hear his claim. | HISTORICAL_RECORD · B, paraphrase |
| T44 | Kit | I’ll leave that place in the packet open. | INVENTED-FICTIONAL · J, B |
| T45 | Action | Read the July hearing | RECONSTRUCTION · J |

Play T40 before T38–T39 and T41–T45. The London note is a separate record, with no dramatic causal link to the appeal or reuse as a sort card. T26, T32 and T41 show how a claim could be excluded from the question before a tribunal. The paper stays with the recorded objections and response. The chair and the National Service Representative receive only their sourced positions.

## Scene 3 · The July ruling and the reference packet

**Sequence · RECONSTRUCTION.** T46–T55 are a single fixed reading path. Reveal the two reasons on separate slips before opening the ruling. The final line of the ruling stays on screen through its own continue action. Then Kit opens the sorting board, T56–T69. Ashby waits until the packet is filed before moving it beside the M1 prediction. The ledger is a read-only view.

| ID | Display or speaker | English copy | Provenance |
|---|---|---|---|
| T46 | Page title | Guildhall, Cambridge · Borough Tribunal · 11 July 1918 | HISTORICAL_RECORD · L |
| T47 | Clerk’s report | The Ministry of National Service had granted permission for the tribunal to hear Eddington’s claim of conscience. | HISTORICAL_RECORD · L, paraphrase |
| T48 | D3 · Title | Dyson’s letter · Submitted at the July hearing | HISTORICAL_RECORD · L |
| T49 | D3 · Body | The Astronomer Royal, Sir Frank Dyson, drew attention to Eddington’s research and urged the tribunal to let him observe the eclipse the following May. Dyson considered him particularly well qualified for the observations. | HISTORICAL_RECORD · L, attributed paraphrase |
| T50 | C3 · Title | Refusal and alternative work · July hearing | HISTORICAL_RECORD · L |
| T51 | C3 · Body | A Quaker from birth, Eddington said the Army could give him no assurance that his duties would be confined to saving life. He was willing to serve with the Friends’ Ambulance Unit or the Red Cross, or to help bring in the harvest. | HISTORICAL_RECORD · L, attributed paraphrase |
| T52 | R3 · Title | Borough Tribunal ruling · 11 July 1918 | HISTORICAL_RECORD · L |
| T53 | R3 · Body | The tribunal was satisfied that Eddington was a conscientious objector. It also found that his astronomical work should continue in the national interest, with particular regard to the following year’s eclipse. | HISTORICAL_RECORD · L, paraphrase |
| T54 | R3 · Condition | Twelve months’ exemption, on condition that he continued his present work. | HISTORICAL_RECORD · L, paraphrase |
| T55 | Kit | This time they heard his own claim. The work is the condition they put on the exemption. | INVENTED-FICTIONAL · reading of L |
| T56 | Prompt | Read an extract, then choose where to file it. | RECONSTRUCTION · J |
| T57 | Action | Read extract | RECONSTRUCTION · J |
| T58 | Action | Back to packet | RECONSTRUCTION · J |
| T59 | Action | File extract | RECONSTRUCTION · J |
| T60 | Feedback | Filed with source. | RECONSTRUCTION · J |
| T61 | Kit · D1 hint | That’s the record of who was left to do the work. Try Observatory duties. | INVENTED-FICTIONAL · S |
| T62 | Kit · D2 hint | That’s the University’s case for keeping the observations going. Try Observatory duties. | INVENTED-FICTIONAL · U |
| T63 | Kit · D3 hint | Dyson is vouching for his skill as an observer. Try Observatory duties. | INVENTED-FICTIONAL · L |
| T64 | Kit · C1 hint | That’s his own application from 1916. Try Statement of conscience. | INVENTED-FICTIONAL · A, B |
| T65 | Kit · C2 hint | That’s where he gives his reasons for refusing. Try Statement of conscience. | INVENTED-FICTIONAL · B |
| T66 | Kit · C3 hint | That’s what he could agree to do in good conscience. Try Statement of conscience. | INVENTED-FICTIONAL · L |
| T67 | Kit · R1 hint | That’s what the appeal changed, including when he could be called up. Try Terms of the ruling. | INVENTED-FICTIONAL · A |
| T68 | Kit · R2 hint | That’s the adjournment and what had to happen before the next hearing. Try Terms of the ruling. | INVENTED-FICTIONAL · B |
| T69 | Kit · R3 hint | That’s the decision reached in July, with its condition. Try Terms of the ruling. | INVENTED-FICTIONAL · L |
| T70 | Action | Close reference copy | RECONSTRUCTION · J |
| T71 | Ashby | Put it beside the prediction. When we come back to this page, I want the figures we wrote in 1917. | INVENTED-FICTIONAL · J, M1 |
| T72 | Ledger | Your 1917 prediction · {prediction} · {certainty} | RECONSTRUCTION · M1, read-only render |
| T73 | Ledger | Ashby’s 1917 entry · 0.87″ (Newtonian-style) | INVENTED-FICTIONAL · M1, historical comparator per E |
| T74 | Ashby | I’m still at 0.87″. I’ll see that you have what you need to test it. | INVENTED-FICTIONAL · J, M1 |
| T75 | Kit | Leave me the next list. I’ll start checking it in the morning. | INVENTED-FICTIONAL · J, M1 |

### Sorting and citation outcomes

The board uses the nine extracts D1–D3, C1–C3 and R1–R3 already read across the chapter. List D1, C1, R1, C2, D2, R2, D3, C3, R3 in that order in the tray. Reuse the numbered title and body text, including both R3 body lines. The paper view carries its source reference from the source register. With a tray card open, the player can select or change the heading until pressing T59. A correct match moves the extract under that heading with the reference attached and shows T60. The attached reference is the citation in the player’s copy. It remains visible on reread, with the same wording as in the extract. For a wrong match, speak the indicated hint once per attempt, leave the card in the tray and return focus to it. Back to packet closes the extract without filing. Already-filed cards can be read again. T59 is available only with an open tray card and a selected heading.

| Extract | Observatory duties | Statement of conscience | Terms of the ruling | Citation carried with extract |
|---|---|---|---|---|
| D1 · T09–T10 | File, T60 | T61 | T61 | S · ObsA1/iii/123–125 |
| D2 · T11–T12 | File, T60 | T62 | T62 | U · Coventry Evening Telegraph, 11 May 1916 and Cambridge Daily News, 16 May 1918, p. 4 |
| D3 · T48–T49 | File, T60 | T63 | T63 | L · Cambridge Daily News, 12 July 1918, p. 3 |
| C1 · T13–T14 | T64 | File, T60 | T64 | A and B · Cambridge Daily News, 14 and 28 June 1918, p. 3 |
| C2 · T38–T39 | T65 | File, T60 | T65 | B · Cambridge Daily News, 28 June 1918, p. 3 |
| C3 · T50–T51 | T66 | File, T60 | T66 | L · Cambridge Daily News, 12 July 1918, p. 3 |
| R1 · T33–T34 | T67 | T67 | File, T60 | A · Cambridge Daily News, 14 June 1918, p. 3 |
| R2 · T42–T43 | T68 | T68 | File, T60 | B · Cambridge Daily News, 28 June 1918, p. 3 |
| R3 · T52–T54 | T69 | T69 | File, T60 | L · Cambridge Daily News, 12 July 1918, p. 3 |

Before all nine are filed, the tray remains open. After the ninth correct placement, T70 appears. Closing always plays T71–T75, then I1. A clean sort and any sequence containing misfiles both use the same filed copy and exit. The June appeal, June adjournment and July decision have already been read in that order. The player sorts the Observatory’s own reference copy, which goes beside the ledger. It has no tribunal submission, score or vote.

**Acceptance in the script.** T19–T21 name who made the two claims and why. D2 and C1 ask the player to preserve the distinction in the packet. T30–T35 show the cost of hearing only the work case in June. T50–T55 show a refusal that allows other work, a conscience claim the July tribunal hears, and the continued-work condition it attaches to the exemption. A player can explain that the University argued that the Observatory needed Eddington, while Eddington argued that military service violated his conscience.

## I1 · Armistice

**Staging · RECONSTRUCTION, J.** Cut from the ledger to one archival clipping layout on the existing paper view. The following is final copy for a composed archival insert, with datelines for the records it summarises. Read top to bottom. T22 advances through the clipping and I12 closes it. Keep the local-loss paragraph in the same type treatment as the public reports. Use paper and room tone with no family reaction or crowd scene.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| I01 | Heading | Armistice | HISTORICAL_RECORD · H1 |
| I02 | Dateline | Britain · November 1918 to early 1919 | RECONSTRUCTION · J, H1–H5 |
| I03 | Label | Archival clipping · Compiled from records | RECONSTRUCTION · J |
| I04 | Dateline | 11 November 1918 · House of Commons | HISTORICAL_RECORD · H1 |
| I05 | Body | The armistice with Germany brought the fighting on the Western Front to a halt. | HISTORICAL_RECORD · H1, paraphrase |
| I06 | Body | Men began returning to civilian life in stages. The Ministry of Labour was still reporting releases from the Army in January. | HISTORICAL_RECORD · H2, paraphrase |
| I07 | Body | Food rationing continued into 1919. Meat and sugar were still rationed. | HISTORICAL_RECORD · H3, paraphrase |
| I08 | Dateline | 20 February 1919 · House of Commons | HISTORICAL_RECORD · H4 |
| I09 | Body | Some conscientious objectors were still in prison. One MP urged that they be held until the last servicemen were demobilised. The Home Secretary gave no such undertaking. | HISTORICAL_RECORD · H4, attributed paraphrase |
| I10 | Body | Allied scientific academies met in Paris after the armistice and advanced plans for new associations among the Allies, with neutral nations eligible to join. Germany and the other Central Powers were left outside those plans. | HISTORICAL_RECORD · H5, paraphrase |
| I11 | Body | At Cambridge Observatory, two assistants were already dead by December 1917. One had died aboard HMS Vanguard and the other in France. | HISTORICAL_RECORD · S, paraphrase |
| I12 | Action | Continue to departure | RECONSTRUCTION · J |

**Exit · RECONSTRUCTION, M1 and M2.** On I12, finish the existing M1 transition by setting `Story.prologue_done = true`, marking the prologue director done, calling `Checkpoint.save("departure")` and loading [`res://scenes/departure.tscn`](../../../scenes/departure.tscn). The next card is the existing [M2 intro caption](../../../scripts/cambridge/content_departure.gd#L16). Kit’s curtains, rationed sugar and checklist lines follow in the existing opening. The sugar line carries through I1 without restating the clipping. The [departure director](../../../scripts/cambridge/departure_director.gd) owns the checklist, sky promise, farewell and onward montage.

Render T72 using the existing localized prediction and certainty labels from [the October ledger](../../../scripts/cambridge/content_epilogue.gd#L101), reading `Story.bet_1917.pick` and `Story.bet_1917.sure` as saved. Leave `Story.bet_1917` (including `ashby` and `year`), `Story.bet`, `Story.report`, `Story.plan` and the coda choices intact through the departure checkpoint. Use only chapter-local sorting state. The 1917 choices, including an uncertain prediction, survive verbatim. Ashby’s 0.87″ belongs to his own ledger entry. M2’s later choices remain M2’s to record. Direct entry at an existing departure checkpoint still begins at M2.

## Localization

Use the existing [locale catalogues](../../../locale/) and the project’s `zh_TW` source-string convention for zh-TW. Reuse cast labels, existing prediction labels and advance controls where they fit. Keep the three heading labels identical in the slots and Kit’s hints. Treat the figures below as layout targets. Wrap at word or phrase boundaries and allow document panels to scroll. Long sources may wrap under their extracts. Keep text, speaker attribution and reading order available at larger text sizes.

| Locale | Length and register | Terms and honorifics |
|---|---|---|
| en | Aim for headings under 25 characters and Kit/Ashby turns under 110. Keep British forms such as “Observatory”, “labour” and “demobilised”. Let long paper summaries wrap. | Use “occupational exemption”, “conscientious objection”, “call-up” and “adjournment”. Keep “Professor Eddington” and “Sir Frank Dyson” in source copy. Kit and Ashby use the established cast labels. |
| ja | Aim for headings around 12 full-width characters and spoken turns around 45 before wrapping. Use plain document prose and the existing Kit/Ashby speech registers. Keep a date and the condition it qualifies together on paper. | 職務上の理由による兵役免除 / 良心的兵役拒否 / 召集延期 / 審理延期. Use 天文台の職務 / 良心に基づく申立て / 裁定内容 for headings. Use 先生 for Ashby per the cast and 教授 for Eddington’s formal title. Preserve Dyson’s title as 王室天文官 with his name. |
| zh-TW | Aim for headings around 10 Han characters and turns around 40 before wrapping. Use Traditional Chinese and Taiwan-facing vocabulary. | 因職務獲准免服兵役 / 良心拒服兵役 / 延後徵召 / 延後審理. Use 天文台職務 / 良心拒役聲請 / 裁定條款 for headings. Use the existing Ashby 先生 label and 教授 for Eddington in the record. Use 皇家天文學家 for Dyson’s office. |
| ko | Aim for headings around 14 Hangul syllables and turns around 50 before wrapping. Use neutral formal prose on the papers. Follow the existing difference between peer speech and address to the mentor. | 직무상 병역 면제 / 양심적 병역 거부 / 소집 연기 / 심리 연기. Use 천문대 직무 / 양심에 따른 진술 / 결정 조건 for headings. Use the existing mentor address and 교수 for Eddington in formal attribution. Keep Dyson’s office as 왕실 천문관. |

**Locked meaning and wording.** T30 and T32 are exact reported English, including the absence of an article in T30. For ja, zh-TW and ko, translate them as reported speech directly and retain the original in the source reference. Keep the first-person declaration and the chair’s procedural exclusion. In summaries and hints, preserve the applicant, forum, grounds and effect of each decision. June overturns the occupational exemption, sets 1 August as the earliest call-up and leaves conscience unheard. July recognises the objection and grants twelve months conditional on continuing his present work, with the eclipse part of the tribunal’s reasoning. Keep the Friends’ Ambulance Unit and Red Cross distinct, and keep harvest labour as an offer. Use the established locale name for the Society of Friends, with “Quaker” as the short form where appropriate. Translate the attributed paraphrases of prejudice as paraphrases. Preserve who opposed contact, which countries were excluded from the Allied plans, and the difference between a backbencher’s request and the Home Secretary’s answer. Keep 0.87″, the arcsecond unit, the Newtonian-style qualifier and the owner of each ledger entry. Use the existing prediction value and certainty strings as recorded.

## Source register

Use the source names, dates and page references here for the paper views. Hearing dates in headings are the events. Citation dates identify the publications, including the reports printed the next day.

- **J, M1** · [Journey design, Tribunal and I1](../JOURNEY.md), [expedition dossier](../../research/expedition_journey_2026-11-26.md) §§1–4, 6, 8, and [existing 1917 content](../../../scripts/cambridge/content_1917.gd). Basis for cast, fictional staging and the distinct historical record.
- **S** · Cambridge Observatory Syndicate minutes, ObsA1/iii/123–124 (4 December 1917) and /125 (12 March 1918), transcribed or indexed in [Dolan’s Eddington chronology](https://www.royalobservatorygreenwich.org/articles.php?article=1289). Dossier §§1, 3.
- **U** · Coventry Evening Telegraph, 11 May 1916, and Cambridge Daily News, 16 May 1918, p. 4, [transcriptions in Dolan](https://www.royalobservatorygreenwich.org/articles.php?article=1289). Dossier §1.
- **W** · Turner, “From an Oxford Note-Book”, The Observatory (1916), and the replies and correspondence discussed in [Stanley, Isis 94, pp. 59–70](https://doi.org/10.1086/376099). [Royal Society MS/603/3/4](https://catalogues.royalsociety.org/CalmView/Record.aspx/Record.aspx?id=MS%2F603%2F3%2F4&src=CalmView.Catalog), Eddington to Larmor, 7 June 1916, catalogue description. Dossier §§2–3.
- **A, B, L** · Cambridge Daily News, 14 June (A), 28 June (B) and 12 July 1918 (L), p. 3 for each, [transcriptions in Dolan](https://www.royalobservatorygreenwich.org/articles.php?article=1289). The Dyson text is represented through the portion printed in L. Dossier §§1, 4.
- **E** · Joint Permanent Eclipse Committee subcommittee minutes, 14 June 1918, [transcribed in Dolan](https://www.royalobservatorygreenwich.org/articles.php?article=1289). For the 0.87″ comparator, [Dyson, Eddington and Davidson, 1920, §1](https://doi.org/10.1098/rsta.1920.0009). Dossier §§1, 5.
- **H1** · [Commons Hansard, 11 November 1918](https://hansard.parliament.uk/Commons/1918-11-11), “Armistice With Germany”, and [UK Parliament’s Armistice history](https://researchbriefings.files.parliament.uk/documents/LLN-2018-0112/LLN-2018-0112.pdf). Dossier §§1, 3.
- **H2** · Ministry of Labour, [The Labour Gazette, January 1919, p. 6](https://escoe-website.s3.amazonaws.com/wp-content/uploads/2019/11/26113448/The-Ministry-of-Labour-Gazette-Jan-1919.pdf), demobilisation and resettlement. Dossier §3.
- **H3** · [Commons Hansard, 29 July 1946](https://hansard.parliament.uk/Commons/1946-07-29/debates/7e15b9d1-3cb3-4be3-8fdd-81f51a5389a4/RationedCommodities%28Statistics%29), retrospective rationing table. The insert uses only the situation in early 1919. Dossier §3.
- **H4** · [Commons Hansard, 20 February 1919](https://hansard.parliament.uk/commons/1919-02-20/debates/7d8b1c43-107e-4983-86e9-76990818d3ed/ConscientiousObjectors), questions on prisoners and Shortt’s response to Kinloch-Cooke. See also the [Commons debate of 5 March 1919, cols. 560–569](https://api.parliament.uk/historic-hansard/commons/1919/mar/05/conscientious-objectors).
- **H5** · [Contemporary report of the Paris Inter-Allied Conference, Nature 102, pp. 325–327](https://www.nature.com/articles/102325d0) and the [London resolutions and Paris reference to their terms](https://en.wikisource.org/wiki/Page:EB1922_-_Volume_31.djvu/579). Scope is the associations the Allied academies were planning. The July 1919 Brussels decisions fall later, in I4.

## String count

**INFERENCE.** Tribunal has 75 numbered English lines across three playable scenes, matching the design’s 75 × 4 = 300 estimate. I1 has 12, matching its 12 × 4 = 48 estimate. These are 87 authored units, including branches, headings, action labels and provenance labels. Citation metadata, repeated controls and reused cast and prediction strings do not add authored lines. Target 12–17 minutes for Tribunal, with the time in reading and sorting.
