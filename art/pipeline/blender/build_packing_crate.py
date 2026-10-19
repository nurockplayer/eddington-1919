"""Low-poly pine packing case with broad battens and eight bent iron straps."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


def corner_strap(sx, sy, top):
    """Two visible plate faces with chamfered bend and top/bottom rims.

    The diagonal back is buried in the pine, saving hidden plate geometry.
    """
    outer = [(0.09, 0), (0.004, 0), (0, 0.004), (0, 0.09)]
    inset = [(0.086, 0.006), (0.009, 0.006),
             (0.006, 0.009), (0.006, 0.086)]
    z0, z1 = (0.40, 0.485) if top else (0.015, 0.10)
    rings = [(inset, z0), (outer, z0 + 0.006),
             (outer, z1 - 0.006), (inset, z1)]
    vertices = [(sx * (0.35 - x), sy * (0.25 - y), z)
                for outline, z in rings for x, y in outline]
    faces = [(3, 2, 1, 0), (12, 13, 14, 15)]
    for ring in range(3):
        for i in range(4):
            j = (i + 1) % 4
            faces.append((ring * 4 + i, ring * 4 + j,
                          (ring + 1) * 4 + j, (ring + 1) * 4 + i))
    mesh = bpy.data.meshes.new("corner_strap")
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    o = bpy.data.objects.new("corner_strap", mesh)
    bpy.context.collection.objects.link(o)
    mesh.materials.append(kit.mat("iron"))
    return o


def handle_cleat(sx):
    """A chunky wooden grip; omit only its buried rear bevel and face."""
    o = kit.box("handle_cleat", (0.04, 0.16, 0.05),
                (sx * 0.35, 0, 0.29), "teak_dark", bevel=0.008)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=o.modifiers[0].name)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.normal_update()
    hidden = [f for f in bm.faces if f.normal.x * sx < -0.1]
    bmesh.ops.delete(bm, geom=hidden, context="FACES")
    bm.to_mesh(o.data)
    bm.free()
    return o


def main():
    kit.reset()
    parts = []
    # Two wide wall boards and a separate lid: readable seams without slats.
    for z in (0.12, 0.34):
        parts.append(kit.box("pine_boards", (0.68, 0.48, 0.22),
                             (0, 0, z), "pine", bevel=0.008))
    parts.append(kit.box("lid", (0.68, 0.48, 0.04),
                         (0, 0, 0.47), "pine", bevel=0.006))
    # Broad battens across each short end and across the lid ends.
    for sx in (-1, 1):
        parts.append(kit.box("end_batten", (0.035, 0.46, 0.07),
                             (sx * 0.3325, 0, 0.29), "teak_dark", bevel=0.006))
        parts.append(kit.box("lid_batten", (0.075, 0.48, 0.035),
                             (sx * 0.295, 0, 0.4825), "teak_dark", bevel=0.006))
        parts.append(handle_cleat(sx))
        for sy in (-1, 1):
            for top in (False, True):
                parts.append(corner_strap(sx, sy, top))
    crate = kit.join("packing_crate", parts)
    bpy.context.view_layer.update()
    kit.set_origin(crate, kit.bottom_centre([crate]))
    crate.location = (0, 0, 0)
    kit.export("assets/models/packing_crate.glb", [crate])


if __name__ == "__main__":
    main()
