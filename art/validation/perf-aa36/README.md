# AA polish 36 · Shelter transition and comparator

**F10 and S9 remain open.** The live input sequence passed seven state checks. Two GPU jobs yielded nine matched timing attempts, all with managed host overlap. The benchmark returned a raw GPU p95 of 0.0 ms in every view on this Metal run, so usable GPU p95 is unavailable.

## Main reproduction and live input

Measured tree `c078285d324fdd2f7f989b037dce498515175ba7` was identical to `origin/main`. The existing `totality_live` awaited second contact before sampling, called the shutter handler directly, and suspended gameplay during forced draws. Its output lacked the countdown-to-contact input handoff. The existing bookmarks supplied the comparison and frozen stages. A separate clip ran the game continuously from 0.75 seconds before contact, sending Space through Godot's input path and checking the resulting state.

The 1600×900 clip spans 447 frames, 7.45 seconds at fixed 60 fps. Space was blocked during contact at frame 62. At frame 184, the roof had rolled away and Space opened the first exposure. Space closed it at frame 228 and was blocked during the plate change at frame 248. Space opened the next plate at frame 355, then closed it at frame 417 with two recorded plates.

## Exploratory native-size timings

Apple M2 Pro, Godot 4.7.2 Metal Forward+, seed 7, standard quality, default 4× MSAA, locale zh_TW, text scale 1.0, reduced motion off. Every process used the existing 20-frame settle, 180-frame render-timing phase and 240 non-presenting forced draws. The raw JSON confirms the native viewport sizes. Matched groups alternated starting resolution and view order. The frame wall clock is display-capped.

| View | Size | Forced avg median (ms) | Forced p95 median (ms) | Worst forced p95 (ms) | Worst attempt | CPU p95 median / max (ms) |
| --- | --- | ---: | ---: | ---: | --- | ---: |
| `totality_sky` · historical comparator | 720p | 4.13 | 6.43 | 7.41 | initial 1 | 0.62 / 0.90 |
| `under_roof_gameplay` · roof and live HUD | 720p | 3.98 | 6.26 | 7.23 | rerun 3 | 0.57 / 0.60 |
| `play_p12` · contact +1.2 s | 720p | 4.11 | 6.46 | 7.33 | initial 1 | 0.53 / 1.33 |
| `play_p25` · contact +2.5 s | 720p | 4.09 | 6.44 | 7.47 | initial 1 | 1.10 / 1.40 |
| `totality_sky` · historical comparator | 1080p | 7.97 | 10.46 | 11.82 | initial 2 | 0.45 / 0.79 |
| `under_roof_gameplay` · roof and live HUD | 1080p | 7.45 | 9.45 | 11.46 | initial 2 | 0.50 / 0.60 |
| `play_p12` · contact +1.2 s | 1080p | 8.34 | 10.34 | 12.04 | rerun 1 | 0.94 / 1.18 |
| `play_p25` · contact +2.5 s | 1080p | 8.30 | 11.18 | 11.91 | rerun 4 | 1.04 / 1.15 |

**720p floor estimate.** The worst observed forced p95 was 7.47 ms at contact +2.5 s. The established ×3 GTX 1650-class proxy gives 22.41 ms, roughly 44.6 fps against the 33.33 ms / 30 fps floor. The estimate is exploratory because zero of three required matched groups were clean.

**Measured 1080p on M2 Pro.** The worst observed forced p95 was 12.04 ms at contact +1.2 s. Contact +2.5 s had the highest median at 11.18 ms and is a candidate for clean repeat profiling. Forced cost rose with resolution while geometry was broadly stable. GPU stage attribution and live frame pacing remain unresolved.

## Evidence and checks

The initial matrix and clip ran 2026-11-27 14:20:41–14:23:32 JST. The rerun sampled 2026-11-27 14:36:52–14:41:50 JST. Both GPU jobs exited 0. The rerun's final line was `AA36 clean matched attempts: 0 of 3 needed`. Active managed work appeared at a sampling boundary in every matched attempt.

The KIOXIA index, 72 per-view benchmark JSON files, exact commands, input event log and clip are under `/Volumes/KIOXIA/eddington-1919-cache/director/accept/aa-36/c078285d324fdd2f7f989b037dce498515175ba7/`. The remaining acceptance evidence needs a quiet host window for three matched groups and a supported GPU timing source.

`test_bench_stats` passed 10 checks with 0 failures after `--check-only` exited 0. Both the capture and benchmark exercised the unmodified main tree. There is no implementation to revert for this evidence-only change.
