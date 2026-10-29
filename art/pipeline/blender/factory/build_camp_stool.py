"""Build a folding expedition stool with a canvas sling seat."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


def canvas_sling():
    """A shallow cloth panel sagging between its two wooden end rails."""
    xs = (-0.205, 0.0, 0.205)
    ys = (-0.17, -0.085, 0.0, 0.085, 0.17)
    vertices = []
    for y in ys:
        sag = 0.03 * (1.0 - abs(y) / 0.17)
        for x in xs:
            # A slight hand-cut asymmetry keeps the sling from reading as machined.
            z = 0.457 - sag + (0.001 if x == 0 and y == -0.085 else 0.0)
            vertices.append((x, y, z))
    faces = []
    for row in range(len(ys) - 1):
        for col in range(len(xs) - 1):
            a = row * len(xs) + col
            b = a + 1
            d = (row + 1) * len(xs) + col
            c = d + 1
            faces.extend(((a, b, c), (a, c, d)))
    mesh = bpy.data.meshes.new("canvas_sling")
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    mesh.update()
    obj = bpy.data.objects.new("canvas_sling", mesh)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(kit.mat("canvas"))
    return obj


def leg_between(name, start, end):
    delta = Vector(end) - Vector(start)
    angle_x = math.degrees(math.atan2(-delta.y, delta.z))
    angle_y = math.degrees(math.atan2(delta.x, math.hypot(delta.y, delta.z)))
    obj = kit.cyl(name, 0.015, delta.length,
                  (Vector(start) + Vector(end)) * 0.5, "teak",
                  rot=(angle_x, angle_y, 0), verts=8, bevel=0.002, segments=1)
    # The 45-degree facets are the round stock itself, not hard edges. Keep
    # the bevel on the end caps while avoiding seams along the octagonal shaft.
    for modifier in obj.modifiers:
        modifier.angle_limit = math.radians(50)
    return obj


def main():
    kit.reset()
    parts = []
    # Each X is a crossed pair of round, splayed legs in a side plane. The
    # rounded tips meet the ground, and the two end frames set the depth.
    for x in (-0.185, 0.185):
        # Offset the two sticks through each X by half their diameter so the
        # crossed wood clears around the pin instead of occupying one volume.
        parts.append(leg_between("folding_leg",
                                 (x - 0.015, -0.175, 0.015),
                                 (x - 0.015, 0.145, 0.43)))
        parts.append(leg_between("folding_leg",
                                 (x + 0.015, 0.175, 0.015),
                                 (x + 0.015, -0.145, 0.43)))
        # The dark iron pin passes through the crossed legs at their joint.
        pin = kit.cyl("centre_pin", 0.018, 0.065,
                      (x, 0.0, 0.253), "iron", rot=(0, 90, 0),
                      verts=8, bevel=0.002, segments=1)
        # Same treatment for the pin's eight-sided cylindrical surface.
        for modifier in pin.modifiers:
            modifier.angle_limit = math.radians(50)
        parts.append(pin)

    # End rails span the stool width and support the sling at either end.
    for y in (-0.17, 0.17):
        parts.append(kit.box("seat_rail", (0.45, 0.04, 0.04),
                             (0.0, y, 0.437), "teak",
                             bevel=0.006, segments=1))
    parts.append(canvas_sling())

    stool = kit.join("camp_stool", parts)
    kit.set_origin(stool, kit.bottom_centre([stool]))
    stool.location = (0.0, 0.0, 0.0)
    kit.export("assets/candidates/af01/camp_stool.glb", [stool])


if __name__ == "__main__":
    main()
