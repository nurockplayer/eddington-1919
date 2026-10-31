#!/usr/bin/env bash
# Render the composed cambridge_rain cue to assets/music/cambridge_rain.ogg.
#
# Steps: write one MIDI file per voice, render the sampled voices with
# sfz_render.py, synthesise the harmonium with reed.py, mix/fold/reverb in
# mix.py, encode with oggenc, then run the strict check_cue.py check.
#
# Needs tools/music/setup_libs.sh to have run once (the two sample libraries).
# Scratch output stays in $WORK (default /private/tmp/edd-music-r1).
# Usage: bash tools/music/render_cambridge.sh
set -euo pipefail

CACHE=${EDD_SOUNDFONTS:-/Volumes/KIOXIA/eddington-1919-cache/soundfonts}
WORK=${EDD_MUSIC_WORK:-/private/tmp/edd-music-r1}
OUT=assets/music/cambridge_rain.ogg
SECONDS_PER_LOOP=64

# Patches and per-stem gain/pan (relative to $CACHE; see
# docs/audio/SOURCES.md for provenance) come from the shared table.
# shellcheck source=tools/music/patches.sh
source "$(dirname "$0")/patches.sh"

mkdir -p "$WORK/midi" "$WORK/stems" "$(dirname "$OUT")"

uv run --with numpy python tools/music/compose_cambridge.py "$WORK/midi"

for voice in cello viola violin piano; do
    echo "render $voice"
    uv run --with numpy --with soundfile python tools/music/sfz_render.py \
        "$CACHE/$(patch_for "$voice")" \
        "$WORK/midi/cambridge_$voice.mid" \
        "$WORK/stems/$voice.wav"
done

echo "render harmonium (reed.py)"
uv run --with numpy python tools/music/reed.py \
    "$WORK/midi/cambridge_harmonium.mid" "$WORK/stems/harmonium.wav"

echo "mix"
uv run --with numpy python tools/music/mix.py \
    --out "$WORK/cambridge_rain.wav" \
    --seconds "$SECONDS_PER_LOOP" \
    --stem harmonium "$WORK/stems/harmonium.wav" "$GAIN_harmonium" "$PAN_harmonium" \
    --stem cello "$WORK/stems/cello.wav" "$GAIN_cello" "$PAN_cello" \
    --stem viola "$WORK/stems/viola.wav" "$GAIN_viola" "$PAN_viola" \
    --stem violin "$WORK/stems/violin.wav" "$GAIN_violin" "$PAN_violin" \
    --stem piano "$WORK/stems/piano.wav" "$GAIN_piano" "$PAN_piano"

echo "encode $OUT"
oggenc -q 5 --serial 1919 -o "$OUT" "$WORK/cambridge_rain.wav"

uv run --with numpy python tools/music/check_cue.py --strict --expect-seconds "$SECONDS_PER_LOOP" "$OUT"
