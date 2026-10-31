# Audio sources

Provenance for the rendered music assets. All sample libraries are CC0 1.0
Universal (https://creativecommons.org/publicdomain/zero/1.0/): no
attribution is required, this file records it anyway.

The sample libraries live outside the repo in the approved cache
`/Volumes/KIOXIA/eddington-1919-cache/soundfonts` (see
`tools/music/setup_libs.sh`). `PINS.txt` in that folder records the commits
below; they are pinned here as well.

| Library | Source | Commit | Licence |
| --- | --- | --- | --- |
| VSCO 2 Community Edition (SFZ branch) | https://github.com/sgossner/VSCO-2-CE | `6dd651d55dde97fd4028699be9d4481f26917891` | CC0 1.0 |
| Versilian Community Sample Library (sfz branch) | https://github.com/sgossner/VCSL | `dfcf4a4918771eee884b96ad4493de82ef84daf6` | CC0 1.0 |

Renderer: `tools/music/sfz_render.py` (this repo, written for this cue).
The harmonium is not sampled: `tools/music/reed.py` ports the reed voice from
`scripts/audio/score.gd`, so that stem is original synthesis by this project.

## Patches

| Voice | Patch |
| --- | --- |
| violin | `VSCO-2-CE/SViolinVib.sfz` (solo violin, arco vibrato sustain) |
| viola | `VSCO-2-CE/ViolaEnsSusVib.sfz` (viola section sustain; VSCO 2 CE ships no solo viola sustain) |
| cello | `VSCO-2-CE/CelloEnsSusVib.sfz` (cello section sustain; VSCO 2 CE ships no solo cello sustain) |
| piano | `VCSL/Chordophones/Zithers/Upright Piano, Knight.sfz` |
| harmonium | original synthesis, `tools/music/reed.py` |

## Rendered assets

| Asset | Sources |
| --- | --- |
| `assets/music/cambridge_rain.ogg` | VSCO 2 CE `SViolinVib.sfz`, `ViolaEnsSusVib.sfz`, `CelloEnsSusVib.sfz`; VCSL `Upright Piano, Knight.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cambridge.py`. |
