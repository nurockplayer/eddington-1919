# Performance summary (main, r06)

Godot 4.7.2-stable (official) · Apple M2 Pro (Apple8) · viewport 1600×900 · seed 7 · 5 repetitions per build (median shown).

Wall-clock frame time is capped by the display refresh (~8.3 ms); **forced-draw** renders without presenting and is the uncapped render-cost figure. Geometry and draw-call changes are reported separately and are not frame-rate claims.


## draw calls

| bookmark | main | r06 |
|---|---|---|
| arrival | 391 | 389 |
| shelter | 297 | 301 |
| coelostat | 201 | 203 |
| house | 158 | 158 |
| totality_sky | 190 | 192 |
| totality_horizon | 156 | 156 |
| darkroom | 298 | 298 |
| eddington_talk | 354 | 355 |
| cottingham_talk | 219 | 221 |

## primitives (k)

| bookmark | main | r06 |
|---|---|---|
| arrival | 208 | 205 |
| shelter | 177 | 195 |
| coelostat | 168 | 186 |
| house | 142 | 142 |
| totality_sky | 119 | 112 |
| totality_horizon | 88 | 88 |
| darkroom | 131 | 131 |
| eddington_talk | 202 | 220 |
| cottingham_talk | 166 | 183 |

## frame avg ms

| bookmark | main | r06 |
|---|---|---|
| arrival | 8.38 | 8.33 |
| shelter | 8.34 | 8.33 |
| coelostat | 8.35 | 8.34 |
| house | 8.34 | 8.34 |
| totality_sky | 8.33 | 8.33 |
| totality_horizon | 8.33 | 8.33 |
| darkroom | 8.38 | 8.33 |
| eddington_talk | 8.34 | 8.33 |
| cottingham_talk | 8.33 | 8.34 |

## frame p95 ms

| bookmark | main | r06 |
|---|---|---|
| arrival | 10.85 | 9.94 |
| shelter | 9.89 | 8.93 |
| coelostat | 10.13 | 9.56 |
| house | 9.42 | 8.97 |
| totality_sky | 9.04 | 8.95 |
| totality_horizon | 9.41 | 8.89 |
| darkroom | 9.45 | 8.93 |
| eddington_talk | 9.65 | 9.13 |
| cottingham_talk | 9.38 | 8.98 |

## forced avg ms

| bookmark | main | r06 | spread (forced avg, min–max) |
|---|---|---|---|
| arrival | 4.27 | 4.63 | main 3.54–8.86; r06 3.86–5.12 |
| shelter | 4.51 | 4.92 | main 3.75–9.76; r06 4.09–5.48 |
| coelostat | 4.32 | 4.71 | main 3.56–8.46; r06 3.93–5.24 |
| house | 3.92 | 3.95 | main 3.25–7.64; r06 3.25–4.54 |
| totality_sky | 2.71 | 2.79 | main 2.30–5.29; r06 2.30–2.91 |
| totality_horizon | 4.18 | 4.26 | main 3.46–8.47; r06 3.49–4.67 |
| darkroom | 4.31 | 5.28 | main 4.28–9.58; r06 4.28–5.51 |
| eddington_talk | 3.86 | 5.21 | main 3.78–8.65; r06 4.18–5.57 |
| cottingham_talk | 3.66 | 4.84 | main 3.59–4.78; r06 3.96–5.16 |

## forced p95 ms

| bookmark | main | r06 |
|---|---|---|
| arrival | 5.45 | 5.75 |
| shelter | 5.59 | 5.91 |
| coelostat | 5.23 | 5.82 |
| house | 4.90 | 4.88 |
| totality_sky | 4.02 | 4.04 |
| totality_horizon | 5.29 | 5.45 |
| darkroom | 4.48 | 6.38 |
| eddington_talk | 4.07 | 6.25 |
| cottingham_talk | 3.82 | 6.08 |
