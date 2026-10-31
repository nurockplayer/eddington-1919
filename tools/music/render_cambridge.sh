#!/usr/bin/env bash
# Render the composed cambridge_rain cue to assets/music/cambridge_rain.ogg.
#
# Steps: write one MIDI file per voice, render the sampled voices with
# sfz_render.py, synthesise the harmonium with reed.py, mix/fold/reverb in
# mix.py, encode with oggenc, then print check_cue.py numbers.
#
# Needs tools/music/setup_libs.sh to have run once (the two sample libraries).
# Scratch output stays in $WORK (default /private/tmp/edd-music-r1).
# Usage: bash tools/music/render_cambridge.sh
set -euo pipefail

CACHE=${EDD_SOUNDFONTS:-/Volumes/KIOXIA/eddington-1919-cache/soundfonts}
WORK=${EDD_MUSIC_WORK:-/private/tmp/edd-music-r1}
OUT=assets/music/cambridge_rain.ogg
SECONDS_PER_LOOP=64

# Patches, relative to $CACHE (see docs/audio/SOURCES.md for provenance).
PATCH_violin="VSCO-2-CE/SViolinVib.sfz"
PATCH_viola="VSCO-2-CE/ViolaEnsSusVib.sfz"
PATCH_cello="VSCO-2-CE/CelloEnsSusVib.sfz"
PATCH_piano="VCSL/Chordophones/Zithers/Upright Piano, Knight.sfz"

# Per-stem gain and pan (equal power). Harmonium is our own synthesis; its
# additive voice is much hotter than the sampled stems, hence the small gain.
# mix.py prints each stem's RMS against the cello's (keep within +6 dB).
GAIN_harmonium=0.05; PAN_harmonium=0.0
GAIN_cello=1.0;      PAN_cello=-0.2
GAIN_viola=0.8;      PAN_viola=0.15
GAIN_violin=0.9;     PAN_violin=0.3
GAIN_piano=1.7;      PAN_piano=0.0

patch_for() {
    case "$1" in
        violin) printf '%s' "$PATCH_violin" ;;
        viola)  printf '%s' "$PATCH_viola" ;;
        cello)  printf '%s' "$PATCH_cello" ;;
        piano)  printf '%s' "$PATCH_piano" ;;
        *) echo "no patch for $1" >&2; return 1 ;;
    esac
}

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

uv run --with numpy python tools/music/check_cue.py "$OUT"
