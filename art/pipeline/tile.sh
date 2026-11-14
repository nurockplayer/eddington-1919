#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} == --check ]]; then
  image=$2
  # Compare the outer edge and all adjacent interior pixels on each axis.
  metric() {
    magick compare -metric MAE \( "$image" -crop "$1" +repage \) \
      \( "$image" -crop "$2" +repage \) null: 2>&1 || true
  }
  value() { local m; m=$(metric "$1" "$2"); m=${m#*(}; echo "${m%)*}"; }
  xedge=$(value 1x1024+0+0 1x1024+1023+0)
  xinner=$(value 1022x1024+0+0 1022x1024+1+0)
  yedge=$(value 1024x1+0+0 1024x1+0+1023)
  yinner=$(value 1024x1022+0+0 1024x1022+0+1)
  read -r x y < <(magick xc: -format "%[fx:$xinner==0?($xedge==0?0:999):$xedge/$xinner] %[fx:$yinner==0?($yedge==0?0:999):$yedge/$yinner]\n" info:)
  mean=$(magick "$image" -resize 1x1\! -depth 8 -format '%[hex:p{0,0}]' info:)
  printf 'wrap_x %s wrap_y %s mean #%s\n' "$x" "$y" "$mean"
  [[ $(magick xc: -format "%[fx:$x<=1.6 && $y<=1.6?1:0]" info:) == 1 ]]
  exit
fi

input=$1 output=$2 target=$3
tmp="${output}.work.miff"
trap 'rm -f "$tmp"' EXIT
# The mask makes the original opaque in the centre and the half-rolled copy
# visible at the borders. Repeat on the other axis.
magick "$input" -gravity center -crop 1:1 +repage -resize 1024x1024\! \
  -write mpr:original +delete \
  mpr:original -roll +512+0 \
  \( mpr:original \( -size 1024x1024 xc: -fx 'min(1,min(i,w-1-i)/160)' \) -alpha off -compose CopyOpacity -composite \) \
  -compose Over -composite -write mpr:x +delete \
  mpr:x -roll +0+512 \
  \( mpr:x \( -size 1024x1024 xc: -fx 'min(1,min(j,h-1-j)/160)' \) -alpha off -compose CopyOpacity -composite \) \
  -compose Over -composite -alpha off -colorspace RGB "$tmp"
read -r r g b < <(magick "$tmp" -format '%[fx:mean.r] %[fx:mean.g] %[fx:mean.b]\n' info:)
read -r tr tg tb < <(magick -size 1x1 "xc:$target" -colorspace RGB -format '%[fx:mean.r] %[fx:mean.g] %[fx:mean.b]\n' info:)
magick "$tmp" -channel R -evaluate multiply "$(magick xc: -format "%[fx:$tr/$r]" info:)" \
  -channel G -evaluate multiply "$(magick xc: -format "%[fx:$tg/$g]" info:)" \
  -channel B -evaluate multiply "$(magick xc: -format "%[fx:$tb/$b]" info:)" \
  +channel -colorspace sRGB -strip -quality 90 "$output"
