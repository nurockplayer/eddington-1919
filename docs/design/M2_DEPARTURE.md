# M2 — Playable interlude: the night before departure, Cambridge, March 1919 (DRAFT)

**Owner / director:** Opus 5.5. **Status:** draft spec, written while M1 is in implementation; finalise
after playing merged M1. **Canon:** Narrative Bible §3B (mentor farewell A+C, gift APPROVED as a
concept), §3I–3M (peer, sky-sharing promise APPROVED in concept, romance tempo LOCKED: intense,
unspoken before departure; friendship route equally complete). Dialogue/staging below = proposals.

## Why
M1 makes the player care about honest records and meet the people. The eclipse only becomes
*personal* if the player leaves something behind: a friend who stays in Cambridge with a worthy
career of their own, and a mentor who supports the journey while asking for honesty. This is the
emotional loading of the 1919 core and the setup of every later payoff (letters, reunion, the
mentor's instrument at the final worktable).

## Shape (6–9 min, playable, no timers)
Same measuring room, early March 1919 (RECONSTRUCTION): blackout curtain gone (Armistice), packing
crates (`R.A.S. ECLIPSE`, matches v0.1), the finished Hyades list, Kit's own work spread out.

1. **Last shared work (mechanic reuse).** Kit reads back the last page of the comparison-star list;
   the player checks each entry on the light box against a plate (reuse Overlay Viewer data path,
   simpler: 5 entries, mark ✓/✗). One mismatch is **the player's own transcription slip**, which Kit
   catches — humility, Kit's competence, and the honest-record theme turned on the protagonist.
   The player chooses how to correct it (strike through and initial vs. overwrite) — same values
   as M1, no score.
2. **Small acts of care (environment + choices).** Kit has already set out the player's usual
   tools; the last page carries both handwritings. Two or three restrained choices
   (stay a little longer / tidy up / joke) set `Story.bond_tone` ("close" | "warm") which only
   colours later lines. Never a gauge, never a reward for chores.
3. **The sky promise (APPROVED concept).** Candidate lines (Notion, not locked): Kit:「到了那邊，
   記得告訴我天空是什麼樣子。」 You:「那你也得告訴我，這裡有什麼變了。」 Kit points to a blank page
   in the workbook:「那裡看到的，記在這裡。」 On the `close` tone, a pause, an almost-question that
   becomes a question about work; **no confession on any route**. The platonic route keeps the
   same promise with equal warmth.
4. **The mentor's gift (APPROVED concept).** Ashby, alone with the player, gives a long-kept
   measuring instrument (type = placeholder `Cast.MENTOR_GIFT`, e.g. a brass measuring loupe —
   type, era and provenance still to be researched; never claim it is a real historical object).
   Candidate farewell (Notion, not locked):「去看看吧。無論你看見什麼，都把它記下來。」
5. **Montage → Príncipe** (moves M1's montage tail here; 1917 prologue ends on the trial task and
   a short "1918" bridge instead).

## 1919 hooks
- The workbook's blank page becomes a night-phase action on Príncipe (write what the sky looked
  like) — content for a later letter/reunion milestone.
- The mentor's instrument is used to inspect plates in the Príncipe darkroom (cosmetic in M2;
  must not change measurement results).

## Not in M2
Keepsake / microimage (open canon), reunion, letters, final worktable, any confession.

## Implementation contract (Director, 2026-10-20; dialogue drafted)
Dialogue lives in `scripts/cambridge/content_departure.gd` (Director-owned, same `{s,t,key?,choices?,then?}`
format as M1). Engineering builds the scene around these functions:

| Function | Used for |
|---|---|
| `intro_caption()` | Fade-in caption. |
| `opening()` | Kit at the light box; key `open`. |
| `check_entries()` | 5 rows `{id,label,list,plate,hand,slip?}`. Plate x/y in mm are fictional measuring-machine values, not real star positions. |
| `kit_reads(entry)` | Kit reads the plate value before each row is marked ✓/✗ on a paper checklist (reuse report-sheet styling; list rows show handwriting via font/ink colour per `hand`). |
| `slip_found(caught_by_player, false_alarm)` | After all 5 marks; key `slip_fix` (0 strike + initial, 1 overwrite). The list page then visibly shows the correction (strike-through + initials, or a smudged rewrite). |
| `before_closing()` | Key `bond` → `Story.bond_tone` = "close" for 0, else "warm". |
| `sky_promise(bond_tone)` | Key `promise`. Kit shows the blank workbook page (prop visible in the room). |
| `mentor_farewell(slip_fix)` | Ashby in the corridor; key `gift`. A prop for `Cast.MENTOR_GIFT` appears in the player's hands/HUD afterwards. |
| `montage()` / `bridge_1918()` | M2 tail into Príncipe; M1 ends on `bridge_1918()` then loads M2. |

Story additions: `bond_tone`, `slip_fix`, `departure_done`. 1919 hooks (cosmetic only, never alter
measurement or score): the mentor's gift as the darkroom inspection prop; night phase offers
"write what the sky looked like" in the workbook (text only).
Bot: `--prologue-autoplay` routes continue through M2 (honest → catches the slip, strikes; tidy →
misses it, overwrites; accuse → false alarm then strikes). Tests: every `slip_found` combination, both
`bond_tone`s, both `slip_fix` farewells non-empty; no line contains a confession.
