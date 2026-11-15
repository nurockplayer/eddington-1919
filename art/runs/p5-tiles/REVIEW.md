# Surface tile review

[Variant 1](sheet-v1.jpg) · [Variant 2](sheet-v2.jpg) · [Flat sheet](sheet-flat.jpg)

The art director rejected the first brick pair for yellow-green mortar; both were regenerated. The new brick raws have warm-grey mortar. A 16-pixel border feather was applied to tiles that initially failed wrap checks.

Art director picks, 2026-11-15 14:1x JST (edd-art), judged on the 3×3 sheets and full-resolution crops of each seam (KIOXIA `director/p5-tiles/judged-20261115/`).

| id | v1 (x, y, mean) | v2 (x, y, mean) | pick |
|---|---|---|---|
| laterite_wet | 1.4478, 1.262, #6D3B29 | 0.905055, 0.5403, #6E3A28 | pick: v2 (v1 shows the tile grid) |
| laterite | 1.37318, 1.27928, #9A5536 | 1.46545, 1.29536, #9A5537 | pick: v2 |
| ground_cover | 1.25957, 1.28774, #3E5829 | 1.36211, 1.30352, #3E582A | pick: v2 (v1 repeats a heart-leaf motif) |
| leaf_litter | 1.45736, 1.23085, #58442F | 1.53175, 1.19218, #57432F | pick: v2 (faint cross-fade ghost at the seam; tolerable on the ground) |
| whitewash | 0.703706, 0.35809, #D1C9B8 | 1.58515, 1.23613, #D1C9B8 | pick: v2 (v1 repeats green stains) |
| roof_tile | 0.61623, 0.56294, #904739 | 0.612368, 0.587186, #904739 | pick: v2, but rewrap before install: the cross-fade doubles the tile ridge at the seam; crop a whole number of tile periods instead |
| brick | 0.574272, 0.54108, #97563D | 0.61509, 0.335069, #97563E | pick: v1 (v2 shows vertical cuts) |
| teak | 0.513671, 1.05665, #6D4B30 | 0.374628, 1.04122, #6D4B31 | pick: v2 (v1 repeats dark knots) |
| canvas | 0.547963, 0.289008, #CFC3A3 | 1.11891, 1.00262, #CFC3A4 | pick: v2 |
| iron_sheet | 0.447048, 0.855215, #4C4A49 | 0.477873, 1.24956, #4C4A49 | pick: v1 (v2 shows horizontal joins) |
| palm_bark | 0.373259, 0.759625, #6A5943 | 1.23665, 1.29409, #6A5943 | pick: v1 |
| teak_dark | 0.597181, 1.27449, #452F22 | 0.465116, 1.28905, #452F22 | pick: v1 (v2 has a dark band) |
| pine | 0.434814, 0.878172, #9A7A4F | 0.310959, 0.902877, #9B794F | pick: v1 (v2 stripes) |
