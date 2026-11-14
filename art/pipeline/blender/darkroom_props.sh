#!/bin/sh
set -eu
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/palette_to_gd.py
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/build_darkroom_props.py
for id in dr_tray dr_bottle dr_plate_holder dr_plate_rack dr_pail dr_jug dr_plate_box; do
  blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/validate.py -- "assets/models/$id.glb" "$id"
done
mkdir -p art/validation/p7-darkroom
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/render_row.py -- art/validation/p7-darkroom/props.png assets/models/dr_tray.glb assets/models/dr_bottle.glb assets/models/dr_plate_holder.glb assets/models/dr_plate_rack.glb assets/models/dr_pail.glb assets/models/dr_jug.glb assets/models/dr_plate_box.glb
blender -b --factory-startup --python-exit-code 1 -P art/pipeline/blender/render_row.py -- art/validation/p7-darkroom/bench.png assets/models/dr_tray.glb assets/models/dr_bottle.glb assets/models/dr_jug.glb
magick art/validation/p7-darkroom/props.png -quality 88 art/validation/p7-darkroom/props.jpg
magick art/validation/p7-darkroom/bench.png -quality 88 art/validation/p7-darkroom/bench.jpg
rm art/validation/p7-darkroom/props.png art/validation/p7-darkroom/bench.png
