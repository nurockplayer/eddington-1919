#!/bin/bash
set -euo pipefail
export TZ=Asia/Tokyo
repo=$PWD
head=$(rtk git rev-parse HEAD)
base=$(rtk git merge-base HEAD origin/main)
out="/Volumes/KIOXIA/eddington-1919-cache/director/loupe-workbook/$head"
mkdir -p "$out/frames" "$out/sheets" "$out/scratch/main" "$out/tools"
cp tools/loupe_workbook/{capture.gd,analyse.py,run.sh} "$out/tools/"
rtk git archive "$base" | tar -xf - -C "$out/scratch/main"
export EDD_SETTINGS_PATH="$out/scratch/settings.cfg"
taskpolicy -b godot --headless --path "$out/scratch/main" --import > "$out/tools/main-import.log" 2>&1
taskpolicy -b godot --headless --path "$repo" --check-only --script "$out/tools/capture.gd" > "$out/tools/head-parse.log" 2>&1
taskpolicy -b godot --headless --path "$out/scratch/main" --check-only --script "$out/tools/capture.gd" > "$out/tools/main-parse.log" 2>&1
for size in 1280x720 1920x1080; do
  rm -f "$EDD_SETTINGS_PATH"
  perl -e 'alarm shift; exec @ARGV' 3000 godot --path "$repo" --windowed --resolution "$size" --fixed-fps 60 --always-on-top --script "$out/tools/capture.gd" -- --out="$out" --sha="$head" --size="$size" > "$out/tools/head-$size.log" 2>&1
  rm -f "$EDD_SETTINGS_PATH"
  perl -e 'alarm shift; exec @ARGV' 3000 godot --path "$out/scratch/main" --windowed --resolution "$size" --fixed-fps 60 --always-on-top --script "$out/tools/capture.gd" -- --out="$out" --sha="$base" --size="$size" --baseline > "$out/tools/main-$size.log" 2>&1
done
python3 "$out/tools/analyse.py" "$out" "$head" "$base"
