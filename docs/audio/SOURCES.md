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
| `assets/music/departure_motif.ogg` | VSCO 2 CE `CelloEnsSusVib.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cues.py`, rendered by `tools/music/render_cue.sh` (same patches and gains as the loop). |
| `assets/music/coda_resolution.ogg` | VSCO 2 CE `SViolinVib.sfz`, `ViolaEnsSusVib.sfz`, `CelloEnsSusVib.sfz`; VCSL `Upright Piano, Knight.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cues.py`, rendered by `tools/music/render_cue.sh` (same patches and gains as the loop). |

## Historical gramophone recording

`assets/audio/gramophone_home_fires_1915.ogg` is a trimmed transfer of a
1915 Victor disc from the Library of Congress National Jukebox. It is a
historical sound recording, not a render of the sample libraries above, and
the CC0 statements at the top of this file do not cover it.

| Field | Value |
| --- | --- |
| Title | "Keep the Home-Fires Burning (Till the Boys Come Home)" |
| Composer | Ivor Novello (1893–1951) |
| Lyricist | Lena Guilbert Ford (d. 1918) |
| Performer | Frederick J. Wheeler, baritone |
| Orchestra | conducted by Walter B. Rogers |
| Disc | Victor 17881, matrix B-16626 take 3 |
| Recorded | 1915-10-08, Camden, NJ |
| First issued | December 1915 |
| Catalogue | https://www.loc.gov/item/jukebox-15093/ |
| Audio | https://data.labs.loc.gov/jukebox/audio/jukebox-15093_1.mp3 |
| Source MD5 | `d0df2e6378e5f61fea5a16ea59676a0b` |
| Dataset | https://data.labs.loc.gov/jukebox/ |

First-release evidence: The Talking Machine World, November 1915, "Record
Bulletins for December, 1915".

Rights: US public domain since 2022-01-01 (sound recording published before
1923). Music and words in the UK/EU public domain since 2022-01-01. UK/EU
sound-recording term expired. No later arranger credited on the LoC item.
Not CC0.

Attribution: Library of Congress, National Jukebox.

Processing (`tools/music/prepare_gramophone.sh`, which downloads the MP3 into
the KIOXIA cache, verifies the MD5 and rebuilds the OGG):

- Trim of the 164.4 s transfer to 0.0–77.3 s: the disc's 0.60 s of surface
  noise before the band enters, through one verse and the first chorus, cut
  inside the section rest at 77.00–77.55 s.
- Mono, 0.3 s fade-in, 2 s fade-out. No denoise, no EQ.
- Peak measured and normalised with `volume=`: 0.475 in the PCM, which
  decodes at 0.491, inside the 0.5 ceiling.
- `oggenc -q 4 --serial 1915`.
- SHA-256 of the OGG:
  `b065b69732f9b06ca3532ae290f4e07747ee834e777e7ba7a5cd88b88a077dec`.
