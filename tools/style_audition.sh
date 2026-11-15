#!/bin/bash
# Run the style variants and assemble the four audition frames.
# Run: orb-test --heavy --host -- tools/style_audition.sh <out dir> [variants.tsv]
set -u
if [ "$#" -lt 1 ]; then
  echo 'usage: tools/style_audition.sh <out dir> [variants.tsv]' >&2
  exit 2
fi
ONLY=${ONLY:-arrival,coelostat_still,totality_sky,dialogue} tools/look_matrix.sh "$1" "${2:-tools/style_audition.tsv}"
code=$?
OUT=$1
variants=${2:-tools/style_audition.tsv}
frames=(arrival coelostat_still totality_sky dialogue)
names=()
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  name=${line%%$'\t'*}
  complete=1
  for frame in "${frames[@]}"; do [ -f "$OUT/$name/$frame.png" ] || complete=0; done
  [ "$complete" -eq 1 ] || continue
  names+=("$name")
done < "$variants"
if [ "${#names[@]}" -gt 0 ]; then
  mkdir -p "$OUT/sheets"
  for name in "${names[@]}"; do
    tiles=()
    for frame in "${frames[@]}"; do tiles+=("$OUT/$name/$frame.png"); done
    sheet="$OUT/sheets/style-$name.jpg"
    magick montage "${tiles[@]}" -tile 2x2 -geometry 1280x720+8+8 -background '#202020' -quality 92 "$sheet"
    echo "$sheet"
  done
  tiles=()
  for frame in "${frames[@]}"; do
    for name in "${names[@]}"; do tiles+=("$OUT/$name/$frame.png"); done
  done
  sheet="$OUT/sheets/side-by-side.jpg"
  magick montage "${tiles[@]}" -tile "${#names[@]}x" -geometry 853x480+6+6 -background '#202020' -quality 92 "$sheet"
  echo "$sheet"
fi
date '+%F %H:%M %Z'
exit "$code"
