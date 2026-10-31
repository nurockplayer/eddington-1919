#!/usr/bin/env bash
# Render one of the one-shot cues to assets/music/<cue>.ogg.
#
# departure_motif and coda_resolution do not loop: compose_cues.py writes the
# MIDI, sfz_render.py / reed.py render the voices the cue uses, mix.py mixes
# them with --oneshot (linear reverb tail, cut to the cue length, faded out),
# oggenc encodes, then check_cue.py --oneshot prints the numbers.
#
# Needs tools/music/setup_libs.sh to have run once (the two sample libraries).
# Scratch output stays in $WORK (default /private/tmp/edd-music-r2).
# Usage: bash tools/music/render_cue.sh departure_motif|coda_resolution
set -euo pipefail

CUE=${1:?usage: bash tools/music/render_cue.sh departure_motif|coda_resolution}
CACHE=${EDD_SOUNDFONTS:-/Volumes/KIOXIA/eddington-1919-cache/soundfonts}
WORK=${EDD_MUSIC_WORK:-/private/tmp/edd-music-r2}
OUT=assets/music/$CUE.ogg

case "$CUE" in
    departure_motif) LENGTH=10.5 ;;
    coda_resolution) LENGTH=16.5 ;;
    *) echo "unknown cue: $CUE" >&2; exit 1 ;;
esac

# shellcheck source=tools/music/patches.sh
source "$(dirname "$0")/patches.sh"

mkdir -p "$WORK/midi" "$WORK/stems" "$(dirname "$OUT")"

uv run --with numpy python tools/music/compose_cues.py "$WORK/midi"

for voice in cello viola violin piano; do
    midi="$WORK/midi/${CUE}_$voice.mid"
    [ -f "$midi" ] || continue
    echo "render $voice"
    uv run --with numpy --with soundfile python tools/music/sfz_render.py \
        "$CACHE/$(patch_for "$voice")" "$midi" "$WORK/stems/${CUE}_$voice.wav"
done

midi="$WORK/midi/${CUE}_harmonium.mid"
if [ -f "$midi" ]; then
    echo "render harmonium (reed.py)"
    uv run --with numpy python tools/music/reed.py \
        "$midi" "$WORK/stems/${CUE}_harmonium.wav"
fi

STEMS=()
for voice in harmonium cello viola violin piano; do
    wav="$WORK/stems/${CUE}_$voice.wav"
    [ -f "$wav" ] || continue
    gain_var="GAIN_$voice"
    pan_var="PAN_$voice"
    STEMS+=(--stem "$voice" "$wav" "${!gain_var}" "${!pan_var}")
done

echo "mix"
uv run --with numpy python tools/music/mix.py \
    --out "$WORK/$CUE.wav" \
    --oneshot --seconds "$LENGTH" \
    "${STEMS[@]}"

echo "encode $OUT"
oggenc -q 5 --serial 1919 -o "$OUT" "$WORK/$CUE.wav"

uv run --with numpy python tools/music/check_cue.py --oneshot "$OUT"
