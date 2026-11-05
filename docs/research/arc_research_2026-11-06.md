# Oracle research: earned conceptual change (2026-11-06 03:37 JST)

Source: oracle-ego (GPT-6, high), prompt in the conversion-arc program. Design proposals, not approved scenes. Used by docs/design/CONVERSION_ARC.md.

## Executive recommendation
The player should not discover that Einstein was right. The player should discover why their previous way of thinking is no longer sufficient—and why the evidence warrants changing their mind.
The strongest design pattern for Eddington 1919 is:
Trust

Predict

Doubt

Test

Revise

A sequence of player-owned beliefs and observations, not exposition followed by a quiz.

The essential design move is to make players commit to a reasonable prediction, encounter evidence they can inspect, consider alternative explanations, and voluntarily revise their judgment.
Three principles should govern implementation:
- Newton must earn the player's trust before relativity challenges it. A competent Newtonian mentor who checks calibration is more persuasive than an opponent constructed to be wrong.
- The evidence must belong to the player. Selecting plates, aligning stars, estimating measurement uncertainty, and comparing predictions should create the conclusion. A predetermined result appearing after a minigame will not.
- Uncertainty is part of the revelation. The strongest ending is not absolute certainty but an evidence-based revision: general relativity has earned stronger support, while the measurements remain imperfect.

This respects the Owner's approved narrative direction, which explicitly preserves the 1917 calibration mystery, the existing 1919 evidence loop, and scientifically legitimate uncertainty. The five narrative recurrences are proposals, not approved scenes (issue37.md:2–4, 7–10, 12–34).
Best reference combination: Outer Wilds for knowledge-based progression, Return of the Obra Dinn for inference from evidence, Chants of Sennaar for revisable hypotheses, and The Witness for recognizing a rule before someone explains it.
These are design analogies, not experimental evidence that any specific mechanic guarantees conceptual change.
## 1. Competitor/reference analysis
The most useful distinction is between games that make players discover a rule, infer an explanation, and change a belief. Eddington needs all three, but has time for only one tightly connected chain.
### Highest-value references
Game
	Mechanism and source of the aha
	What to borrow / what not to copy
	
Outer Wilds
	Information itself unlocks progression. An earlier mystery becomes solvable when the player understands something new.
	Borrow: return to an unchanged object with new understanding. Avoid: the open-world scale and long exploration loops.
	
Return of the Obra Dinn
	Frozen scenes provide incomplete evidence; players infer identities and causes. Correct answers are confirmed in groups, rather than clue by clue.
	Borrow: an evidence ledger and delayed confirmation. Avoid: dozens of required deductions or waiting too long to validate a single measurement.
	
The Witness
	Puzzles implicitly teach rules through examples and carefully constructed exceptions. The recognition happens in the player's mind.
	Borrow: a simple example followed by a revealing variation. Avoid: prolonged obscurity and hintless bottlenecks.
	
Chants of Sennaar
	Players write provisional translations, recognize recurring symbols in new contexts, and eventually validate their hypotheses.
	Borrow: hypotheses that persist, recur, and can be revised. Avoid: an extensive dictionary or translation progression.
	
Heaven's Vault
	Ambiguous inscriptions permit interpretations that influence the protagonist's understanding; certainty is not immediately granted.
	Borrow: legitimate uncertainty and revisable interpretation. Avoid: treating alternative physical truths as equally valid narrative branches.
	
The Case of the Golden Idol
	Players gather clues and reconstruct an explanation by filling in missing parts themselves.
	Borrow: assemble a scientific conclusion from measured evidence. Avoid: reducing scientific uncertainty to a single magic correct sentence.
	

Outer Wilds is particularly relevant to the returning light-box motif: the physical object need not change; the player's understanding changes.
Chants of Sennaar offers a particularly useful production lesson: its developers deliberately repeat clues in multiple contexts so players can validate their own interpretations. A small, repeated scientific idea can therefore do more work than several newly introduced lessons. 
Nintendo+5

### Other valuable references
Game
	Mechanism and why it works
	Transfer / limitation
	
Her Story
	Search terms chosen by the player determine which interview fragments appear; the investigative question itself becomes a tool.
	Let players request specific records or comparisons. Do not build a huge searchable archive.
	
Baba Is You
	Rules are manipulable objects. An apparent impossibility becomes possible by reconsidering the system rather than the individual move.
	Make the player question an assumption about light or reference frames. No need for a general-purpose rule engine.
	
Papers, Please
	Repeated procedural checks become emotionally meaningful when following the rules conflicts with judgment and responsibility.
	Make rejecting a beautiful but unreliable plate a meaningful decision. Avoid excessive repetitive bureaucracy.
	
Disco Elysium — Thought Cabinet
	Ideas become explicit, internalized mental structures with gameplay consequences, sometimes beneficial and sometimes harmful.
	A smaller hypothesis notebook could visibly evolve. No need for skill modifiers or RPG progression.
	
Opus Magnum
	Players design, test, improve, and own their solutions rather than merely executing prescribed steps.
	Give limited but genuine control over measurement methods. Do not build an open-ended instrument simulator.
	
Kerbal Space Program
	Failed experiments expose the difference between intuitive motion and actual orbital mechanics.
	Allow a small safe-to-fail experiment and meaningful retry. Full orbital simulation is unnecessary.
	
Universe Sandbox
	Changing parameters produces observable consequences, teaching causal relationships through controlled counterfactuals.
	A few predetermined comparisons are enough; avoid a general astrophysical simulation.
	

Supporting examples: 
HER STORY+5

### Relativity games and tactile-puzzle references
Reference
	Mechanism
	Useful lesson and limitation
	
A Slower Speed of Light (MIT)
	Players collect orbs that progressively lower the simulated speed of light, making relativistic visual effects increasingly perceptible.
	Borrow: turn an invisible phenomenon into an embodied experience. Limit: the demonstration concerns special relativity, not gravitational deflection.
	
Velocity Raptor
	Near-light-speed puzzles expose length contraction, timing and visual effects; it distinguishes measured from observed appearances.
	Borrow: make reference frames and viewpoints explicit. Limit: do not transplant relativistic-velocity gameplay into a general relativity lesson.
	
Einstein's Playground
	An interactive special-relativity visualization built around observers, moving environments and clocks.
	Borrow: let players compare observers' descriptions of the same event. Limit: it is an educational visualization, not evidence that a full physics engine is necessary.
	
Lumino City
	Tangible environmental mechanisms make manipulating objects intrinsically enjoyable.
	Borrow: give the orrery, box and measuring instruments satisfying physical feedback. Limit: handmade spectacle alone does not produce scientific understanding.
	

These distinctions matter: MIT's A Slower Speed of Light, Velocity Raptor, and Einstein's Playground chiefly explore special relativity. Their interaction patterns are useful, but cannot be copied as direct demonstrations of general relativity. 
MIT Game Lab+3

Overall ranking for Eddington's particular problem: Chants of Sennaar and Obra Dinn are the strongest evidence-interface references; Outer Wilds and The Witness are the strongest conceptual-revelation references. The dedicated relativity games are most useful for presentation and frame-of-reference clarity.
## 2. Learning science mapped to mechanics
### Conceptual change requires more than a surprising contradiction
Posner, Strike, Hewson and Gertzog's 1982 framework identifies four conditions for adopting a new conception. The model was developed partly through research on learning relativity, making it unusually relevant here. 
Wiley Online Library

Learning principle
	Eddington implementation
	
Dissatisfaction
	Demonstrate Newton's predictive success first. Then expose a precise residual that deserves investigation—not an implausibly catastrophic failure.
	
Intelligibility
	Use the closed box to help players build a comprehensible alternative intuition about gravity and acceleration.
	
Plausibility
	Return to the box with light, and connect the new prediction to a real observable: apparent star positions near the Sun.
	
Fruitfulness
	Have the player use the alternative model to anticipate a previously unexplained observation, then test it against independent data.
	

Here are the complementary learning mechanisms:
Principle
	Concrete playable implementation
	
Predict–Observe–Explain (POE)
	Before the box experiment, record a prediction and a reason. Run the experiment. Afterwards, ask which assumption must be reconsidered.
	
Cognitive conflict
	Show a result that appears inconsistent with the player's expectation, but allow measurement error, an overlooked body, or a mistaken assumption as candidate explanations.
	
Refutation text
	Present a short, diegetic mentor's note: a reasonable existing claim, a specific reason it is incomplete, and a better explanation. Unlock it after experimentation rather than before.
	
Self-explanation
	Ask the player to link a conclusion to a specific observation: “Which result made you reconsider?” Prefer selecting an evidence card plus a brief explanation over repeating a taught phrase.
	
Productive failure
	Let the player attempt an initial judgment with incomplete evidence. Then introduce a missing comparison or calibration method, and let them revise.
	
Desirable difficulty
	Reuse a familiar measurement procedure in a different context, rather than teaching it again. Add conceptual difficulty, not microscopic clicking, hidden controls or arbitrary time pressure.
	

Critical qualification: cognitive conflict does not automatically create conceptual change. Chinn and Brewer identify multiple responses to anomalous evidence, most of which protect an existing belief—rejecting the data, reinterpreting it, or proposing auxiliary explanations. Thus a player who blames a discrepancy on misalignment is not necessarily failing; they may be reasoning appropriately. The design needs to let them test that explanation. 
Sage Journals

The supporting research is reasonably strong, though generally drawn from educational settings rather than short historical adventure games:
- POE explicitly elicits predictions and their reasoning before observation. 
Assessment Resource Banks
- Self-explanation can improve understanding beyond reliance on worked examples. 
Wiley Online Library
- A meta-analysis of productive failure/problem-solving-before-instruction found a moderate advantage over instruction-first approaches (Hedges' g=0.36g=0.36g=0.36); application depends on appropriate scaffolding. 
Tanmay Sinha, Manu Kapur, 2021
- A meta-analysis of refutation texts found a moderate learning benefit (g=0.41g=0.41g=0.41) over comparison conditions. 
PubMed
- Bjork's desirable difficulties are beneficial when they engage learnable processes, not when they simply make the experience harder. 
eScholarship

### The strongest concrete example: the same box, twice
The first encounter teaches that dropping a ball inside a sufficiently small closed cabin cannot, by itself, distinguish a stationary gravitational environment from a suitably accelerating cabin.
Later, the player returns to that same box and considers a pulse of light. Changing reference frames reveals how an observer accelerating with the cabin describes the light's trajectory.
The aha is not “the light curves, therefore Einstein is right.” It is:
“I thought the first experiment was only about falling objects. Now I see why the same reasoning forces me to reconsider light—and why an eclipse could test a quantitative prediction.”
That is a small, achievable conceptual reorganization. It also correctly stops short of deriving the full 1.75-arcsecond prediction from the box alone. 
einstein-online.info+2

## 3. The biggest risks: agreement without persuasion
The single greatest risk is scripted epistemology: the player performs scientific-looking actions, but the game has already decided what those actions mean.
This can produce completion without understanding. The player learns which option advances the story, not why one explanation is more convincing.
Six failure modes deserve attention:
Risk
	Warning sign
	Correction
	
The answer is announced
	Eddington explains relativity immediately after the demonstration.
	Allow the player to express the inference first; characters respond afterward.
	
Evidence is not player-owned
	The game supplies a final measurement unrelated to the selected plates.
	Preserve the connection between source plate, calibration, measurement and conclusion.
	
Newton is a strawman
	The mentor rejects evidence out of pride or ignorance.
	Give the mentor legitimate methodological objections that the player must address.
	
The anomaly is emotionally invisible
	Mercury's residual is just another number in a document.
	First establish the predictive precision that makes a small unexplained residual matter.
	
The correct answer is visibly privileged
	The game highlights 1.75″, rewards agreement, or blocks uncertainty.
	Permit “insufficient evidence” when justified; never make ideological allegiance the success condition.
	
The analogy substitutes for evidence
	Players treat the animated light box as experimental proof of GR.
	Separate thought experiments, theoretical predictions, actual observations and historical conclusions.
	

There is also a narrative risk: making scientific doubt equivalent to a lack of courage. A Newtonian character who wants better calibration before abandoning a successful theory is practicing science, not obstructing it.
The desired emotional change is better expressed as intellectual humility plus warranted confidence—not conversion to a favored authority.
## 4. Eight highest-leverage design moves
Ranked by recommended implementation priority, favoring cheap changes and reuse of existing Godot interactions. Costs are relative estimates, not assessments of the current codebase.
Rank
	What the player does
	Belief it moves
	Blind playtest question
	Cost
	
1. Prediction ledger
	Records an expected outcome, confidence level and short reason before seeing the eclipse evidence.
	From “the answer is known” to “my expectation is testable.”
	“What did you expect the measurement to show before you examined the plates, and why?”
	Low
	
2. Strong Newtonian case
	Inspects successful old predictions and the Mercury residual; considers measurement error, additional matter and model limitations.
	From “Newton failed” to “an excellent theory has a limited unexplained discrepancy.”
	“Why would a careful astronomer still trust Newtonian mechanics?”
	Low
	
3. Reuse Cambridge calibration
	Recognizes and applies the calibration lesson from the 1917 star-chart mismatch to a later plate.
	From “any shift is new physics” to “measurement artifacts must be excluded.”
	“How could an apparent star displacement arise without any gravitational light deflection?”
	Low
	
4. Evidence-linked conclusions
	Attaches a specific plate, measurement or observation to a provisional hypothesis in a notebook.
	From “authority determines truth” to “claims must be supported by evidence.”
	“Which observation most affected your conclusion, and why?”
	Low
	
5. Reject a tempting plate
	Encounters a visually persuasive but poorly focused or misaligned plate; accepts or rejects it using consistent quality criteria.
	From “the result I want is the best result” to “reliability matters more than agreement.”
	“Why might excluding a plate be more scientific than including it?”
	Low–medium
	
6. Two-pass closed-box experiment
	Compares gravity and acceleration using a ball; later returns to the same apparatus and compares observers' descriptions of a light pulse.
	From “gravity only concerns falling objects” to “gravity and reference frames matter for understanding light.”
	“What can the closed-box experiment establish, and what can't it establish?”
	Medium
	
7. Model comparison with uncertainty
	Overlays predictions of 0″, 0.87″ and 1.75″ with measured deflection and uncertainty, after performing the measurement.
	From “any bending proves Einstein” to “different physical models predict quantitatively different outcomes.”
	“Why would observing some light deflection not, by itself, distinguish the competing theories?”
	Medium
	
8. Independent evidence and revised judgment
	Compares Príncipe with Sobral, acknowledges disagreements or weaknesses, and writes a revised conclusion in the Cambridge coda.
	From “one decisive measurement proves a theory” to “confidence increases through accountable, converging evidence.”
	“Would the Príncipe observations alone justify your final confidence? Why?”
	Medium
	

### How to keep the measurement honest
The most important implementation constraint concerns moves 5–8.
Do not make a poor plate produce the correct answer merely because the player selected the scientifically appropriate option. The selected data should produce a defensible result, or an appropriately uncertain one.
A viable implementation can use a small curated dataset, fixed underlying star positions and plate-quality metadata. The player controls which observations are admitted and how measurements are checked. The resulting uncertainty must remain traceable to those choices, without changing historical observations to reward a preferred conclusion.
If selected evidence is inconclusive, the player should still progress. The continuation can involve requesting independent observations rather than choosing the correct theory as a password.
For blind testing, recruit players unfamiliar with the story, provide no coaching and record their actual choices. Ask the associated open-ended question after play, using a subset of questions per participant to avoid fatigue. Score conceptual reasoning, not whether the participant repeats the words “general relativity.”
A particularly strong evaluation is a transfer test: give players a new fictional observation with different error bars and ask whether it distinguishes the models. Someone who can reason correctly about unfamiliar evidence has demonstrated more than recall of the ending.
## 5. Relativity-specific misconceptions and historical pitfalls
Do not teach
	Scientifically responsible framing
	
“Light bends because photons have mass.”
	Photons have zero rest mass. In GR, light follows null paths through curved spacetime. An older Newtonian corpuscle model offers a historically relevant comparison, not the modern explanation.
	
“Newton predicts zero deflection.”
	Zero represents a particular simplified assumption. A Newtonian-style corpuscular treatment predicts approximately 0.87″ at the solar limb; full GR predicts approximately 1.75″.
	
“Newton calculated 0.87″ himself.”
	Historically inaccurate. The Newtonian-style result has a separate calculation history, notably including Soldner.
	
“Einstein always predicted 1.75″.”
	Einstein's 1911 calculation gave approximately the half-value; his full GR treatment later doubled the prediction. That development is historically and conceptually valuable.
	
“The equivalence principle proves GR.”
	The local equivalence principle provides a powerful starting point. The full quantitative 1.75″ prediction also involves the geometry of spacetime.
	
“The accelerating-box light path curves in every reference frame.”
	Its description depends on the observer's frame. Clearly distinguish the accelerating cabin's coordinates from an inertial frame.
	
“The eclipse measured the deflection of one visible beam.”
	Astronomers inferred small apparent shifts in stellar positions by comparing photographic observations and accounting for instrumental effects.
	
“Mercury's 43″ was its total precession.”
	Approximately 43 arcseconds per century was the unexplained residual after accounting for known contributions—not the total precession and not a starlight-deflection measurement.
	
“The 1919 eclipse proved Einstein beyond doubt.”
	The campaign provided important evidence favoring GR, with limitations in weather, optics, measurement and analysis. Subsequent tests strengthened the case.
	

Historical note: the original eclipse paper explicitly set out the three alternatives of no deflection, Newtonian-style half-deflection and full GR deflection. Its abstract is an excellent reference for the in-game model comparison. 
MapleScholar+2

The Royal Society's archival record also confirms the two-site structure, cloudy conditions at Príncipe, differences in photographic quality at Sobral, and the November 6, 1919 announcement. The weaker Sobral astrographic observations are particularly useful for demonstrating why selecting data demands scrutiny. 
catalogues.royalsociety.org+2

Three production safeguards follow:
- Label the box's visible light-path animation as a time/space-exaggerated illustration. Do not suggest that a real small box would display detectable curvature to the naked eye.
- Keep the distinction between the physical 1919 setting and the educational visualization. Do not introduce anachronistic laser apparatus into the historical scene.
- For historical numbers and reported statements, retain the brief's HISTORICAL_RECORD / RECONSTRUCTION / FICTION / DISPUTED classification (issue37.md:23–28).

## 6. Recommended 30–40 minute experience
Rather than adding five new chapters, reuse the approved settings and props to deliver three conceptual turns.
0–10 min

Cambridge — trust with a crack
Keep the ordinary star-chart calibration mystery intact. Introduce Newton's record of success and Mercury's already-known residual through the orrery or documents. The player learns why both confidence and caution are rational.

10–15 min

The box — a new intuition
One short interactive sequence, revisited or extended through the light experiment. The goal is a plausible new question, not a complete derivation of GR.

15–32 min

Príncipe — the evidence must survive scrutiny
Preserve planning, exposure timing, clouds, darkroom work, plate selection and measurement. The player compares model predictions against an estimate whose limitations they understand.

32–40 min

Cambridge coda — an earned revision
The mentor's earlier concern about calibration returns. Independent results can strengthen or qualify the player's conclusion. Their final judgment acknowledges both the evidence and its limits.

These time allocations are proposed pacing targets, not confirmed implementation requirements.
### Final design decision
For the first production iteration, implement moves 1–5 using the existing narrative and measurement interfaces before developing the more ambitious box visualization. Then blind-test whether players can explain the move from measurement to inference. Build moves 6–8 where the tests show a specific conceptual gap.
The central success criterion is not whether the player chooses 1.75″. It is whether the player can say, in their own words:
Newtonian mechanics deserved my confidence. The discrepancy deserved investigation. The alternative gave us a testable prediction. The measurements—after checking their limitations—gave me reasons to revise my judgment.
That is the scientific version of the 醍醐味 the Owner is aiming for: the delight of recognizing that an idea you initially resisted explains something you have now understood for yourself.
The existing narrative brief already supports this arc and explicitly warns against replacing gameplay with lectures or oversized new physics systems (issue37.md:30–34). The recommendation above is a design proposal, not a claim that those scenes or mechanics have been approved or implemented.