# Performance summary (r04, r05)

Godot 4.7.2-stable (official) · Apple M2 Pro (Apple8) · viewport 1600×900 · seed 7 · 3 repetitions per build (median shown).

Wall-clock frame time is capped by the display refresh (~8.3 ms); **forced-draw** renders without presenting and is the uncapped render-cost figure. Geometry and draw-call changes are reported separately and are not frame-rate claims.


## draw calls

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 395 | 391 |
| shelter | 271 | 297 |
| coelostat | 189 | 201 |
| house | 142 | 158 |
| totality_sky | 179 | 190 |
| totality_horizon | 161 | 156 |
| darkroom | 305 | 298 |

## primitives (k)

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 222 | 208 |
| shelter | 169 | 177 |
| coelostat | 168 | 168 |
| house | 145 | 142 |
| totality_sky | 130 | 119 |
| totality_horizon | 93 | 88 |
| darkroom | 136 | 131 |

## frame avg ms

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 8.33 | 8.33 |
| shelter | 8.38 | 8.34 |
| coelostat | 8.34 | 8.33 |
| house | 8.33 | 8.42 |
| totality_sky | 8.39 | 8.33 |
| totality_horizon | 8.33 | 8.33 |
| darkroom | 8.33 | 8.57 |

## frame p95 ms

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 10.60 | 10.03 |
| shelter | 9.20 | 9.18 |
| coelostat | 9.22 | 8.94 |
| house | 9.19 | 9.11 |
| totality_sky | 9.77 | 9.10 |
| totality_horizon | 8.83 | 9.40 |
| darkroom | 8.97 | 11.85 |

## forced avg ms

| bookmark | r04 | r05 | spread (forced avg, min–max) |
|---|---|---|---|
| arrival | 2.77 | 3.58 | r04 2.72–2.78; r05 3.58–3.64 |
| shelter | 2.72 | 3.82 | r04 2.71–2.73; r05 3.75–3.83 |
| coelostat | 2.60 | 3.64 | r04 2.59–2.61; r05 3.60–3.70 |
| house | 2.46 | 3.36 | r04 2.42–2.46; r05 3.29–3.99 |
| totality_sky | 2.37 | 2.32 | r04 2.04–2.39; r05 2.30–2.33 |
| totality_horizon | 2.49 | 3.49 | r04 2.49–2.51; r05 3.43–3.51 |
| darkroom | 3.03 | 4.93 | r04 3.02–3.18; r05 4.39–5.13 |

## forced p95 ms

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 3.14 | 3.93 |
| shelter | 3.02 | 4.01 |
| coelostat | 2.79 | 3.87 |
| house | 2.57 | 3.60 |
| totality_sky | 3.35 | 2.44 |
| totality_horizon | 2.72 | 3.62 |
| darkroom | 3.26 | 5.91 |
