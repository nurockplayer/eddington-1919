# Story audit — Eddington 1919 《雲層之後》

Story consultant read-only report, 2026-11-13 JST. Sources: Notion Narrative Bible (3fed7d8b…, last edited 2026-10-27), `docs/design/*.md`, `docs/HISTORY_1919.md`, `docs/CAMBRIDGE_PEOPLE.md`, all five content files, `scripts/main.gd` + the three Cambridge directors (grep only). All sample dialogue below is FICTION draft in English for the lead; the game is written in 繁體中文. Nothing here is Owner canon.

---

## A. Current story as played (prologue path)

Line counts are dialogue entries (`{s,t}` dicts), approximate. "Main" = every prologue player sees it; "opt" = needs an interaction the player may skip. The direct-1919 path (title → Príncipe) skips every Cambridge beat and the coda/epilogue.

| # | Scene | File:function | ~lines | Cast | Player does | Emotional beat | Path |
|---|---|---|---|---|---|---|---|
| 1 | 1917 cold open | `content_1917.gd:opening` | 8 | Kit | one banter choice (sugar) | warmth, rationing texture | main |
| 2 | Plate 14 investigation | `kit_guess`, `kit_talk`, `viewer_feedback`, `viewer_hint`, `examine` | ~45 | Kit, room props | overlay viewer (flip/rotate), logbook, loupe on residual; Kit independent re-check | "the copyist enlisted 1915" (1 line); Kit's variable star + "問號" | main (examines/gramophone opt) |
| 3 | Orrery check (move B) | `orrery_check`, `orrery_suspect_entry` | 9 | prop voice | mark Neptune/Halley/Mercury 對得上/對不上; pick a Mercury suspect | none (expository, well-made) | main (forced via `orrery_errand` if skipped) |
| 4 | Report sheet | `report_rows` | data | — | 4 rows of chips | the accusation temptation | main |
| 5 | Ashby reviews | `mentor_review` | ~35 | Ashby, Kit | answer his challenge; revise or submit | **Kit: 「我們小時候畫的那張星圖，也被人這樣說過。」** (only on accuse); Ashby's "整張紙上我最喜歡的一行" | main |
| 6 | Dyson's note + the bet (move A) | `mentor_dyson` | ~25 | Ashby | write 0 / 0.87 / 1.75 / 說不準 + confidence | Ashby's 30 years of Newton; "理論沒有國籍" | main |
| 7 | 「三天後」 Eddington exam | `eddington_exam` | ~20 | Eddington, Ashby | two honest-variant questions | "他在法國" (copyist) | main |
| 8 | The box, by hand (move E) | `eddington_box` + `box_sketch.gd` | 12 | Eddington, Ashby | drop the pencil, choose where you are, where the light lands | none | main |
| 9 | Plan board | `plan_intro`, `plan_cards`, `plan_blocked`, `plan_finish` | ~30 | E, A | pick 3–4 cards | "你願意簽的，比你願意相信的多。" | main |
| 10 | Trial task + cabinet check | `trial_task`, `trial_check` | 10 | E, Kit | 3 weeks?; how to note a 0.3″ misfit | Kit from across the room: 「……兩週？」 | main |
| 11 | Ashby alone | `mentor_after` | 7 | Ashby | one choice | 「他喜歡你。他不會說出來」; 「被一張乾淨的底片說服——而不是被一個好故事」 | main |
| 12 | Kit coda 1917 | `kit_coda` | 12 | Kit | the childhood chart question (3 answers) | **「如果真的有遠征……算了。」** — the best unspoken line in the game; player cannot answer | main |
| 13 | Montage 1917→1918 | `montage` | 3 captions | — | — | — | main |
| 14 | M2 opening | `content_departure.gd:opening` | 5 | Kit | sugar callback | "整整四年，我第一次在這個房間看見外面的路燈" | main |
| 15 | Last shared check | `check_entries`, `kit_reads`, `slip_found` | ~14 | Kit | mark 5 rows ✓/✗; strike-and-initial vs overwrite | the slip is **yours**; 「兩年，一千多行，錯一行」 | main |
| 16 | Small acts of care | `before_closing` | 7 | Kit | 1 choice → `bond_tone` | sharpened pencils; two shadows on one plate | main (triggered by talking to Kit) |
| 17 | Sky promise | `sky_promise` | ~9 | Kit | 1 choice → `sky_promise` | the dated blank page; 「……你的鉛筆。記得帶。」 | main |
| 18 | Ashby's gift + light in the box | `mentor_farewell`, `mentor_farewell_after` | ~14 | Ashby | 2 choices; light sketch | the loupe (「用了三十年，鏡片我自己磨過一次」); 「去看看吧。無論你看見什麼，都把它記下來。」 | main |
| 19 | Montage → Príncipe | `montage` | 4 captions | — | — | fiction disclosure | main |
| 20 | Príncipe PREP | `content.gd:briefing`, `eddington_prep`, `cottingham_*`, `plan_text`, `oxford_text` | ~20 | Eddington, Cottingham | wind drive, rate-check at chronometer, carry plates, read notes, rehearse | **none** — pure instruction; one prologue callback line | main |
| 21 | TOTALITY 302 s | `totality_*` (M5 cues) | 9 | Cottingham, Eddington (callouts) | call 開始/停 on cloud | hindsight reads only | main |
| 22 | NIGHT | `night_intro`, `comparison_*`, `rules_prompt`, `bet_prompt`, `bet_vs_plates`, `interval_*`, `judgment_prompt`, `judgment.gd` grade lines, `cottingham_coda` | ~60 | Eddington, Cottingham | fetch comparison plates (if card missed), write rule, keep/change bet, select, measure, read 2σ, choose telegram + reason | Eddington's graded reaction; Cottingham thanks you for the seconds | main (workbook write opt) |
| 23 | CODA (prologue only) | `content_coda.gd` | ~25 | you (internal) | write workbook page (if not yet), pick up the loupe, choose first words to Kit | Ashby's charge answered in thought; 「見到 Kit，第一句話要說什麼？」 | main |
| 24 | EPILOGUE Oct 1919 (move D) | `content_epilogue.gd` | ~40 | Ashby | copy Sobral rows, weight astrographic set, October bet, final reason | 「在這件事上，我錯了。」 (conditional) | main |
| 25 | Ending screen | `ending.gd` | ~15 | — | read; history toggle | the verdict | main |

Total authored dialogue ≈ 480 entries. Kit speaks ≈ 70 of them and is **absent from scenes 20–25**. The protagonist speaks ≈ 25 lines, almost all parenthetical thoughts in the coda.

---

## B. Gap table vs the Bible

| Approved beat (Bible §) | Status | Where |
|---|---|---|
| Protagonist wants to be seen (B) | **thin** — implied by Ashby/Eddington praise; never said or chosen | `mentor_after`, `kit_coda` |
| Protagonist fears the expedition ends with nothing (C) | **missing** — no line, no choice, no scene voices it; Príncipe has no stakes dialogue | — |
| A→B→C escalating conflict with Eddington (§4) | A **thin** (drive vs plates is a mechanic with no argument); B **present** as grading (`judgment.gd`, reselect); C **missing** — the player never doubts Eddington | `main.gd:_after_judgment` |
| Mentor Ashby, Newtonian, supportive, rigorous (§3B) | **present**, strong | `content_1917.gd`, `content_epilogue.gd` |
| Ashby's gift before departure (§3B A+C) | **present** | `mentor_farewell` |
| Ashby's farewell line | **present** (candidate line used verbatim) | `mentor_farewell_after` |
| Kit: warm, funny, competent, independent career (§3I–3J) | **present** in 1917/M2 (variable star, the slip); career never *shown* after M2 | `kit_coda`, `slip_found` |
| Unequal opportunity, restrained (§3I beat 3) | **thin** — one 「如果真的有遠征……算了。」 | `kit_coda` |
| Kit names the protagonist's impatience (§3I beat 5) | **missing** (M2 slip is close but reversed: Kit catches *your* error kindly) | `slip_found` |
| Sky promise (§3L) | **present** setup; **payoff missing** — the page is written, nobody reads it | `sky_promise`, `principe_workbook` |
| Letters during expedition (§3J beat 3) | **missing** (none; acceptable per Bible's "paper-only" constraint, but no substitute) | — |
| Summer/autumn 1919 reunion with Kit (§3K) | **missing** — epilogue has Ashby only | `content_epilogue.gd` |
| Unsent letter (§3K C) | **missing** (correctly undrafted; needs a scene to live in) | — |
| Childhood chart → accused of lying (§3O) | **thin** — referenced 3× (Kit on accuse, `kit_coda`, `kit_close` thought); never dramatised, never paid | `mentor_review:258`, `kit_coda:608` |
| Romance optional, unspoken before ending; friendship equal (§3M) | **present and correct** (`bond_tone` colours only) | `before_closing`, `sky_promise`, `kit_close` |
| Quiet mutual confirmation at the ending (§3M) | **missing** (no Kit at the end) | — |
| Same desk, raw plates, mentor's tool (§5) | **present** — epilogue reuses the 1917 room; loupe is a prop in NIGHT/CODA; ending shows a plate. The three objects (plate / loupe / Kit's page) are never composed together | `epilogue_director.gd`, `ending.gd` |
| Cottingham as skilled peer, credited (§3H) | **present** functionally (drive, exposure reads); as a *person* **thin** | `content.gd` |
| Dyson credited | **present** (1917 note, letter, telegrams addressed to him) | several |
| Príncipe locals / Sundy credited (§0, §3H) | **missing** — not one line | — |
| Mercury 43″ → box → 1.75″ loop (§8) | **present** (moves B, E, D) | several |
| Keepsake / microphotograph (§3N, OPEN) | correctly **absent** | — |
| No gendered pronoun for Kit (cast rule) | **violated**: 「她」 twice | `content_coda.gd:96,98` |

---

## C. Diagnosis — why it does not yet move a player

1. **The protagonist has no voice and no declared want.** Across ~480 lines, "你" speaks about 25, nearly all parenthetical. The one moment the story invites a want — Kit's 「如果真的有遠征……算了。」 — the player cannot answer; the scene cuts to 「先做清單」. The Bible's engine (B: wants to be seen; C: fears nothing will come of it) is nowhere said, chosen or enacted. Without a stated want there is nothing to lose, so the eclipse is a well-tuned minigame, exactly what M1's "Why" paragraph diagnosed in October.

2. **Príncipe — the production priority — has people-shaped functions, not people.** From the montage caption to the coda, every Eddington and Cottingham line is instruction, status or grading: 「可用底片 %d 張」, 「走速對上了」, 「你的理由站在底片上，這很好」. Nobody fears, nobody hopes aloud, nobody mentions the two years, the ship, the morning's thunderstorm as anything but weather. The real material is extraordinary and unused: Eddington did not look at the eclipse (「換底片」 — HISTORICAL, his own account), Cottingham's "go home alone" exchange, the Sundy plantation and its workers. The slice currently has zero emotional beats between the camp and totality.

3. **Setups without payoffs; Kit disappears.** The game plants the sky promise (「回來的時候，我要看」), the dated blank page, the first-words-to-Kit choice (`kit_first`, stored in `Story` and in the run record) — and then the epilogue is Ashby and a chart. Kit is never seen again; the page is never read; `kit_first` is never spoken. The childhood chart is mentioned three times and never shown or resolved. A player who cared about Kit (the game's warmest writing) is handed an accounting scene.

4. **No conflict with Eddington; the mentors never disagree where it hurts.** Ashby and Eddington are both right, always, and agree on every card (「我們兩個難得完全同意」 is charming once; it is the pattern). The player is graded, never opposed. The Bible's conflict C — the protagonist asking the professor whether he already decided the answer, and seeing their own bias in the mirror — is the dramatic question of the whole piece and has no scene. Eddington's one admission that would make him human (「包括我。」 on the rules card) is a single word.

5. **Pacing and register: evaluation, not experience.** The dominant loop is "choose a line → a wiser character tells you how honest that was" (`mentor_review`, `eddington_exam`, `judgment.gd`, `weight_reply`, `final_reply`). It is excellent pedagogy and it reads as a report card. The strongest moments are the ones that break the loop — Kit's four minutes nobody is waiting for, two shadows on one plate, the mirrored "14" — because they are specific, physical and under-explained. The ending then dissolves into ledgers: bet, October bet, final reason, astro weight. The Bible asks the finale to be told "以動作、物件、沉默與場景構圖"; the current one is five stored strings.

---

## D. Treatment

**Spine.** A young assistant who was once called a liar for drawing the sky they saw wants, more than anything, to be believed — and goes to the edge of the world to measure a number that might come out as nothing. The person who believed them first stays behind and asks for only one thing: tell me what the sky looked like, the one you saw yourself. On Príncipe the fear comes true for 250 seconds and then almost doesn't; in the dark the assistant must decide whether to write what the plates say or what they need them to say. Back at the same desk, with the mentor's loupe, the raw plates and the friend's page, the assistant discovers that being believed was never about the number: it was about writing down what you saw, and having someone who wanted to read it.

Changes ranked by emotional payoff per cost. "Slice" = Príncipe camp → totality (+ the night that pays it off).

### D1. Let the player want something (1917) — low cost, feeds everything
- **Where:** `content_1917.gd:kit_coda`, rewrite the tail. New `Story.want` ∈ {seen, nothing, silent}.
- **Player does:** answers Kit's 「如果真的有遠征……」 instead of being cut off.
- **Sample (FICTION):**
  - Kit: "If there really is an expedition—" (stops) "Never mind. The Hyades won't line up by themselves."
  - Choice A, You: "I'd go. I want to do one thing somebody actually looks at."
  - Kit: "Somebody looks at your tea every night. … I know what you mean."
  - Choice B, You: "I'd go. And then what if there's nothing on the plates?"
  - Kit: "Then you'd come back and tell me there was nothing. That's still a thing you saw."
  - Choice C: (silence) — Kit: "Right. Lists first."
- **Sets up:** D2, D4, D6 recall `Story.want` in one line each. **Lines:** ~10. **Fact-check:** none. **Slice:** feeds it.

### D2. The rainy morning at the camp (Príncipe) — high payoff, low cost, IN SLICE
- **Where:** `content.gd` new `camp_morning(want)`, played once before `briefing()` when the player first reaches Eddington (`main.gd` PREP "eddington" branch, before the briefing). Prologue and direct paths both get it (want = -1 on direct).
- **Player does:** one choice; then the briefing continues as now.
- **Sample (RECONSTRUCTION of the recorded rain and Eddington's mood; FICTION dialogue):**
  - Eddington: "I've been watching that gap since six. It closes every time I believe in it."
  - Cottingham: "Before we sailed, Dyson told me: if the plates show twice Einstein's number, Eddington goes mad and I come home alone." (beat) "He didn't say what happens if they show nothing."
  - Eddington: "Then we go home together and say so."
  - Choice: "We still have five minutes." / "And if there is nothing on them?" / (say nothing)
  - On "nothing", Eddington: "Then there is nothing, and sixteen plates that say so. Dyson can read a blank plate. So can your Mr Ashby."
  - If `want == nothing`: You (thought): "(Two years ago I said that to Kit as a joke.)"
- **Sets up:** D4 (go home alone payoff), the stakes of every exposure. **Lines:** ~14. **Fact-check:** the Dyson–Cottingham exchange is Eddington's own retelling (Chandrasekhar, *Eddington*, 1983; Eddington's 1919 account) — verify wording and that it was said at Dyson's before departure; keep it as Cottingham *recalling* it, never as a quotation. Morning thunderstorm + cloud: HISTORICAL (already in `briefing`). **Slice:** yes.

### D3. After third contact — "I did not see the eclipse" — low cost, IN SLICE
- **Where:** `content.gd` new `after_totality(n_plates, any_clear)`; `main.gd:_end_totality` plays it before the fade to NIGHT.
- **Player does:** nothing but read two lines and, if the workbook page is unwritten, see it highlighted here instead of only at night (`_add_night_workbook` objective moves earlier; text unchanged).
- **Sample:**
  - Eddington: "I didn't see it. One glance to be sure it had begun, one half-way for the cloud. The rest was plates." (HISTORICAL paraphrase of his account)
  - Cottingham: "I saw it." (beat) "Thin cloud, the last minute or so. Like a lamp behind frosted glass."
  - If n_plates == 0, Eddington: "Then we have the cloud. Write the cloud down."
  - Kit's dated page, objective: 「在工作簿記下你看到的天空」.
- **Pays off:** the sky promise becomes something the player does *at the moment* rather than six hours later. **Lines:** ~6. **Fact-check:** Eddington's "I did not see the eclipse, being too busy changing plates" — his own words; cite exact source (Eddington, *The Observatory* 1919 / Trinity account). **Slice:** yes.

### D4. "Cottingham, you won't have to go home alone." — the night's emotional peak — low-med cost
- **Where:** `main.gd:_after_judgment` → after Eddington's graded lines and before `cottingham_coda`; new `content.gd:go_home_alone(case)` keyed on evidence class (`favors_e` + clean, `favors_e` + not clean, `ambiguous`/`favors_half`, `none`).
- **Player does:** nothing; this is the one place the game is allowed to be quiet.
- **Sample (RECONSTRUCTION; Eddington's own anecdote):**
  - favors_e & clean — Eddington (to Cottingham, not to you): "Cottingham. You won't have to go home alone."  Cottingham: "…I'd packed for it."
  - ambiguous — Eddington: "Cottingham, I can't tell you yet whether you're going home alone."  Cottingham: "Then I'll wait. I've a clock to pack."
  - none — Eddington: "We go home together, and we say what we saw."
  - Then the existing `cottingham_coda`.
- **Guardrail:** the payoff is Cottingham's, not the player's; nothing here changes grading or the telegram. **Lines:** ~8. **Fact-check:** same source as D2; confirm the Príncipe line is Eddington's recollection, mark RECONSTRUCTION. **Slice:** night (direct payoff of D2).

### D5. Conflict C — pressing Eddington — medium cost
- **Where:** `main.gd:_start_judgment`: after the interval question and before the telegram, offer one extra choice; new `content.gd:press_eddington(bet_pick, interval_truth)` and reply.
- **Player does:** chooses to ask, or not. Asking costs nothing in score; it changes two later lines (coda thought; epilogue Ashby remark).
- **Sample (FICTION; must not diminish Eddington):**
  - Choice: "You decided this was 1.75 before we sailed, didn't you?" / "Say nothing."
  - Eddington: "Yes. I hoped. That's why the rule was written before you measured, and why Dyson has the Sobral plates and not me." (beat) "Now you. What did you write in 1917?"
  - If player bet 1.75 and plates are ambiguous: You: "(1.75. Very sure.)" Eddington: "Then we are two people hoping, with one set of plates between us. Write the telegram for the plates."
  - If player bet 0.87/0: Eddington: "Then one of us is going to be disappointed tonight, and the plates don't care which."
- **Sets up:** the Bible's self-recognition; gives `kit_close` and `ashby_answer` one conditional line each (「這一次，你差一點就成了那個好故事」 already exists and lands harder after this). **Lines:** ~16. **Fact-check:** Sobral plates reduced at Greenwich under Dyson (already in `CONVERSION_ARC.md` guardrails). **Slice:** night.

### D6. Kit in October 1919 — the reunion — medium-high cost, highest payoff outside the slice
- **Where:** `scenes/epilogue.tscn` already has the room and `kit.glb`; `content_epilogue.gd` new `kit_reunion(kit_first, bond_tone, sky_promise, kit_line)`, played after `opening()` and before the letter (Ashby: 「信在桌上。先跟 Kit 說話去。」). Add `kit_unsent()` as an **optional** examine on Kit's end of the table.
- **Player does:** (1) says the stored `kit_first` line — finally delivered; (2) hands over the workbook; Kit reads the player's actual page aloud (the generated `sky` text); (3) Kit shows their half of the promise: one page of what changed in Cambridge; (4) a two-minute shared task that is Kit's: the variable star's period, now measured to the minute — the player reads three timings and Kit marks them, reversing the 1917 roles; (5) the unsent envelope is visible; Kit may offer it; the player may decline to read.
- **Sample (FICTION):**
  - Kit: "You're thinner. Say it, whatever you decided to say first."
  - (player's `kit_first` line, already authored, e.g. "The cloud only thinned at the end. I watched it the whole time.")
  - Kit (reading the page): "'I looked up for a long time.' … You spelled Príncipe wrong."
  - Kit: "Mine. What changed here: the lamps are back on Trumpington Street. The empty desk has a first-year in it who puts sugar in everything. The star — eleven hours, four minutes. It was never late. I was."
  - On the envelope, Kit: "The boat takes six weeks. You'd have been home before it. So I didn't send it." Choice: "May I read it?" / "Keep it. Tell me instead." — on `close` tone only, Kit: "…Later. Not tonight." (no confession on any route)
- **Pays off:** sky promise, `kit_first`, Kit's independent career, unequal opportunity (one line, restrained), the childhood chart if `kit_choice == 0`. **Lines:** ~45. **Fact-check:** mail time Cambridge–Príncipe 1919 (steamer via Lisbon; weeks, not days); Eddington's party reached Liverpool 1919-07-14 (Trinity archive) so a *July* reunion is also possible — the lead chooses July (warmer, before Sobral news) or October (one scene). Kit's star period is invented; keep it unnamed. **Slice:** no.

### D7. Sundy and the people who built the station — low cost, IN SLICE
- **Where:** `content.gd:examine` new ids `sundy_view` (hotspot facing the plantation house) and a second Cottingham line in `cottingham_first` or `cottingham_done`.
- **Player does:** examines; optional.
- **Sample (HISTORICAL frame, RECONSTRUCTION wording):**
  - "Roça Sundy. Senhor Carneiro's house. The shelter, the pier that landed the crates, the men who carried the coelostat up the hill — none of them will be in the report."
  - Cottingham: "The carpenters here work faster than mine in Thrapston. I'd hire two of them if they'd come."
- **Guardrail:** credits locals and the Portuguese host without inventing names beyond Carneiro. **Lines:** ~4. **Fact-check:** Jerónimo Carneiro / Roça Sundy hosting (Eddington's letters; Crispino & Paolantonio 2019); Cottingham's Thrapston workshop (HISTORICAL). **Slice:** yes.

### D8. The final tableau: three objects, no ledger — low cost
- **Where:** `epilogue_director.gd:_end_epilogue` before the fade; `content_epilogue.gd:tableau(has_kit_page)`.
- **Player does:** a camera move over the desk; one line.
- **Sample:** caption only — "The plate. The loupe. The page." then Ashby (if conceded): "Leave them there. Someone will want to see how you got it." / (else) "Leave them there. Someone will want to argue." Kit (if D6): "Outside. You said you'd show me." → the two walk out; the real night sky (Bible §3M option B, as visual only, no words). **Lines:** ~4. **Slice:** no.

### D9. Eddington's private cost — optional, DISPUTED, low cost
- **Where:** `content.gd:examine` id `tent_letter` (a letter on Eddington's table).
- **Sample:** "A letter from the Astronomer Royal, dated 1918. A tribunal, an exemption, a condition. You put it back." Nothing more.
- **Fact-check (must):** Eddington's 1918 conscientious-objector tribunal and Dyson's intervention tying exemption to the expedition — well documented (Chandrasekhar 1983; Stanley 2003) but historians dispute how formal the "condition" was. Keep it to one examine or cut. **Lines:** 2. **Slice:** yes.

### D10. Fix the pronoun breach — trivial
- `content_coda.gd:96,98` 「她大概已經記了一整頁」 / 「她會想知道」 → write around Kit (「Kit 大概已經記了一整頁」). Cast rule in `cast.gd`.

Build order recommendation: D10, D1, D2, D3, D7 (one PR; all inside or feeding the slice; ~35 lines), then D4 + D5 (night; ~24 lines), then D6 + D8 (reunion; needs Kit staging in the epilogue room; ~50 lines). D9 only after a Sonnet fact-check.

---

## E. Keepsake — the open microphotograph (NEEDS THE OWNER'S PICK; nothing below is canon)

Constraints from §3N–3O: one person has carried it since childhood; neither knows the secret; revealed in Cambridge in 1919 under a magnifier that rhymes with the observing work; content ties to the childhood chart; works on both routes; never evidence for relativity.

**Option 1 — The pencil cap (protagonist carries it; Kit's hand inside).** The pencil motif already runs through the game (「你的鉛筆。記得帶」, 「上次你借走我三枝」). The protagonist's propelling pencil has a cheap Stanhope cap whose viewing lens cracked out years ago, leaving a speck nobody could read — a visual rhyme with plate 14's 「極淡的白」 that needed a second instrument. Ashby's 30-year loupe is that instrument. Inside: the children's rejected star chart, reduced, with Kit's childhood lettering: "We saw it. — K." Who made it: the one adult who believed the two children (a grandparent or a village photographer — the Owner picks) had the chart reduced so it could not be lost, and gave it as an ordinary pencil; the adult died or moved before saying what it was. Why unseen: no lens, and children do not look at pencil caps. Payoff: Kit recognises their own hand; the protagonist learns they carried Kit's belief for fifteen years without knowing. Friendship route: "we saw it" is complete in itself. Romance route: the same object, a longer silence.

**Option 2 — Kit's watch fob (Kit carries it; the protagonist's drawing inside).** Mirror of Option 1 with the roles swapped: the protagonist drew the chart; Kit's family had it reduced. Stronger for "Kit always saw you"; weaker because the reveal happens on Kit's body, so the player's loupe moment is about someone else's object.

**Option 3 — Ashby's loupe is the keepsake.** The brass loupe's handle holds the microphotograph; Ashby was the adult who believed the children (he knew the protagonist as a child). Elegant, one object fewer, but it makes Ashby's gift a planted secret, collides with "one of the two carried it since childhood", and risks the "sentimental relic" the Bible forbids. Not recommended.

**Recommendation:** Option 1. It uses an existing motif, keeps the reveal in the protagonist's hands with the mentor's tool, keeps Kit's agency (Kit *wrote* the line that was believed), and rhymes exactly with plate 14 without sharing any scientific mechanism. Fact-check before any draft: Stanhope microphotograph manufacture c. 1900–1905 in England/France, lens-less failure mode, whether a 10–15× loupe resolves a Stanhope image (it is designed for ~100×; the text may need to be the chart's shape plus one word, not a sentence). Draft microtext: "We saw it. — K." (not the Bible's earlier 「看不清楚也沒關係」 candidate).

---

## F. Guardrails checked

- **Real people not diminished.** Every proposed Eddington line is rooted in his own account (not looking at the eclipse; the "go home alone" exchange; rules before measuring; Sobral at Greenwich). D5 has him admit hope, not bias, and point to what he actually did. Ashby stays a Newtonian with method, never a strawman (already true). Dyson is credited in D2/D5 and already in the 1917 note, the telegrams and the letter.
- **Cottingham credited.** D2/D4 give him the two best-remembered lines of the expedition; D7 credits his trade (Thrapston). He still drives and exposes; the player never replaces him.
- **Locals credited.** D7 is the first mention of Roça Sundy, the host and the workers; it names only the documented host.
- **Protagonist not a historical third observer.** The M2 montage disclosure stands; D2–D4 add no claim of membership; the player still only calls the cloud. D7's "none of them will be in the report" also covers the protagonist.
- **No anachronisms introduced.** No lasers, no telegraph-speed mail (D6 makes the six-week boat the reason for the unsent letter), no radio; Stanhope technology predates 1905 (needs the specific check above).
- **Friendship route not second-class.** D1, D3, D6, D8 and the keepsake all resolve fully with `bond_tone == warm`; the `close` tone only adds a pause or a "later". No confession appears before the ending on any route; D8's walk outside is visual and wordless.
- **Science outcome not gated by romance or friendship.** None of D1–D9 touches `eclipse_sim.gd`, `judgment.gd`, grading, the telegram set, the bet or the epilogue's weighting; D4/D5 read the evidence class and never write it.
- **History/fiction tags.** Every new line above carries its tag; D2, D3, D4, D6, D7, D9 need a Sonnet fact-check before a PR (per the narrative PR pattern); D9 is DISPUTED and optional.
- **Existing breach found:** `content_coda.gd:96,98` use 「她」 for Kit against `cast.gd`'s rule (D10).
