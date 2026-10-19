"""Painted-diorama coelostat; dimensions and pivot follow the gameplay layout."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import kit
from mathutils import Vector


def cell_ring():
    """A shallow annular cell, with an open centre for the silvered face."""
    import bpy

    count = 20
    vertices = []
    for z, radius in ((-0.025, 0.22), (0.025, 0.22),
                      (-0.025, 0.195), (0.025, 0.195)):
        for i in range(count):
            angle = 2 * math.pi * i / count
            vertices.append((radius * math.cos(angle), radius * math.sin(angle), z))
    faces = []
    for a, b in ((0, 1), (1, 3), (3, 2), (2, 0)):
        for i in range(count):
            j = (i + 1) % count
            faces.append((a * count + i, a * count + j,
                          b * count + j, b * count + i))
    mesh = bpy.data.meshes.new("cell")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    o = bpy.data.objects.new("cell", mesh)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(kit.mat("brass"))
    # Recalculate winding before applying the soft bevel.
    import bmesh
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    bevel = o.modifiers.new("bevel", "BEVEL")
    bevel.width = 0.004
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    o.location = (0, 0, 1.40)
    o.rotation_euler.x = math.radians(30)
    return o


def main():
    kit.reset()
    parts = []
    # Four broad masonry courses; the bevels suggest shallow mortar joints.
    for i in range(4):
        parts.append(kit.box("pier_course", (1, 1, 0.25),
                             (0, 0, 0.125 + 0.25 * i), "brick", bevel=0.006))
    parts.append(kit.box("cap", (1.08, 1.08, 0.06), (0, 0, 1.03), "stone"))
    parts.append(kit.cyl("flange", 0.18, 0.04, (0, 0, 1.08), "iron"))
    parts.append(kit.cyl("column", 0.105, 0.12, (0, 0, 1.15),
                         "iron", radius_top=0.075))
    parts.append(kit.box("yoke_bridge", (0.58, 0.10, 0.075),
                         (0, 0, 1.21), "iron"))
    for x in (-0.26, 0.26):
        parts.append(kit.box("yoke_arm", (0.065, 0.10, 0.225),
                             (x, 0, 1.315), "iron"))
        parts.append(kit.cyl("bearing", 0.065, 0.075, (x, 0, 1.40),
                             "iron", rot=(0, 90, 0), verts=12))
    parts.append(kit.box("drive_bracket", (0.30, 0.12, 0.06),
                         (0.43, 0, 1.08), "iron"))
    parts.append(kit.box("clock_drive", (0.42, 0.34, 0.36),
                         (0.62, 0, 0.92), "teak_dark"))
    for z in (0.77, 1.07):
        parts.append(kit.box("drive_rail", (0.43, 0.035, 0.045),
                             (0.62, -0.17, z), "teak_dark", bevel=0.007))
    parts.append(kit.cyl("winding_hub", 0.055, 0.04, (0.84, 0, 0.94),
                         "brass", rot=(0, 90, 0), verts=12))
    parts.append(kit.box("crank_arm", (0.025, 0.035, 0.11),
                         (0.86, 0, 0.89), "brass", bevel=0.006))
    parts.append(kit.cyl("crank_grip", 0.023, 0.055, (0.88, 0, 0.84),
                         "brass", rot=(0, 90, 0), verts=8, bevel=0.004))
    parts.append(kit.cyl("weight_rod", 0.012, 0.19, (0.72, 0, 0.655),
                         "iron", verts=8, bevel=0.003))
    parts.append(kit.cyl("drive_weight", 0.055, 0.12, (0.72, 0, 0.51),
                         "iron", verts=12))
    static = kit.join("coelostat", parts)
    kit.set_origin(static, Vector((0, 0, 0)))

    # +Z rotated 30 degrees about X gives (0, -0.5, sqrt(3)/2):
    # the reflecting normal looks forward, 60 degrees above horizontal.
    normal = Vector((0, -0.5, math.sqrt(3) / 2))
    pivot = Vector((0, 0, 1.40))
    moving = [cell_ring(), kit.cyl("silvered_face", 0.20, 0.02,
                                  pivot + normal * 0.022, "mirror",
                                  rot=(30, 0, 0), verts=20, bevel=0.003)]
    for x in (-0.235, 0.235):
        moving.append(kit.cyl("pivot_boss", 0.04, 0.07, (x, 0, 1.40),
                              "brass", rot=(0, 90, 0), verts=12, bevel=0.005))
    mirror = kit.join("coelostat_mirror", moving)
    kit.set_origin(mirror, pivot)
    # The registry declares the drive's bounds offset; keep the pier at zero.
    kit.export("assets/models/coelostat.glb", [static, mirror])


if __name__ == "__main__":
    main()
