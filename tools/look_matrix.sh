#!/bin/bash
# Run each look variant and collect benchmark tables and contact sheets.
# Run: orb-test --heavy --host -- tools/look_matrix.sh <out dir> [variants.tsv]
# Owner rule: windowed Godot only Mon–Fri 09:00–15:00 JST.
set -u

if [ "$#" -lt 1 ]; then
  echo "usage: tools/look_matrix.sh <out dir> [variants.tsv]" >&2
  exit 2
fi
if [ "${WINDOWED_OK:-0}" != 1 ]; then
  day=$(TZ=Asia/Tokyo date +%u)
  hour=$(TZ=Asia/Tokyo date +%H)
  if [ "$day" -ge 6 ] || [ "$((10#$hour))" -lt 9 ] || [ "$((10#$hour))" -ge 15 ]; then
    echo "windowed Godot only Mon–Fri 09:00–15:00 JST" >&2
    exit 2
  fi
fi
mkdir -p "$1" || exit 1
OUT=$(cd "$1" && pwd) || exit 1
variants=${2:-tools/look_matrix.tsv}
SEED=${SEED:-7}
ONLY=${ONLY:-}
godot --headless --path . --import >/dev/null 2>&1
ok=0
total=0
successful=()
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  name=${line%%$'\t'*}
  extra=${line#*$'\t'}
  if [ "$extra" = "$line" ]; then extra=; fi
  total=$((total + 1))
  t0=$(date +%s)
  # Intentional splitting of the TSV's extra arguments.
  perl -e 'alarm shift; exec @ARGV' 600 godot --path . --resolution 1280x720 --fixed-fps 60 --always-on-top -- --benchmark="$OUT/$name" --seed="$SEED" $extra ${ONLY:+--bench-only=$ONLY} >"$OUT/$name.log" 2>&1
  code=$?
  if [ "$code" -eq 0 ] && [ -f "$OUT/$name/benchmark.json" ] && ! grep -q 'LOOK-SET ERROR' "$OUT/$name.log"; then
    ok=$((ok + 1))
    successful+=("$name")
    result=ok
  else
    result=FAIL
  fi
  printf '%s %s %ss\n' "$name" "$result" "$(( $(date +%s) - t0 ))"
done < "$variants"
python3 -I tools/look_matrix_stats.py "$OUT"
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
      magick montage "${tiles[@]}" -resize 640x360 -tile 3x -geometry +6+6 -background '#202020' -fill white "$OUT/sheets/$b.jpg"
    done
  else
    echo 'magick not installed; skipping contact sheets'
  fi
fi
printf 'look matrix: %s/%s variants -> %s %s\n' "$ok" "$total" "$OUT" "$(date '+%F %H:%M %Z')"
[ "$ok" -eq "$total" ]
