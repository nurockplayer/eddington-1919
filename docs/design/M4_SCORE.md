# M4 — Score and silence (Game Director spec)

This document describes the score that ships. The original all-procedural proposal was D013; D014 replaced its source restriction and Cambridge silence floor, and later work added `departure_promise`, the totality soundscape, and a diegetic gramophone. See [D013–D015](../DECISIONS.md), [audio sources](../audio/SOURCES.md), and [the gramophone spec](GRAMOPHONE.md).

## Intent

The score supports the journey without deciding what the evidence means. Cambridge has a composed, melodic rain cue; the departure has a promise and a montage motif; the three totality layers build and withdraw around the eclipse; the coda closes the journey. The gramophone is a separate diegetic historical recording.

## Cue inventory

| Cue | Where it plays (implementation) | Source class |
|---|---|---|
| `cambridge_rain` | Cambridge room, started by `scripts/cambridge/director.gd` `_build_audio`; the gramophone ducks it in `_gramophone_start` and restores it in `_gramophone_end`. | Sample-rendered composition using CC0 samples and the project's synthesized harmonium; `assets/music/cambridge_rain.ogg`. |
| `departure_promise` | Departure dialogue after the bond response; `scripts/cambridge/departure_director.gd` `_dialogue_done`. | Sample-rendered composition using CC0 samples and synthesized harmonium; `assets/music/departure_promise.ogg`. |
| `departure_motif` | Departure montage; `scripts/cambridge/departure_director.gd` `_montage` stops the promise and starts this cue. | Sample-rendered composition using CC0 samples and synthesized harmonium; `assets/music/departure_motif.ogg`. |
| `totality_drone` | 1919 totality, after the 2-second score hold following second contact; `scripts/main.gd` `_process_totality`. | Procedural GDScript synthesis (`scripts/audio/score.gd`); no sampled OGG is listed for this layer. |
| `totality_glass` | Starts with the drone and ducks while an exposure is open; `scripts/main.gd` `_process_totality`. | Procedural GDScript synthesis (`scripts/audio/score.gd`). |
| `totality_edge` | Last 18 game seconds before third contact, alongside the third-contact warning; `scripts/main.gd` `_process_totality`. | Procedural GDScript synthesis (`scripts/audio/score.gd`). |
| `coda_resolution` | Once at the ending; `scripts/cambridge/epilogue_director.gd` `_end_epilogue` and `scripts/main.gd` `_play_resolution`. | Sample-rendered composition using CC0 samples and synthesized harmonium; `assets/music/coda_resolution.ogg`. |
| `gramophone_home_fires_1915` | Diegetic record in the Cambridge room; `scripts/cambridge/director.gd` `_gramophone_start` and `_gramophone_end`. | Historical 1915 recording from the Library of Congress; public-domain status is documented in SOURCES.md. It is not CC0 and is not part of the composed score. |

The code uses a rendered OGG when one exists and keeps GDScript synthesis as fallback. Provenance and exact sample patches are in [SOURCES.md](../audio/SOURCES.md). The historical recording has separate provenance and rights notes there.

## Musical decisions still in force

- D014 permits CC0 sample sources for rendered cues and retains procedural synthesis for the totality layers. It replaces D013's ban on sample files, SoundFonts, and downloaded audio. No AI-generated music.
- The motif's F♯ resolution belongs in the coda; the metronome remains the only pulse during totality. Music does not read cloud density or feed back into play.
- D014 lowers the `cambridge_rain` near-silence floor from 40% to about 20% of the loop.
- D015's mix targets and measured levels are recorded in [D015](../DECISIONS.md); sampled cues have individual offsets and the synthesized fallback cues target −24 dBFS.

## Silence and transitions in the shipped game

- 1919 PREP has no score. The score is held for 2 seconds after second contact before `totality_drone` and `totality_glass` fade in. The soundscape also fades birds out over 6 seconds, dips surf by 18 dB over 1.5 seconds, and fades insects up from −60 dB over 3 seconds. See `scripts/main.gd` `_quiet_birds`, `_begin_totality`, and the second-contact transition in `_process_totality`.
- During totality the glass layer ducks to silence over 0.4 seconds while the shutter is open and returns over 1.2 seconds after it closes. The drone continues. The edge layer enters for the last 18 game seconds. All three score layers stop with a 1.5-second fade at third contact; NIGHT remains unscored.
- Departure is scored: `departure_promise` plays in the dialogue and `departure_motif` in the montage. The former fades out as the latter begins.
- The gramophone ducks `cambridge_rain` to silence over 1.5 seconds and restores it over 3 seconds when playback ends.
- The coda resolution is triggered by the journey's ending flow, not by a verdict or a successful measurement.

## Superseded proposal

D013's procedural-only rule and its 40% `cambridge_rain` silence test no longer describe the shipped score; D014 replaced them with the sampled cue policy and about-20% Cambridge silence floor. The proposed fixed cue levels, durations, spectral tests, rendering-thread requirements, Music-bus/toggle design, and proposed test checklist in the earlier version of this document are not current requirements. Current implementation and provenance are described above and in the linked decisions and source inventory.
