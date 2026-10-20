# Oracle final source and visual review

Transport: Ego-lite, ChatGPT UI Pro. [Conversation](https://chatgpt.com/c/6ad6b188-c848-83ee-8476-bb6921c674e1).

Source commit: `9b6952dbf5b843152b911e1696bbbfc23557345c`.
Raw-source digest: `b7b2bb734e8a7be769336b7f27f22454f6ffe497880cd5bc6a88b4b390acf6f7`.

The completed independent response follows as visible-page text. The reviewer did not rerun Godot; producer runtime results are recorded separately in M3_VERIFICATION.md. No human playtest is claimed.

No blocking findings.

Final implementation commit: 9b6952dbf5b843152b911e1696bbbfc23557345c
Verified raw-source digest: b7b2bb734e8a7be769336b7f27f22454f6ffe497880cd5bc6a88b4b390acf6f7

Independently verified

Source integrity and scope. All 47 raw source files match their manifest hashes. Recomputing SHA-256 over the compact, sorted JSON file-hash map produces the digest above. Comparing the ZIP bytes against the earlier reviewed bundle confirms exactly four changed files: the sky shader, both bot scripts, and test_coda.gd. Main/UI, simulation, Judgment, and Director-owned text are byte-identical to that earlier bundle. Source reviewed:
m3-final-source.zip
.

Evidence integrity. All 50 evidence-manifest entries match their raw hashes, with no missing or unlisted evidence files. All 23 original PNGs are 1600×900, and the three separately attached PNGs match their ZIP counterparts byte-for-byte. Evidence reviewed:
m3-final-evidence.zip
.

Sky visuals. I inspected all five requested original before/after pairs: careful 05, 06, 06b and rushed 05, 06. The final captures remove the square background cells and show a slightly darker sky. Thick local cloud suppresses stars consistently with the corona; thinner regions reveal them together. Careful 06b retains an immediately identifiable corona ring and nearby field stars. The final shader uses the same cloud visibility and compositing path for these elements.

Ending and coda visuals. I inspected the careful and honest collapsed/expanded endings and all nine coda frames. Both final ending first views fit the viewport without scrolling and present title → cable → Eddington’s response → three evidence bullets, followed by the history toggle, with the existing buttons visible. The expanded captures show the toggle working and the historical section opening into scrollable content. Source comparison confirms preservation of the full history and fiction text, including material below the expanded screenshots’ visible area. The coda frames show the opening, workbook prompt and opened workbook, loupe prompt, Ashby and Kit dialogue entries, lamp-out, and completed ending.

Flow, input, and pause behavior. The source retains the prologue-only coda, required workbook-before-loupe order, cached Judgment inputs, eased camera, Kit close, lamp/fade sequence, and direct-1919 bypass. The honest continuation helper waits for both the required phase and transition completion, leaves coda dialogue to its parent, and has no reachable handler or teleport fallback. The strengthened pause regression starts with lit lamps, holds beyond the full transition duration, checks that ending has not begun, and verifies extinguishing and completion after resuming.

Supplied execution evidence checked

The route logs and receipts agree on these outcomes:

| Route | Endpoint | Score | Recorded result |
|---|---|---:|---|
| Honest | ENDING | 4 | Five coda checks true; no failures |
| Tidy | PREP | — | Established endpoint retained; no failures |
| Accuse | PREP | — | Established endpoint retained; no failures |
| Careful | ENDING | 4 | Zero stuck events; new-sky restart recorded |
| Rushed | ENDING | 0 | Zero stuck events |
| Cherry | ENDING | 3 | Zero stuck events |

All six native exit receipts report 0. The eight suite receipts agree with their logs, including coda 59/0; bridge pause reports 6/0. The supplied layout result reports 648 px within 740 px, and the export log reaches completion. Careful’s baseline/final receipts preserve four exposures, selection 1/2/4, and the same score-4 ending despite the disclosed 12 → 9 available-holder difference.

Review limits: I independently checked the source, hashes, original rendered images, and supplied execution evidence; I did not rerun Godot. Coda captures show first authored entries, while the 12 grade/clean/measured combinations, both Kit tones, and fade-pause behavior are supported by inspected source/tests and their supplied results. The two skipped honest viewer captures receive no visual credit. Baseline darkroom remains context only. No credit is assigned to the aborted attempt, teardown/IMK warnings, human playtesting, reading-time or pacing validation, or exported-app playtesting.
