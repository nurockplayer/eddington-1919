# Performance summary (v01, r03, r04)

Godot 4.7.2-stable (official) · Apple M2 Pro (Apple8) · viewport 1600×900 · seed 7 · 3 repetitions per build (median shown).

Wall-clock frame time is capped by the display refresh (~8.3 ms); **forced-draw** renders without presenting and is the uncapped render-cost figure. Geometry and draw-call changes are reported separately and are not frame-rate claims.


## draw calls

| bookmark | v01 | r03 | r04 |
|---|---|---|---|
| arrival | 424 | 427 | 395 |
| shelter | 286 | 288 | 271 |
| coelostat | 207 | 207 | 189 |
| house | 160 | 160 | 142 |
| totality_sky | 153 | 153 | 179 |
| totality_horizon | 194 | 194 | 161 |
| darkroom | 374 | 374 | 305 |

## primitives (k)

| bookmark | v01 | r03 | r04 |
|---|---|---|---|
| arrival | 417 | 417 | 222 |
| shelter | 292 | 293 | 169 |
| coelostat | 326 | 323 | 168 |
| house | 277 | 277 | 145 |
| totality_sky | 100 | 100 | 130 |
| totality_horizon | 302 | 302 | 93 |
| darkroom | 497 | 497 | 136 |

## frame avg ms

| bookmark | v01 | r03 | r04 |
|---|---|---|---|
| arrival | 8.32 | 8.37 | 8.33 |
| shelter | 8.33 | 8.34 | 8.38 |
| coelostat | 8.34 | 8.45 | 8.34 |
| house | 8.33 | 8.70 | 8.33 |
| totality_sky | 8.41 | 8.34 | 8.39 |
| totality_horizon | 8.45 | 8.38 | 8.33 |
| darkroom | 8.34 | 8.38 | 8.33 |

## frame p95 ms

| bookmark | v01 | r03 | r04 |
|---|---|---|---|
| arrival | 10.40 | 10.05 | 10.60 |
| shelter | 9.29 | 9.15 | 9.20 |
| coelostat | 9.08 | 9.46 | 9.22 |
| house | 9.35 | 11.02 | 9.19 |
| totality_sky | 9.17 | 9.25 | 9.77 |
| totality_horizon | 9.32 | 9.38 | 8.83 |
| darkroom | 9.08 | 9.38 | 8.97 |

## forced avg ms

| bookmark | v01 | r03 | r04 | spread (forced avg, min–max) |
|---|---|---|---|---|
| arrival | 2.73 | 2.76 | 2.77 | v01 2.71–4.27; r03 2.74–2.77; r04 2.72–2.78 |
| shelter | 2.57 | 2.63 | 2.72 | v01 2.55–2.60; r03 2.62–2.63; r04 2.71–2.73 |
| coelostat | 2.54 | 2.58 | 2.60 | v01 2.51–2.59; r03 2.58–2.63; r04 2.59–2.61 |
| house | 2.67 | 2.79 | 2.46 | v01 2.43–2.92; r03 2.50–2.80; r04 2.42–2.46 |
| totality_sky | 1.97 | 1.90 | 2.37 | v01 1.94–2.11; r03 1.89–1.90; r04 2.04–2.39 |
| totality_horizon | 2.51 | 2.52 | 2.49 | v01 2.49–2.91; r03 2.48–3.03; r04 2.49–2.51 |
| darkroom | 3.06 | 3.28 | 3.03 | v01 3.02–3.24; r03 3.20–3.75; r04 3.02–3.18 |

## forced p95 ms

| bookmark | v01 | r03 | r04 |
|---|---|---|---|
| arrival | 2.94 | 2.92 | 3.14 |
| shelter | 2.68 | 2.76 | 3.02 |
| coelostat | 2.71 | 2.75 | 2.79 |
| house | 3.38 | 3.85 | 2.57 |
| totality_sky | 2.48 | 2.10 | 3.35 |
| totality_horizon | 2.97 | 2.65 | 2.72 |
| darkroom | 3.26 | 4.57 | 3.26 |
