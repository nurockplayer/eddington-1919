"""Build the canvas shelter and horizontal camera tube in Blender metres.

Run with Blender 5.2: blender -b --factory-startup -P <this file>.
The eye end/front faces -Y; all exported origins stay at ground-level zero.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


GROUND = Vector((0, 0, 0))


def finish(name, parts):
    obj = kit.join(name, parts)
    kit.set_origin(obj, GROUND)
    return obj


def build_shelter():
    kit.reset()
    kit._mats.clear()
    frame_parts = []
    for row, y, height in (("front", -3.15, 2.75), ("rear", 3.15, 2.85)):
        for side, x in (("left", -2.3), ("right", 2.3)):
            name = f"sun_shelter_{row}_{side}"
            frame_parts.append(kit.cyl(
                name + "_post", 0.07, height, (x, y, height / 2),
                "teak", verts=12, bevel=0.012))
            # Broad, simplified rope wraps; each strap is at least 2 cm thick.
            for z in (height - 0.045, height + 0.025):
                frame_parts.append(kit.box(
                    name + "_lashing", (0.18, 0.18, 0.025), (x, y, z),
                    "pine", bevel=0.006))
    frame_parts.extend([
        kit.box("sun_shelter_front_beam", (4.9, 0.12, 0.12),
                (0, -3.15, 2.81), "teak_dark", bevel=0.02),
        kit.box("sun_shelter_rear_beam", (5.2, 0.30, 0.30),
                (0, 3.2, 3.0), "teak_dark", bevel=0.02),
    ])
    slope = (3.15 - 2.87) / (3.2 + 3.15)
    angle = math.atan(slope)
    for x in (-2.3, 2.3):
        frame_parts.append(kit.box(
            "sun_shelter_side_beam", (0.12, 6.35 / math.cos(angle), 0.12),
            (x, 0.025, 3.01 - 0.06 * math.cos(angle)), "teak_dark",
            rot=(math.degrees(angle), 0, 0), bevel=0.02))
    frame = finish("sun_shelter", frame_parts)

    # Shear a slab rather than rotating it: the Y edges remain exactly +/-3.5.
    canvas = kit.box("sun_shelter_roof_slab", (5.2, 7.0, 0.04),
                     (0, 0, 2.87 + 3.15 * slope + 0.02),
                     "canvas", bevel=0.008)
    for v in canvas.data.vertices:
        v.co.z += slope * v.co.y
    front_top = 2.87 + (-3.5 + 3.15) * slope + 0.04
    roof = finish("sun_shelter_roof", [
        canvas,
        kit.box("sun_shelter_roof_valance", (5.4, 0.03, 0.35),
                (0, -3.485, front_top - 0.175), "canvas", bevel=0.008),
    ])
    roll_parts = [kit.cyl(
        "sun_shelter_roll_canvas", 0.14, 5.0, (0, 3.2, 3.29),
        "canvas", rot=(0, 90, 0), verts=16)]
    for x in (-1.85, 0, 1.85):
        roll_parts.append(kit.cyl(
            "sun_shelter_roll_band", 0.15, 0.04, (x, 3.2, 3.29),
            "pine", rot=(0, 90, 0), verts=16, bevel=0.006))
    roll = finish("sun_shelter_roll", roll_parts)
    kit.export("assets/models/sun_shelter.glb", [frame, roof, roll])


def lens_cell():
    """Brass annulus with a real opening for the recessed object-glass face."""
    count = 20
    vertices = []
    for y, radius in ((1.75, 0.25), (1.89, 0.25),
                      (1.75, 0.195), (1.89, 0.195)):
        for i in range(count):
            a = math.tau * i / count
            vertices.append((radius * math.cos(a), y, 1.35 + radius * math.sin(a)))
    faces = []
    for a, b in ((0, 1), (1, 3), (3, 2), (2, 0)):
        for i in range(count):
            j = (i + 1) % count
            faces.append((a * count + i, a * count + j,
                          b * count + j, b * count + i))
    mesh = bpy.data.meshes.new("horizontal_tube_lens_cell")
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    cell = bpy.data.objects.new("horizontal_tube_lens_cell", mesh)
    bpy.context.collection.objects.link(cell)
    cell.data.materials.append(kit.mat("brass"))
    bevel = cell.modifiers.new("bevel", "BEVEL")
    bevel.width = 0.006
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    return cell


def trestle_leg(name, foot, head):
    """Sheared timber with horizontal end cuts, keeping every foot at z=0."""
    height = head[2]
    leg = kit.box(name, (0.07, 0.07, height),
                  (foot[0], foot[1], height / 2), "teak", bevel=0.008)
    for v in leg.data.vertices:
        t = (v.co.z + height / 2) / height
        v.co.x += (head[0] - foot[0]) * t
        v.co.y += (head[1] - foot[1]) * t
    return leg


def build_tube():
    kit.reset()
    kit._mats.clear()
    parts = [kit.box("horizontal_tube_body", (0.46, 3.5, 0.46),
                     (0, 0, 1.35), "iron")]
    for y in (-1.6, -0.55, 0.55, 1.6):
        parts.append(kit.box("horizontal_tube_band", (0.50, 0.06, 0.50),
                             (0, y, 1.35), "iron", bevel=0.008))
    parts.append(lens_cell())
    # Face at y=1.884, 6 mm behind the cell lip; a 2 cm solid disc.
    parts.append(kit.cyl("horizontal_tube_object_glass", 0.19, 0.02,
                         (0, 1.874, 1.35), "ebonite",
                         rot=(90, 0, 0), verts=20, bevel=0.006))
    for index, y in enumerate((-1.25, 1.25)):
        for xsign in (-1, 1):
            for ysign in (-1, 1):
                parts.append(trestle_leg(
                    f"horizontal_tube_trestle_{index}_leg_{xsign}_{ysign}",
                    (xsign * 0.35, y + ysign * 0.12, 0),
                    (xsign * 0.20, y + ysign * 0.035, 1.075)))
        parts.extend([
            kit.box(f"horizontal_tube_trestle_{index}_stretcher", (0.65, 0.10, 0.07),
                    (0, y, 0.35), "teak", bevel=0.008),
            kit.box(f"horizontal_tube_trestle_{index}_saddle", (0.56, 0.14, 0.06),
                    (0, y, 1.09), "teak_dark", bevel=0.008),
        ])
    parts.extend([
        kit.box("horizontal_tube_plate_carrier", (0.60, 0.18, 0.60),
                (0, -1.83, 1.35), "teak_dark"),
        kit.box("horizontal_tube_plate_slot", (0.02, 0.12, 0.45),
                (0.306, -1.83, 1.35), "ebonite", bevel=0.006),
    ])
    for z in (1.13, 1.57):
        parts.append(kit.box("horizontal_tube_plate_batten", (0.60, 0.03, 0.055),
                             (0, -1.929, z), "teak", bevel=0.008))
    tube = finish("horizontal_tube", parts)
    kit.export("assets/models/horizontal_tube.glb", [tube])


if __name__ == "__main__":
    build_shelter()
    build_tube()
