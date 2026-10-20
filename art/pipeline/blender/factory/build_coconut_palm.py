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
        # Two profile rows make each collar a crisp, readable raised ring.
        profile.extend(((z - 0.035, radius),
                        (z, radius + 0.02)))
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
    """Four arch segments with continuous, deeply notched folded V margins."""
    forward = Vector((math.cos(yaw), math.sin(yaw), 0))
    side = Vector((-math.sin(yaw), math.cos(yaw), 0))
    root = Vector((0.10 + 0.035 * math.sin(7.5 * 0.92),
                   -0.07 + 0.025 * math.sin(7.5 * 0.78), 7.5))
    young = index in (1, 6, 8)
    arch = (0.46 + 0.025 * (index % 3)) if young else 0.28 + 0.035 * (index % 4)
    tip_drop = (0.55 + 0.10 * (index % 3)) if young else 1.20 + 0.18 * (index % 5)
    # The brief initial arch rolls into a long falling outer blade. The five
    # spine stations retain the batch's four major segments.
    spine = ((0.0, 0.0), (0.16, arch * 0.80), (0.33, arch),
             (0.66, -tip_drop * 0.35), (1.0, -tip_drop))

    def point(t, across):
        interval = next((i for i in range(4) if t <= spine[i + 1][0]), 3)
        a, za = spine[interval]
        b, zb = spine[interval + 1]
        rise = za + (zb - za) * (t - a) / (b - a)
        fold = 0.012 + 0.055 * math.sin(math.pi * t)
        p = root + forward * (reach * t) + side * across
        # The shared ridge stays high; the leaflet margins fall away from it.
        p.z += rise + (fold if across == 0 else -fold)
        if across:
            p.z += 0.025 * math.sin(phase + t * 5.0) * across
        return tuple(p)

    vertices = [point(t, 0) for t, _rise in spine]
    # Six outward leaflet teeth alternate with six deep notches on each side.
    # A continuous margin keeps the frond substantial against the sky rather
    # than leaving disconnected, hair-thin fins along a narrow strip.
    edge_t = (0.0, 0.10, 0.16, 0.24, 0.31, 0.39, 0.46,
              0.54, 0.61, 0.69, 0.76, 0.84, 0.91, 1.0)
    widths = (0.04, 0.23, 0.075, 0.35, 0.11, 0.41, 0.12,
              0.38, 0.105, 0.30, 0.08, 0.19, 0.045, 0.025)
    faces = []
    for sign in (-1, 1):
        offset = len(vertices)
        for t, width in zip(edge_t, widths):
            variation = 0.96 + 0.04 * math.sin(phase + t * 7.0)
            vertices.append(point(t, sign * width * variation))
        # Join two ordered chains directly: 17 triangles per half-blade.
        # Shared spine vertices make a true folded sheet with no floating fins.
        i, j = 0, 0
        while i < 4 or j < len(edge_t) - 1:
            if i < 4 and (j == len(edge_t) - 1 or spine[i + 1][0] <= edge_t[j + 1]):
                face = (i, i + 1, offset + j)
                i += 1
            else:
                face = (i, offset + j + 1, offset + j)
                j += 1
            faces.append(face if sign > 0 else tuple(reversed(face)))
    return vertices, faces, "foliage_deep" if index % 2 == 0 else "foliage_light"


def coconut_mesh(center, radius=0.14, sides=6):
    """Small faceted fruit with tapered ends, attached into the crown."""
    cx, cy, cz = center
    verts = []
    # Six-sided oval fruit with tapered ends: 12 triangles per coconut.
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
        material = kit.mat(name)
        # Thin folded fronds must remain visible from both standing and low views.
        if name.startswith("foliage_"):
            material.use_backface_culling = False
        mesh.materials.append(material)
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
    assert kit.triangles([palm]) <= 590
    kit.export("assets/candidates/af01/coconut_palm.glb", [palm])


if __name__ == "__main__":
    main()
