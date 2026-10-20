"""Build one rough-hewn post-and-rail fence module for the Príncipe camp."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bpy
import bmesh
from mathutils import Vector


def swept_rail(name, stations, bottom_z, material):
    """Create one subtly sagged, chamfered timber rail as a single mesh."""
    half_y = 0.0675
    half_z = 0.052
    chamfer = 0.012
    section = [
        (-half_y + chamfer, -half_z),
        (half_y - chamfer, -half_z),
        (half_y, -half_z + chamfer),
        (half_y, half_z - chamfer),
        (half_y - chamfer, half_z),
        (-half_y + chamfer, half_z),
        (-half_y, half_z - chamfer),
        (-half_y, -half_z + chamfer),
    ]
    vertices = []
    for x, y, z in stations:
        for sy, sz in section:
            vertices.append((x, y + sy, z + bottom_z + sz))
    faces = []
    faces.append(tuple(reversed(range(8))))
    faces.append(tuple((len(stations) - 1) * 8 + i for i in range(8)))
    for row in range(len(stations) - 1):
        for i in range(8):
            j = (i + 1) % 8
            faces.append((row * 8 + i, row * 8 + j,
                          (row + 1) * 8 + j, (row + 1) * 8 + i))

    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(kit.mat(material))
    bevel = obj.modifiers.new("softened hewn edges", "BEVEL")
    bevel.width = 0.006
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    return obj


def main():
    kit.reset()
    parts = []

    # The post leans gently toward the next module; its foot remains at the
    # segment's -X boundary and both rails pass into it for a solid joint.
    parts.append(kit.cyl(
        "fence_post", 0.06, 1.098,
        (-1.19, 0, 0.55), "pine",
        rot=(1.0, 0, 0), verts=8, bevel=0.008, segments=1,
    ))

    # Slightly uneven stations keep the long rails hand-hewn in silhouette.
    xs = [-1.25, -0.78, -0.12, 0.56, 1.25]
    sag = [0.000, 0.018, 0.031, 0.020, 0.000]
    wav = [0.000, -0.002, 0.003, -0.002, 0.000]
    stations = [(x, w, -dip) for x, w, dip in zip(xs, wav, sag)]
    parts.append(swept_rail("lower_rail", stations, 0.34, "teak"))
    parts.append(swept_rail("upper_rail", stations, 0.77, "pine"))

    fence = kit.join("post_rail_fence", parts)
    bpy.context.view_layer.update()
    kit.set_origin(fence, kit.bottom_centre([fence]))
    fence.location = (0, 0, 0)
    kit.export("assets/candidates/af01/post_rail_fence.glb", [fence])


if __name__ == "__main__":
    main()
