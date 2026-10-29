"""Raised cocoa-drying barcaça with a sliding corrugated gable roof."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


def mesh_object(name, vertices, faces, material):
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


def corrugated_roof():
    # Broad 20 cm flutes run DOWN the pitch (X), draining to the eaves.
    # Short flat shoulders soften the profile. The palette iron is exported
    # double-sided, with chamfered 2 cm turned edges instead of a second skin.
    profile = []
    for flute in range(15):
        for fraction, lift in ((0.0, 0.0), (0.2, 0.02),
                               (0.5, 0.02), (0.7, 0.0)):
            y = -3.0 + (flute + fraction) * 0.2
            profile.append((y, lift))
    profile.append((0.0, 0.0))
    count = len(profile)
    verts = [(x, y, z + lift)
             for x, z in ((-1.6, 1.73), (0.0, 2.18), (1.6, 1.73))
             for y, lift in profile]
    faces = []
    for slope in range(2):
        for i in range(count - 1):
            a, b = slope * count + i, (slope + 1) * count + i
            faces.append((a, b, b + 1, a + 1))
    # Perimeter follows the corrugation at each eave and the two gable ends.
    boundary = (list(range(count)) + [2 * count - 1, 3 * count - 1]
                + list(range(3 * count - 2, 2 * count - 1, -1)) + [count])
    rim_start = len(verts)
    for i in boundary:
        x, y, z = verts[i]
        # The inward return is the single-segment bevel on the cut sheet rim.
        dx = -math.copysign(0.008, x) if abs(x) > 1.59 else 0.0
        dy = 0.008 if y < -2.99 else (-0.008 if y > -0.01 else 0.0)
        verts.append((x + dx, y + dy, z - 0.02))
    for i, a in enumerate(boundary):
        j = (i + 1) % len(boundary)
        faces.append((a, boundary[j], rim_start + j, rim_start + i))
    return mesh_object("roof_sheet", verts, faces, "iron")


def roller(x, y):
    # Eight sides with integral 8 mm rim chamfers; 6 cm tread width. The
    # wheel overlaps its timber girt and contacts the iron rail at Z=1.63.
    vertices = []
    for dx, radius in ((-0.03, 0.032), (-0.022, 0.04),
                       (0.022, 0.04), (0.03, 0.032)):
        for i in range(8):
            a = math.tau * i / 8
            vertices.append((x + dx, y + radius * math.sin(a),
                             1.67 + radius * math.cos(a)))
    faces = [tuple(reversed(range(8))), tuple(range(24, 32))]
    for row in range(3):
        for i in range(8):
            j = (i + 1) % 8
            faces.append((row * 8 + i, row * 8 + j,
                          (row + 1) * 8 + j, (row + 1) * 8 + i))
    return mesh_object("roof_roller", vertices, faces, "iron")


def timber_between(name, start, end, width, depth):
    a, b = Vector(start), Vector(end)
    obj = kit.box(name, (width, depth, (b - a).length),
                  (a + b) / 2, "teak", bevel=0.008)
    obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    return obj


def main():
    kit.reset()
    static = []
    # The 6 m overall run comprises a 3 m deck (-Y/front) and a 3 m
    # uncovered rail bay (+Y/back). No invisible cantilever supports it.
    for row, y in enumerate((-2.76, -0.24)):
        for side, x in enumerate((-1.30, 1.30)):
            static.append(kit.box(
                "brick_pier", (0.38, 0.42, 0.65), (x, y, 0.325),
                "brick", rot=(0, 0, (row - side) * 0.6), bevel=0.025))
        static.append(kit.box("cross_bearer", (3.02, 0.14, 0.16),
                              (0, y, 0.72), "teak"))
    for x in (-1.33, 0.0, 1.33):
        static.append(kit.box("deck_joist", (0.14, 2.94, 0.12),
                              (x, -1.50, 0.80), "teak"))

    # Seven transverse planks rest on three joists, with their top at 0.9 m.
    # Unequal widths keep the deck from looking machine assembled.
    boundaries = [-2.98, -2.56, -2.13, -1.72, -1.29, -0.87, -0.44, -0.02]
    for i, (left, right) in enumerate(zip(boundaries, boundaries[1:])):
        gap_left = 0.0 if i == 0 else 0.006
        gap_right = 0.0 if i == 6 else 0.006
        width = right - left - gap_left - gap_right
        y = (left + gap_left + right - gap_right) / 2
        static.append(kit.box("deck_plank", (3.2, width, 0.06),
                              (0, y, 0.87), "teak", bevel=0.008))
    for x in (-1.56, 1.56):
        static.append(kit.box("edge_board", (0.08, 3.0, 0.15),
                              (x, -1.5, 0.955), "teak", bevel=0.008))
    for y in (-2.96, -0.04):
        static.append(kit.box("end_board", (3.04, 0.08, 0.15),
                              (0, y, 0.955), "teak", bevel=0.008))
    static.append(kit.box("drying_cocoa", (2.99, 2.80, 0.025),
                          (0, -1.5, 0.911), "laterite_wet", bevel=0.006))

    for x in (-1.44, 1.44):
        for y in (-2.83, -0.08, 2.83):
            static.append(kit.box("rail_post", (0.12, 0.12, 1.56),
                                  (x, y, 0.78), "teak", bevel=0.01))
        static.append(kit.box("rail_bearer", (0.12, 6.0, 0.12),
                              (x, 0, 1.545), "teak", bevel=0.008))
        static.append(kit.box("iron_runner", (0.08, 6.0, 0.03),
                              (x, 0, 1.615), "iron", bevel=0.006))
        static.append(timber_between(
            "extension_knee_brace", (x, 2.83, 0.97),
            (x, 2.29, 1.51), 0.08, 0.08))

    moving = [corrugated_roof()]
    for x in (-1.44, 1.44):
        moving.append(kit.box("roof_eave_girt", (0.10, 2.96, 0.08),
                              (x, -1.50, 1.720), "teak", bevel=0.008))
        for y in (-2.73, -0.27):
            moving.append(roller(x, y))
    moving.append(kit.box("roof_ridge_cap", (0.08, 3.0, 0.04),
                          (0, -1.50, 2.18), "iron", bevel=0.008))
    for y in (-2.88, -0.12):
        for sign in (-1, 1):
            moving.append(timber_between(
                "gable_rafter", (sign * 1.48, y, 1.73),
                (0, y, 2.15), 0.075, 0.075))

    platform = kit.join("cocoa_drying_barcaca", static)
    roof = kit.join("cocoa_drying_barcaca_roof", moving)
    bpy.context.view_layer.update()
    for obj in (platform, roof):
        kit.set_origin(obj, Vector((0, 0, 0)))
    kit.export("assets/candidates/af01/cocoa_drying_barcaca.glb",
               [platform, roof])


if __name__ == "__main__":
    main()
