"""Build a three-plank field table on splayed timber trestles."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bpy
from mathutils import Vector


def plank(index, y):
    """Keep the surveyed envelope while easing the hand-planed board ends."""
    obj = kit.box("table_plank", (1.80, 0.26, 0.03),
                  (0, y, 0.745), "teak", bevel=0.006)
    # Slightly different slopes, all inside the dimensioned top envelope.
    drops = ((0.0013, 0.0), (0.0004, 0.0017), (0.0, 0.0009))
    for vertex in obj.data.vertices:
        vertex.co.z -= drops[index][vertex.co.x > 0]
    return obj


def brace(name, start, end, size):
    start, end = Vector(start), Vector(end)
    delta = end - start
    obj = kit.box(name, (*size, delta.length), (start + end) / 2,
                  "teak_dark", bevel=0.006)
    obj.rotation_euler = delta.to_track_quat("Z", "Y").to_euler()
    return obj


def main():
    kit.reset()
    parts = [plank(i, y) for i, y in enumerate((-0.27, 0.0, 0.27))]
    splay = math.radians(12)
    # Account for the rotated rectangular end faces: every foot meets Z=0.
    leg_height = 0.710
    leg_length = (leg_height - 0.07 * math.sin(splay)) / math.cos(splay)
    for x in (-0.60, 0.60):
        for side in (-1, 1):
            parts.append(kit.box("trestle_leg", (0.05, 0.07, leg_length),
                                 (x, side * 0.20, leg_height / 2), "teak_dark",
                                 rot=(side * 12, 0, 0), bevel=0.006))
        # The cap supports all three boards; the low tie intersects both legs.
        parts.append(kit.box("trestle_cap", (0.09, 0.73, 0.07),
                             (x, 0, 0.695), "teak_dark", bevel=0.008))
        parts.append(kit.box("trestle_tie", (0.06, 0.53, 0.07),
                             (x, 0, 0.27), "teak_dark", bevel=0.006))
    parts.append(kit.box("long_stretcher", (1.29, 0.06, 0.07),
                         (0, 0, 0.27), "teak_dark", bevel=0.006))
    for side in (-1, 1):
        parts.append(brace("stretcher_knee", (side * 0.15, 0, 0.29),
                           (side * 0.60, 0, 0.685), (0.045, 0.05)))
    table = kit.join("trestle_table", parts)
    bpy.context.view_layer.update()
    kit.set_origin(table, kit.bottom_centre([table]))
    table.location = (0, 0, 0)
    # Compensate for the small loss at the bevelled, splayed foot corners.
    height = max(v.co.z for v in table.data.vertices)
    for vertex in table.data.vertices:
        vertex.co.z *= 0.76 / height
    kit.export("assets/candidates/af01/trestle_table.glb", [table])


if __name__ == "__main__":
    main()
