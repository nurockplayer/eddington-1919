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
