#!/bin/bash
# Run each look variant and collect benchmark tables and contact sheets.
# Run: tachi-run --heavy --host -- tools/look_matrix.sh <out dir> [variants.tsv]
# Windowed Godot only while the host gate is open (`heavy-window --help`); tachi-run --heavy waits for it.
set -u

if [ "$#" -lt 1 ]; then
  echo "usage: tools/look_matrix.sh <out dir> [variants.tsv]" >&2
  exit 2
fi
if [ -e "$1" ]; then
  echo "look matrix: output path already exists; choose a fresh directory: $1" >&2
  exit 2
fi
mkdir -p "$1" || exit 1
OUT=$(cd "$1" && pwd) || exit 1
variants=${2:-tools/style_audition.tsv}
SEED=${SEED:-7}
ONLY=${ONLY:-}
godot --headless --path . --import >/dev/null 2>&1
ok=0
total=0
successful=()
stopped=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  name=${line%%$'\t'*}
  extra=${line#*$'\t'}
  if [ "$extra" = "$line" ]; then extra=; fi
  total=$((total + 1))
  if ! reason=$(heavy-window); then
    echo "windowed Godot: heavy gate closed before $name: $reason; stopping matrix" >&2
    stopped=1
    break
  fi
  t0=$(date +%s)
  # Intentional splitting of the TSV's extra arguments.
  perl -e 'alarm shift; exec @ARGV' 600 godot --path . --resolution 1280x720 --fixed-fps 60 --always-on-top -- --benchmark="$OUT/$name" --seed="$SEED" $extra ${ONLY:+--bench-only=$ONLY} >"$OUT/$name.log" 2>&1
  code=$?
  if [ "$code" -eq 0 ] && [ -f "$OUT/$name/benchmark.json" ] && ! grep -qE 'LOOK-SET ERROR|STYLE ERROR' "$OUT/$name.log"; then
    ok=$((ok + 1))
    successful+=("$name")
    result=ok
  else
    result=FAIL
  fi
  printf '%s %s %ss\n' "$name" "$result" "$(( $(date +%s) - t0 ))"
done < "$variants"
python3 -I tools/look_matrix_stats.py "$OUT" "${successful[@]}"
if [ "$ok" -gt 0 ]; then
  if command -v magick >/dev/null 2>&1; then
    mkdir -p "$OUT/sheets"
    for png in "$OUT/${successful[0]}"/*.png; do
      [ -f "$png" ] || continue
      b=${png##*/}; b=${b%.png}
      tiles=()
      for name in "${successful[@]}"; do
        tiles+=(-label "$name" "$OUT/$name/$b.png")
      done
      magick montage -font /System/Library/Fonts/Helvetica.ttc "${tiles[@]}" -resize 640x360 -tile 3x -geometry +6+6 -background '#202020' -fill white "$OUT/sheets/$b.jpg"
    done
  else
    echo 'magick not installed; skipping contact sheets'
  fi
fi
printf 'look matrix: %s/%s variants -> %s %s\n' "$ok" "$total" "$OUT" "$(date '+%F %H:%M %Z')"
[ "$stopped" -eq 0 ] && [ "$ok" -eq "$total" ]
