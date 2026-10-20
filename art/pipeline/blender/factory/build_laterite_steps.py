"""Two crisp, dark basalt terrace steps bedded in narrow laterite joints."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy


def mesh_part(name, vertices, faces, material, bevel):
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
    chamfer = obj.modifiers.new("dressed_edge", "BEVEL")
    chamfer.width = bevel
    chamfer.segments = 1
    chamfer.limit_method = "ANGLE"
    return obj


def stair_core():
    # Mortar reaches into the joints and overlaps the slab undersides.
    # Two 15 cm rises, noses at -.40/-.04, flush with the .30 m terrace.
    profile = [(-0.388, 0.0), (0.40, 0.0), (0.40, 0.222),
               (-0.028, 0.222), (-0.028, 0.072), (-0.388, 0.072)]
    vertices = [(x, y, z) for x in (-0.80, 0.80) for y, z in profile]
    n = len(profile)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    return mesh_part("laterite_steps_infill", vertices, faces, "laterite", 0.004)


def clip_polygon(polygon, axis, bound, keep_greater):
    """Trim footprint edges while retaining the small yaw on dressed blocks."""
    clipped = []
    for a, b in zip(polygon, polygon[1:] + polygon[:1]):
        inside_a = a[axis] >= bound if keep_greater else a[axis] <= bound
        inside_b = b[axis] >= bound if keep_greater else b[axis] <= bound
        if inside_a:
            clipped.append(a)
        if inside_a != inside_b:
            t = (bound - a[axis]) / (b[axis] - a[axis])
            clipped.append(tuple(a[i] + (b[i] - a[i]) * t for i in range(2)))
    return clipped


def basalt_block(name, x0, x1, front, back, bottom, top, yaw, shift):
    # Parallel long sides have a slight yaw. Dressing the front and rear
    # produces level, exact noses instead of an unsafe wavy walking surface.
    angle = math.radians(yaw)
    depth = back - front + 0.045
    width = x1 - x0
    cx, cy = (x0 + x1) / 2, (front + back) / 2 + shift
    polygon = []
    for x, y in ((-width / 2, -depth / 2), (width / 2, -depth / 2),
                 (width / 2, depth / 2), (-width / 2, depth / 2)):
        polygon.append((cx + x * math.cos(angle) - y * math.sin(angle),
                        cy + x * math.sin(angle) + y * math.cos(angle)))
    for axis, bound, greater in ((0, -0.80, True), (0, 0.80, False),
                                 (1, front, True), (1, back, False)):
        polygon = clip_polygon(polygon, axis, bound, greater)
    vertices = [(x, y, z) for z in (bottom, top) for x, y in polygon]
    n = len(polygon)
    faces = [tuple(reversed(range(n))), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    return mesh_part(name, vertices, faces, "basalt", 0.004)


def main():
    kit.reset()
    parts = [stair_core()]
    # Two substantial lower treads, three upper treads. Unequal widths and
    # small offsets preserve hand-dressed masonry rather than equal repeats.
    # Nearly parallel yaw keeps the joints 10-12 mm before the 4 mm chamfer.
    courses = [
        (0.15, -0.40, -0.04, [(-0.80, -0.0825), (-0.0715, 0.80)],
         (1.2, 1.4), (0.008, -0.006), (0.090, 0.086)),
        (0.30, -0.04, 0.40, [(-0.80, -0.313), (-0.302, 0.267), (0.278, 0.80)],
         (-1.3, -1.1, -1.4), (-0.007, 0.009, -0.004), (0.086, 0.094, 0.090)),
    ]
    for row, (level, nose, rear, cells, yaws, shifts, thicknesses) in enumerate(courses):
        for col, ((left, right), yaw, shift, thickness) in enumerate(
                zip(cells, yaws, shifts, thicknesses)):
            parts.append(basalt_block(
                f"laterite_steps_tread_{row}_{col}", left, right, nose, rear,
                level - thickness, level, yaw, shift))
            # Long low facing slabs tuck under the treads and into the infill.
            low = row * 0.15
            parts.append(basalt_block(
                f"laterite_steps_riser_{row}_{col}", left, right, nose, nose + 0.085,
                low, level - thickness + 0.012, yaw, shift))

    steps = kit.join("laterite_steps", parts)
    bpy.context.view_layer.update()
    kit.set_origin(steps, kit.bottom_centre([steps]))
    steps.location = (0, 0, 0)
    kit.export("assets/candidates/af01/laterite_steps.glb", [steps])


if __name__ == "__main__":
    main()
