# Art pipeline: generate → choose → build → validate in Godot → feed back

The loop is built for speed. Image generation takes about 1 minute, so **exploration is cheap**. Commitment is expensive, so it happens only after gates. Every image, prompt, choice, mesh and screenshot is kept so a new agent can reproduce or continue the work.

```
 S1 Explore ──► S2 Choose & codify ──► S3 Build 3D ──► S4 Validate in Godot ──► S5 Feed back
   gen.py          REVIEW.md, prompt      Blender build /     lookdev (G3) +         prompt/spec/palette
   contact sheet   version bump, refs     Tripo → ingest,      in-game benchmark      changes → next run
                   (G1)                   validate.py (G2)     (G4), tests, autoplay  (S1)
                                    S6 Record: manifest · REVIEW · assets.toml status · LOG.md · validation/
```

## Tool status (measured 2026-10-19 on this machine)

| Tool | Status | Notes |
|---|---|---|
| **GPT image generation** via Codex CLI (`codex exec`, image_generation tool) | ✅ working | **Timing:** 55–90 s per image. 2–3 parallel jobs are reliable; 8 at once failed. Codex passes our prompt through **verbatim**, which is verified in `tool_prompt` in every manifest from r02 on. Output is 1536×1024 or 1024×1024. |
| Gemini image API (`gen.py --gens gemini`) | ⛔ quota | Adapter written and request accepted, but the account's free tier has 0 image requests (HTTP 429). It needs a paid key. |
| **"dot"** | ❓ not found | No CLI, app, MCP server or key by that name exists on this machine. **Owner: please say what dot is** (app, API or model name), and it can be added as a `--gens` adapter. |
| **Tripo** image→3D (`tripo.py`) | ⛔ no key | The client is written from the v3 API docs and never executed. Set `TRIPO_API_KEY` to enable stage S3a. |
| **Blender 5.2.2** headless | ✅ | `kit.py` (palette materials, bevels, export) and `validate.py` (G2). |
| **Godot 4.7.2** | ✅ | Lookdev scene (G3), in-game benchmark (G4), logic tests, autoplay. |

## S1 Explore: many cheap variants

```bash
# One subject, several styles × variants; images + exact prompts → art/runs/<run>/
python3 art/pipeline/gen.py --run r04-xyz --styles E_diorama_plate_grade --subject darkroom_night --gens gpt --n 3
# Optional style anchor (see warning below), extra text, id tag
python3 art/pipeline/gen.py ... --ref art/runs/r01-directions/key_station-B-gpt-1-v2.jpg --extra "dusk" --tag dusk
python3 art/pipeline/contact_sheet.py art/runs/r04-xyz --cols 3
```

- **Prompt assembly** (`gen.py compose`): **style (medium first)**, then series identity, then subject, then framing (keyframes only), then a one-line reminder of the medium, then the avoid list. All blocks are versioned TOML in `art/prompts/` (`series/base.toml`, `<era>/styles.toml`, `<era>/subjects.toml`).
- **Manifest** (`manifest.jsonl`): one line per image, with id, generator, model, block versions, ref images, the full prompt, the prompt the tool actually received, seconds, the raw PNG's sha256 and a timestamp. Committed JPEGs are 1280 px; raw PNGs stay in `_raw/`, which is git-ignored.

Hard-won prompt rules (from our runs):
1. **Medium first.** With the subject first, all four r01 styles collapsed into the same photoreal render.
2. **Reference images copy composition, not just style.** In r02, a `--ref` keyframe made the totality "look up" shot copy the reference's layout. Use refs only for the *same* shot, or use a style-only ref such as an asset sheet.
3. **Grade wording is ignored** ("sepia", "glass-plate grade"). Put the grade in-engine (`scripts/look.gd`).
4. **State every historical negative explicitly:** no domes, a windowless darkroom. Unconstrained models default to clichés.
5. Keep keyframe subjects under about 120 words. Asset subjects list parts bottom-to-top with dimensions.
6. **Paint-over the real game (r05).** Run `--subject paintover --ref <in-game benchmark screenshot>`. You get a lighting and material target for the *same* camera and layout, which is the most useful image for improving the playable scene.
7. **State the time and the light sources in paint-overs.** The model invents golden hour and daylight leaks. Check the result against history before adopting anything (r05: a low sun at 14:00 and a sunlit darkroom were both rejected).

## S2 Choose and codify (gate G1)

Write `art/runs/<run>/REVIEW.md` with:
- the contact sheet
- a scorecard (BIBLE §2 criteria for directions; for assets: silhouette, part list correct, proportions vs spec, buildable, history)
- **the pick and why**
- **what changes next round:** the prompt diff and version bump

Promote winners:
- **Style wording** goes to `styles.toml`, with `status = "chosen"`.
- **Images** become the asset's `concept` entry in `assets.toml`.
- **Rejected ideas** go into the BIBLE §8 do/don't table.

**G1 passes when:** the image is historically plausible (it is checked against `docs/HISTORY_1919.md` and `docs/PROVENANCE.md`), its parts match the spec, and it fits the chosen direction.

## S3 Build 3D (gate G2)

Choose the route per asset (BIBLE §3):

- **S3b, Blender procedural** (default for instruments and architecture):
  - `art/pipeline/blender/build_<asset>.py` uses `kit.py`.
  - Dimensions come from `assets.toml`; the concept image is only a shape reference.
  - Run: `blender -b --factory-startup -P art/pipeline/blender/build_coelostat.py`
- **S3a, Tripo** (organic and irregular props; needs `TRIPO_API_KEY`):
  - `python3 art/pipeline/tripo.py <asset> <concept.jpg>` writes `art/sources/tripo/<asset>/<task>.glb` plus a receipt.
  - Then clean it up in Blender: scale to spec, origin at bottom-centre, decimate to budget, check the palette and value of its texture. `ingest.py` is still **TODO**: write it on the first real Tripo run, using `kit.py` and `validate.py`.

- **S3c, people (MPFB route, r06):**
  - Set up once: `art/pipeline/setup_mpfb.sh`. It verifies the downloads by sha256 and installs MPFB into an isolated `BLENDER_USER_RESOURCES`.
  - Build: `eval "$(art/pipeline/setup_mpfb.sh --env)"`, then `blender -b --python art/pipeline/blender/build_person.py -- <id>`.
  - Specs live in `art/people/people.toml`. The build gives:
    - an MPFB body with the `game_engine` rig
    - **CC0-only** assets; a licence gate reads each file header
    - palette materials
    - a standing pose and the `idle` loop
    - head-bone accessories
  - In game: `world_builder._person()` swaps the figure in under the unchanged NPC body, and `main._update_npc_look()` drives the head look-at.

**G2:** `blender -b --factory-startup -P art/pipeline/blender/validate.py -- assets/models/<asset>.glb <asset>` checks:
- triangle budget, material count and texture size
- dimensions within tolerance
- origin
- no degenerate faces
- name prefix

It writes `art/validation/<asset>.g2.json`.

## S4 Validate in Godot (gates G3 and G4)

```bash
godot --headless --path . --import                       # pick up new/changed GLBs
# G3 neutral lookdev: scale refs, palette chips, 4 cameras incl. backlit silhouette
godot --path . --always-on-top res://scenes/lookdev.tscn -- --capture=$PWD/art/validation/g3-<label>
# G4 in-game benchmark: 7 bookmarks × game lighting states + render stats (fixed seed)
godot --path . --always-on-top -- --benchmark=$PWD/art/validation/g4-<label> --seed=7
python3 art/pipeline/compare.py art/validation/g4-baseline-v0.1 art/validation/g4-<label> --out art/validation/g4-<label>/compare.jpg
# Cost attribution: hide scene groups (veg_shrub, veg_palm, ...) and compare two runs
godot --path . --always-on-top -- --benchmark=$PWD/art/validation/g4-<label>-noX --seed=7 --bench-hide=veg_shrub
# Gameplay must be unchanged
godot --headless --path . --script res://tests/test_sim.gd
godot --path . --always-on-top -- --autoplay=careful --shots=/tmp/e1919 --speed=2
```

`--always-on-top` is required on macOS; a hidden window never finishes drawing.

Lookdev frames prop-sized rows with fixed cameras. Bigger rows, such as architecture, pull the cameras back automatically (`frame_scale` in `lookdev.json`). Capture architecture and props separately, e.g. `--assets=sun_shelter` and then `--assets=horizontal_tube`.

**G3 passes when:**
- the measured dimensions in `lookdev.json` match the spec
- the silhouette reads in the backlit shot
- the colours sit with the palette chips
- there are no lighting artifacts (inverted normals, shading seams)

**G4 passes when:**
- **Readability:** in every bookmark, the evidence is still the first read (squint test) and interactables are visible.
- **Performance**, reported as separate metrics and never conflated:
  - draw calls within +20% of the baseline per bookmark
  - **forced-draw** (uncapped render cost) avg ≤ 6 ms and within +25% of the baseline, or the cost justified in the review
  - wall-clock p95 ≤ 12 ms (median over repetitions; any single repetition above it is flagged in the review)
  - Use ≥ 3 repetitions (`art/pipeline/baseline.sh` + `perf_summary.py`) for any performance claim, with nothing else running on the machine.
  - Wall-clock averages are display-capped (~8.3 ms), and fewer primitives is not an FPS claim ([perf-r04](validation/perf-r04/README.md)).
- **Gameplay:** logic tests pass and the careful autoplay reaches its ending.
- **Concept parity:** the matching concept keyframe and the in-game shot agree on mood, value structure and key forms. They need not match in detail.

**G5 acceptance:** the Game Director sets `status = "accepted"` in `assets.toml` and records it in `LOG.md`.

## S5 Feed back

Every G3/G4 finding becomes exactly one of:
- a **prompt change** (version bump with a reason comment)
- a **spec change** (`assets.toml`)
- a **palette or grade change** (`palette.toml` → `palette_to_gd.py`, or `look.gd`)
- a **code change** (`world_builder.gd`)

Log it in the run's `REVIEW.md` and in `LOG.md`, then start the next run. Do not fix findings silently.

## S6 Record and hand off

| What | Where |
|---|---|
| Generated images, prompts, timings | `art/runs/<run>/` (jpg, `manifest.jsonl`, `contact.jpg`, `REVIEW.md`) |
| Prompt library (versioned) | `art/prompts/` |
| Style rules | `art/BIBLE.md` |
| Palette, asset contracts | `art/palette.toml`, `art/assets.toml` |
| Build scripts, validators, tools | `art/pipeline/` |
| Final assets | `assets/models/*.glb` (imported by Godot) |
| Validation evidence | `art/validation/` (G2 json, G3/G4 screenshots, `benchmark.json`, `compare.jpg`) |
| Decisions over time | `art/LOG.md`, plus `docs/DECISIONS.md` for major changes |

`art/` has a `.gdignore`, so Godot never imports concept images or exports them in the build.

## Series reuse

| Reusable as-is for the next era | Era-specific (copy and replace) |
|---|---|
| `art/pipeline/*` (gen, contact sheet, compare, Blender kit and validator, Tripo client), `prompts/series/base.toml`, lookdev scene, benchmark harness, gates, BIBLE §1 | `prompts/<era>/`, `palette.toml`, `assets.toml`, `scripts/look.gd` grade, BIBLE §2–§8 |
