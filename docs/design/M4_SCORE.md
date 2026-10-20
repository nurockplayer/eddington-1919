# M4 — Original procedural score (Game Director spec)

Owner direction (2026-10-20): "an original procedural score (no external assets): Cambridge rain, totality tension, coda resolution. Keep it restrained."

## Intent

The music should be felt more than noticed. It has three jobs:

- Cambridge: make the rainy room feel lonely and patient.
- Totality: hold the player's breath without telling them anything the sky does not already show.
- Coda: let the journey land.

Silence is the default. Most of the game stays unscored: 1919 PREP, the darkroom NIGHT, and almost all of M2.

## One motif, one instrument family

- **Instrument: a reed-organ (harmonium) voice.** An Edwardian parlour or chapel would plausibly have had one. Build it additively:
  - Partials 1–7, amplitude roughly 1/n with partial 2 slightly emphasised.
  - A gentle low-pass, and an attack of ≥0.6 s and release of ≥1.2 s.
  - A faint bellows swell: slow amplitude drift of ±1.5 dB at 0.1–0.2 Hz. No vibrato.
- **Second voice for totality only: "glass".** Near-pure sines with a slow beat between two slightly detuned partials (0.3–0.8 Hz beating).
- **Motif, "the plate":** A3 – D4 – E4 – F4, rising, with F4 left unresolved (D minor, open).
  - Each note ~1.6 s, overlapping, with legato release.
  - The coda answers it with A3 – D4 – E4 – **F♯4**, settling on a D major chord (D3 A3 D4 F♯4). The third changes from minor to major. That change is the whole payoff, so the motif must not resolve to F♯ anywhere else.
- **Tuning:** equal temperament, A4 = 440 Hz.

## Cues

| Cue id | Where | Shape | Target level (`volume_db` on Music bus) |
|---|---|---|---|
| `cambridge_rain` | M1 `scenes/cambridge.tscn`, from the opening fade-in until the montage fade begins | Seamless loop, 48–64 s. Sparse two- and three-note harmonium chords in D Dorian/minor (Dm, Gm/D, C/D, Am). Each chord lasts 4–8 s, with **at least 40% of the loop silent**. The motif is stated once per loop, softly, and never with F♯. | −30 dB (rain bed is −21 dB) |
| `departure_motif` | M2, departure montage only (`_montage()` fade), once | Single motif statement, 8–10 s, then fade. No other M2 music: the clock and street carry that night. | −30 dB |
| `totality_drone` | 1919 TOTALITY, from the fade-in after second contact | Loop, 20–30 s. Open fifth D2 + A2, sustained, no rhythmic content. | −30 dB |
| `totality_glass` | layered over the drone | Loop, 20–30 s. E4 + A4 glass with slow beating. | −34 dB, see behaviour below |
| `totality_edge` | layered, last 18 game seconds only (same trigger as the "第三接觸快到了" toast) | Loop. Adds G2 (a sus4 against the drone), so the drone stays unresolved. | fades in over 3 s to −32 dB |
| `coda_resolution` | Once per run, at whichever comes first: coda lamp-out (`_end_coda`, start of the lamp tween), or `_show_ending` for players with no coda | Answer motif, then the D major chord held 6–8 s and released; total 14–18 s. It must carry across the fade into the ending panel without being cut. | −28 dB |

### Totality behaviour (time-based on game state only)

- **Pulse:** the metronome is the only pulse. Score cues contain no rhythm at all.
- **Exposures:** while `sim.is_exposing()`, `totality_glass` ducks to silence over 0.4 s and returns over 1.2 s after the shutter closes. The drone holds, like a held breath.
- **Clouds:** the score must **not** react to cloud density or to anything else the player could use as a hint. Inputs are limited to t_game, the exposure state and the phase.
- **End of totality:** all totality layers fade out over 1.5 s with the light return. Silence follows.
- **Pause:** layer volumes are driven from `_process_totality`, so they freeze under pause and the Tab log just as t_game does. The streams themselves may keep sounding, which is fine.

## Spectral and mix rules (testable)

- **No energy near the tick.** All score cues have negligible energy at 1.5–2.4 kHz, the metronome's band (the tick is at 1900 Hz). Guard this with a Goertzel test at 1900 Hz relative to the cue's RMS.
- **No clipping, generous headroom.** Peak |sample| ≤ 0.5 before `volume_db`, and RMS well below that.
- **Clean loop seams.** The last ~50 ms crossfades into the first, or both ends sit at zero with matching slope. Test that the |Δ| across the seam is no larger than the 99th-percentile |Δ| inside the loop.
- **Music bus.** Create a `Music` bus at runtime (`AudioServer.add_bus`) if it is missing; do not add a bus-layout file unless that is cleaner. Every score player uses it.
- **Music toggle.** Add a `音樂：開／關` toggle to the pause menu that mutes the Music bus, persisted in `user://settings.cfg` (ConfigFile). The default is on.

## Hard rules

1. **Music never changes simulation, score, timing or bot outcomes.**
   - Score code must not call the global `randf()`/`randi()`/`randomize()`. Use a private `RandomNumberGenerator` with a fixed seed.
   - Required unchanged on the bots: careful 4, rushed `--seed=515` 0, cherry `--seed=4242` 3, and honest prologue autoplay reaching ENDING with the coda.
   - All existing suites must keep passing with the same counts.
2. **Original and procedural only.**
   - No sample files, no SoundFonts, no downloaded or generated audio, and no third-party melody.
   - Everything is synthesised in GDScript from the code in this repo.
3. **Rendering must not hitch.**
   - Render on a worker thread (`WorkerThreadPool` or `Thread`) and start each cue when it is ready.
   - Cache rendered streams in a static dictionary so 1919 replays do not re-render.
   - Main-thread cost added to scene `_ready` must be ≤ 30 ms per scene.
   - If a cue is not ready when its trigger fires, skip it or start it late with a fade-in. Never block.
   - Rendering at 22050 Hz is fine. 11025 Hz is acceptable for `totality_drone` only if the result stays clean.
4. **Headless tests.** Under `--headless` the score system may render synchronously or skip playback, but render functions must still be testable directly.
5. **Dialogue.** Content files stay untouched: `content_1917.gd`, `content_departure.gd`, `content_coda.gd`, `cast.gd`.

## Code shape (suggested)

- **`scripts/audio/score.gd`:**
  - Pure static synthesis: `render(cue: String) -> PackedFloat32Array` plus helpers (`reed(note, dur, …)`, `glass(…)`, envelope, one-pole low-pass).
  - Deterministic: the same output on every call.
  - Also `stream(cue) -> AudioStreamWAV` (via the existing `_wav`) with the cache.
- **`scripts/audio/score_player.gd` (Node):**
  - `play(cue, fade_in)`, `stop(cue, fade_out)`, `set_layer_db(cue, db, time)`.
  - Owns the Music bus and its AudioStreamPlayers.
  - Uses threaded render, and tweens with `TWEEN_PAUSE_STOP` where a fade belongs to a paused beat. Follow the existing pattern.
- **Wiring:** in `scripts/cambridge/director.gd`, `scripts/cambridge/departure_director.gd` and `scripts/main.gd`, at the trigger points named above.
- **`tools/render_score.gd`:** a `--script` tool that writes each cue to `user://score/<cue>.wav`, or to a path argument, for audition.

## Tests (new `tests/test_score.gd`)

- **Determinism:** each cue renders identically twice.
- **Global RNG untouched:**
  1. `seed(1234)` and capture `randf()` ×3.
  2. `seed(1234)` again, render every cue, then capture `randf()` ×3.
  3. The two captures must be equal.
- **Signal checks:** peak ≤ 0.5, loop seams continuous, and 1900 Hz Goertzel energy below the threshold for every cue.
- **Silence:** `cambridge_rain` is ≥ 40% near-silent (by frame RMS).
- **Resolution placement:** F♯ appears only in `coda_resolution`. Test this with a Goertzel at F♯4 = 369.99 Hz against F4 = 349.23 Hz on the motif cues.
- **Durations** fall within the ranges above.
- **Wiring:** a cue-trigger log in the score player that the bots can assert.
  - The 1919 careful bot logs `totality_drone` start, `totality_glass` ducks during exposures, then the totality stop and `coda_resolution` or ending.
  - The honest prologue run logs `cambridge_rain`, `departure_motif`, `totality_*` and `coda_resolution` once.
- **Music toggle:** muting the bus sets mute and survives a ConfigFile round-trip (use a test path, never the player's real settings file).

## Out of scope

- Adaptive stingers on discoveries, PREP/NIGHT music, and per-grade variants of the resolution.
- Any external or licensed music. The Owner's earlier "music sourcing" question is answered by this original score.
