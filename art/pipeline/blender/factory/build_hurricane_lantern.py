"""Build a period tubular kerosene lantern with a separate wick light anchor."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


def shaped_mesh(name, vertices, faces, material, bevel=0.006):
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
    mod = obj.modifiers.new("soft rims", "BEVEL")
    mod.width = bevel
    mod.segments = 1
    mod.limit_method = "ANGLE"
    # Octagonal round tubing is a curved surface; soften its exposed end rims.
    mod.angle_limit = math.radians(50)
    return obj


def tube(name, path):
    """Continuous eight-sided bent tube, avoiding separate floating elbows."""
    points = [Vector(p) for p in path]
    vertices = []
    for i, point in enumerate(points):
        tangent = points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]
        tangent.normalize()
        across = Vector((tangent.z, 0, -tangent.x))
        for j in range(8):
            angle = 2 * math.pi * j / 8
            vertices.append(point + 0.01 * (math.cos(angle) * across
                                            + Vector((0, math.sin(angle), 0))))
    faces = [tuple(reversed(range(8))), tuple(range((len(points) - 1) * 8, len(points) * 8))]
    for i in range(len(points) - 1):
        for j in range(8):
            k = (j + 1) % 8
            faces.append((i * 8 + j, i * 8 + k, (i + 1) * 8 + k, (i + 1) * 8 + j))
    return shaped_mesh(name, vertices, faces, "iron")


def globe():
    """The twelve-sided globe uses the unmodified palette glass material."""
    profile = ((0.090, 0.034), (0.115, 0.053), (0.153, 0.055),
               (0.193, 0.044), (0.229, 0.030))
    vertices = [(r * math.cos(2 * math.pi * j / 12),
                 r * math.sin(2 * math.pi * j / 12), z)
                for z, r in profile for j in range(12)]
    faces = [tuple(reversed(range(12))), tuple(range(48, 60))]
    for i in range(4):
        for j in range(12):
            k = (j + 1) % 12
            faces.append((i * 12 + j, i * 12 + k, (i + 1) * 12 + k, (i + 1) * 12 + j))
    return shaped_mesh("glass_globe", vertices, faces, "plate_glass")


def main():
    kit.reset()
    parts = [kit.cyl("fuel_fount", 0.09, 0.060, (0, 0, 0.030), "iron", verts=12),
             kit.cyl("fount_shoulder", 0.085, 0.030, (0, 0, 0.065), "iron",
                     radius_top=0.041, verts=12),
             kit.cyl("globe_seat", 0.042, 0.022, (0, 0, 0.085), "iron", verts=12),
             globe(),
             kit.cyl("wick", 0.011, 0.050, (0, 0, 0.115), "iron", verts=8, bevel=0.006),
             kit.cyl("globe_canopy", 0.063, 0.026, (0, 0, 0.236), "iron",
                     radius_top=0.040, verts=12),
             kit.cyl("chimney", 0.032, 0.040, (0, 0, 0.261), "iron", verts=12),
             kit.cyl("rain_cap", 0.043, 0.020, (0, 0, 0.285), "iron", verts=12)]
    # Avoid beveling the radial facets of the circular fount; its rims stay soft.
    for obj in parts:
        if obj.modifiers:
            obj.modifiers[0].angle_limit = math.radians(50)
    for side in (-1, 1):
        path = [(side * 0.070, 0, 0.043), (side * 0.085, 0, 0.075),
                (side * 0.090, 0, 0.148), (side * 0.085, 0, 0.218),
                (side * 0.049, 0, 0.244)]
        parts.append(tube("air_tube", path))
    parts.append(tube("bail_handle", [(-0.085, 0, 0.218), (-0.088, 0, 0.267),
                                      (-0.073, 0, 0.300), (-0.042, 0, 0.324),
                                      (0, 0, 0.330), (0.042, 0, 0.324),
                                      (0.073, 0, 0.300), (0.088, 0, 0.267),
                                      (0.085, 0, 0.218)]))
    lantern = kit.join("hurricane_lantern", parts)
    kit.set_origin(lantern, Vector((0, 0, 0)))
    # The brass flame is an unlit palette marker: the game attaches its light here.
    marker = kit.cyl("flame_marker", 0.01, 0.024, (0, 0, 0.152), "brass",
                     verts=8, bevel=0.006)
    marker.modifiers[0].angle_limit = math.radians(50)
    flame = kit.join("hurricane_lantern_flame", [marker])
    kit.set_origin(flame, Vector((0, 0, 0.14)))
    kit.export("assets/candidates/af01/hurricane_lantern.glb", [lantern, flame])


if __name__ == "__main__":
    main()
