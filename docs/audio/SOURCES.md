# Audio sources

Provenance for every sound the release plays: the audio files it ships and the
sounds the game synthesises while it runs.

`tools/audio_provenance.py` checks this file against the release export. Every
audio file an `export_presets.cfg` preset ships needs one `File` row with its
SHA-256, every function in a shipped script that synthesises sound needs one
`Generator` row, and a row with nothing shipped behind it fails as well. Run
`python3 -I tools/audio_provenance.py` after adding, re-rendering or removing a
sound, and update the row in the same change.

Licence classes used below:

| Class | Meaning |
| --- | --- |
| CC0 1.0 | The recording itself is CC0 1.0 Universal. |
| Original + CC0 1.0 samples | Composed and rendered by this project from CC0 1.0 sample libraries and this project's own synthesis. |
| Original | Synthesised by this project's code; no third-party material. |
| Public domain, not CC0 | A historical recording in the public domain; no CC0 statement in this file covers it. |

## CC0 samples and recordings

All sample libraries and field recordings in this section are CC0 1.0
Universal (https://creativecommons.org/publicdomain/zero/1.0/): no attribution
is required, this file records it anyway.

### Sample libraries

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

| Voice | Patch |
| --- | --- |
| violin | `VSCO-2-CE/SViolinVib.sfz` (solo violin, arco vibrato sustain) |
| viola | `VSCO-2-CE/ViolaEnsSusVib.sfz` (viola section sustain; VSCO 2 CE ships no solo viola sustain) |
| cello | `VSCO-2-CE/CelloEnsSusVib.sfz` (cello section sustain; VSCO 2 CE ships no solo cello sustain) |
| piano | `VCSL/Chordophones/Zithers/Upright Piano, Knight.sfz` |
| harmonium | original synthesis, `tools/music/reed.py` |

### Rendered music

| File | Source | Author | Licence class | SHA-256 |
| --- | --- | --- | --- | --- |
| `assets/music/cambridge_rain.ogg` | VSCO 2 CE `SViolinVib.sfz`, `ViolaEnsSusVib.sfz`, `CelloEnsSusVib.sfz`; VCSL `Upright Piano, Knight.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cambridge.py`, rendered by `tools/music/render_cambridge.sh`. | Eddington 1919 project; samples by Versilian Studios | Original + CC0 1.0 samples | `2ba282cd4eac291f339442b33879e5aa170b0cab68abc5771110f7118ff66d9f` |
| `assets/music/departure_motif.ogg` | VSCO 2 CE `CelloEnsSusVib.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cues.py`, rendered by `tools/music/render_cue.sh` (same patches and gains as the loop). | Eddington 1919 project; samples by Versilian Studios | Original + CC0 1.0 samples | `20637cf73b21d43d2e79ce7672930ceaa89147c2168b8d870d5dace56336aea3` |
| `assets/music/departure_promise.ogg` | VSCO 2 CE `ViolaEnsSusVib.sfz`; VCSL `Upright Piano, Knight.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cues.py`, rendered by `tools/music/render_cue.sh` (same patches and gains as the loop). | Eddington 1919 project; samples by Versilian Studios | Original + CC0 1.0 samples | `97ad014cd9f618cca69120a643569dd32a5c1e31708ed8713bebeba9fa10749d` |
| `assets/music/coda_resolution.ogg` | VSCO 2 CE `SViolinVib.sfz`, `ViolaEnsSusVib.sfz`, `CelloEnsSusVib.sfz`; VCSL `Upright Piano, Knight.sfz`; original harmonium synthesis (`tools/music/reed.py`). Composed by `tools/music/compose_cues.py`, rendered by `tools/music/render_cue.sh` (same patches and gains as the loop). | Eddington 1919 project; samples by Versilian Studios | Original + CC0 1.0 samples | `ebc72e5da22840e995b031b1caa824ddf5939b36e9d0c0e8e645b45a6fe82a51` |

### Field recordings

These recordings were downloaded on 2026-11-14 JST. Each excerpt was mixed to
mono at 44.1 kHz, with a two-second tail-to-head crossfade and no processing
gain; playback gain matches the synthesized bed's effective RMS. The bird and
insect beds use Freesound HQ previews (lossy MP3 sources) of CC0 sounds.
SHA-256 is the shipped OGG; Raw SHA-256 is the downloaded source.

| File | Source | Author | Licence class | SHA-256 | Excerpt (start, source length) | Raw SHA-256 |
| --- | --- | --- | --- | --- | --- | --- |
| `assets/sfx/bed_birds.ogg` | https://freesound.org/people/felix.blume/sounds/868965/ | felix.blume | CC0 1.0 | `cf2a682242647c1ddcada3dba67c0bb2b17ecbb2801e3c14a1a1b35b4b004b97` | 60 s, 62 s | `20f899e4fa61e458844acb715afaba8119c28a962d4c52226f296416bb5c1ce9` |
| `assets/sfx/bed_insects.ogg` | https://freesound.org/people/felix.blume/sounds/669221/ | felix.blume | CC0 1.0 | `eb2d60868bb882b6d72f558176c0771142bd1cd2725a800e18a6bee3e1190395` | 60 s, 62 s | `147d3db1aefbe3dc7378a916e2a5e3281ddbd1a5637c6073c6b75841214168d8` |
| `assets/sfx/bed_surf.ogg` | https://bigsoundbank.com/small-waves-and-beach-2-s1448.html | Joseph Sardin | CC0 1.0 | `efe11f662dac3d83a78a207239699a75cc5d5284ac0b0383a42822bbc579173c` | 300 s, 42 s | `ae2432cb02c10e1b27c377ad038cde0d6568b3bc6782b44b00b6320cef728472` |

## Historical recording (not CC0)

`assets/audio/gramophone_home_fires_1915.ogg` is a trimmed transfer of a
1915 Victor disc from the Library of Congress National Jukebox. It is a
historical sound recording, not a render of the sample libraries above, and
the CC0 statements in this file do not cover it.

| File | Source | Author | Licence class | SHA-256 |
| --- | --- | --- | --- | --- |
| `assets/audio/gramophone_home_fires_1915.ogg` | Library of Congress National Jukebox, https://www.loc.gov/item/jukebox-15093/ (Victor 17881), trimmed by `tools/music/prepare_gramophone.sh` | Frederick J. Wheeler with orchestra conducted by Walter B. Rogers; music Ivor Novello, words Lena Guilbert Ford | Public domain, not CC0 | `b065b69732f9b06ca3532ae290f4e07747ee834e777e7ba7a5cd88b88a077dec` |

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
- `oggenc -q 4 --serial 1915`; the SHA-256 of the result is in the row above.

## Runtime synthesis

No file ships for these sounds: the game computes their samples when it runs.
One row per function that turns computed samples into a sound.

| Generator | Sounds | Author | Licence class |
| --- | --- | --- | --- |
| `scripts/main.gd::_build_audio` | Príncipe: metronome tick, prep-completion click, shutter open, plate change, third-contact chime; synthesised insect, surf and bird beds, replaced by the field recordings above whenever those files ship | Eddington 1919 project | Original |
| `scripts/player.gd::_synth_step` | footsteps, wood and earth, three variants each | Eddington 1919 project | Original |
| `scripts/ui.gd::_build_viewer_sfx` | darkroom plate viewer: plate select, mark (also the micrometer tick), measure | Eddington 1919 project | Original |
| `scripts/audio/score.gd::stream` | score cues `totality_drone`, `totality_glass`, `totality_edge` (synthesised in `render`); synthesised stand-ins for the four rendered cues above, used only when their OGG is absent | Eddington 1919 project | Original |
| `scripts/audio/score.gd::_envelope_resolution` | stereo PCM for `coda_resolution`, with attack and release applied to the shipped OGG listed above | Eddington 1919 project; samples by Versilian Studios | Original + CC0 1.0 samples |
| `scripts/cambridge/director.gd::_build_audio` | Cambridge study: clock tick, click, rain bed | Eddington 1919 project | Original |
| `scripts/cambridge/director.gd::_build_foley` | Cambridge light box: paper flip, plate nudge, star fields settling, pencil mark | Eddington 1919 project | Original |
| `scripts/cambridge/departure_director.gd::_build_audio` | departure: clock tick, street bed | Eddington 1919 project | Original |
| `scripts/cambridge/epilogue_director.gd::_build_audio` | epilogue: clock tick, street bed | Eddington 1919 project | Original |
| `tools/render_score.gd::_run` | none in play: a developer tool that writes the score cues to WAV for audition; it ships because the export presets do not exclude `tools/` | Eddington 1919 project | Original |
