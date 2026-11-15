# Príncipe slice: art direction and log

Owned by the art director (role `edd-art`, Fable 5.2). The Owner picked this seat on 2026-11-14 13:0x JST from a blind audition (Opus, GPT, Fable; this answer was label Z). Read this file first after every /clear.

## Owner direction (2026-11-14 JST)

- Look target: Life is Strange: True Colors > Tell Me Why >>>> the current build.
- Pick: Z (this direction), **with saturation pushed toward Y** (the GPT proposal). The Owner said Y's saturation catches the eye at first glance, while Z has more story. Saturation is a grade and albedo knob; keep Z's composition, light and story framing.
- Scope: the Príncipe camp through totality (and the darkroom), to shippable quality before anything else.

## Reference images (this folder: `slice_principe/`)

- `current/`: the nine audition frames from the build of 2026-11-13 (1280x720). The baseline.
- `concepts/Z_*.jpg`: Codex image-gen paint-overs of this direction (arrival, coelostat, totality_sky; one generation each, no rerolls). `concepts/Y_*.jpg`: the same frames for the Y direction, kept as the **saturation reference**. Prompts and provenance: `concepts/prompts.jsonl`. Full-size PNGs: KIOXIA `eddington-1919-cache/director/audition-1113/concepts/`.
- Known generation slips, not direction: Z's daytime frames wrongly show an eclipse disc in the sky; Y keeps the façade text.
- True Colors / Tell Me Why stills are copyrighted: keep any you collect on KIOXIA only, never in this repo.

## Audition answer (verbatim, 2026-11-13)


### 1. Diagnosis

1. **No light direction.** arrival, house, shelter, coelostat: posts, trees and people cast nothing; the canvas underside is as bright as the sky; the earth is the same value under the shelter as outside. Unlit cut-outs.
2. **One noise texture plays every material.** The same mottle is canvas (shelter roof), plaster (house), brick (coelostat pier) and darkroom wall. No normals or roughness, so brass and mirror reflect nothing. The ground is one flat green; the path an airbrushed blob without an edge.
3. **Placeholder landforms and plants.** Hills are perfect hemispheres (house, cottingham_talk); bushes are faceted icospheres, palms are combs. totality_horizon is nothing but these silhouettes, so the cheapness peaks at the climax.
4. **The sky is noise.** Overcast is flat white with grey blobs at one frequency; no haze, no sun direction. In totality_sky the clouds are purple blobs and the eclipsed sun is a soft disc with a pinpoint: no corona, no twilight band. The moment the game exists for has no image.
5. **Mannequins at the worst distance.** eddington_talk: full body, dead centre, A-pose, face about 40 px tall with hollow eyes, suit one untextured white. cottingham_talk and coelostat: the same, plus a decal moustache. Hands are mitts.
6. **Text as set dressing.** "ROÇA SUNDY" in a modern sans on the façade and bold "R.A.S. ECLIPSE PRINCIPE" on crates read as labels, not objects.
7. **No camera language.** Wide lens, horizon mid-frame, no foreground element, no depth of field, no grade; the sky clips to white, totality_horizon's ground to black.
8. **The darkroom is empty.** A self-lit white card on a bare table; no safelight lamp, trays, bottles or microscope. The plate should be a glass negative, dark with star points.

### 2. The look

One sentence: a humid tropical afternoon painted in gouache; a warm key when the sun breaks, pearl-grey wrap light when it doesn't, shadows deep but never black, every surface hand-painted.

**From True Colors (the bar):** the value structure (one clear key, warm bounce, cool sky fill; shadows at 15–20%, highlights rolling off); painterly albedo with visible brushwork, no photo noise; atmospheric depth (haze, god rays, dust); a warm filmic grade; close, off-centre, shallow dialogue cameras. **From Tell Me Why:** overcast that still has form (soft light with a direction), damp saturated vegetation, period objects as heroes, over-the-shoulder framing. **Out of reach:** performance-captured faces, hair, cloth simulation; the substitute is section 5.

**Other references:** Firewatch (flat colour shapes, layered haze, silhouetted vegetation: our achievable landscape); Season: A Letter to the Future (painterly surfaces at indie scale); Winslow Homer's Bahamas watercolours (lime-washed walls, palms, hazy white sky).

**Palette:** laterite red-brown earth (keep it); foliage olive to yellow-green in light, blue-teal in shade; walls warm off-white with grey damp streaks at the base; roof terracotta gone brown with moss; brass, black lacquer, raw canvas as accents. Eclipse: indigo zenith, salmon-orange horizon band all round, pearl corona.

**Light:** sun about 50° high (totality was 14:13 local), 5200 K; DirectionalLight with soft shadows (angular size 1–2°), SSAO, SDFGI or baked GI, AgX tonemap, exposure so the sky never clips; light volumetric and height fog, far hills tinted toward the sky; canvas with backlight translucency so pole shadows show through the roof.

**Materials:** tileable painted albedos from image generation ("gouache, hand-painted, no photographic noise"), normals derived, roughness painted; brick with mortar, wood with grain, metallic brass with a reflection probe.

**Grain and camera:** 1–2% film grain, gentle vignette, no sepia in play (the toned print stays in portraits and chapter cards); 55° horizontal FOV, eye at 1.6 m, horizon on a third, a dark foreground element on one edge, depth of field only in dialogue.

### 3. Three target frames

**arrival.** Camera low (1.5 m) on the red path, running diagonally from bottom-left to the shelter on the right third. Sun upper-right behind the canvas: the roof glows warm and the poles throw long shadows toward the player across wet red earth with puddles (it stormed that morning) and leaf litter. House behind-left, half hidden by a cacao tree and a soft dark palm trunk at the left edge; two hill layers with haze between; broken cloud, one warm gap. Cottingham small, bent over a crate; Eddington walking toward us, hand shading his eyes. Removed: lawn, hemispheres, metal base disc, big text.

**coelostat.** Camera at 1.2 m, close. The brick pier fills the left third; the mirror reflects the real sky; brass crank and drive box at centre with its falling weight; the tube leaves top-right in soft focus. Cottingham waist-up in three-quarter, bent to the clock, brim shading his face, hands on the crank; the house a pale shape in haze. Sun upper-left: a hot highlight on the brass, the gimbal's shadow on the cap. Removed: façade text, second hill, flat pier paint.

**totality_sky.** Looking up about 60° from the shelter's edge; one beam crosses the lower-left corner, palm fronds silhouetted right. Sun on the upper-right third: black disc, pearl corona to two solar radii with streamers, thin cloud veils crossing it lit from behind, two cloud layers at different speeds. Zenith indigo, Venus visible, the bottom edge warming to orange. Over twenty seconds the cloud thins and the corona emerges. Removed: purple blobs, grey glow, pinpoint.

### 4. The plan

1. **Lighting and post (M):** shadows, SSAO, GI, fog, AgX, grade, FOV, vignette, grain. Biggest gain; everything else is judged after it.
2. **Sky and eclipse (M):** layered painted clouds, twilight gradient, corona shader, the cloud-thinning sequence.
3. **Terrain (M):** sculpted hills with ridgelines and tree lines; ground shader blending laterite, grass and litter; path edges, puddles.
4. **Vegetation (L):** palms with painted alpha fronds, cacao, banana, undergrowth, wind; silhouettes designed for the eclipse frames.
5. **Materials (M):** canvas translucency, plaster weathering, brick, wood, brass, lacquer; stencils at the right size.
6. **Characters (M):** section 5.
7. **Props and darkroom (S):** tarps, rope, plate boxes; safelight lamp, trays, glass negative, microscope.

**Cut or hide:** full-body character shots; the lawn; a walkable far field (fence the slice to shelter, house front and path; tree lines and fog beyond); the sea band in totality_horizon; the façade text (a small weathered sign at most); idle bare hands.

### 5. Characters

- **Framing:** never full body. Dialogue uses a locked camera at 2–2.5 m, waist-up three-quarter or over-the-shoulder, eyes on the upper third, depth of field on, face at least 120 px tall at 720p.
- **Stylise:** simplify the MPFB faces (ears, cheeks, nose), larger painted irises with a catchlight, hand-painted skin with warm and cool zones, subsurface on. Cloth with painted folds and seams: linen, not flat white.
- **Hide what cannot act:** brims and Eddington's round glasses shade the eyes; hands hold a crank, plate holder or pencil, or stay out of frame.
- **Motion:** retarget free Mixamo idle and talk cycles in Blender; weight shift, breathing, a blink every 3–5 s, head and eye look-at with a small lag, two or three gesture clips.
- **Off camera at the climax:** Eddington did not watch the eclipse; he was changing plates. Totality is first person at the plate holder, Cottingham calling time off screen.

### 6. Acceptance

- Light: every outdoor frame has a visible cast shadow; nothing self-lit except the safelight and the corona.
- Values: under 3% clipped white, under 3% pure black (darkroom exempt).
- Silhouette and depth: at 160x90 the frame still reads with foreground, subject and hazed background; no visible facets on plants or hills.
- Materials: five distinct responses in the coelostat frame (brass, lacquer, canvas, brick, cloth).
- Characters: the framing checks above; idle motion within two seconds; no A-pose anywhere.
- Eclipse: corona and cloud veil both visible, indigo zenith, orange horizon, no purple blobs.
- Fidelity: instruments match the 1919 expedition photographs (horizontal tube, coelostat on a pier, clock drive).
- Performance: 30 fps at 720p on a GTX 1650, measured under the shelter at totality.
- Blind contact sheet: six slice frames beside True Colors stills; a viewer names none of ours as placeholder.

## Log

Newest last. Each round: date and time (JST), what changed, the frames judged (paths), the verdict.

- 2026-11-14 13:0x JST (edd-lead): seat set up. First round = plan step 1 (lighting and post), with the saturation push toward Y folded into the grade.
- 2026-11-14 13:2x JST (edd-art), round 1 dispatched, **nothing judged yet** (Saturday: no windowed run until 2026-11-16 09:00 JST).
  - Frames read: `slice_principe/current/arrival.jpg`, `coelostat.jpg`; `concepts/Z_arrival.jpg`, `Y_arrival.jpg`, `Y_coelostat.jpg`.
  - What the current build does (`scripts/look.gd`, `main._build_environment`, `_apply_light`): ACES at white 1.0, saturation 0.86 plus a sepia LUT, sky ambient at 0.72 against a sun of about 0.7 under cloud (so shadows exist but do not read), no GI (the earth under the canvas is as bright as outside), depth fog only, player FOV 72° vertical.
  - Numbers (320×180 nearest, luma Rec.709 on display values; saturation = (max − min) / max):

    | frame | luma p05 | p50 | p95 | sat | sat lower half |
    |---|---|---|---|---|---|
    | current/arrival | 0.18 | 0.33 | 0.94 | 0.24 | 0.40 |
    | current/coelostat | 0.05 | 0.27 | 0.90 | 0.33 | 0.48 |
    | current/house | 0.18 | 0.43 | 0.94 | 0.22 | 0.36 |
    | Y_arrival | 0.12 | 0.29 | 0.73 | 0.36 | 0.46 |
    | Y_coelostat | 0.12 | 0.32 | 0.69 | 0.40 | 0.49 |
    | Z_arrival | 0.17 | 0.35 | 0.67 | 0.34 | 0.43 |

    The gap to Y is less the ground than the sky: ours sits at 0.9+ and has no colour. Step 1 pulls the sky down and the key up; sky colour itself is step 2.
  - **Step 1 value targets (daytime frames):** luma p95 ≤ 0.80, p05 0.08–0.15, lower-half saturation ≥ 0.45, clipped white and black under 3%.
  - Decisions (also on GitHub via `lead-decision`): Príncipe leaves the plate grade (Cambridge and departure keep it); one parameter set `Look.PRINCIPE` with `--look-set=key=value,…` overrides; first-pass defaults ACES white 5.0, exposure 1.1, saturation 1.18, split-tone LUT (cool shadows, identity from 0.85), sun floor 0.3 and gain 1.8, ambient 0.5, sky gain 0.72, SDFGI and light volumetric fog (off at low quality, never over the sky), vignette 0.22, grain 0.03, FOV 60° vertical (the audition's 55° horizontal is about 33° vertical: kept for locked dialogue cameras, too narrow to walk in). ACES over the audition's AgX because r05 found AgX milky; AgX is a variant.
  - Dispatched (Codex Terra): `art/p1-look` (the look; draft PR until I have seen it) and `art/p1-look-matrix` (benchmark image stats, `tools/look_matrix.sh`: one benchmark run per variant, stats table, contact sheets). Briefs: `.claude/briefs/p1-look.md`, `p1-matrix.md`.
  - 2026-11-14 13:36 JST: the look is draft PR #318 (head `cdbd2d6`). Diff checked against the brief: values and scope as specified, CI green, 54 + 100 headless checks pass. Nothing judged visually yet, so it stays draft.
  - Monday 2026-11-16 09:00 JST: `orb-test --heavy --host -- tools/look_matrix.sh /Volumes/KIOXIA/eddington-1919-cache/director/look-matrix/1116` on the two branches merged locally; judge the sheets (base, nograde, agx, white1, sat_lo, sat_hi, key_hi, no_sdfgi, no_volfog, fov72, fov55), set the defaults, then accept or send back.
- 2026-11-14 14:0x JST (edd-art), round 1 look brought forward, **nothing judged yet**. edd-lead relayed at 13:59 JST that the Owner is out for at least an hour, so the windowed matrix runs today: heavy ticket #1102, `run_windowed.sh` on KIOXIA `director/look-matrix/` (stops on any keyboard or mouse activity, deadline 15:15 JST), variants in priority order (`variants_1114.tsv`), output `director/look-matrix/1114/`. It runs on a detached merge of `art/p1-look` + `art/p1-look-matrix` in the `p1-look` worktree.
- 2026-11-14 14:1x JST (edd-art), parallel asset tracks dispatched (plan steps 3, 4, 5, 7; Codex Terra; none depends on the step 1 values). **Nothing judged yet.**
  - Read first: `art/factory/af01/contact-views.jpg` on branch `claude/af01-fix-round` (68553d3). Verdict: the 12 camp props (table, stool, cask, lantern, chest, plate rack, bucket, ladder, sawhorse, wheelbarrow, fence, barcaça) make the camp read lived-in and are worth taking as the next dressing batch; not the steps, not that palm. They are flat palette fills, so they need the painted materials below to stop reading as kit.
  - Decisions: (1) painted surfaces are **albedo tiles keyed by palette swatch**, colour-matched to the swatch hex, world-triplanar, replacing the one shared noise in `world_builder.weather()`; every kit GLB (materials `E1919_<swatch>`) then picks them up without re-export. No normal maps yet. (2) Vegetation becomes alpha cards with painted cut-outs on Blender trunks; cut-outs first, models after I have seen them. (3) Far terrain is three ridge rings with two phonolite towers behind the camp (bearing 140° and 168°, in the `totality_horizon` view); the Sun and house sector (bearing −38°) stays low; the sea is hidden. (4) The darkroom gets seven kit props; the lantern, the measuring table and the evidence sheet are untouched; rack plates are dark so they do not compete with the evidence.
  - Tracks (briefs in `.claude/briefs/`): `p5-tiles` (11 surfaces × 2 variants, sheets in `art/runs/p5-tiles/`, no PR until I pick), `p4-leaves` (6 cut-outs × 2 variants incl. `forest_edge`, sheets in `art/runs/p4-leaves/`, no PR until I pick), `p7-darkroom` (draft PR, renders in `art/validation/p7-darkroom/`), `p3-ridges` (draft PR, `art/validation/p3-ridges/panorama.jpg` and `silhouette.jpg`).
  - Next after judging: install picked tiles to `assets/textures/principe/` and wire them in `weather()`; ground shader (laterite, ground cover, litter, path edges, puddles); vegetation kit (palm, cacao, banana, undergrowth, forest-edge ring at 46–60 m) and its wiring in `palm()` / `_vegetation()`; af01 camp props; façade and crate text down to a small sign.
- 2026-11-14 14:3x JST (edd-art), p5-tiles first look at the **raw** generations only (22 swatches, before wrap and colour match; no picks yet). Image: KIOXIA `director/p5-tiles/raw-sheet-20261114-1434.jpg` (unlabelled, alphabetical).
  - **Rejected: both brick swatches.** The mortar is yellow-green and the bricks are toy red; matching the mean to `#985B45` would not fix the mortar hue. Regenerated once with thin recessed pale warm-grey lime mortar and weathered orange-red bricks; ids stay `brick-v1`, `brick-v2`, old raws go to `raw/rejected/` (decision on #317).
  - The other ten surfaces read as one painted family and go on to the processed sheets. To check there, not decided: leaf litter looks autumnal and large (scale and hue after matching); teak is very orange; the canvas seam repeats once per tile; palm bark reads as horizontal fibre bands, fine on a trunk if the bands stay level.
  - Process note: the worker reported the 22 raws copied to KIOXIA when only one was; I copied the other 21 from the paths in `REVIEW.md` before the processing job started. The run then stopped at the wrapper's wait limit and was resumed (`.claude/briefs/p5-tiles-followup-1.md`).
- 2026-11-14 14:4x JST (edd-art), p4-leaves judged on **my own re-cut of the 12 raws** (the worker's sheets did not exist yet). Images: KIOXIA `director/p4-leaves/judged-20261114/`.
  - Two defects found by looking, both missed by the numeric check: (1) the ten committed cut-outs were black (`leaves-committed-black.jpg`): the colour-spread step in `cutout.sh` wiped the RGB and `--check` never looked at colour; (2) `forest_edge` lost its alpha in the wrap, and the cross-fade wrap **my brief specified** leaves ghost palms at the seam (`forest-crossfade-ghost.jpg`).
  - Decisions (on #317): `forest_edge` wraps by mirror, 2048 px wide (`forest-mirror-rolled.jpg`: no seam, no ghost; the mirror symmetry is visible if you look for it and will sit behind 3D palms); `--check` also fails a cut-out under 8 % mean chroma. The fixed script is `.claude/briefs/p4-leaves-cutout-fixed.sh`, run over all 12 raws before it went to the worker.
  - **Picks** (`leaves-colour-fixed.jpg`, on `#CDB58F`): both variants of `coconut_frond`, `cacao_branch` (the red flush leaves are right for cocoa), `banana_leaf` (v1 first: more splits, reads as banana from further away) and `undergrowth`; `coconut_frond_dry` v1 only (v2 has keyed-out holes near the base); `forest_edge` v1 and v2. The set reads as one hand: broad gouache strokes, blue-green shade and yellow-green light, saturation on the Y side. No white fringe on the dusk blue.
  - Open, to judge in engine: the fronds are flat and symmetric, so the cards must be bent along the rib; the bottom third of `forest_edge` (cocoa pods, big leaves) reads near-scale and is to be hidden or UV-cropped on the 46–60 m ring; its five evenly spaced palms may read as a row.
  - The worker was resumed (`.claude/briefs/p4-leaves-followup-1.md`) to take the fixed script, rebuild, and write the manifest, sheets and `REVIEW.md` with these picks. No PR until the vegetation-kit brief installs them.
- 2026-11-15 14:0x JST (edd-art), **step 1 look judged** on the windowed matrix of 2026-11-14 (run stopped at 15:07 JST by the Owner's return: 8 of 11 variants done, `no_volfog`, `fov72`, `fov55` missing). Images: KIOXIA `director/look-matrix/1114/sheets/<bookmark>.jpg` (top row base / nograde / no_sdfgi, bottom row sat_hi / key_hi / agx; no labels, ImageMagick has no font), numbers in `1114/stats.tsv`.
  - **SDFGI off.** It is what crushes the shade: on `coelostat` the Príncipe assistant's face and hat go to flat black with it (clipped black 21.9 % → 0 % without), `shelter` 5.2 % → 0 %, `eddington_talk` p05 0.062 → 0.123 (in target). Without it faces in shade read and the camp keeps its contrast; forced-draw cost is unchanged.
  - **Saturation 1.30** (from 1.18), toward Y as the Owner asked. Lower-half saturation is still 0.29–0.43 in day frames against the 0.45 target: the grade alone cannot get there, the grey-green ground noise is the cause, so the rest comes from the painted tiles (p5) and the ground shader. `sat_hi` alone only moved it +0.03.
  - Kept: ACES, white 5.0, exposure 1.1, key and ambient (`key_hi` brightened without fixing anything; `agx` flattened the day and kept the black crush). Luma p95 is already ≤ 0.80 everywhere.
  - Still failing, carried: black clip on `totality_sky` / `totality_horizon` (~2–13 %) and `darkroom` (20 %); judged with step 2 (sky) and the darkroom props, not in the grade.
  - Dispatched: #318 Codex session resumed (`.claude/briefs/p1-look-followup-defaults.md`, Sol high: Codex is behind pace). Acceptance in a PR comment with these sheets once the combined defaults are rendered in Monday's window (2026-11-16 09:00 JST).
- 2026-11-15 14:1x JST (edd-art), p4-leaves rebuilt and p5-tiles judged; vegetation and tile wiring dispatched.
  - p4-leaves (`art/p4-leaves` b11b8e4): the worker's rebuilt sheets (`art/runs/p4-leaves/sheet-colour.jpg`, `sheet-dusk.jpg`) match my re-cut: colour back, no white fringe on the totality blue, no seam in the mirrored `forest_edge`. Picks unchanged.
  - p5-tiles picks (`art/runs/p5-tiles/REVIEW.md`, f295064; images `sheet-v1.jpg`, `sheet-v2.jpg`, `sheet-flat.jpg`, KIOXIA `director/p5-tiles/judged-20261115/`): v2 for laterite_wet, laterite, ground_cover, leaf_litter, whitewash, roof_tile, teak, canvas; v1 for brick, iron_sheet, palm_bark, teak_dark, pine. The rejects repeat a recognisable motif in 3×3 (heart leaves, green stains, dark knots) or show the tile grid. The cross-fade wrap fails on regular patterns: roof_tile v2 doubles the tile ridge at the seam (`seam-crops-laterite-litter-roof.jpg`), so it is re-wrapped by a whole-period crop before install; leaf_litter v2 keeps a faint ghost at the seam, acceptable on the ground.
  - Tile wiring (`.claude/briefs/p5-install.md`, branch `art/p5-install`): `weather()` resolves a tile by explicit id, then `E1919_<swatch>` material name, then exact palette colour; world-triplanar, metres per repeat from brick 0.6 m to laterite 2.0 m; albedo becomes the ratio to the swatch so tinted kit materials keep their offset; the UV2 noise stays on top; the darkroom roof gets `iron_sheet`. Ground tiles are installed but wait for the ground-shader brief.
  - Vegetation (`.claude/briefs/veg-cards.md`, branch `art/veg-cards`): frond cards on the old spine, bent Λ along the rib; shrubs keep their 70 transforms and names (`shrub_cocoa` becomes cacao branches with undergrowth at the foot, `banana_clump` six arched leaf cards), variants by instance data; forest edge as two rounded-square loops at 47 m and 57 m half-side, not the 46–60 m circle I planned, because the bounds walls are a square at 42 m and a circle would put the player inside the band at the corners. The band sinks by 55 % in the house and Sun sector (−62°…−14°) so that view stays low; the bottom third of the cut-out is cropped by UV. The palm trunk stays a plain cylinder until both PRs land (then `palm_bark`).
- 2026-11-15 18:0x JST (edd-art), **p3-ridges round 1 judged: not accepted**, round 2 dispatched. Images: `art/validation/p3-ridges/panorama.jpg`, `silhouette.jpg` at 487aefa (branch `art/p3-ridges`, not pushed), copies on KIOXIA `director/p3-ridges/judged-20261115/`.
  - The towers are flat-topped mesas about 100 m wide and 55 m high: they read as hats, not as Príncipe's plugs. That was my brief ("base about 90 m wide"), not the worker. Round 2 gives each a lopsided profile by control points: 140° about 25 m wide at half height and 65 m above the massif (top about 160 m), one near-vertical flank and a shoulder on the other; 168° a 33 m thumb (top about 128 m). The far ring gets 0.25° columns there.
  - Sawtooth "conifers" on the near ring at 297° and 348° (the canopy phase aliased against the columns): replaced by rounded 11 m billows on arc length. Dark blotches on the slopes (rows crossing under the radial gully push): gullies become a height cut that runs straight down the slope.
  - The house and Sun sector was a ruler line for 70°: it now undulates (near 4.5–7.5 m with the billows, mid 9–14 m so a second layer shows behind, far ≤ 30 m). Still under 5° elevation.
  - Crest lines get two more octaves (no long straight ramps); the massif top varies 84–96 m.
  - The lit render gets a haze preview per ring and a tele frame of the towers (`towers.jpg`), because near, mid and far had one value and the towers were 40 px wide in the montage.
  - Decisions (on #316): meshes renamed `principe_ridges_near/mid/far` (G2 `names_prefixed` passes); G2 `origin_bottom_centre` skipped for this asset (the feet sit at −2 m by design); `eye_white` `#D1C8BC` also on this branch, identical to p7-darkroom, because `palette_to_gd.py` on main rejects the old value and no branch can add a swatch without it.
  - Follow-up `.claude/briefs/p3-ridges-followup-2.md` (Sol high: Codex is behind pace). The Blender job waits for the heavy gate (Monday 2026-11-16 08:30 JST or the Owner away).
- 2026-11-15 18:2x JST (edd-art), veg-cards (#341) first test job failed; fronds keep one material. No images judged (nothing rendered yet).
  - The job hung from 18:07 JST on three parse errors in `scripts/world_builder.gd` (untyped loop variable at lines 655, 656, 882); I stopped it at 18:24 JST (exit 143). The follow-up test line parses with `--check-only` first, so a script error exits instead of hanging.
  - Decision (on #341): the fronds keep **one shared card material**. Green v1, green v2 and dry v1 sit in one `ShaderMaterial` and a per-instance `pick` chooses. My brief asked for three materials and for `tests/test_sun_crescents.gd` ("all fronds share mesh and material") to pass unchanged; the two contradict. One material keeps the existing check, at the cost of one more sampler in the card shader.
  - The worker had opened #341 ready; it is a draft again until I accept renders (Monday 2026-11-16 09:00 JST window).
  - Follow-up `.claude/briefs/veg-cards-followup-1.md` (session resumed). p1-matrix (#339): its fix `44eaf66` waited 4 h behind the hung job; the run is resumed to wait for the test and push.
- 2026-11-15 18:3x JST (edd-art), **p7-darkroom round 1 judged: not accepted yet** (draft PR #344, 4ff605e). Images: `art/validation/p7-darkroom/props.jpg`, `bench.jpg` on `art/p7-darkroom`, copies on KIOXIA `director/p7-darkroom/judged-20261115/`.
  - Accepted as built: bottle (amber glass, cork, blank label), plate holder, plate rack, plate box.
  - Jug: reads as a vase. The handle torus is sunk in the body (a black nub), the spout is one loose triangle, the body is nearly a cylinder. Round 2: belly low and a narrow neck with a flared lip, the lip pinched into a spout, an enamel strap handle opposite it; `dims_m` 0.16 × 0.21 × 0.24.
  - Pail: the rim is notched (a 4-sided rim torus cutting the 24-gon wall) and the bail is a full ring inside the pail. Round 2: the roll is part of the lathe profile; the bail is a half ring hinged at two ears, resting outside the rim.
  - Tray: the liquid was a black slab to the brim (my swatch `#1E1A16` and my "1 cm below the rim"). Round 2: 2 cm below the rim so a band of enamel shows, `tray_liquid` `#54432F`.
  - `zinc` `#7F8483`, roughness 0.55, metallic 0.3: at metallic 0.6 it renders near black with nothing to reflect, which is what the darkroom is.
  - The bench render was too dark to judge (light 60 → 200), and a `closeup.jpg` of the three is added. Oracle approved the diff and named the same two handles (major, minor).
  - Follow-up `.claude/briefs/p7-darkroom-fu2.md` (Sol high, session resumed); decision on #344. The Blender rebuild waits for the heavy gate.
- 2026-11-15 20:1x JST (edd-art), **p7-darkroom round 2 judged: tray accepted, jug and pail one more round** (draft PR #344, 156b92e). Images: `art/validation/p7-darkroom/closeup.jpg`, `props.jpg`, `bench.jpg` on `art/p7-darkroom`; copies and my crops on KIOXIA `director/p7-darkroom/judged-20261115-r2/` (`crops-jug-pail-2010.jpg`).
  - Tray: accepted. A pale enamel band shows all round a brown liquid, also under the bench light.
  - Pail: the rim is one roll and the bail lies outside on its ears, as asked. But the outer wall renders charcoal while the inside is grey, same `zinc`: `lathe()` smooth-shades the caps too, and the wall is one 23 cm span between the bottom n-gon and the underside of the roll, so its normals point at the floor. Not a swatch problem.
  - Jug: reads as a jug (handle loop with daylight through it, pinched spout opposite). Left: the mouth is closed by a disc 3.5 cm down (my profile stopped there), the handle is seven straight segments, the belly shades blotchy under the bench light (same normal fault at the base).
  - Round 3 (`.claude/briefs/p7-darkroom-fu3.md`, session resumed): sharp edges above 75° and at the caps on the pail and jug bodies, with a normal self-check on the pail wall; jug interior down to a floor at 1.2 cm; handle resampled to 12 segments. Bottle, holder, rack, box and tray stay byte-identical. The heavy gate was open (Owner away), so the rebuild runs tonight; the in-game look is still Monday's.
  - The worker's oracle review failed (exit 5, ChatGPT logged out in ego-lite); no review of 156b92e was run because round 3 moves the head. veg-cards (#341): codex review approves c93d6f2 (0 blockers, 0 majors); still draft for Monday.
- 2026-11-15 18:5x JST (edd-art), **roof tile re-wrapped and accepted for install** (draft PR #340). Images judged: full-resolution seam crop old vs new and the 3×3 sheet, KIOXIA `director/p5-tiles/judged-20261115/roof-rewrap-seam-old-vs-new-1859.jpg`, `roof-rewrap-3x3-1859.jpg`; the 3×3 is also `art/runs/p5-tiles/roof_tile-v2-rewrap-3x3.jpg` on `art/p5-install`.
  - The worker's two whole-period crops failed the wrap check (5.8 / 3.7, then 3.1 / 4.0 against 1.6) because my brief forbade any feather; the oracle review blocked installing the cross-faded tile with its doubled ridge, and the worker asked for a new source.
  - Decision (on #340): neither. I made the tile myself: raw `roof_tile-v2.png`, centred crop 1086×1085 (6×5 periods of 181×217 px), 1024², no half-roll cross-fade, only `tile.sh`'s 16 px border feather, colour match `#93493A`. Check `0.641818 / 0.563404`, mean `#8F4739`. Courses run straight through the seam; no doubled ridge. The moss tufts still repeat every metre (as in the pick); judge that on the Monday render from the camp.
  - The review's two majors are issue #345 (palm trunks never get `palm_bark`; the manifest test does not enforce the wrap limit). Follow-up `.claude/briefs/p5-install-fu-roof.md` (Sol high, session resumed): record, test, push.
- 2026-11-15 18:5x JST (edd-art), veg-cards (#341): renderer readback. No images judged.
  - Godot's headless dummy renderer returns default per-instance MultiMesh data, so the shrub variant readback failed on every odd instance (32 checks). Decision (on #341): the readback is asserted only on a real renderer; headless skips it and prints the count (66). I run the same test windowed on Monday before accepting. The unused shrub and banana GLBs stay until the cards pass the render.
  - Follow-up `.claude/briefs/veg-cards-followup-2.md` (Sol high, session resumed).
- 2026-11-15 19:0x JST (edd-art), matrix runner (#339) stacked on #318, draft again. No images judged.
  - The review blocker was real: nine default variants ask for `--look-set` overrides that only `art/p1-look` (#318) implements. The worker merged that branch into `art/p1-look-matrix` (9a53b98) without asking; tests pass, oracle approves.
  - Decision (on #339): keep the merge as a stack, do not run the gate. Merging #339 first would land #318's look defaults (SDFGI off, saturation 1.30) before I have accepted them on a render. Order: Monday render from the `p1-matrix` worktree (it now holds both), accept #318, gate #318, merge main into #339 (`tests/benchmark.gd` conflicts), new review, gate.
  - Majors (stats mix old runs; the window is checked only at start) are issue #346.
