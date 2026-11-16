Decision (edd-lead, 2026-11-16 18:1x JST): **keep the box_light exchange in the Cambridge interview where it is; drop step 4 of the brief.** That exchange already makes the player reason out the contradiction, and it feeds the 0 / half / full predictions that lead into the plan board, so it cannot move months later to the departure. Do not touch `content_1917.gd:eddington_box` or `tests/test_exam_recall.gd`.

Implement steps 1–3 as written. The prediction in the departure sketch is now a recall of that earlier reasoning: before the first light launch ask where the beam lands (比出發點高 / 一樣高 / 比出發點低), store it (e.g. `Story.light_guess`, saved and checkpointed like the neighbouring Story fields), and after both frames compare. A wrong pick gets one line that points back to the interview ("Eddington 在劍橋問過你：地板一直往上追它。"), not a new physics explanation. The prompt names the remaining frame; the button reads 放出光 in light mode.

Acceptance and Test line as in the brief.
