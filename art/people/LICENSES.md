# Character asset licences (r06)

All third-party content in `assets/models/eddington.glb` and `assets/models/cottingham.glb` is **CC0**. This is enforced at build time. MPFB's bundled inputs (base mesh, `game_engine` rig and weights, morph targets) are checked too: the base mesh by its CC0 header, the rest pinned by sha256 to MPFB 2.0.18, so any change stops the build until reviewed. `build_person.py` also refuses any descriptor, and any geometry file it references (`obj_file`), whose header lacks the affirmative line "This asset was explicitly released as CC0". A mere mention of CC0 is not enough (r06 review). Everything else is made in this repo: hats, glasses, the moustache, palette materials, pose and idle animation.

| Item | Source | Licence | Evidence |
|---|---|---|---|
| MPFB 2.0.18 (tool, never shipped) | Blender Extensions platform, `extensions.blender.org/add-ons/mpfb/`. Download sha256 `c075b3e9…2a2dad` is verified by `art/pipeline/setup_mpfb.sh`. | GPL-3.0-or-later | The extension page. Only the tool's *output* ships, not its code. |
| MakeHuman base mesh and targets, used through MPFB | MPFB bundled data (`3dobjs/base.obj`, targets) | CC0 | File header: "This asset was explicitly released as CC0 in september 2020". MakeHuman licence page: "All core assets are shared under … CC0". |
| `game_engine` rig and weights | MPFB bundled data (`rigs/standard/*.json`) | CC0 | MPFB contributor docs describe "MPFB's promise that all bundled assets are CC0". |
| Body proxy `male1591`, hair `short02`, eyebrows `eyebrow010` and `eyebrow004`, eyes `low-poly`, `male_elegantsuit01`, `male_casualsuit01`, `shoes02` | MakeHuman system assets pack `makehuman_system_assets_cc0.zip` (files2.makehumancommunity.org; sha256 `b542127a…bc8028a0107` recorded 2026-10-20) | CC0 | The pack page lists every item as CC0. Each file's header says "explicitly released as CC0 in september 2020 … Copyright (C) 2020 Data Collection AB". |

**Not used, on purpose:** any CC-BY pack (e.g. Hair 02/03, Suits 03/04, Glasses 02, System eye materials 03), community assets, and MakeHuman skin textures. Skins are flat palette colours by art direction, so no photographic skin texture ships.

**Note on authorship:** CC0 asks for no attribution, but we credit the MakeHuman Community and Data Collection AB in `docs/PROVENANCE.md`.

## Cambridge exports (2026-10-26 JST)

`ashby.glb` and `eddington_cambridge.glb` reuse the same checked CC0 base,
`game_engine` rig, `male1591` proxy, `short02` hair, `eyebrow004` (Ashby) /
`eyebrow010` (Eddington), `low-poly` eyes, `male_elegantsuit01` and `shoes02`.
The existing affirmative-header and bundled-input SHA gates apply unchanged.
No new third-party download is required. Grey moustache and spectacles are
repo-authored procedural geometry; palette, garment region colours and poses
are repo-authored. No skin or fabric textures ship in either GLB.

The four dialogue JPEGs are exact copies of Owner-approved generated p02 picks,
with source filenames and manifest ids recorded in `REFERENCE.md` and
`art/runs/p02-portraits/manifest.jsonl`. They are labelled reconstructions in the
runtime UI; Ashby is fictional. No new image generation or paid API is used here.
