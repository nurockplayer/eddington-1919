# A12: 畫質 低 vs 標準 (G4 benchmark, 1919 bookmarks)

Run 2026-11-03 13:59–14:01 JST on the M2 Pro dev Mac at main bb407c2, 1600×900 window, interleaved low/standard × 3 reps; host load 7–11 (other projects running), so compare paired medians only. Metric per the perf method: `forced_draw_ms` (wall frame time is display-capped at ~8.3–10 ms).

| bookmark | forced p95 std → low (ms) | VRAM std → low (MB) |
|---|---|---|
| arrival | 3.94 → 2.02 | 328 → 195 |
| shelter | 4.08 → 2.18 | 328 → 195 |
| coelostat | 3.97 → 2.12 | 328 → 195 |
| house | 3.28 → 1.86 | 328 → 195 |
| totality_sky | 2.67 → 1.43 | 322 → 195 |
| totality_horizon | 3.52 → 1.84 | 362 → 195 |
| darkroom | 4.26 → 2.16 | 362 → 195 |
| eddington_talk | 4.25 → 2.57 | 368 → 195 |
| cottingham_talk | 3.87 → 2.17 | 368 → 195 |

Low cuts render cost ~45–50% and VRAM ~40–47%; draw calls unchanged (156–389). Not covered: the Cambridge 1917 chapter (no benchmark bookmarks there) and any machine slower than the dev Mac — a minimum-spec claim needs a run on target hardware (Steam Deck class), which waits on B2/B10.
Screenshots were deleted after the run (one-off data); JSON + provenance kept.
