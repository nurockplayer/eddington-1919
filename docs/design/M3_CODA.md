# M3 — Príncipe coda and 1919 legibility (Director, 2026-10-20)

## Why
- M1 and M2 load the player with two people: Ashby ("convince me with a clean plate, not a good story") and Kit ("tell me
  what the sky looked like — the one you saw yourself"). The 1919 ending never answers either of them. It is a long,
  even wall of evidence, Eddington's lines and history.
- The totality sky, the moment that decides everything, has blocky square background stars that read through cloud.
  That works against the one judgement the player must make: is the cloud thin enough right now?

## Coda (prologue players only; direct-1919 players keep the v0.1 ending unchanged)
After Eddington's response to the telegram (the existing judgment dialogue), and before the ending screen:
1. `ContentCoda.opening()`. Eddington leaves and the player is alone in the darkroom at night. Lamp lit, Cottingham gone.
2. Workbook:
   - If it is not yet written, it becomes the one required action. It is highlighted, with the objective 「在工作簿記下你看到的天空」 and `principe_workbook(bond_tone)`.
   - If it was written during the night phase, play `workbook_again()`.
3. The loupe (always present for prologue players) is the second interaction. `ashby_answer(fit, clean, measured_any)` uses the same grade as the ending.
4. `kit_close(bond_tone)`. The lamp goes out, the scene fades, then the ending screen.

## Ending screen
- Lead with the title, the telegram and Eddington's response.
- Next, show the evidence as 3 short bullets.
- Put the long "歷史上" block and the fiction/history note behind a 「歷史上發生了什麼」 toggle or button, so nothing is lost.
- Same buttons as now.

## Totality legibility (no sim or score change)
- Background stars must be round and soft, not square cells.
- Cloud density must attenuate background and field stars as strongly as it hides the corona. A thick cloud hides them; a gap reveals the field stars by the Sun at the same moment the corona ring appears.
- The totality sky should be a little darker, in line with the historical "deep twilight" (cosmetic).
- Keep the gap frame `careful_06b` instantly readable.
