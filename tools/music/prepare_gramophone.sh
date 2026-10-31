#!/usr/bin/env bash
# Trim the Library of Congress transfer of Victor 17881 (Frederick J. Wheeler,
# "Keep the Home-Fires Burning") to one verse and the first chorus, and encode
# assets/audio/gramophone_home_fires_1915.ogg.
#
# The transfer runs 164.4 s. A 1 s RMS envelope of the whole file is printed
# on every run; the cut points were chosen from it:
#   START = 0.0   The disc opens with 0.60 s of surface noise (first 1 s RMS
#                 0.017, against 0.15-0.20 once the band plays) before the
#                 band enters at 0.60 s. The design asks for the needle drop,
#                 so the trim starts at the first sample.
#   END   = 77.3  The first section ends at 76.95 s and the band comes back
#                 hard at 77.60 s (1 s RMS 0.20). The rest between, 0.55 s
#                 (77.00-77.55), is the longest pause between phrases in the
#                 playing time (the other phrase gaps are 0.15-0.45 s), and
#                 it closes the first half of the performance: one verse and
#                 the first chorus. 77.3 sits inside the rest, so the 2 s
#                 fade-out covers the last phrase and its decay.
#
# Processing: mono, 0.3 s fade-in, 2 s fade-out, peak measured and then
# normalised with `volume=`, OGG Vorbis q4. No denoise, no EQ: the
# acoustic-era sound is the point.
#
# Needs curl, ffmpeg, oggenc and uv. The MP3 is cached in $CACHE (KIOXIA, kept
# between runs, so the download happens once); scratch output stays in $WORK
# (default /private/tmp/edd-gramo). Runs from the repo root.
# Usage: bash tools/music/prepare_gramophone.sh
set -euo pipefail

# Cut points in the source transfer, in seconds.
START=0.0
END=77.3

URL=https://data.labs.loc.gov/jukebox/audio/jukebox-15093_1.mp3
SRC_MD5=d0df2e6378e5f61fea5a16ea59676a0b
CACHE=${EDD_GRAMOPHONE_CACHE:-/Volumes/KIOXIA/eddington-1919-cache/gramophone}
WORK=${EDD_GRAMO_WORK:-/private/tmp/edd-gramo}
OUT=assets/audio/gramophone_home_fires_1915.ogg
SRC=$CACHE/jukebox-15093_1.mp3

mkdir -p "$CACHE" "$WORK" "$(dirname "$OUT")"

if [ ! -f "$SRC" ]; then
    echo "download $URL"
    curl -fL --retry 2 -o "$SRC.part" "$URL"
    mv "$SRC.part" "$SRC"
fi

actual=$(md5 -q "$SRC")
if [ "$actual" != "$SRC_MD5" ]; then
    echo "MD5 mismatch for $SRC: got $actual, expected $SRC_MD5" >&2
    exit 1
fi
echo "source $SRC (md5 $actual)"

echo "1 s RMS envelope of the source"
uv run --with numpy python -I - "$SRC" <<'PY'
import subprocess
import sys

import numpy as np

RATE = 48000
raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", sys.argv[1], "-f", "f32le", "-ac", "1",
     "-ar", str(RATE), "-"],
    check=True, capture_output=True,
).stdout
x = np.frombuffer(raw, dtype="<f4").astype(np.float64)
print(f"duration {x.size / RATE:.3f} s")
frames = x.size // RATE
rms = np.sqrt(np.mean(x[: frames * RATE].reshape(frames, RATE) ** 2, axis=1))
for i, r in enumerate(rms):
    print(f"{i:4d} s  rms {r:.4f}")
PY

FADE_OUT_ST=$(awk -v e="$END" -v s="$START" 'BEGIN { printf "%.3f", e - s - 2.0 }')
echo "trim $START-$END s, mono, 0.3 s fade-in, 2 s fade-out"
ffmpeg -v error -y -ss "$START" -to "$END" -i "$SRC" -ac 1 -c:a pcm_s16le \
    -af "afade=t=in:st=0:d=0.3,afade=t=out:st=$FADE_OUT_ST:d=2" \
    "$WORK/gramophone_trim.wav"

# Measure the trimmed peak, then apply the gain that brings it to 0.475. The
# design's ceiling is 0.5 and the Vorbis encode lifts the decoded peak by
# about 3 %: 0.475 in the PCM decodes at 0.491, 0.5 would overshoot.
PEAK=$(uv run --with numpy python -I - "$WORK/gramophone_trim.wav" <<'PY'
import subprocess
import sys

import numpy as np

raw = subprocess.run(
    ["ffmpeg", "-v", "error", "-i", sys.argv[1], "-f", "f32le", "-ac", "1", "-"],
    check=True, capture_output=True,
).stdout
x = np.frombuffer(raw, dtype="<f4")
print(f"{float(np.max(np.abs(x))):.9f}")
PY
)
GAIN=$(awk -v p="$PEAK" 'BEGIN { printf "%.6f", 0.475 / p }')
echo "peak $PEAK, gain $GAIN"
ffmpeg -v error -y -i "$WORK/gramophone_trim.wav" -af "volume=$GAIN" \
    -c:a pcm_s16le "$WORK/gramophone_norm.wav"

oggenc -q 4 --serial 1915 -o "$OUT" "$WORK/gramophone_norm.wav"
shasum -a 256 "$OUT"
uv run --with numpy python tools/music/check_cue.py --oneshot "$OUT"
