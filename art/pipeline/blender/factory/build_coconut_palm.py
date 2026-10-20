"""Procedural low-poly coconut palm for the af01 repeated foliage kit."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bpy
import bmesh
from mathutils import Vector


def trunk_mesh():
    """Eight-sided, gently leaning six-section trunk with five ring collars."""
    sides = 8
    rings = []
    profile = [(0.0, 0.16)]
    for joint in range(1, 6):
        z = 7.5 * joint / 6
        radius = 0.16 * (1.0 - 0.18 * z / 7.5)
        profile.extend(((z - 0.035, radius),
                        (z, radius + 0.02),
                        (z + 0.035, radius)))
    profile.append((7.5, 0.16 * (1.0 - 0.18)))
    for z, radius in profile:
        cx = 0.10 * (z / 7.5) + 0.035 * math.sin(z * 0.92)
        cy = -0.07 * (z / 7.5) + 0.025 * math.sin(z * 0.78)
        rings.append([(cx + radius * math.cos(2 * math.pi * i / sides),
                       cy + radius * math.sin(2 * math.pi * i / sides), z)
                      for i in range(sides)])
    verts = [v for ring in rings for v in ring]
    faces = []
    for ri in range(len(rings) - 1):
        for i in range(sides):
            j = (i + 1) % sides
            faces.append((ri * sides + i, ri * sides + j,
                          (ri + 1) * sides + j, (ri + 1) * sides + i))
    faces.append(tuple(range(sides - 1, -1, -1)))
    top = (len(rings) - 1) * sides
    faces.append(tuple(top + i for i in range(sides)))
    return verts, faces


def frond_mesh(index, yaw, reach, phase):
    """Four-segment folded V blade with a gently zig-zag leaflet silhouette."""
    forward = Vector((math.cos(yaw), math.sin(yaw), 0))
    side = Vector((-math.sin(yaw), math.cos(yaw), 0))
    # Match the centre of the final trunk ring so every frond grows from it.
    root = Vector((0.10 + 0.035 * math.sin(7.5 * 0.92),
                   -0.07 + 0.025 * math.sin(7.5 * 0.78), 7.5))
    # Four intervals; inward leaves arch lower and outer tips droop farther.
    arch = 0.50 if index == 0 else 0.38 + 0.06 * (0.5 + 0.5 * math.sin(index * 1.7))
    tip_drop = 0.32 + 0.06 * (index % 5)
    profile = [(0.0, 0.00, 0.08), (0.26, arch * 0.70, 0.30),
               (0.57, arch, 0.42), (0.84, arch * 0.60, 0.34),
               (1.0, -tip_drop, 0.06)]
    verts, faces = [], []
    for row, (t, rise, width) in enumerate(profile):
        center = root + forward * (reach * t) + Vector((0, 0, rise))
        # Alternating width gives the blade edge a broad, readable leaflet rhythm.
        edge_scale = (0.84 if row % 2 else 1.0) * (0.94 + 0.06 * math.sin(phase + row))
        half = width * edge_scale / 2
        fold = min(0.055, width * 0.16)
        for across in (-1, 0, 1):
            p = center + side * (half * across)
            p.z -= abs(across) * fold
            verts.append(tuple(p))
    for row in range(4):
        for band in range(2):
            a = row * 3 + band
            faces.append((a, a + 3, a + 4, a + 1))
    return verts, faces, "foliage_deep" if index % 2 == 0 else "foliage_light"


def coconut_mesh(center, radius=0.14, sides=8):
    """Small faceted fruit with tapered ends, attached into the crown."""
    cx, cy, cz = center
    verts = []
    # Eight-sided oval equator with pointed, softly tapered ends: 32 tris.
    for i in range(sides):
        a = 2 * math.pi * i / sides
        verts.append((cx + radius * math.cos(a),
                      cy + radius * 0.88 * math.sin(a), cz))
    bottom, top = len(verts), len(verts) + 1
    verts.extend(((cx, cy, cz - radius * 0.76), (cx, cy, cz + radius * 0.76)))
    faces = []
    for i in range(sides):
        j = (i + 1) % sides
        faces.append((bottom, j, i))
        faces.append((i, j, top))
    return verts, faces


def main():
    kit.reset()
    verts, faces = [], []
    material_ids = []

    def append_mesh(new_verts, new_faces, material):
        offset = len(verts)
        verts.extend(new_verts)
        faces.extend(tuple(offset + i for i in f) for f in new_faces)
        material_ids.extend([material] * len(new_faces))

    trunk_v, trunk_f = trunk_mesh()
    append_mesh(trunk_v, trunk_f, "teak_dark")

    # Cardinal leaves set the 6 m crown bounds; six more fill the intervening arcs.
    yaws = [0, math.pi / 2, math.pi, 3 * math.pi / 2,
            *[math.radians(a) for a in (32, 68, 112, 148, 212, 328)]]
    frond_indices = []
    for i, yaw in enumerate(yaws):
        leaf_v, leaf_f, material = frond_mesh(i, yaw, 2.83 + 0.08 * (i % 3), i * 0.7)
        start = len(verts)
        append_mesh(leaf_v, leaf_f, material)
        frond_indices.extend(range(start, start + len(leaf_v)))

    # Fit only the crown in X/Y. The trunk remains exactly 7.5 m tall with a
    # 0.16 m base radius, and the shared roots stay attached to its top ring.
    crown_root = Vector((0.10 + 0.035 * math.sin(7.5 * 0.92),
                         -0.07 + 0.025 * math.sin(7.5 * 0.78), 7.5))
    crown_bounds = [Vector(verts[i]) for i in frond_indices]
    crown_lo = Vector((min(v.x for v in crown_bounds), min(v.y for v in crown_bounds), 0))
    crown_hi = Vector((max(v.x for v in crown_bounds), max(v.y for v in crown_bounds), 0))
    crown_scale = Vector((6.0 / (crown_hi.x - crown_lo.x),
                          6.0 / (crown_hi.y - crown_lo.y), 1.0))
    for i in frond_indices:
        p = Vector(verts[i])
        verts[i] = (crown_root.x + (p.x - crown_root.x) * crown_scale.x,
                    crown_root.y + (p.y - crown_root.y) * crown_scale.y,
                    p.z)

    # Five nuts overlap the narrowing trunk around its upper crown.
    nut_heights = (6.88, 6.93, 6.98, 7.04, 7.12)
    nuts = []
    for height, angle in zip(nut_heights, (0, 72, 144, 216, 288)):
        angle = math.radians(angle)
        trunk_x = 0.10 * (height / 7.5) + 0.035 * math.sin(height * 0.92)
        trunk_y = -0.07 * (height / 7.5) + 0.025 * math.sin(height * 0.78)
        nuts.append((trunk_x + 0.19 * math.cos(angle),
                     trunk_y + 0.19 * math.sin(angle), height))
    for center in nuts:
        nut_v, nut_f = coconut_mesh(center)
        append_mesh(nut_v, nut_f, "teak_dark")

    mesh = bpy.data.meshes.new("coconut_palm_mesh")
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    obj = bpy.data.objects.new("coconut_palm", mesh)
    bpy.context.collection.objects.link(obj)
    # Three palette slots only; surfaces are individually assigned by component.
    material_names = ["teak_dark", "foliage_deep", "foliage_light"]
    for name in material_names:
        mesh.materials.append(kit.mat(name))
    slot = {name: i for i, name in enumerate(material_names)}
    for poly, name in zip(mesh.polygons, material_ids):
        poly.material_index = slot[name]
        poly.use_smooth = False

    obj.location = (0, 0, 0)
    bpy.context.view_layer.update()
    # Use the shared join/origin/export path; there is exactly one component object.
    palm = kit.join("coconut_palm", [obj])
    kit.set_origin(palm, kit.bottom_centre([palm]))
    palm.location = (0, 0, 0)
    kit.export("assets/candidates/af01/coconut_palm.glb", [palm])


if __name__ == "__main__":
    main()
