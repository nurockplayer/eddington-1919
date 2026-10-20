"""Build a grooved timber drying rack with four dark developed negatives."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


GROOVES = [-0.242 + 0.044 * index for index in range(12)]


def grooved_base():
    # Twelve broad V cuts are part of the board, replacing the spec's tiny
    # dowels. Between cuts the timber stays at least 2 cm wide; no loose pegs.
    profile = [(-0.30, 0.06)]
    for x in GROOVES:
        profile.extend([(x - 0.011, 0.06), (x, 0.04), (x + 0.011, 0.06)])
    profile.append((0.30, 0.06))
    vertices = [(x, y, z) for x, top in profile
                for y, z in ((-0.13, 0), (0.13, 0),
                             (-0.13, top), (0.13, top))]
    # Strip quads avoid concave end-cap tessellation and its zero-area slivers.
    faces = [(0, 2, 3, 1)]
    for index in range(len(profile) - 1):
        a, b = index * 4, (index + 1) * 4
        faces.extend([(a, a + 1, b + 1, b),
                      (a + 2, b + 2, b + 3, a + 3),
                      (a, b, b + 2, a + 2),
                      (a + 1, a + 3, b + 3, b + 1)])
    end = (len(profile) - 1) * 4
    faces.append((end, end + 1, end + 3, end + 2))
    mesh = bpy.data.meshes.new("grooved_board")
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    board = bpy.data.objects.new("grooved_board", mesh)
    bpy.context.collection.objects.link(board)
    mesh.materials.append(kit.mat("teak"))
    bevel = board.modifiers.new("soft_cut_edges", "BEVEL")
    # The groove edges share this small chamfer; a full 6 mm bevel would
    # swallow the V bottoms. Outer timber edges use the same restrained cut.
    bevel.width = 0.006
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    return board


def main():
    kit.reset()
    parts = [grooved_base()]
    # Uprights are tenoned into the base. The back rail leaves an open front
    # (-Y), so the silhouette shows the grooves and each separate negative.
    for x, roll in ((-0.273, 0.22), (0.273, -0.16)):
        parts.append(kit.box("end_post", (0.048, 0.048, 0.355),
                             (x, 0.104, 0.2225), "teak_dark",
                             rot=(0, roll, 0), bevel=0.006))
    parts.append(kit.box("back_top_rail", (0.566, 0.03, 0.055),
                         (0, 0.115, 0.370), "teak_dark", bevel=0.006))
    # 3 mm glass is the batch's explicit exception to the 2 cm feature rule.
    # Each plate sits in a V trough, tips slightly left and meets the back
    # rail. The varied lean is small enough to preserve a serious tool read.
    for slot, lean, height in ((1, -4.2, 0.315), (4, -3.5, 0.316),
                               (7, -4.6, 0.314), (10, -3.9, 0.315)):
        angle = math.radians(lean)
        # A 3 mm slab seats where the V opens to its width (z = .04273).
        bottom = Vector((GROOVES[slot], -0.0005, 0.04273))
        rise = Vector((math.sin(angle), 0, math.cos(angle)))
        parts.append(kit.box("glass_negative", (0.003, 0.207, height),
                             bottom + rise * (height / 2), "sea_slate",
                             rot=(0, lean, 0), bevel=0.0005))
    rack = kit.join("plate_rack", parts)
    bpy.context.view_layer.update()
    kit.set_origin(rack, kit.bottom_centre([rack]))
    rack.location = (0, 0, 0)
    # The tiny post tilt stays inside the registry envelope without rescaling
    # the specified glass thickness or the cut spacing.
    pts = [rack.matrix_world @ v.co for v in rack.data.vertices]
    dims = Vector([max(p[i] for p in pts) - min(p[i] for p in pts)
                   for i in range(3)])
    assert all(abs(a - b) < 0.002 for a, b in zip(dims, (0.60, 0.26, 0.40))), tuple(dims)
    kit.export("assets/candidates/af01/plate_rack.glb", [rack])


if __name__ == "__main__":
    main()
