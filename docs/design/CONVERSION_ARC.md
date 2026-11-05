# Conversion arc: from trusting Newton to being persuaded by evidence

Owner directive 2026-11-06 JST: a player who starts out believing only Newton should be genuinely persuaded by relativity through their own play, and feel the 醍醐味. This note is the lead's design for that program. Inputs:
- a read-only belief-arc map of the current game (Sonnet, 2026-11-06 03:3x JST);
- an oracle-ego research answer on reference games and conceptual-change research (`~/.local/state/oracle-ego/runs/20261106-033333-18668-edd-arc-research/answer.md`);
- issue #37 (Owner's narrative direction and the history/physics gate).

## Success criterion

The player is not supposed to "pick 1.75". After play they should be able to say, in their own words:

> Newton deserved my confidence. The small discrepancy deserved investigation. The new idea gave a testable number. My plates, once I had checked what could fool me, gave me a reason to change my mind — and so did someone else's.

The arc is **trust → predict → doubt → test → revise** (Posner et al. 1982: dissatisfaction, intelligible, plausible, fruitful; predict–observe–explain).

## Where the game stands (2026-11-06, main 1968aea)

Strong, and player-owned: the 1917 calibration mystery, rules-first plate selection, cloud-timed exposures, re-selection that has to be justified, error bars and the 2σ question, and telegrams that never reward "EINSTEIN CONFIRMED".

Weak: the Newton-versus-light content is *told*.
1. The player never commits to 0 / 0.87 / 1.75 before seeing data (`content_1917.gd` `mentor_dyson`, `content.gd:22`, `chart.gd:61-70`).
2. The decisive number is computed for the player. Measure runs `combined()` over generated values (`eclipse_sim.gd:265`, `main.gd:1538`), and no step has the player read a shift off a plate.
3. Mercury's 43″ is three pages on an optional orrery (`content_1917.gd:108-115`, `room_builder.gd:449`). It never returns.
4. The closed box and light in the box are dialogue (`content_1917.gd:355-365`, `content_departure.gd:134-146`). The single choice converges whatever the player picks.
5. The ending states the historical verdict (`main.gd:1683-1686`). Sobral is not playable, and Ashby never reacts to the player's evidence.

## Moves, in build order

| # | Move | Player does | Belief it moves | Blind-playtest question | Cost |
|---|---|---|---|---|---|
| A | **Prediction ledger** | 1917: after Dyson's note, writes their own guess (0 / 0.87 / 1.75 / can't say) and how sure they are; Ashby writes his. 1919: before Measure the ledger comes back (keep or change). After the interval question: their bet set against their plates. Ending and coda recall it. | "the answer is known" → "my expectation is testable" | What did you expect before you measured, and why? | low |
| B | **Newton earns trust; Mercury is felt** | The orrery is on the main path. The player checks three Newtonian predictions against the record (Neptune found on paper, Halley's 1910 return, Mercury's perihelion) and finds the one misfit: 43″/century. They choose what to suspect (a measurement slip / an unseen planet "Vulcan" / the theory itself); Ashby treats all three as reasonable. Humility beat: Einstein's own 1911 figure was the half value. | "Newton is old" → "an excellent theory with one honest residual" | Why would a careful astronomer still trust Newton in 1917? | low–med |
| C | **The player reads the shift** | In the darkroom, for each included plate, the player sets a micrometer crosshair on one marked star (eclipse plate vs. the Oxford/night plate, exaggeration labelled) and the plate's value comes from *their* setting, with its own scatter. A careless setting widens σ. | "the game tells me the number" → "this number is mine" | Where did your number come from? | med–high |
| D | **Sobral arrives; Ashby revises (or doesn't)** | Coda: the Sobral telegram (historical figures) arrives. The player plots it beside their own result and decides whether the astrographic set should count. Ashby, who wrote his guess in 1917, reacts to the player's evidence and to his own entry. Mercury returns: the 1915 theory that predicts 1.75″ also accounts for the 43″. One idea, two cracks closed (fruitfulness). | "one plate proves it" → "independent, accountable evidence converges" | Would Príncipe alone justify your confidence? | med |
| E | **The box, twice, by hand** | 1917: drop a ball in the closed box, toggle "on the ground" and "pulled in space": the two are indistinguishable. Departure: the same box with a light pulse, with a frame switch shown as a labelled, exaggerated illustration. | "gravity is about falling things" → "gravity and acceleration matter for light" | What can the box show, and what can't it? | med |

Order: A, then B and D (D needs A's ledger for Ashby's reaction), then C, then E. Per the oracle advice, blind-test after A + B + D before building E.

## Guardrails (from issue #37 and the research)

- Never make the truth a password. Inconclusive plates still progress; "not yet decided" remains a respected outcome.
- The truth stays at 1.75″ (it is the history). A careless player's plates must still be able to come out ambiguous or Newton-leaning. Do not tune the simulation so that "doing it right" always yields a clean Einstein.
- Label every exaggerated visual as illustration. No lasers. The box does not derive 1.75″.
- Numbers and quotations keep the HISTORICAL_RECORD / RECONSTRUCTION / FICTION / DISPUTED tags in code comments and `docs/PROVENANCE.md`. A Sonnet fact-check comes before any PR that adds history (B, D).
  - 0.87″ is a Newtonian-style corpuscle result (Soldner 1801; not Newton himself).
  - Einstein 1911 ≈ 0.83″.
  - Sobral 4-inch 1.98″ ± 0.12″; Sobral astrographic ≈ 0.93″ (scale problems, set aside: DISPUTED); Príncipe 1.61″ ± 0.30″.
  - Mercury's 43″/century is the residual, not the total precession.
- Ashby is never a strawman. His doubts are about method, and the player must answer them with evidence.
- Every PR follows the narrative PR pattern. Tests drive the real flow (`_dialogue_done`, `ui._seq`, the real viewer), each change gets a revert-check, and gameplay changes get a windowed look in the next 09–15 JST window.

## Acceptance

1. A blind newcomer session (`docs/PLAYTEST_NEWCOMER.md`, updated with the questions above, plus one transfer question: "here is a new plate with these error bars; does it tell the models apart?").
2. Automated: each move's suite, the honest/careful/rushed autoplay routes, and the full e2e before a build.
