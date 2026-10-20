"""Tapered expedition bucket with a rolled lip, riveted ears and timber bail grip."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


def mesh_part(name, vertices, faces, material):
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
    return obj


def bucket_shell():
    # The rolled lip is the wall-thickness cue; the broad inside is left open.
    # Profile chamfers replace a modifier here, avoiding bevelled facet seams.
    profile = [(0.108, 0.000), (0.142, 0.180), (0.150, 0.192),
               (0.146, 0.200), (0.134, 0.200), (0.130, 0.196),
               (0.130, 0.180), (0.108, 0.010)]
    n = 16
    vertices = [(r * math.cos(i * math.tau / n),
                 r * math.sin(i * math.tau / n), z)
                for r, z in profile for i in range(n)]
    faces = []
    for ring in range(len(profile) - 1):
        for i in range(n):
            j = (i + 1) % n
            faces.append((ring * n + i, ring * n + j,
                          (ring + 1) * n + j, (ring + 1) * n + i))
    faces.extend([tuple(reversed(range(n))),
                  tuple((len(profile) - 1) * n + i for i in range(n))])
    return mesh_part("rolled_bucket_shell", vertices, faces, "iron")


def bail():
    # Eight-sided 2 cm wire; the bends differ slightly, as on a worked bail.
    points = [Vector(p) for p in [(-0.148, 0, 0.183),
                                  (-0.136, 0, 0.231),
                                  (-0.070, 0, 0.286),
                                  (0.070, 0, 0.286),
                                  (0.148, 0, 0.183)]]
    vertices = []
    for i, p in enumerate(points):
        tangent = points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]
        normal = Vector((tangent.z, 0, -tangent.x)).normalized()
        for j in range(8):
            angle = j * math.tau / 8
            v = p + 0.010 * (normal * math.cos(angle) +
                             Vector((0, 1, 0)) * math.sin(angle))
            vertices.append(v)
    # The exposed wire ends enter the solid ears, so no end caps are visible.
    faces = []
    for ring in range(len(points) - 1):
        for i in range(8):
            j = (i + 1) % 8
            faces.append((ring * 8 + i, ring * 8 + j,
                          (ring + 1) * 8 + j, (ring + 1) * 8 + i))
    return mesh_part("forged_bail", vertices, faces, "iron")


def main():
    kit.reset()
    parts = [bucket_shell(), bail()]
    for side in (-1, 1):
        parts.append(kit.box("bail_ear", (0.040, 0.040, 0.045),
                             (side * 0.140, 0, 0.173), "iron", bevel=0.006))
    parts.append(kit.cyl("timber_grip", 0.014, 0.130, (0, 0, 0.287),
                         "teak_dark", rot=(0, 90, 0), verts=8, bevel=0.003))
    bucket = kit.join("zinc_bucket", parts)
    bpy.context.view_layer.update()
    kit.set_origin(bucket, Vector((0, 0, 0)))
    assert kit.triangles([bucket]) <= 510
    # No lightened iron swatch exists: preserve the palette material verbatim.
    kit.export("assets/candidates/af01/zinc_bucket.glb", [bucket])


if __name__ == "__main__":
    main()
