#!/bin/bash
# Run through job-run and tachi-run --heavy --host from the project root.
set -euo pipefail
tools_dir=$(cd "$(dirname "$0")/.." && pwd)
for state in day_clear partial_cloud totality_clear totality_thin; do
    "$HOME/.local/bin/python3" "$tools_dir/windowed_capture.py" \
        --settings "$tools_dir/row2/settings.cfg" --wall-seconds 650 --first-frame-seconds 60 \
        --engine-arg=--language --engine-arg=en --expect '960:f_*.png' --expect 1:camera.tsv \
        "$1/$state" res://tools/row2/capture.gd -- "$state" --seed=7 --bench-size=1280x720
done
