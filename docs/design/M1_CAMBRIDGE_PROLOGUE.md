# M1 — Playable prologue: Cambridge, October 1917

**Owner / director:** Opus 5.5 (Game Director). **Status:** spec for implementation, 2026-10-20.
**Canon source:** Notion Narrative Bible §0, §§3B–3J, 3O (Owner-APPROVED structure). Everything in this
file that is *dialogue, names, staging or a specific prop* is a **director's proposal**, not Owner canon,
and must stay easy to replace (see "Placeholders").

## Why this milestone

v0.1 opens cold on Príncipe. The player has no one to care about and no reason to fear an
inconclusive result, so the eclipse is a well-made minigame with no emotional stakes. The approved
narrative fixes that in a 1917 prologue: the player earns trust **by keeping an inconvenient record
honestly**, meets the mentor, the peer and Eddington, learns *with their hands* why a star that
"moved" may only be a turned plate, and helps plan a fair eclipse test. The 1919 core then becomes
the payoff of something the player did.

## Player experience target (12–18 min, no physics knowledge needed)

A newcomer should be able to say afterwards, unprompted:
1. "Two records of the same stars didn't line up; I found out the copy was made with the plate
   flipped and slightly turned — it wasn't anyone lying."
2. "One dot still didn't match, and I wrote it down as unresolved instead of hiding it."
3. "To test the eclipse fairly you need the same stars photographed without the Sun, and stars far
   from the Sun to check the plate isn't turned or scaled."
4. They want to know what happens to Kit / the mentor / the expedition.

No timers, no fail states. Wrong or hasty choices get questioned by characters and can be revised.

## Placeholders (all reversible; keep in ONE file `scripts/cambridge/cast.gd`)

| Role | Placeholder | Rule |
|---|---|---|
| Protagonist | 「你」, no name | No gendered pronoun anywhere for the protagonist. |
| Peer (same age, fictional) | **Kit**（暫名） | Gender undecided → never use 他/她 for Kit; write around it. |
| Mentor (fictional, Newtonian) | **Ashby 先生**（暫名） | Addressed as 「先生」/「Ashby 先生」. Avoid pronouns where cheap. |
| Copyist of the old chart (fictional, absent) | 「抄錄的人」 — enlisted 1915 | No name, no initials. Never imply a real Observatory assistant. |
| Eddington (real) | Eddington | Fiction scene; dialogue is dramatised and labelled. |

The **childhood keepsake / microimage is NOT in this milestone** — no placeholder object either.
The childhood star-chart accusation (APPROVED §3O) may be *referenced* in one or two lines by Kit,
without inventing specifics (no ages, places, names of bullies, or how the chart was drawn).

## Scene: the measuring room (`scenes/cambridge.tscn`)

Cambridge Observatory measuring room, an evening in October 1917 (RECONSTRUCTION; the room's
layout is invented). Interior ≈ 9 m × 6 m × 3.6 m, built procedurally like `world_builder.gd`
(reuse its helpers: `box`, `cyl`, `mat`, `evidence_mat`, `weather`, `interactable`, `hotspot`, `npc`).

- **Worktable** (center): green-shaded lamp = key light (warm pool). On it: the **light box**
  (看片台 — slanted frosted glass, lit from below; evidence-bright), the copy chart, a loupe,
  inkwell, the player's notebook.
- **Kit's end of the table:** a stack of plates and Kit's own ledger (Kit's independent work).
- **Tall sash window**, rain streaks, **blackout curtain** half drawn (wartime lighting rules —
  fact-check pending, keep it as atmosphere only). Cold blue fill light from it.
- **Shelves** with ledgers; the **observing log** (觀測日誌) for 1915 is here.
- **Plate cabinet** (shallow drawers).
- **Empty desk** with chair pushed in, a coat still on the hook, a folded letter (fiction texture:
  the copyist enlisted; no name).
- Small coal fire (low), **regulator clock** (ticking audio), door to the corridor (NPC entrances).
- Lighting: cinematic — lamp pool vs. cold window, rest in shadow; reuse `scripts/look.gd` grade.
  Evidence (light box, plate, chart) is the brightest thing in frame (BIBLE S1). Audio: rain bed,
  clock tick, page/glass clicks (procedural like `main.gd`).

## Beats and mechanics

### Beat 0 — Title / chapter select (in `main.gd`'s existing title)
Keep `run/main_scene = main.tscn` (autoplay and benchmark depend on it). The title gets:
**「序章　劍橋，1917」**（primary, first）→ `change_scene_to_file("res://scenes/cambridge.tscn")`;
**「普林西比，1919」** (= the existing start button `ui.start_btn`, unchanged behaviour for the bot);
**「離開」**. Update the title blurb so it introduces the whole story, not only Príncipe.

### Beat 1 — Cold open (≈1 min)
Fade in at the worktable. Caption: 「劍橋天文台・1917 年 10 月」 + small 「（重建場景）」.
`C17.opening()` plays (Kit). Objective: 「核對 14 號星場的抄錄圖，交給 Ashby 先生」.
Player can walk the room (WASD/mouse, same controls as v0.1). E interacts.

### Beat 2 — The discrepancy (≈3–5 min) — the core puzzle
Interacting with the light box opens the **Overlay Viewer** (2D, full-screen modal):
- **Plate layer (fixed):** negative look (dark star dots on pale grey glass, subtle grain), ~18 stars
  of varied size, the plate's own **scratched label "14"** near one corner and a **scratched north
  arrow** that is tilted ≈3.2° from the plate edge (both readable normally, NOT mirrored).
- **Copy layer (tracing paper, movable):** ink dots + a drawn grid aligned with the paper edge + the
  copyist's drawn north arrow (parallel to the paper edge) + the copied label, which appears
  **mirror-reversed** (because the copyist traced the plate from the glass side).
  The copy = mirror(plate) rotated by +3.2°, plus **one extra dot** (the residual, see below).
- **Controls:** drag to move the copy; **翻面** button (mirror the tracing); rotate with ⟲/⟳ buttons
  (0.5° steps) and Q/E keys; **重設**; **關閉**. While the copy is *roughly* over the plate, draw
  thin **difference arrows** from each copy dot to its nearest plate star (within a radius) so the
  pattern of the error is visible (after flipping: arrows all circulate the same way → rotation).
- **Alignment:** when flipped, |rotation error| < 0.6° and offset small, snap and glow:
  「17 個點重合了，還有 1 個沒有對上」. Matching is computed, not scripted (headless-testable).
- **Clickable details (set clue flags + toast via `C17.viewer_feedback(id)`):**
  `label_mirrored` — clicking the copy's reversed "14" (or the plate's "14" after seeing both);
  `arrow_tilted` — clicking the plate's scratched arrow;
  `residual` — clicking the unmatched dot once aligned opens a **loupe inset** showing the plate at
  that spot: a tiny pale, ambiguous speck — could be a faint star, could be an emulsion flaw.
  It cannot be decided from one plate. (Do NOT resolve it in M1.)
- The first time the player sees the mismatch and closes the viewer (or talks to Kit), Kit offers a
  natural but wrong guess (`C17.kit_guess()`): maybe it's a different field / different night.
  The **observing log** on the shelf (`examine:logbook`) rules that out (same plate number, field,
  date) → clue `log`.
- **Hint ladder:** talking to Kit returns `C17.kit_talk(state)` keyed on progress; also, after 90 s in
  the viewer without new progress, one gentle toast hint (`C17.viewer_hint(state)`).
- **Independent check:** once the player has aligned the copy, Kit can be asked to re-check
  independently (`C17.kit_double_check()`), sets `kit_checked`. This is Kit's real contribution
  and can be credited in the report.

### Beat 3 — The record (≈2 min)
The notebook on the table opens the **Report Sheet** (2D page). Four rows of option chips; options
appear only when the evidence for them has been found (state the gating in data, from
`C17.report_rows()`):
1. **原因** — 抄錄時底片翻面（鏡像）[needs `label_mirrored`] · 底片放斜約 3°［needs `arrow_tilted`］ ·
   兩者都有［needs both］ · 原因未查明 · 抄錄的人草率／編造 (always available — the tempting accusation).
2. **原始抄錄圖** — 保留原圖，旁附更正 · 重畫一張乾淨的，舊的作廢.
3. **沒對上的那一點** — 標「未解決，需另一張底片」 · 當成墨漬刪掉 · 寫「可能是新天體」.
   (Row 3 only after `residual` is found; otherwise it reads 「（沒有發現）」 and is recorded as such.)
4. **複核** — checkbox 「Kit 獨立複核」 (only if `kit_checked`).
Submit = 「交給 Ashby 先生」 → stores `Story.report` → Beat 4. No score is shown.

### Beat 4 — The mentor (≈3 min)
Ashby 先生 enters (wet coat; a journal under the arm). `C17.mentor_review(report)` reacts to the
sheet (different lines for accusation / redrawn / deleted residual / honest), then
`C17.mentor_dyson(report)`: Dyson's 1917 note about the 1919 eclipse and the Hyades (HISTORICAL);
the mentor's respectful Newtonian position; and the bridge: *"If stars 'move' on an eclipse plate,
how will anyone know it isn't a turned plate?"* The mentor says the sheet will go to Eddington.

### Beat 5 — Eddington (days later, ≈2 min)
Fade; caption 「三天後」; daylight-grey window, lamp off. Eddington is at the table with the
player's sheet (fiction scene). `C17.eddington_exam(report, state)` — two questions with honest
variants; no wrong-answer fail. Then Beat 6 at the same table, mentor present.

### Beat 6 — Three-way planning (≈4 min) — the second mechanic
**Plan Board** (2D): the question 「怎樣的日食觀測，才算公平的比較？」, 4 slots, 8 cards from
`C17.plan_cards()` = `{id, text, kind: "core"|"helpful"|"bias", react: Array}`. Clicking a card toggles
it into a slot and plays its short `react` dialogue (mentor and Eddington may disagree on priority).
**Finish** enabled with ≥3 cards; if a `bias` card is in the plan, finishing plays
`C17.plan_blocked(card)` and returns to the board (characters ask you to reconsider — no penalty).
On finish: `Story.plan = [ids]`, `C17.plan_finish(plan)`.

### Beat 7 — The trial task (≈1 min)
`C17.trial_task()` — Eddington entrusts a real preparation task (prepare and plate-check a list of
comparison stars in the Hyades field). NOT expedition membership. `C17.mentor_after(report)`:
mentor alone with the player, proud and cautious.

### Beat 8 — Kit coda and bridge (≈1–2 min)
Evening again. `C17.kit_coda(report, state)` (a choice; childhood reference; Kit's own work; the
first hint of unequal opportunity). Then the **montage** `C17.montage()` = list of
`{t: String, tag: "HISTORICAL"|"FICTION"}` shown as captions over black, then
`change_scene_to_file("res://scenes/main.tscn")` with `Story.from_prologue = true`, which makes
`main.gd` skip its title, show 「1919 年 5 月 29 日・普林西比」 and start PREP directly.

## Continuity into 1919 (small hooks)
- `Story` autoload (`scripts/story.gd`): `from_prologue`, `prologue_done`, `clues: Dictionary`,
  `report: Dictionary` (`cause`, `original`, `residual`, `kit_credited`), `plan: Array`, `kit_choice`.
  Pure data, no nodes (co-op boundary rule D006).
- In Príncipe, if `Story.prologue_done`: `Content.plan_text()` appends 「你在 1917 年參與擬定的
  原則：…」 listing the chosen plan cards; Eddington's briefing gets one extra line from
  `C17.principe_callback(Story)`. Nothing in 1919 grading depends on prologue choices.

## Shared UI additions (in `ui.gd`, used by both chapters)
- **Dialogue log:** every shown dialogue line is appended to a history; **Tab** toggles a scrollable
  panel with the last ~60 lines. (Accessibility requirement, Narrative Bible §3D.)
- Captions/fades/toasts/objectives: reuse existing API.

## Content interface (`scripts/cambridge/content_1917.gd`, preloaded as `C17`)
Static functions returning dialogue arrays in the existing format
(`{s, t, key?, choices?, then?}`) or plain data. The **director writes this file**; the implementer
creates a stub with the same signatures and short placeholder lines so everything runs:
`intro_caption()`, `opening()`, `kit_guess()`, `kit_talk(state)`, `kit_double_check()`,
`examine(id)` for ids `logbook, empty_desk, letter, window, fire, clock, cabinet, kit_ledger, notebook_before`,
`viewer_feedback(id)`, `viewer_hint(state)`, `report_rows()`, `mentor_review(report)`,
`mentor_dyson(report)`, `interlude_caption()`, `eddington_exam(report, state)`, `plan_intro()`,
`plan_cards()`, `plan_blocked(card)`, `plan_finish(plan)`, `trial_task()`, `mentor_after(report)`,
`kit_coda(report, state)`, `montage()`, `principe_callback(story)`.
`state` = `Story.clues` merged with `{aligned, residual_found, kit_checked, report_done, viewer_opens}`.

## Verification (what "done" means)
- Headless tests (`tests/test_prologue.gd`): overlay matching math (unflipped ≈0 matches, flipped
  unrotated partial, flipped+rotated 17/18), clue gating of report options, Story persistence,
  plan finish rules. Existing `tests/test_sim.gd` still 155/155.
- **Prologue autoplay** `--prologue-autoplay=honest|tidy|accuse --shots=DIR` driving the real UI
  through input events end-to-end into the 1919 PREP phase, with screenshots of every beat and a
  JSON receipt. (Launch with `--always-on-top`; see memory note on hidden windows.)
- Existing v0.1 autoplay (careful/rushed/cherry) and `--benchmark` unchanged.
- macOS export builds and includes the new scene.
- **Not claimed:** human playtest. A newcomer test using `docs/PLAYTEST.md` + the four statements
  above is the next gate.

## Historical / fiction boundaries
HISTORICAL: Dyson's 1917 note on the 1919 eclipse and the Hyades; the Joint Permanent Eclipse
Committee (Nov 1917); Eddington as Observatory director; the 1.75″ / 0.87″ / 0 framing; the war.
FICTION: the protagonist, Kit, Ashby, the copyist, the measuring-room scene, plate 14, the mirror
error, all dialogue, the meeting with Eddington, the plan board, the trial task, and the player's
presence on the expedition. Record new items in `docs/PROVENANCE.md`.
