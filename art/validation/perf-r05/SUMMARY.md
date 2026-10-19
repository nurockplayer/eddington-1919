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
| shelter | 8.38 | 7.02 |
| coelostat | 8.34 | 6.90 |
| house | 8.33 | 7.72 |
| totality_sky | 8.39 | 8.54 |
| totality_horizon | 8.33 | 6.59 |
| darkroom | 8.33 | 6.77 |

## frame p95 ms

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 10.60 | 11.42 |
| shelter | 9.20 | 10.38 |
| coelostat | 9.22 | 12.57 |
| house | 9.19 | 11.61 |
| totality_sky | 9.77 | 13.82 |
| totality_horizon | 8.83 | 11.95 |
| darkroom | 8.97 | 12.06 |

## forced avg ms

| bookmark | r04 | r05 | spread (forced avg, min–max) |
|---|---|---|---|
| arrival | 2.77 | 3.60 | r04 2.72–2.78; r05 3.48–4.04 |
| shelter | 2.72 | 3.74 | r04 2.71–2.73; r05 3.73–3.80 |
| coelostat | 2.60 | 3.62 | r04 2.59–2.61; r05 3.52–3.64 |
| house | 2.46 | 3.21 | r04 2.42–2.46; r05 3.20–3.27 |
| totality_sky | 2.37 | 2.43 | r04 2.04–2.39; r05 2.25–2.54 |
| totality_horizon | 2.49 | 3.42 | r04 2.49–2.51; r05 3.41–3.43 |
| darkroom | 3.03 | 4.31 | r04 3.02–3.18; r05 4.27–4.78 |

## forced p95 ms

| bookmark | r04 | r05 |
|---|---|---|
| arrival | 3.14 | 3.75 |
| shelter | 3.02 | 3.94 |
| coelostat | 2.79 | 3.88 |
| house | 2.57 | 3.37 |
| totality_sky | 3.35 | 3.18 |
| totality_horizon | 2.72 | 3.57 |
| darkroom | 3.26 | 4.57 |
