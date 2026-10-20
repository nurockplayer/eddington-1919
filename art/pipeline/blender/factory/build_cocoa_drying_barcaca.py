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


def timber_between(name, start, end, width, depth):
    a, b = Vector(start), Vector(end)
    obj = kit.box(name, (width, depth, (b - a).length), (a + b) / 2,
                  "teak", bevel=0.008)
    obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
    return obj


def bean_bed():
    # A shallow, broken cross-section makes the cocoa read as long raked rows.
    # The low 2-4 cm crests remain visible from standing height without looking
    # like roof ribs or regular molded pods.
    xmin, xmax = -1.49, 1.49
    y0, y1 = -3.90, 0.30
    nx, ny = 13, 4
    verts = []
    for j in range(ny):
        y = y0 + (y1 - y0) * j / (ny - 1)
        phase = 0.19 * math.sin((y + 3.92) * 1.6)
        for i in range(nx):
            x = xmin + (xmax - xmin) * i / (nx - 1)
            # Five broad ridges with slightly uneven spacing and height.
            wave = math.sin((x + 1.45) * (math.tau * 5.0 / 2.90) + phase)
            crest = max(0.0, wave) ** 1.35
            along = 0.78 + 0.22 * math.sin((y + 3.4) * 2.1 + i * 0.11)
            z = 0.620 + 0.040 * crest * along
            verts.append((x, y, z))
    faces = []
    for j in range(ny - 1):
        for i in range(nx - 1):
            a = j * nx + i
            faces.append((a, a + 1, a + nx + 1, a + nx))
    # Close the surface down to the deck so the ridges are a solid bed rather
    # than paper-thin faces, while keeping its top distinctly non-flat.
    top_count = len(verts)
    perimeter = list(range(nx))
    perimeter += [j * nx + nx - 1 for j in range(1, ny)]
    perimeter += list(range((ny - 1) * nx + nx - 2, (ny - 1) * nx - 1, -1))
    perimeter += [j * nx for j in range(ny - 2, 0, -1)]
    lower = []
    for idx in perimeter:
        x, y, _z = verts[idx]
        lower.append(len(verts))
        verts.append((x, y, 0.600))
    for p in range(len(perimeter)):
        q = (p + 1) % len(perimeter)
        faces.append((perimeter[p], perimeter[q], lower[q], lower[p]))
    return mesh_object("bean_ridges", verts, faces, "laterite_wet")


def corrugated_roof():
    # Low corrugation ripples run along the roof pitch from ridge to eave.
    # Their profile repeats down the 4.4 m roof length, as on a sheet roof.
    profile = []
    flute_width = 4.4 / 18
    for flute in range(18):
        for fraction, lift in ((0.0, 0.0), (0.5, 0.012)):
            profile.append((-4.0 + (flute + fraction) * flute_width, lift))
    profile.append((0.4, 0.0))
    count = len(profile)
    verts = [(x, y, z + lift)
             for x, z in ((-1.6, 1.75), (0.0, 2.188), (1.6, 1.75))
             for y, lift in profile]
    faces = []
    for slope in range(2):
        for i in range(count - 1):
            a, b = slope * count + i, (slope + 1) * count + i
            faces.append((a, b, b + 1, a + 1))
    # Narrow turned returns along the two eaves, leaving the gable ends open.
    for xrow in (0, 2):
        lower = len(verts)
        for i in range(count):
            x, y, z = verts[xrow * count + i]
            verts.append((x - math.copysign(0.008, x), y, z - 0.018))
        for i in range(count - 1):
            a, b = xrow * count + i, xrow * count + i + 1
            faces.append((a, b, lower + i + 1, lower + i))
    return mesh_object("roof_sheet", verts, faces, "iron")


def roller(x, y):
    # Small 8-sided steel rollers sit directly on the iron runners.
    radius = 0.04
    zc = 1.62
    verts = []
    for dx in (-0.03, 0.03):
        for i in range(8):
            a = math.tau * i / 8
            verts.append((x + dx, y + radius * math.sin(a),
                          zc + radius * math.cos(a)))
    faces = [tuple(reversed(range(8))), tuple(range(8, 16))]
    for i in range(8):
        j = (i + 1) % 8
        faces.append((i, j, 8 + j, 8 + i))
    return mesh_object("roof_roller", verts, faces, "iron")


def main():
    kit.reset()
    static = []

    # Low raised deck occupies the -Y end: 4.4 m long, with its top at 0.60 m.
    for x in (-1.30, 1.30):
        for y in (-3.72, -1.80, 0.12):
            static.append(kit.box("brick_pier", (0.38, 0.38, 0.60),
                                  (x, y, 0.30), "brick", bevel=0.018))
    for y in (-3.72, -1.80, 0.12):
        static.append(kit.box("cross_bearer", (2.90, 0.14, 0.12),
                              (0, y, 0.54), "teak", bevel=0.006))
    for x in (-1.34, 0.0, 1.34):
        static.append(kit.box("deck_joist", (0.14, 4.34, 0.10),
                              (x, -1.80, 0.55), "teak", bevel=0.006))

    # Unequal plank widths give the deck a hand-built rhythm.
    boundaries = [-4.0, -3.45, -2.92, -2.34, -1.80, -1.23, -0.68, -0.12, 0.40]
    for i, (left, right) in enumerate(zip(boundaries, boundaries[1:])):
        gap_l = 0.0 if i == 0 else 0.008
        gap_r = 0.0 if i == len(boundaries) - 2 else 0.008
        width = right - left - gap_l - gap_r
        y = (left + gap_l + right - gap_r) / 2
        static.append(kit.box("deck_plank", (3.08, width, 0.06),
                              (0, y, 0.57), "teak", bevel=0.006))

    # Low perimeter boards hold the drying bed in place, with tops at 0.72 m.
    for x in (-1.55, 1.55):
        static.append(kit.box("edge_board", (0.10, 4.40, 0.12),
                              (x, -1.80, 0.66), "teak", bevel=0.006))
    for y in (-3.95, 0.35):
        static.append(kit.box("end_board", (3.10, 0.10, 0.12),
                              (0, y, 0.66), "teak", bevel=0.006))
    static.append(bean_bed())

    # Side rails run the complete 8 m footprint; their independent posts touch
    # the ground and the extra +Y bay remains clear for the rolling roof.
    for x in (-1.48, 1.48):
        for y in (-3.82, 0.0, 3.82):
            static.append(kit.box("rail_post", (0.12, 0.12, 1.42),
                                  (x, y, 0.71), "teak", bevel=0.006))
        static.append(kit.box("rail_beam", (0.14, 8.0, 0.12),
                              (x, 0, 1.48), "teak", bevel=0.006))
        static.append(kit.box("iron_runner", (0.08, 8.0, 0.04),
                              (x, 0, 1.56), "iron", bevel=0.004))

    moving = [corrugated_roof()]
    # Eaves are about 1.75 m high so the bed stays visible beneath them.
    for x in (-1.48, 1.48):
        moving.append(kit.box("roof_eave_girt", (0.10, 4.40, 0.08),
                              (x, -1.80, 1.76), "teak", bevel=0.006))
        moving.append(roller(x, -3.78))
        moving.append(roller(x, 0.18))
        for y in (-3.78, 0.18):
            moving.append(kit.box("roller_hanger", (0.04, 0.08, 0.16),
                                  (x, y, 1.67), "iron", bevel=0.006))
    for y in (-3.88, 0.28):
        for sign in (-1, 1):
            moving.append(timber_between("gable_rafter",
                (sign * 1.48, y, 1.79), (0, y, 2.16), 0.07, 0.07))
    moving.append(kit.box("roof_ridge_cap", (0.08, 4.40, 0.04),
                          (0, -1.80, 2.18), "iron", bevel=0.004))

    platform = kit.join("cocoa_drying_barcaca", static)
    roof = kit.join("cocoa_drying_barcaca_roof", moving)
    bpy.context.view_layer.update()
    for obj in (platform, roof):
        kit.set_origin(obj, Vector((0, 0, 0)))
    kit.export("assets/candidates/af01/cocoa_drying_barcaca.glb",
               [platform, roof])


if __name__ == "__main__":
    main()
