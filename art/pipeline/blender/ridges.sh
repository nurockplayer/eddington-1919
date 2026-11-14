#!/bin/sh
set -eu
blender -b --factory-startup -P art/pipeline/blender/build_ridges.py
g2=0
blender -b --factory-startup -P art/pipeline/blender/validate.py -- assets/models/principe_ridges.glb principe_ridges || g2=$?
blender -b --factory-startup -P art/pipeline/blender/render_ridges.py
for kind in view silhouette; do
  set --
  for bearing in -37 -20 52 142 200 270; do
    set -- "$@" -label "$bearing°" "art/validation/p3-ridges/${kind}_${bearing}.png"
  done
  output=panorama
  [ "$kind" = view ] || output=silhouette
  magick montage "$@" -resize 640x360 -geometry 640x360+0+0 -tile 3x2 "art/validation/p3-ridges/$output.jpg"
done
rm art/validation/p3-ridges/*.png
exit "$g2"
