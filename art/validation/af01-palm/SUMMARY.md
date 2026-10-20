# Performance summary (prim, kit)

Godot 4.7.2-stable (official) · Apple M2 Pro (Apple8) · viewport 1600×900 · seed 7 · 3 repetitions per build (median shown).

Wall-clock frame time is capped by the display refresh (~8.3 ms); **forced-draw** renders without presenting and is the uncapped render-cost figure. Geometry and draw-call changes are reported separately and are not frame-rate claims.


## draw calls

| bookmark | prim | kit |
|---|---|---|
| arrival | 389 | 255 |
| shelter | 301 | 221 |
| coelostat | 203 | 172 |
| house | 158 | 120 |
| totality_sky | 194 | 67 |
| totality_horizon | 156 | 61 |
| darkroom | 298 | 112 |
| eddington_talk | 355 | 258 |
| cottingham_talk | 221 | 173 |

## primitives (k)

| bookmark | prim | kit |
|---|---|---|
| arrival | 205 | 235 |
| shelter | 195 | 219 |
| coelostat | 186 | 214 |
| house | 142 | 170 |
| totality_sky | 116 | 139 |
| totality_horizon | 88 | 122 |
| darkroom | 131 | 152 |
| eddington_talk | 220 | 243 |
| cottingham_talk | 184 | 214 |

## frame avg ms

| bookmark | prim | kit |
|---|---|---|
| arrival | 8.33 | 8.33 |
| shelter | 8.38 | 8.34 |
| coelostat | 8.34 | 8.34 |
| house | 8.34 | 8.38 |
| totality_sky | 7.87 | 8.38 |
| totality_horizon | 8.34 | 8.34 |
| darkroom | 8.33 | 8.33 |
| eddington_talk | 8.33 | 8.33 |
| cottingham_talk | 8.34 | 8.38 |

## frame p95 ms

| bookmark | prim | kit |
|---|---|---|
| arrival | 10.13 | 10.09 |
| shelter | 9.72 | 9.68 |
| coelostat | 9.88 | 9.76 |
| house | 9.53 | 9.72 |
| totality_sky | 10.04 | 9.67 |
| totality_horizon | 10.17 | 9.81 |
| darkroom | 9.69 | 9.71 |
| eddington_talk | 9.47 | 9.52 |
| cottingham_talk | 9.88 | 9.81 |

## forced avg ms

| bookmark | prim | kit | spread (forced avg, min–max) |
|---|---|---|---|
| arrival | 5.45 | 5.57 | prim 5.44–5.48; kit 4.84–7.10 |
| shelter | 6.03 | 5.73 | prim 5.51–6.27; kit 5.04–7.21 |
| coelostat | 5.64 | 5.65 | prim 5.53–5.78; kit 5.55–7.20 |
| house | 4.33 | 4.50 | prim 4.19–4.40; kit 4.40–5.81 |
| totality_sky | 3.47 | 3.62 | prim 3.11–4.50; kit 3.61–3.77 |
| totality_horizon | 4.87 | 4.60 | prim 4.60–6.59; kit 4.58–6.60 |
| darkroom | 6.25 | 6.26 | prim 6.19–7.45; kit 6.22–7.65 |
| eddington_talk | 6.01 | 6.22 | prim 4.99–6.12; kit 6.07–7.52 |
| cottingham_talk | 5.72 | 5.72 | prim 5.21–6.51; kit 5.66–6.13 |

## forced p95 ms

| bookmark | prim | kit |
|---|---|---|
| arrival | 7.32 | 7.76 |
| shelter | 8.10 | 7.42 |
| coelostat | 7.46 | 7.55 |
| house | 5.34 | 5.55 |
| totality_sky | 4.86 | 4.88 |
| totality_horizon | 6.14 | 5.89 |
| darkroom | 8.80 | 8.76 |
| eddington_talk | 8.06 | 8.60 |
| cottingham_talk | 7.53 | 7.60 |
