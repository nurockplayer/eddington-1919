#!/bin/bash
set -euo pipefail

if [[ ${1:-} == --check ]]; then
  file=$2
  # The forest band is mostly opaque by design; single leaves are not.
  max_coverage=75
  [[ $(basename "$file") == forest_edge-* ]] && max_coverage=90
  read -r width height coverage fringe chroma < <(magick "$file" -alpha on -format '%w %h ' info:; magick "$file" -alpha on -fx 'a>0.5?1:0' -format '%[fx:mean*100] ' info:; magick "$file" -alpha on -fx 'a>0.5?(0.2126*r+0.7152*g+0.0722*b>0.92?1:0):0' -format '%[fx:mean*100] ' info:; magick "$file" -alpha on -fx 'a>0.5?(max(r,max(g,b))-min(r,min(g,b))):0' -format '%[fx:mean*100]\n' info:)
  fringe=$(awk -v f="$fringe" -v c="$coverage" 'BEGIN {if(c>0) printf "%.3f",100*f/c; else print 0}')
  # Mean chroma of the opaque pixels: a cut-out that lost its colour (grey or black) fails.
  chroma=$(awk -v f="$chroma" -v c="$coverage" 'BEGIN {if(c>0) printf "%.3f",100*f/c; else print 0}')
  printf 'size %sx%s coverage %.3f%% fringe %s%% chroma %s%%\n' "$width" "$height" "$coverage" "$fringe" "$chroma"
  awk -v c="$coverage" -v f="$fringe" -v k="$chroma" -v m="$max_coverage" 'BEGIN {exit !(c>=8 && c<=m && f<=1 && k>=8)}'
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
  # Mirror wrap: the tile is the matte followed by its mirror image, so both seams are exact
  # (a cross-fade with a rolled copy leaves ghost palms at the seam).
  magick "$tmp/matte.png" \( +clone -flop \) +append +repage "$tmp/matte.png"
  width=$(magick "$tmp/matte.png" -format '%w' info:)
  # Trim vertically while retaining the full width.
  bounds=$(magick "$tmp/matte.png" -format '%@' info:)
  height=${bounds#*x}; height=${height%%+*}; y=${bounds##*+}
  y=$((y > 8 ? y - 8 : 0))
  height=$((height + 16))
  magick "$tmp/matte.png" -crop "${width}x${height}+0+${y}" +repage -resize 2048x "$tmp/trim.png"
else
  magick "$tmp/matte.png" -trim +repage -bordercolor none -border 8 -resize 1024x1024 "$tmp/trim.png"
fi

# Spread colours outward from opaque pixels (blurred copies composited underneath, widening each
# pass; the rest takes the mean colour), then restore the original alpha.
magick "$tmp/trim.png" -alpha extract "$tmp/final-alpha.png"
mean=$(magick "$tmp/trim.png" -channel A -threshold 50% +channel -resize '1x1!' -alpha off -format '%[hex:p{0,0}]' info:)
magick "$tmp/trim.png" -channel A -threshold 50% +channel \
  \( +clone -blur 0x2  -channel A -level 0,1% +channel \) -compose DstOver -composite \
  \( +clone -blur 0x4  -channel A -level 0,1% +channel \) -compose DstOver -composite \
  \( +clone -blur 0x8  -channel A -level 0,1% +channel \) -compose DstOver -composite \
  \( +clone -blur 0x16 -channel A -level 0,1% +channel \) -compose DstOver -composite \
  -background "#${mean:0:6}" -alpha remove -alpha off "$tmp/rgb.png"
magick "$tmp/rgb.png" "$tmp/final-alpha.png" -alpha off -compose CopyOpacity -composite \
  -depth 8 -strip PNG32:"$out"
