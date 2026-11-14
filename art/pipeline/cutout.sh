#!/bin/bash
set -euo pipefail

if [[ ${1:-} == --check ]]; then
  file=$2
  read -r width height coverage fringe < <(magick "$file" -alpha on -format '%w %h ' info:; magick "$file" -alpha on -fx 'a>0.5?1:0' -format '%[fx:mean*100] ' info:; magick "$file" -alpha on -fx 'a>0.5?(0.2126*r+0.7152*g+0.0722*b>0.92?1:0):0' -format '%[fx:mean*100]\n' info:)
  fringe=$(awk -v f="$fringe" -v c="$coverage" 'BEGIN {if(c>0) printf "%.3f",100*f/c; else print 0}')
  printf 'size %sx%s coverage %.3f%% fringe %s%%\n' "$width" "$height" "$coverage" "$fringe"
  awk -v c="$coverage" -v f="$fringe" 'BEGIN {exit !(c>=8 && c<=75 && f<=1)}'
  exit
fi

wrap=0
if [[ ${1:-} == --wrap-x ]]; then wrap=1; shift; fi
in=$1
out=$2
tmp=$(mktemp -d "$(dirname "$out")/.cutout.XXXXXXXX")
trap 'rm -rf "$tmp"' EXIT

# The largest channel distance from white gives a conservative matte.
magick "$in" -alpha off -fx 'max(1-r,max(1-g,1-b))' -level 5%,12% \
  -morphology Erode Disk:1 "$tmp/alpha.png"
magick "$in" "$tmp/alpha.png" -alpha off -compose CopyOpacity -composite "$tmp/matte.png"
if (( wrap )); then
  width=$(magick "$tmp/matte.png" -format '%w' info:)
  magick "$tmp/matte.png" -roll "+$((width / 2))+0" "$tmp/rolled.png"
  magick "$tmp/matte.png" -alpha off -fx 'min(1,min(i,w-1-i)/160)' "$tmp/mask.png"
  magick "$tmp/rolled.png" "$tmp/matte.png" "$tmp/mask.png" -compose Over -composite "$tmp/matte.png"
  # Trim vertically while retaining the original width.
  bounds=$(magick "$tmp/matte.png" -format '%@' info:)
  height=${bounds#*x}; height=${height%%+*}; y=${bounds##*+}
  y=$((y > 8 ? y - 8 : 0))
  height=$((height + 16))
  magick "$tmp/matte.png" -crop "${width}x${height}+0+${y}" +repage -resize 1024x "$tmp/trim.png"
else
  magick "$tmp/matte.png" -trim +repage -bordercolor none -border 8 -resize 1024x1024 "$tmp/trim.png"
fi

# Spread colours outward from opaque pixels, then restore the original alpha.
magick "$tmp/trim.png" -alpha extract "$tmp/final-alpha.png"
magick "$tmp/trim.png" -channel A -threshold 99% +channel \
  -channel RGBA -morphology Voronoi Euclidean:4,16 +channel \
  "$tmp/final-alpha.png" -alpha off -compose CopyOpacity -composite \
  -depth 8 -strip PNG32:"$out"
