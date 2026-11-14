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
