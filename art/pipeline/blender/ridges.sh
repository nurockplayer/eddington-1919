#!/bin/sh
set -eu
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/build_ridges.py
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/validate.py -- assets/models/principe_ridges.glb principe_ridges
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/render_ridges.py
for kind in view silhouette; do
  set --
  for bearing in -37 -20 52 142 200 270; do
    set -- "$@" -label "${bearing}°" "art/validation/p3-ridges/${kind}_${bearing}.png"
  done
  output=panorama
  [ "$kind" = view ] || output=silhouette
  magick montage -font /System/Library/Fonts/Helvetica.ttc "$@" -resize 640x360 -geometry 640x360+0+0 -tile 3x2 "art/validation/p3-ridges/$output.jpg"
done
magick montage art/validation/p3-ridges/towers_lit.png art/validation/p3-ridges/towers_silhouette.png -geometry 1280x720+0+0 -tile 2x1 art/validation/p3-ridges/towers.jpg
rm art/validation/p3-ridges/*.png
