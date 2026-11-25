# The joint meeting and I4–I6

Script-ready English copy for [The expedition journey](../JOURNEY.md). Burlington House, London, 6 November 1919. Moves: none. Wire after the Príncipe slice is accepted.

Each numbered row is one visible source string. Text in braces is supplied by the run or by the player. The provenance column is for production. The on-paper labels distinguish the historical summaries, the reconstructed chart and the fictional workbook. Dates follow the local calendar of the record.

## Route and reuse

| Join | Cue and carried material |
|---|---|
| I3 → I4 | [I3-14 “Continue homeward”](https://github.com/nurockplayer/eddington-1919/blob/0685f730c586bb6457cd2cf9c07ac58f63e103ff/docs/design/journey/SUNDY.md#i3--two-cables) turns from the paired cables and Brazil credit to I4-01 on the same paper. It follows the full-story Sundy coda and lamp-out. Preserve the recorded run, workbook, gifts and ending plate. |
| I4 → October epilogue | I4-20 closes the archival paper and takes the existing full-story transition in [`_lamp_out_then_ending()`](../../../scripts/main.gd#L1818) into [`epilogue.tscn`](../../../scenes/epilogue.tscn). Keep the existing run recording, plate and October checkpoint at this handoff. Standalone slice and replay keep their current routing. |
| October epilogue → London | Play all of October, including the comparison, the astrographic weight, the ledger, the Mercury residual, the October bet, the selected reason and Ashby's reply. His [London line](../../../scripts/cambridge/content_epilogue.gd#L235) precedes the closing tableau. Let the [tableau](../../../scripts/cambridge/content_epilogue.gd#L62) finish on Kit's invitation to go outside. Take the [`"tableau"` completion and fade](../../../scripts/cambridge/epilogue_director.gd#L248) to L01 before the current ending reveal. Carry the historical weight choice as the player's October judgment, and carry the run, prediction, selected reason and Kit's workbook. |
| London → I5 | L84 takes the held chart and workbook to black, then cuts to I5-01. Give the quiet its own advance after the last exchange. |
| I5 → I6 | I5-12 turns the remembrance page into I6-01. |
| I6 → ending review | I6-16 returns to October's deferred ending reveal. Use [`Ending.build` and the existing review](../../../scripts/ending.gd#L28) with the same run, ending plate and replay controls. The existing October reason remains labelled as October's entry. Put London's L81 and the committed player line at the foot of the review, where it is the final notebook entry. Finish the route with the existing resolution cue and checkpoint clear at this reveal. |

**RECONSTRUCTION · J.** Three playable scenes share one abstracted room. Use a threshold framing, a close view of the assistant's chart, and a wider framing at the close. Seat Kit and Ashby beside the assistant at the edge of the public room. Deliver the proceedings as attributed text in the foreground. Keep the dais and audience abstract, with no historical lip-sync, specific historic room layout, display apparatus or staged crowd reaction.

Reuse the [October chart format](../../../scripts/cambridge/epilogue_chart.gd) for its horizontal deflection axis, prediction guides and labelled rows. London's chart uses probable-error bars as specified below. Reuse the [report sheet](../../../scripts/cambridge/report_sheet.gd) for paper surfaces, evidence choices and annotation placement, and the [ending review](../../../scripts/ending.gd) for the final run summary. One report-sheet paper view serves all three interludes. Use L14 to turn pages within the inserts. In reduced motion use held framings and cuts. At large text sizes stack the chart's row explanations and notes in focus order, with the same chart numbers and text available to read.

## Scene 1 · At the threshold

### Beat 1 · The prediction page

**INVENTED-FICTIONAL · J, October.** In the black after October, pick up the workbook after the sky promised in the tableau. At L02 it opens to the sky entry shared with Kit. Ashby opens the old prediction page beside it. Bring forward the player's actual prediction and October answer. Give Ashby one L07–L11 reaction from October's [`ledger_case`](../../../scripts/cambridge/content_epilogue.gd#L120). This is a short reprise of his response to the player's run. His public response can change even if the player's judgment stays where it was.

| ID | Display or speaker | English copy | Provenance |
|---|---|---|---|
| L01 | Chapter title | The joint meeting | RECONSTRUCTION · J |
| L02 | Kit | Here's the sky you put in the book. I kept the page turned down. | INVENTED-FICTIONAL · J, workbook thread |
| L03 | Ashby | Here's what I wrote before you went. There's room beside it. | INVENTED-FICTIONAL · J |
| L04 | Ledger | Mr Ashby's prediction · 0.87″ | INVENTED-FICTIONAL · J, October |
| L05 | Ledger | Your 1917 prediction · {prediction} | INVENTED-FICTIONAL · J, October |
| L06 | Workbook | Your October reason · {October reason} | INVENTED-FICTIONAL · J, October |
| L07 | Ashby · conceded | I had 0.87″ on that page. Your plates gave me a reason to cross it out. Leave it legible. | INVENTED-FICTIONAL · J, October |
| L08 | Ashby · zero only | Your plates leave room for zero. I'd check the apparatus before I asked anyone to believe that. | INVENTED-FICTIONAL · J, October |
| L09 | Ashby · own low | Your plates come down near my figure. Sobral's small telescope gives me a reason to doubt it. | INVENTED-FICTIONAL · J, October |
| L10 | Ashby · inconclusive | Yours leave room for both figures. I wanted to see what could be measured on the other side of the sea. | INVENTED-FICTIONAL · J, October |
| L11 | Ashby · no value | You left the number blank. I want to hear what the other plates can bear. | INVENTED-FICTIONAL · J, October |
| L12 | Kit | Shall we go in? Bring the book. | INVENTED-FICTIONAL · J |
| L13 | Advance | Enter the meeting | RECONSTRUCTION · J |
| L14 | Shared paper advance | Continue | RECONSTRUCTION · J |

The workbook shows any numerical personal result on its own page, using L15–L17. Use the simulated run's displayed uncertainty label as in the run review, with the label legible before the sheet is turned. If `combined.n` is zero, use L17 in place of L16. The personal point never enters the historical figure or either evidence selection.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| L15 | Workbook figure label | Your plates · Simulation | RECONSTRUCTION · J |
| L16 | Workbook figure value | {personal value}″ ± {personal uncertainty}″ · Simulated measurement | RECONSTRUCTION · J |
| L17 | Workbook figure fallback | No deflection could be measured from your plates. | RECONSTRUCTION · J |

## Scene 2 · The plates before the societies

### Beat 2 · Two principal results

**HISTORICAL_RECORD · D §1, O pp. 389–394, N, R §V. RECONSTRUCTION · J for the presentation.** L13 brings up the place, date and chair. Show the two announcements in order. Then reveal the first two rows in the assistant's copy. L24–L29 are persistent chart copy from here through beat 8. Use any extra room in the frame to hold the comparison guides, including zero. The common quantity is deflection at the Sun's limb.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| L18 | Place and date | Burlington House, London · 6 November 1919 | HISTORICAL_RECORD · O, D §1 |
| L19 | Record heading | Royal Society and Royal Astronomical Society · Joint meeting | HISTORICAL_RECORD · O p. 389 |
| L20 | Chair | Sir J. J. Thomson chairs the meeting. | HISTORICAL_RECORD · O p. 389 |
| L21 | Paper label | Historical record · Summary of the proceedings | RECONSTRUCTION · J |
| L22 | Sobral announcement | The Astronomer Royal, Frank Dyson, reports the Sobral results. The 4-inch telescope gives 1.98″ at the Sun's limb. | HISTORICAL_RECORD · O, N, R §V |
| L23 | Príncipe announcement | Arthur Eddington reports 1.61″ from the Príncipe plates. | HISTORICAL_RECORD · O, N, R §V |
| L24 | Chart label | Reconstructed chart · Historical observations | RECONSTRUCTION · J |
| L25 | Axis | Deflection at the Sun's limb (arcseconds) | HISTORICAL_RECORD · R §V |
| L26 | Guide | 0″ · No deflection | HISTORICAL_RECORD · R §§1–3 |
| L27 | Guide | 0.87″ · Newtonian-style comparison | HISTORICAL_RECORD · R §§1–3 |
| L28 | Guide | 1.75″ · Einstein's prediction | HISTORICAL_RECORD · R §§1–3, J |
| L29 | Bar legend | Bars show ± one probable error, as reported. | RECONSTRUCTION · J, R §V |
| L30 | Row | Sobral 4-inch · 1.98″ ± 0.12″ probable error | HISTORICAL_RECORD · R §V |
| L31 | Row | Príncipe · 1.61″ ± 0.30″ probable error | HISTORICAL_RECORD · R §V |

### Beat 3 · The other Sobral plates

**HISTORICAL_RECORD · D §§1, 4–5, O, N, R §§22–25 and 37, SN.** Reveal the astrograph as one row with two outlined markers keyed to the two treatments of the same plates. Put L35–L39 beside it. Keep this row open as the paper advances through the objections. Use the full report's pair of reductions here. Dyson discussed more than one scale treatment at the meeting, and the contemporary accounts and the full report give intermediate figures that differ. L33–L34 label the chart's published reductions without assigning those exact numbers to spoken remarks.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| L32 | Instrument row | Sobral astrograph · Same plates, two scale treatments | HISTORICAL_RECORD · R §§22–25, N |
| L33 | First marker | About 0.93″ · With the inferred scale change | HISTORICAL_RECORD · R §25 |
| L34 | Second marker | About 1.52″ · With the alternative scale treatment | HISTORICAL_RECORD · R §25, N |
| L35 | Focus note | The Sobral notebook records a serious change of focus when the eclipse plates were examined. The star images were blurred. | HISTORICAL_RECORD · SN, R §§13, 23 |
| L36 | Scale note | A change in plate scale changes the distances between star images. The reduction has to separate that change from the deflection. | HISTORICAL_RECORD · R §§22–25 |
| L37 | Scale treatment | The 1.52″ reduction allows for the scale change from refraction and aberration alone. | HISTORICAL_RECORD · N, R §§23–25 |
| L38 | Astrograph legend | Probable errors unavailable for these two values. | HISTORICAL_RECORD · R §25 |
| L39 | Weight note | The full report gives the astrographic series much less weight and publishes its reductions. | HISTORICAL_RECORD · R §§25, 37 |
| L40 | Advance | Annotate precision | RECONSTRUCTION · J |

### Beat 4 · First annotation

**RECONSTRUCTION · J, R §§22–25 and 37.** Lay L41 beside the three rows. In both annotation beats, select one reference on the report sheet, preview its annotation and choose L53 to commit. Every offered choice has a distinct first note. Once committed, follow it with the remaining notes in table order so the chart always bears the complete answer. For this beat the first note and the added notes sit together in the precision margin. L54 is the final line of that margin. Continue with L14. The choice records where the assistant began. It changes the emphasis and order of the notes only.

The common plot stays fixed from L40 onwards. Pin the 4-inch bar to 1.86–2.10″ and the Príncipe bar to 1.31–1.91″ with end caps. Keep the unbarred astrograph markers at about 0.93″ and 1.52″ on the same row. Use marker shape as well as colour. These bars show the report's probable errors, so the October format's standard-deviation and two-error whiskers are turned off in London. Keep the weakness of the astrograph legible without collapsing or greying out its values.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| L41 | Question | The shifts are small. Where would you begin to show what the plates can distinguish? | RECONSTRUCTION · J, D §1 |
| L42 | Margin heading | Precision and scale | RECONSTRUCTION · J |
| L43 | Choice | Sobral 4-inch | RECONSTRUCTION · J |
| L44 | First note for L43 | The 4-inch gives the tighter probable error. Its 1.98″ favours the larger deflection. | RECONSTRUCTION · J, R §V |
| L45 | Added note for L43 | The Príncipe observation is independent and less precise. Its 1.61″ also favours the larger deflection. | RECONSTRUCTION · J, R §V |
| L46 | Added note for L43 | The Sobral astrograph changes from about 0.93″ to about 1.52″ under a different scale treatment. Keep both figures in view. | RECONSTRUCTION · J, R §25 |
| L47 | Choice | Príncipe | RECONSTRUCTION · J |
| L48 | First note for L47 | Príncipe gives a second site's check. The wider probable error goes beside its result. | RECONSTRUCTION · J, R §V |
| L49 | Added note for L47 | Sobral's sharper 4-inch plates give the tighter result. Both sites favour the larger deflection. | RECONSTRUCTION · J, R §V |
| L50 | Choice | Sobral astrograph | RECONSTRUCTION · J |
| L51 | First note for L50 | The astrograph's two figures come from the same blurred plates. The scale assumption affects their weight. | RECONSTRUCTION · J, R §§22–25 |
| L52 | Added note for L50 | The 4-inch series gives the tighter probable error. Príncipe independently favours the larger deflection with a wider probable error. | RECONSTRUCTION · J, R §V |
| L53 | Commit, both annotations | Keep this annotation | RECONSTRUCTION · J |
| L54 | Closing annotation | Two sites favour the larger bending. Keep the error bars and the scale question with the result. | RECONSTRUCTION · J, R §V |

L43 commits L44–L46. L47 commits L48, L49 and L46. L50 commits L51 and L52. All then show L54. Present the first note next to the evidence selected and place the added notes where their rows can still be read. No result value, uncertainty or original October choice is changed.

### Beat 5 · Newall asks about the Sun's atmosphere

**HISTORICAL_RECORD · D §4, O p. 395, P p. 73.** Leave the precision margin pinned. Read the acknowledgement and reservation under Newall's own attribution. Use the short verified excerpt on the record, with the remainder explicitly in summary. The hypothesis is an alternative way to interpret the apparent shift. Leave it as a question.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| L55 | Attribution | H. F. Newall · An extended solar atmosphere | HISTORICAL_RECORD · O p. 395 |
| L56 | Recorded words | “I feel that the Einstein effect holds the day” | HISTORICAL_RECORD · O p. 395, quoted in P p. 73 |
| L57 | Proceedings summary | Newall keeps open another interpretation. He asks whether a similar observation might have been made to test for an extended atmosphere around the Sun. | HISTORICAL_RECORD · O p. 395, P p. 73 |
| L58 | Kit | He gives them the result and keeps his question. | INVENTED-FICTIONAL · J |

### Beat 6 · Silberstein asks for a different observation

**HISTORICAL_RECORD · D §§1–2, O pp. 396–397, SJ.** L14 turns to a new entry with Silberstein's name. Leave the two sites visible. His question concerns the theory's predicted shift of the Sun's spectral lines. It is a demand for independent evidence. Give it room on its own paper, apart from Newall's question about what moved the star images and apart from the political attacks in I6.

| ID | Display or speaker | English copy | Provenance |
|---|---|---|---|
| L59 | Attribution | Ludwik Silberstein · The solar spectrum | HISTORICAL_RECORD · O pp. 396–397 |
| L60 | Proceedings summary | Silberstein asks what has become of the predicted gravitational redshift in the Sun's spectrum. He calls for evidence from that test too. | HISTORICAL_RECORD · O pp. 396–397 |
| L61 | Context note | The available Mount Wilson measurements had failed to detect the expected displacement of the solar lines. | HISTORICAL_RECORD · SJ |
| L62 | Ashby | Another question to take to another instrument. Put it beside the first. | INVENTED-FICTIONAL · J |
| L63 | Advance | Annotate the open test | RECONSTRUCTION · J |

## Scene 3 · What can be said in the room

### Beat 7 · Second annotation

**RECONSTRUCTION · J, O pp. 395–397, R §V.** On L63, slide the new annotation into a second margin on the same plot, with the precision margin still available. Ask the player to pick the question to label first. Commit the selected note, then read the other two in their table order. Keep the distinction between the two speakers visible even when the redshift note is read first. In both wide and stacked views end with the two principal results in the same view and the two unbarred astrograph marks accessible below them. After L72 hold for a full breath in the room and let L14 advance when the player is ready.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| L64 | Margin heading | What the eclipse can test | RECONSTRUCTION · J |
| L65 | Question | Which question would you label first? | RECONSTRUCTION · J |
| L66 | Choice | How far did starlight bend? | RECONSTRUCTION · J |
| L67 | Answer | Tested here. The star positions measure bending. The 4-inch series and Príncipe favour the larger shift. | RECONSTRUCTION · J, R §V |
| L68 | Choice | Could a solar atmosphere explain it? | RECONSTRUCTION · J, O p. 395 |
| L69 | Answer | Interpretation still open to challenge. Newall raises an extended solar atmosphere as a question about the apparent displacement. | RECONSTRUCTION · J, O p. 395 |
| L70 | Choice | Did the Sun's spectral lines shift? | RECONSTRUCTION · J |
| L71 | Answer | An independent test is needed. These star positions cannot measure the gravitational redshift of solar spectral lines. | RECONSTRUCTION · J, O pp. 396–397 |
| L72 | Closing annotation | Eclipse result · Evidence for the larger deflection. Solar redshift · An open test at this meeting. | RECONSTRUCTION · J, O, R §V |

L66 commits L67, L69, L71. L68 commits L69, L67, L71. L70 commits L71, L67, L69. All then show L72. Keep the question heading, instrument labels and values when the player changes focus between margins.

### Beat 8 · Beside the old figure

**INVENTED-FICTIONAL · J, October. RECONSTRUCTION · J for the room and pause.** Open the framing while keeping the chart readable. Ashby points from the Sobral 4-inch to Príncipe. The old prediction page is beneath the assistant's hand. This exchange happens aloud at the edge of the public room as the recorded discussion ends. It belongs to the fictional trio. Do not add a reply, invitation, applause or judgment from the societies.

Read L73–L76 and give the player a blank field for a sentence in their own words. Show their existing October reason above it as L06. L78 previews the player's line as their part of the exchange, with L80 available to go back before committing. L79 commits any nonblank reason or reservation, prints it as L78 beside L04 and L05, and lets Kit answer L82–L83. The submitted text is the player's exact line. Keep it on paper through the last look and bring it back in the existing ending review. Hold the room in silence on L84. The next sound, if used, is the paper turning into I5. Keep the two places and the old prediction in the same composition. The player leaves when they've had time to read them.

| ID | Display or speaker | English copy | Provenance |
|---|---|---|---|
| L73 | Ashby | The small telescope at Sobral gives the sharper result. And here is Príncipe, across an ocean, leaning the same way. | INVENTED-FICTIONAL · J, R §V |
| L74 | Ashby | I'd have kept my figure without those plates. Keep the question about the spectrum on the page as well. | INVENTED-FICTIONAL · J |
| L75 | Kit | What would you say here, with your old prediction still in front of you? | INVENTED-FICTIONAL · J |
| L76 | Ashby | Say what you can stand by, even if it's a question. | INVENTED-FICTIONAL · J |
| L77 | Field label | Write your reason or reservation | RECONSTRUCTION · J |
| L78 | Assistant, preview and committed reply | {player's own sentence} | INVENTED-FICTIONAL · Player-authored |
| L79 | Commit | Say it and keep it | RECONSTRUCTION · J |
| L80 | Return to field | Revise your line | RECONSTRUCTION · J |
| L81 | Workbook and ending-review label | Your line at Burlington House | INVENTED-FICTIONAL · J |
| L82 | Kit | Here. Beside the figure you came with. | INVENTED-FICTIONAL · J |
| L83 | Kit | At Sundy there was a page for what you could see. This one is for what you can say. | INVENTED-FICTIONAL · J |
| L84 | Advance after the hold | Read the papers | RECONSTRUCTION · J |

Owner's release question at L84: “Does it feel epic?” Judge it in both walks below. The hold belongs to the agreement of the two observing sites now open to public challenge, with enough space to read the player's own words before the headline arrives.

## I4 · Homeward and across Europe

**HISTORICAL_RECORD · D §§1, 3–4, Z, R §§12–25, 29, 35, SN, B, E9. RECONSTRUCTION · J for the paper.** Open with the letter and the two separate return dates. Turn next to the Sobral observation and reduction, then to the July Brussels record and the September papers. This is a retrospective file. The May notebook and July Brussels report have their own dates even though the route has already reached the return. Leave the last leg's ship name and the delivery of the letters open. Brazilian research retains its own credit on the previous I3 page. I4-20 opens October with the assistant's fictional run already recorded.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| I4-01 | Title | Homeward and across Europe | RECONSTRUCTION · J |
| I4-02 | Frame | Historical records · Letters, telegram and report summaries | RECONSTRUCTION · J |
| I4-03 | Departure record | Príncipe · 12 June 1919. A dispute over passage rates sends Eddington and Cottingham home early aboard the crowded Zaire. | HISTORICAL_RECORD · Z, R §29, D §1 |
| I4-04 | Letter attribution | A. S. Eddington to Sarah Ann Eddington · Aboard Zaire · 21 June 1919 | HISTORICAL_RECORD · Z |
| I4-05 | Letter summary | Eddington writes that one plate he measured agreed with Einstein and that a second seemed to offer a little support. He has made no preliminary announcement of the measurement. | HISTORICAL_RECORD · Z, paraphrase |
| I4-06 | Letter summary | He recalls how delighted they were to hear that the Brazil party had succeeded. | HISTORICAL_RECORD · Z, paraphrase |
| I4-07 | Letter excerpt | “I shall look forward to the strawberries” | HISTORICAL_RECORD · Z, excerpt |
| I4-08 | Return record | Liverpool · 14 July 1919. The Príncipe observers reach England. | HISTORICAL_RECORD · D §1, R §29 |
| I4-09 | Sobral comparison record | Sobral · 11–18 July 1919. The team photographs the same star field with the Sun elsewhere. | HISTORICAL_RECORD · R §§14–15 |
| I4-10 | Sobral return record | Greenwich · 25 August 1919. The British Sobral team has brought home two series of plates. | HISTORICAL_RECORD · R §15 |
| I4-11 | Notebook attribution | British Sobral expedition notebook · Entry for 30 May 1919 | HISTORICAL_RECORD · SN |
| I4-12 | Notebook excerpt | “there had been a serious change of focus” | HISTORICAL_RECORD · SN, excerpt |
| I4-13 | Reduction summary | At Greenwich, comparing the eclipse and July photographs means working out how any change in their scale affects the apparent shifts. The blurred astrographic images make that harder. | HISTORICAL_RECORD · R §§16–25 |
| I4-14 | Príncipe plate record | Plate X was measured on Príncipe. Plate W was developed and measured after the return to England. | HISTORICAL_RECORD · R §35, D §6 |
| I4-15 | Institutional record | Brussels · July 1919. The new International Research Council keeps the defeated Central Powers outside the organisation. | HISTORICAL_RECORD · B, D §3 |
| I4-16 | Telegram attribution | Hendrik Lorentz to Albert Einstein · The Hague · 22 September 1919 | HISTORICAL_RECORD · E9 doc. 108 |
| I4-17 | Telegram summary | From the neutral Netherlands, Lorentz relays a preliminary deflection between about 0.9″ and twice that amount. He sends congratulations. | HISTORICAL_RECORD · E9 doc. 108, paraphrase |
| I4-18 | Letter attribution | Albert Einstein to Pauline Einstein · Berlin · 27 September 1919 | HISTORICAL_RECORD · E9 doc. 113 |
| I4-19 | Letter summary | Einstein writes to his mother with the good news from Lorentz that the British expedition had found a deflection. | HISTORICAL_RECORD · E9 doc. 113, paraphrase |
| I4-20 | Advance | Return to Cambridge | RECONSTRUCTION · J |

Page groups are I4-01–08, I4-09–14, I4-15–17 and I4-18–20. Use I4-02 on the paper throughout. The note on X and W describes the historical work. The earlier darkroom combined stages for play. Preserve that distinction when the October epilogue returns to the assistant's measured result.

## I5 · In print

**HISTORICAL_RECORD · D §§1, 3, T, NY, A, R §V. RECONSTRUCTION · J for the clippings and captions.** On the cut from beat 8, show the London masthead and the stacked headline. Turn to the New York masthead and title. Bring back the finding below the headlines in a readable body size, then turn to the remembrance card. The date card and silence stand on their own, with no invented reactions or new speakers. Use I5-02 on the clipping pages. Use L14 between pages, and I5-12 off the remembrance card.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| I5-01 | Title | In print | RECONSTRUCTION · J |
| I5-02 | Frame | Historical record · Newspaper headlines | RECONSTRUCTION · J |
| I5-03 | London masthead | The Times · London · 7 November 1919 · p. 12 | HISTORICAL_RECORD · T |
| I5-04 | London headline | REVOLUTION IN SCIENCE. | HISTORICAL_RECORD · T, headline |
| I5-05 | London deck | NEW THEORY OF THE UNIVERSE. | HISTORICAL_RECORD · T, headline |
| I5-06 | London deck | NEWTONIAN IDEAS OVERTHROWN. | HISTORICAL_RECORD · T, headline |
| I5-07 | New York masthead | The New York Times · New York · 10 November 1919 · p. 17 | HISTORICAL_RECORD · NY |
| I5-08 | New York headline | LIGHTS ALL ASKEW IN THE HEAVENS | HISTORICAL_RECORD · NY, headline |
| I5-09 | New York deck | EINSTEIN THEORY TRIUMPHS | HISTORICAL_RECORD · NY, headline |
| I5-10 | Finding beneath the clipping | Two eclipse series favoured Einstein's larger light deflection. A third was sensitive to plate scale. The Sun's spectral lines remained a separate test. | HISTORICAL_RECORD · O, R §V, summary |
| I5-11 | Remembrance card | Britain · 11 November 1919. A two-minute silence marks the first anniversary of the Armistice. | HISTORICAL_RECORD · A |
| I5-12 | Advance | Read the replies | RECONSTRUCTION · J |

## I6 · Replies

**HISTORICAL_RECORD · D §§1–3, EE, M, BT. RECONSTRUCTION · J for the paper.** Begin with the December letter, then turn back briefly to the November nomination and follow the Council record through January. Turn to the Berlin rally and Einstein's published response. Use I6-02 throughout and L14 between the three pages. The player reads an attributed paraphrase of Einstein's account of the rally's motives. Keep the slurs out of the text in every locale. Put the view of his response on a dated sheet of its own with no imagery or names borrowed from the London objections. I6-16 leaves that sheet for the run review.

| ID | Display | English copy | Provenance |
|---|---|---|---|
| I6-01 | Title | Replies | RECONSTRUCTION · J |
| I6-02 | Frame | Historical records · Letter, Council record and newspaper response | RECONSTRUCTION · J |
| I6-03 | Letter attribution | Arthur Eddington to Albert Einstein · 1 December 1919 | HISTORICAL_RECORD · EE |
| I6-04 | Letter summary | Eddington writes about the reception of the eclipse results in Britain. He hopes the work will help British and German scientists renew their contacts. | HISTORICAL_RECORD · EE, paraphrase |
| I6-05 | Letter excerpt | “It is the best possible thing that could have happened for scientific relations between England and Germany.” | HISTORICAL_RECORD · EE, excerpt |
| I6-06 | Council heading | Royal Astronomical Society · Gold Medal | HISTORICAL_RECORD · M |
| I6-07 | Nomination | 14 November 1919 · H. H. Turner and James Jeans put Einstein's name forward. | HISTORICAL_RECORD · M, D §2 |
| I6-08 | December vote | 12 December 1919 · The Council selects Einstein, subject to confirmation. | HISTORICAL_RECORD · M |
| I6-09 | January vote | 9 January 1920 · The Council declines to confirm the award. | HISTORICAL_RECORD · M |
| I6-10 | Outcome | The Society awards no Gold Medal in 1920. | HISTORICAL_RECORD · M |
| I6-11 | Rally record | Berlin Philharmonie · 24 August 1920 | HISTORICAL_RECORD · BT, D §1 |
| I6-12 | Rally caption | A public rally attacks relativity and its author. | HISTORICAL_RECORD · BT, D §§1, 3 |
| I6-13 | Reply attribution | Albert Einstein · Berliner Tageblatt · 27 August 1920 · pp. 1–2 | HISTORICAL_RECORD · BT |
| I6-14 | Article heading | Meine Antwort | HISTORICAL_RECORD · BT, title excerpt |
| I6-15 | Reply summary | In his public response, Einstein says that hostility to him as a Jew and nationalist feeling helped drive the attacks. | HISTORICAL_RECORD · BT, Einstein's account in paraphrase |
| I6-16 | Advance | Open your run review | RECONSTRUCTION · J |

## Two walks through the script

**Strong personal result · INFERENCE, sample run.** Take I3-14 to the letter aboard Zaire, then read the return dates, scale problem, Brussels record and tentative reply from September. I4-20 reaches October. The simulated plates give 1.78″ with bounds clear of 0.87″ and a clean run. Read the two Sobral series, retain the weaker one with a reservation, and examine the Mercury residual. In October move from the 0.87″ forecast to the larger value and select the personal plates as the reason. Ashby names the London date and Kit closes the tableau. The fade reaches L01. L06 recalls the October choice, L07 gives Ashby's concession and L16 stays in the workbook. In the room hear both sites and see both scale treatments. Choose L43 and commit L44–46 and L54. Hear Newall, then Silberstein. Choose L70 and commit L71, L67, L69 and L72. After the hold, Ashby uses the two independent observations in L73 and leaves the spectrum question visible in L74. At L77 write “My plates made me doubt 0.87″, and the sharper Sobral plates are why I'd say so here.” Speak it at L79. Kit puts that exact line beside the old prediction in L82–83 and the room holds. L84 opens the headlines and the silence. I5-12 opens the letter, medal vote and Berlin reply. I6-16 ends on the same sentence in the existing review.

**Unreadable personal result · INFERENCE, sample run.** Take I3-14 through the same I4 papers and I4-20 into October. The personal chart has no point. Read both Sobral series and keep the astrograph under question. Use the Mercury scene, retain the October holdout and select the unchanged-mind reason. Ashby allows that entry to stand. Kit finishes the tableau and the fade reaches L01. L11 gives Ashby's uncertainty and L17 records the unreadable result. The two independently obtained historical results and the scale treatments appear as on the strong route. Choose L50 and commit L51, L52 and L54. Read the two objections separately, choose L68 and commit L69, L67, L71 and L72. After the same hold, Ashby makes the public comparison. At L77 write “I couldn't measure mine. Sobral's 4-inch persuades me about the bending, but I want to see the test of the solar lines.” Speak it at L79. Kit leaves the reservation beside the prediction. L84 and I5-12 carry the same public record through print, remembrance and the replies. I6-16 ends on the reservation verbatim. With a numerical but inconclusive run the sole changes here are L10 and L16. The annotation choices, reply field and ending handoff are the same.

## Four-locale string notes

Use the [existing catalogues](../../../locale/) and the Traditional Chinese source register. Use room for wraps and vertical reading on the papers. Treat these lengths as layout targets. Keep each value, arcsecond mark and uncertainty together, with the instrument name and qualifier adjacent even when they wrap. Carry the focus order and selected note with the localized label. Use a multiline field with IME composition for the player's own sentence. Keep entered text verbatim at both appearances, including through a locale change.

| Locale | Length and register | Terms and forms of address |
|---|---|---|
| en | Aim for 28 characters for controls and 100 for spoken lines before wrapping. Use British spelling and a contemporary, plain workbook voice. | Mr Ashby in the assistant's labels and Kit without a title. Use probable error, plate scale, astrograph, solar limb and gravitational redshift. Keep Astronomer Royal as Dyson's office and Sir J. J. Thomson as chair. |
| ja | Aim for 13 full-width characters for controls and 42 per spoken line before wrapping. Use a factual register for records and Kit's established familiar register. | アシュビー先生 and キット. Use 確率誤差, 乾板のスケール, 天体写真儀, 太陽周縁 and 重力赤方偏移. Preserve Thomson's title in the chair line and Dyson's office as 王室天文官. |
| zh-TW | Aim for 12 Han characters for controls and 38 per spoken line before wrapping. Use the game's Taiwan-facing Traditional Chinese terms. | Ashby 先生 and Kit. Use 機率誤差, 底片尺度, 天體照相儀, 日緣 and 重力紅移. Use 皇家天文學家 for Dyson's office and retain Thomson's 爵銜 in the chair line. |
| ko | Aim for 15 Hangul syllables for controls and 42 per spoken line before wrapping. Keep record captions formal and the existing Kit and Ashby registers in speech. | 애슈비 선생님 and 킷. Use 확률오차, 건판의 축척, 천체사진의, 태양 가장자리 and 중력 적색편이. Use 왕실천문관 for Dyson and preserve Thomson's title in the chair line. |

Keep the literal excerpts L56, I4-07, I4-12 and I6-05, the headline lines I5-04–06 and I5-08–09, and the German title I6-14 in their original language with faithful localized reading text where needed. Preserve their attributions and keep the headline's claims on its own sheet. Do not paraphrase the committed player line, dates, numerical values or archive identifiers. Preserve the place-name diacritics in source credits. Place the title and sender with each document. Use no extra courtesy titles in archive attributions. Keep 0.87″ qualified as Newtonian-style and the historical ± values explicitly labelled probable errors. Preserve both astrographic estimates as results from the same plates under different scale assumptions, with no invented error bars. Keep blurring, scale change, simulated cloud and no measured value distinct. Preserve uncertainty in the June and September material, the distinction between Newall's interpretation and Silberstein's independent test, and Einstein's attribution of nationalist and antisemitic motives. Translate the account of exclusion in I4-15 with both the institution and the excluded bloc named.

## Source string count

| Section | New English strings | Four locales | Journey estimate |
|---|---:|---:|---:|
| Joint meeting | 83 | 332 | 95 × 4 = 380 |
| I4 · Homeward and across Europe | 20 | 80 | 20 × 4 = 80 |
| I5 · In print | 12 | 48 | 12 × 4 = 48 |
| I6 · Replies | 16 | 64 | 16 × 4 = 64 |
| Total | 131 | 524 | 143 × 4 = 572 |

L01–L84 include one substitution-only row (L78). Count the shared L14 control, reused annotation notes, labels, templates and branches once. Existing October text, cast names, the supplied player text, and original-language excerpts repeated alongside their localized readings add no separate strings. The London count stays below the estimate with one set of chart labels and one pair of annotation margins.

## Sources and wiring dependencies

- **J** · [Journey design](../JOURNEY.md), §4, I4–I6, Size and reuse, Lines we do not cross, Corrections owed and Later scene briefs.
- **D** · [Expedition dossier](../../research/expedition_journey_2026-11-26.md), sections as cited.
- **O** · “Joint Eclipse Meeting of the Royal Society and the Royal Astronomical Society”, *The Observatory* 42 (1919), pp. 389–398. [Volume](https://books.google.com/books?id=-2wYAQAAIAAJ)
- **N** · A. C. D. Crommelin, “Results of the Total Solar Eclipse of May 29 and the Relativity Theory”, *Nature* 104 (13 November 1919), pp. 280–281. [Contemporary account](https://www.nature.com/articles/104280a0)
- **R** · F. W. Dyson, A. S. Eddington and C. Davidson, expedition report, *Phil. Trans. R. Soc. A* 220 (1920), pp. 291–333. The two charted astrographic reductions are on p. 312, and the final comparison is in §V on p. 332. The chart uses published reductions and probable errors, including where meeting accounts use different intermediate figures. [Report scan](https://w.astro.berkeley.edu/~kalas/labs/documents/dyson1920.pdf)
- **P** · Newall's acknowledgement as quoted in *Publications of the Astronomical Society of the Pacific* 32 (1920), p. 73. [Contemporary quotation](https://adsabs.harvard.edu/pdf/1920PASP...32...71.)
- **SJ** · Charles E. St. John, “A Search for an Einstein Relativity-Gravitational Effect in the Sun”, *PNAS* 3 (1917), pp. 450–452. [Paper](https://doi.org/10.1073/pnas.3.7.450)
- **Z** · Trinity EDDN/A/4/9, A. S. Eddington to Sarah Ann Eddington, 21 June and 2 July 1919. I4 uses the 21 June entry. [Transcription](https://archives.trin.cam.ac.uk/index.php/letter-from-a-s-eddington-to-sarah-ann-eddington-19)
- **SN** · Cambridge University Library GBR/0180/RGO 8/166, British Sobral notebook, 30 May entry. [Transcription in Crispino, appendix pp. 1–2](https://www.scielo.br/j/rbef/a/kr4wVYLHqLSVyyHWmKpWdNv/)
- **B** · *International Research Council: Constitutive Assembly held at Brussels, July 18 to July 28, 1919*, cited in D §3. [Proceedings notice](https://www.nature.com/articles/105543a0)
- **E9** · *The Collected Papers of Albert Einstein*, vol. 9, docs. 108 and 113. [Editorial chronology](https://assets.press.princeton.edu/books/einstein11/chronology.pdf) · [Lorentz telegram facsimile](https://einstein-virtuell.mpiwg-berlin.mpg.de/VEA/SC-1186093004_MOD493045400_SEQ868400509_SL-1745097384_en.html)
- **T** · *The Times*, 7 November 1919, p. 12. [Reproduced clipping](https://crai.ub.edu/sites/default/files/imatges/Noticies/BibliotecaFisica_reduit_maxim.pdf)
- **NY** · *The New York Times*, 10 November 1919, p. 17. [Clipping](https://www.sciencehistory.org/wp-content/uploads/2025/04/lights_all_askew_nyt_11091919.pdf)
- **A** · UK Parliament, House of Commons Library, historical note on the two-minute silence. [Armistice history](https://commonslibrary.parliament.uk/research-briefings/cbp-12243/)
- **EE** · Einstein Archives ALS 9-260, A. S. Eddington to Albert Einstein, 1 December 1919. [Facsimile and quoted excerpt](https://einstein-virtuell.mpiwg-berlin.mpg.de/VEA/SC-1186093004_MOD493045400_SEQ1309236718_SL476360399_en.html)
- **M** · RAS Council Minutes, 14 November and 12 December 1919 and 9 January 1920, as cited and excerpted by Matthew Stanley, pp. 85–87. [Stanley](https://doi.org/10.1086/376099) · [RAS Gold Medal register](https://ras.ac.uk/awards-and-grants/awards/gold-medal-a)
- **BT** · Albert Einstein, “Meine Antwort”, *Berliner Tageblatt*, morning issue, 27 August 1920, pp. 1–2. *Collected Papers*, vol. 7, doc. 45. [Newspaper scan](https://digital.sciencehistory.org/works/d3nxj7w)
- **October** · [Existing epilogue content](../../../scripts/cambridge/content_epilogue.gd), the reunion workbook, prediction ledger, reason and tableau. [Sundy workbook and I3](https://github.com/nurockplayer/eddington-1919/blob/0685f730c586bb6457cd2cf9c07ac58f63e103ff/docs/design/journey/SUNDY.md).

Carry the [Sundy dependencies](https://github.com/nurockplayer/eddington-1919/blob/0685f730c586bb6457cd2cf9c07ac58f63e103ff/docs/design/journey/SUNDY.md#dependencies-for-later-content-briefs) into wiring. In particular, the [existing ending historical block](../../../scripts/ending.gd#L79) needs the published-cable attribution from I3 with the addressee open. Keep the archived astrograph reductions and the low weight legible wherever the ending recaps the meeting. The fictional darkroom draft retains its own review slot.
