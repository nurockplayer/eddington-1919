# System requirements and FPS targets (A12)

Owner 2026-11-04 00:3x JST: the Steam baseline is the hardware most Steam players use. Source: Steam Hardware & Software Survey, October 2026, read 2026-11-04 00:36 JST (cx-exec search run `search-20261104-003446-23728`).

## What Steam players have (October 2026)

- OS: Windows 93.70% (Windows 11 72.51%, Windows 10 21.11%), Linux 3.95%, macOS 2.35%.
- Top GPUs: RTX 3060 and RTX 5070 (3.78% each), RTX 4060 Laptop, RTX 4060, RTX 3050, RTX 5060, RTX 5060 Ti, RTX 5060 Laptop, GTX 1650, RTX 4060 Ti. The named integrated families (Iris Xe, UHD, Radeon Graphics) add up to 7.71% at least.
- Most common: 8 GB VRAM (26.92%), 16 GB RAM (41.42%), 8 CPU cores (28.68%), 1920×1080 primary display (50.23%). 90.63% of GPUs are DirectX 12 class.

## Targets

| | Recommended | Minimum |
|---|---|---|
| OS | Windows 10/11 64-bit | Windows 10 64-bit |
| GPU | RTX 4060 class, 8 GB VRAM | GTX 1050 Ti / GTX 1650 class, 4 GB VRAM, Vulkan 1.2 |
| RAM | 16 GB | 8 GB |
| CPU | 6–8 cores | 4 cores |
| Target | 60 fps at 1920×1080, 畫質 標準 | 30 fps at 1280×720, 畫質 低 |

macOS (already exported): Apple silicon M1 or later, macOS 11.

## Margin from the dev Mac benchmark (estimate, not a measurement)

The G4 benchmark (`art/validation/perf-a12/SUMMARY.md`, 2026-11-03 JST, M2 Pro, 1600×900) gives the worst forced-draw p95 over all 14 bookmarks of both chapters as 4.26 ms on 標準 and 2.57 ms on 低. VRAM peaks at 368 MB on 標準 and 195 MB on 低.

- Recommended: scaling 4.26 ms to 1080p (×1.44 pixels) gives ≈ 6.1 ms on the M2 Pro. An RTX 4060 is faster than the M2 Pro GPU, so 60 fps (16.7 ms) leaves a margin of more than 2.5×.
- Minimum: a GTX 1050 Ti has about a third of the M2 Pro GPU's raster throughput (rough cross-vendor ratio). Scaling 2.57 ms to 720p (×0.64) and by ×3 gives ≈ 5 ms, against 33.3 ms for 30 fps. Even 1080p 低 (≈ 11 ms) stays inside 60 fps.
- VRAM: 195–368 MB is far below both 4 GB and 8 GB.

These are GPU-side estimates across vendors and APIs (Metal against Vulkan/D3D12). CPU-side frame time and shader-compile hitches are not covered. Confirmation on real Windows hardware is part of the exported-build playtest (A11/B10); if a minimum-class machine misses 30 fps on 低, lower the minimum row rather than the targets.
