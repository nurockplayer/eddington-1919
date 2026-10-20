"""Two supported, rough-dressed laterite house-terrace steps."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy


def stair_core():
    """One continuous infill supports both courses and all dressed blocks."""
    # The dressed noses sit at -0.40 and -0.04 m. Recess the infill faces
    # slightly so laterite mortar remains visible between the front stones.
    profile = [(-0.38, 0.0), (0.40, 0.0), (0.40, 0.28),
               (-0.02, 0.28), (-0.02, 0.13), (-0.38, 0.13)]
    x0, x1 = -0.80, 0.80
    verts = [(x, y, z) for x in (x0, x1) for y, z in profile]
    n = len(profile)
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    mesh = bpy.data.meshes.new("laterite_steps_infill")
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("laterite_steps_infill", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(kit.mat("laterite"))
    bevel = obj.modifiers.new("soft_architecture_edges", "BEVEL")
    bevel.width = 0.02
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    return obj


def stone_block(name, size, location, yaw):
    return kit.box(name, size, location, "stone",
                   rot=(0, 0, yaw), bevel=0.02, segments=1)


def projected_half_depth(width, depth, yaw):
    angle = math.radians(yaw)
    sin_a, cos_a = abs(math.sin(angle)), abs(math.cos(angle))
    sharp_corner = (width * sin_a + depth * cos_a) / 2
    return sharp_corner - 0.02 * min(sin_a, cos_a)


def main():
    kit.reset()
    parts = [stair_core()]

    # Four broad dressed blocks across each course. Their deterministic width
    # offsets stay within 1.2 cm; the small, even joints read as stone courses.
    widths = [0.375, 0.375, 0.375, 0.375]
    width_offsets = [-0.010, 0.004, -0.005, 0.012]
    x_centres = [-0.598, -0.199, 0.199, 0.598]
    levels = [0.15, 0.30]
    noses = [-0.40, -0.04]
    yaw = [[-1.2, 1.5, -1.7, 1.0], [1.4, -1.6, 1.0, -1.1]]

    # Lower tread is one 0.36 m nose-to-nose run. The upper course carries an
    # additional 0.08 m of bedding to the exact rear edge at y=0.40.
    tread_depths = [0.36, 0.44]
    depth_offsets = [-0.008, 0.004, -0.005, 0.010]
    thickness_offsets = [0.004, -0.003, 0.004, -0.004]

    for row, (level, nose, nominal_depth) in enumerate(
            zip(levels, noses, tread_depths)):
        for col, (base_width, x) in enumerate(zip(widths, x_centres)):
            w = base_width + width_offsets[col]
            d = nominal_depth + depth_offsets[col]
            angle = yaw[row][col]
            half_depth = projected_half_depth(w, d, angle)
            # Keep the lower nose at -0.40 and the upper cap at the rear edge
            # +0.40 despite each block's small yaw and depth variation.
            y = nose + half_depth if row == 0 else 0.40 - half_depth
            zthick = 0.05 + thickness_offsets[col]
            parts.append(stone_block(
                "laterite_steps_tread_block",
                (w, d, zthick),
                (x, y, level - zthick / 2),
                angle,
            ))

    # Each 15 cm riser is faced with four overlapping dressed stones. The
    # outer faces reach the two exact noses; their backs bury into the infill.
    for row, (nose, level) in enumerate(zip(noses, levels)):
        low = 0.0 if row == 0 else levels[row - 1]
        for col, (base_width, x) in enumerate(zip(widths, x_centres)):
            w = base_width + width_offsets[col]
            angle = yaw[row][col]
            depth = 0.06
            half_depth = projected_half_depth(w, depth, angle)
            h = level - low - 0.03
            parts.append(stone_block(
                "laterite_steps_riser_block",
                (w, depth, h),
                (x, nose + half_depth, low + h / 2),
                angle,
            ))

    steps = kit.join("laterite_steps", parts)
    bpy.context.view_layer.update()
    kit.set_origin(steps, kit.bottom_centre([steps]))
    steps.location = (0, 0, 0)
    kit.export("assets/candidates/af01/laterite_steps.glb", [steps])


if __name__ == "__main__":
    main()
