"""Original procedural reconstructions; no external assets. See loupe_workbook.md."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import bpy
import kit


def loupe():
    # A folding brass magnifier supported upright; the open aperture keeps the
    # lens silhouette legible without an opaque disc resembling a bottle cap.
    return [kit.torus('lens_ring', .115, .018, (0, 0, .255), 'brass', rot=(70, 0, 0), major_seg=48, minor_seg=8),
            kit.cyl('handle', .017, .155, (0, .025, .105), 'brass', verts=16, bevel=.003),
            kit.box('folding_foot', (.18, .16, .016), (0, .025, .008), 'brass', bevel=.006),
            kit.cyl('hinge', .028, .05, (0, .025, .035), 'brass', rot=(0, 90, 0), verts=20)]


def workbook():
    parts = [kit.box('binding', (.025, .35, .035), (0, 0, .022), 'teak_dark', bevel=.004)]
    for side in (-1, 1):
        tilt = -side * 7
        parts += [kit.box('cover', (.255, .35, .015), (side*.125, 0, .025), 'teak_dark', rot=(0, tilt, 0), bevel=.003),
                  kit.box('page_block', (.238, .325, .028), (side*.124, 0, .048), 'canvas', rot=(0, tilt, 0), bevel=.002)]
        # Broad ink rules and a margin, authored geometry on the cream pages.
        for row in range(9):
            y = -.124 + row*.03
            parts.append(kit.box('rule', (.204, .0016, .001), (side*.124, y, .063), 'pine', rot=(0, tilt, 0), bevel=0))
        parts.append(kit.box('margin', (.0018, .285, .001), (side*.037, 0, .0514), 'pine', bevel=0))
    return parts


kit.reset()
for name, build in [('mentor_loupe', loupe), ('field_workbook', workbook)]:
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete(use_global=False)
    obj = kit.join(name, build())
    bpy.context.view_layer.update()
    kit.set_origin(obj, kit.bottom_centre([obj]))
    obj.location = (0, 0, 0)
    kit.export('assets/models/' + name + '.glb', [obj])
