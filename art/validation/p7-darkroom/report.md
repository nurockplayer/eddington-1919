# Darkroom prop kit: slice acceptance row 8, item 3 (prerequisite)

Report 2026-11-22 00:46:32 JST. Draft PR #344. HOLD: one inherited paper-region acceptance finding remains.

Capture candidate `f20158b0c0fcdcbf30b136b6d25171ff294509ab`, baseline main `4e9f2c6d0ec1cf8569fbbed3989842e635960faa`. Captured 2026-11-22T00:43:09 JST through 2026-11-22T00:43:56 JST. Rebased product commit `507f62601bd3452a026f64176d62545f4f43e6da` is on current main `4a3004fbc6eba41ae6892b0c6c4dd5104e086f02`. The newer main changes only docs, tests and tools; rendering inputs are unchanged. The following evidence-only commit adds these images and this report without changing the game.

## Acceptance

1. Rebased on current main. All seven GLBs are byte-identical to accepted `4cbc3b06cfc59852fc55dbfed90fcf2204a47520`; no Blender rebuild or material edits. SHA-256 values are in geometry-sha256.json in the external packet.
2. Seven prop types / 13 placed instances are drawn by the existing engraving pass. The 26 native day/night instance crops retain their source pixels without rescaling. Jug, pail, tray, bottle, holder, rack and box have contour/edge line work and hatching or bounded paper reserves. No per-prop shader or tint bypass was introduced.
3. Doorway daylight, Oxford lantern render layers/range and prompt drop 100 are unchanged. All ten measured prompt/object overlaps are zero. Oxford ink difference is 0.7714 on both heads (minimum 0.25). The strict doorway paper-region condition remains HOLD on both main and head; see below.
4. The darkroom remains a red safelight night scene. The plate/sheet, loupe and notebook remain visible on the measuring bench; see comparison-darkroom and the night bench views.
5. All four measured UI evidence regions have zero changed pixels. Props have no colliders and remain clear of the measuring-table area. test_totality, test_plate_reading and test_micrometer passed as listed below.
6. Palette source change: eye_white #D8CFC2 → #D1C8BC. No other existing source colour changed. Regeneration adds previously missing table entries from the existing source plus the accepted kit swatches.

## Capture conditions

Windowed 1280x720, seed 7, fixed 60 Hz, always on top, native canvas 1600x900. No content_scale_size assignment in capture instrumentation. Title, dialogue narration and the opening toast are dismissed. 232 frames, 240 receipt checks, zero capture failures, one numeric acceptance finding. Lossless scratch and source frames were deleted after native crops, sheets, receipts, counts and hashes existed.

## Paper regions

#393 counting method: 8-connected cream/white regions (R>=220, G>=211, B>=191, R-B<=40), excluding HUD and the depth-tested bench mask expanded one native pixel. Each frame uses its largest visible cream-paper sky star as cutoff. When no star crosses that threshold, the recorded cutoff is zero; every nonempty off-bench patch counts. The previous assertion requiring a measurable star was removed; the criterion was not relaxed.

| Head | Frame | Star pixels | Off-bench regions larger than star |
|---|---|---:|---:|
| 4e9f2c6 | oxford_case_night | 52 | 0 |
| f20158b | oxford_case_night | 77 | 0 |
| 4e9f2c6 | lantern_night | 10 | 0 |
| f20158b | lantern_night | 42 | 0 |
| 4e9f2c6 | doorway_night | 0 | 1 |
| f20158b | doorway_night | 0 | 1 |

The single failing region is identical on main and head: 50 pixels, native bounds [828,355,851,358], in doorway_night. Oxford and lantern views have zero off-bench regions larger than their visible star. See doorway-paper-patch-native.png and the annotated full frames in the external packet.

## Oxford ink

| Head | Object | Background | Difference |
|---|---:|---:|---:|
| 4e9f2c6 | 1.0000 | 0.2286 | 0.7714 |
| f20158b | 1.0000 | 0.2286 | 0.7714 |

Linear-decoded diagnostic coverage; visible case mesh eroded one pixel; background x710..759 y390..409, matching #393.

## Held-surface counts

#393 method: max RGB change >=16/255; static masks eroded eight pixels; baseline repeat/control noise >=3/255 expanded eight pixels; dialogue above y450; Eddington x520..780 y170..355 excluding prompt; day and red interior full frame outside HUD. Removing the opening toast increases the counted area of day/interior frames compared with the earlier packet.

| Frame | Counted pixels | Changed pixels |
|---|---:|---:|
| arrival | 690894 | 0 |
| coelostat_still | 796392 | 0 |
| totality_sky | 777819 | 0 |
| totality_wide | 660583 | 0 |
| totality_horizon | 695547 | 0 |
| dialogue | 430416 | 0 |
| darkroom | 905898 | 3323 |
| eddington_night | 48546 | 541 |
| plate_box_day | 801932 | 29196 |
| measure_day | 810017 | 11077 |
| mentor_loupe_day | 807432 | 11482 |
| mentor_loupe_night | 879665 | 9422 |

Darkroom, Eddington-night background and darkroom object views include the requested prop additions. The other held surfaces remain pixel-identical under this method. These raw counts are retained, not relabelled as zero.

## Evidence widgets

| Region | Changed pixels |
|---|---:|
| plate_viewer_night | 0 |
| loupe_night | 0 |
| micrometer_night | 0 |
| result_chart_night | 0 |

All prompt/object mask intersections are zero; prompt-overlap.json contains the ten main/head checks.

## Native prop crops

| Instance | State | Native bounds | Visible pixels | Crop |
|---|---|---|---:|---|
| DrTray0 | day | [545, 336, 738, 444] | 10132 | [branch-prop-DrTray0_day-native.png](branch-prop-DrTray0_day-native.png) |
| DrTray1 | day | [553, 340, 727, 433] | 7258 | [branch-prop-DrTray1_day-native.png](branch-prop-DrTray1_day-native.png) |
| DrTray2 | day | [565, 345, 712, 421] | 4818 | [branch-prop-DrTray2_day-native.png](branch-prop-DrTray2_day-native.png) |
| DrBottle0 | day | [613, 295, 667, 407] | 2936 | [branch-prop-DrBottle0_day-native.png](branch-prop-DrBottle0_day-native.png) |
| DrBottle1 | day | [612, 294, 669, 414] | 3324 | [branch-prop-DrBottle1_day-native.png](branch-prop-DrBottle1_day-native.png) |
| DrBottle2 | day | [612, 296, 667, 412] | 3130 | [branch-prop-DrBottle2_day-native.png](branch-prop-DrBottle2_day-native.png) |
| DrBottle3 | day | [618, 309, 663, 401] | 1808 | [branch-prop-DrBottle3_day-native.png](branch-prop-DrBottle3_day-native.png) |
| DrPlateRack | day | [574, 303, 702, 413] | 9155 | [branch-prop-DrPlateRack_day-native.png](branch-prop-DrPlateRack_day-native.png) |
| DrPlateHolder | day | [572, 360, 716, 424] | 4886 | [branch-prop-DrPlateHolder_day-native.png](branch-prop-DrPlateHolder_day-native.png) |
| DrPail | day | [584, 288, 696, 412] | 7706 | [branch-prop-DrPail_day-native.png](branch-prop-DrPail_day-native.png) |
| DrJug | day | [609, 312, 671, 403] | 2780 | [branch-prop-DrJug_day-native.png](branch-prop-DrJug_day-native.png) |
| DrPlateBox0 | day | [584, 349, 695, 420] | 1337 | [branch-prop-DrPlateBox0_day-native.png](branch-prop-DrPlateBox0_day-native.png) |
| DrPlateBox1 | day | [586, 331, 692, 419] | 4152 | [branch-prop-DrPlateBox1_day-native.png](branch-prop-DrPlateBox1_day-native.png) |
| DrTray0 | night | [545, 336, 738, 444] | 10132 | [branch-prop-DrTray0_night-native.png](branch-prop-DrTray0_night-native.png) |
| DrTray1 | night | [553, 340, 727, 433] | 7258 | [branch-prop-DrTray1_night-native.png](branch-prop-DrTray1_night-native.png) |
| DrTray2 | night | [565, 345, 712, 421] | 4818 | [branch-prop-DrTray2_night-native.png](branch-prop-DrTray2_night-native.png) |
| DrBottle0 | night | [613, 295, 667, 407] | 2936 | [branch-prop-DrBottle0_night-native.png](branch-prop-DrBottle0_night-native.png) |
| DrBottle1 | night | [612, 294, 669, 414] | 3324 | [branch-prop-DrBottle1_night-native.png](branch-prop-DrBottle1_night-native.png) |
| DrBottle2 | night | [612, 296, 667, 412] | 3130 | [branch-prop-DrBottle2_night-native.png](branch-prop-DrBottle2_night-native.png) |
| DrBottle3 | night | [618, 309, 663, 401] | 1808 | [branch-prop-DrBottle3_night-native.png](branch-prop-DrBottle3_night-native.png) |
| DrPlateRack | night | [574, 303, 702, 413] | 9155 | [branch-prop-DrPlateRack_night-native.png](branch-prop-DrPlateRack_night-native.png) |
| DrPlateHolder | night | [572, 360, 715, 424] | 3651 | [branch-prop-DrPlateHolder_night-native.png](branch-prop-DrPlateHolder_night-native.png) |
| DrPail | night | [584, 288, 696, 412] | 7706 | [branch-prop-DrPail_night-native.png](branch-prop-DrPail_night-native.png) |
| DrJug | night | [609, 312, 671, 403] | 2780 | [branch-prop-DrJug_night-native.png](branch-prop-DrJug_night-native.png) |
| DrPlateBox0 | night | [584, 349, 695, 420] | 1337 | [branch-prop-DrPlateBox0_night-native.png](branch-prop-DrPlateBox0_night-native.png) |
| DrPlateBox1 | night | [586, 331, 692, 419] | 4152 | [branch-prop-DrPlateBox1_night-native.png](branch-prop-DrPlateBox1_night-native.png) |

## PR or commit

Draft https://github.com/nurockplayer/eddington-1919/pull/344. Product commit `507f62601bd3452a026f64176d62545f4f43e6da`; rendering source `f20158b`. The PR body pins image URLs to the evidence commit. Full external packet: `/Volumes/KIOXIA/eddington-1919-cache/director/p7-darkroom/f20158b0c0fcdcbf30b136b6d25171ff294509ab/`.

## Tests

Command: `orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/p7-darkroom/9429cab7d09d4623ee2904e024a7d9b065e86405/tools/run.sh`. Import and --check-only ran before every test. Focused test result lines:

- `test_darkroom_props`: `test_darkroom_props: 78 checks, 0 failures`.
- `test_darkroom_lantern`: `29 darkroom lantern checks, 0 failures`.
- `test_style_engraving`: `test_style_engraving: 459 checks, 0 failures`.
- `test_plate_reading`: `test_plate_reading: 195 checks, 0 failures`.
- `test_micrometer`: `156 checks, 0 failures`.
- `test_totality`: `658 checks, 0 failures`.

Those tests passed on 9429cab; the prop implementation is unchanged by the later rebases. The complete brief Test line (including look, layout, overlay and night-dress suites) is left to cx-exec and was not run here. Existing Godot shutdown resource-leak messages appear in the props and totality logs; their processes exited successfully.

Capture command: `orb-test --heavy --host -- bash /Volumes/KIOXIA/eddington-1919-cache/director/p7-darkroom/f20158b0c0fcdcbf30b136b6d25171ff294509ab/tools/run.sh`. Last result line: `PACKET 232 frames; 1 acceptance failures; 2026-11-22 00:43:57 JST`. Exit 70 is the reported paper-region finding, not an infrastructure failure.

## Assumptions

- The explicit draft requirement wins over generic ready-PR boilerplate.
- Remake the accepted kit on main; preserve all seven meshes and the accepted placements. The inherited kit sources, import metadata, G2 reports and new evidence explain the diff exceeding 300 lines.
- Latest main differs from the captured main only in docs, tests and tools; no additional rendering run is needed for those changes or the evidence-only commit.
- Preserve the paper threshold and record a strict zero cutoff when no cream-paper star is measurable.

## Follow-ups

Lead/director decides the inherited doorway paper finding. The full brief Test line remains with cx-exec.

## Blocked

No denied actions. The doorway paper-region acceptance fails identically on main and head. Changing lighting or the evidence surface to remove it would change main behaviour, so that decision is left to the lead.

DECISION: doorway_night has the same 50-pixel off-bench paper patch on main and head, with no measurable cream-paper star; accept this inherited exception or authorize a separate lighting/evidence-surface correction? Recommendation: accept the inherited exception for #344 and keep #393 lighting unchanged.
