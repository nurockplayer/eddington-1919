"""Procedural 1919 plantation wheelbarrow with flared boards and spoked wheel."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bmesh
import bpy
from mathutils import Vector


def beam(name, start, end, width, thickness, material, bevel=0.008):
    """A rectangular timber whose long local Y axis joins two points in YZ."""
    a, b = Vector(start), Vector(end)
    delta = b - a
    obj = kit.box(name, (width, delta.length, thickness), (a + b) / 2,
                  material, rot=(math.degrees(math.atan2(delta.z, delta.y)), 0, 0),
                  bevel=bevel)
    return obj


def bent_handle(x):
    """One continuous shaft that clears the tray and rises behind its end."""
    path = [Vector((-0.525, 0.225)), Vector((0.54, 0.29)), Vector((0.67, 0.52))]
    tangents = [(path[1] - path[0]).normalized(),
                ((path[1] - path[0]).normalized() + (path[2] - path[1]).normalized()).normalized(),
                (path[2] - path[1]).normalized()]
    verts, faces = [], []
    half_w, half_t = 0.024, 0.021
    for point, tangent in zip(path, tangents):
        normal = Vector((-tangent.y, tangent.x))
        for dx, dn in ((-half_w, -half_t), (half_w, -half_t),
                       (half_w, half_t), (-half_w, half_t)):
            yz = point + normal * dn
            verts.append((x + dx, yz.x, yz.y))
    faces.extend(((0, 3, 2, 1), (8, 9, 10, 11)))
    for section in range(2):
        a, b = section * 4, (section + 1) * 4
        for edge in range(4):
            nxt = (edge + 1) % 4
            faces.append((a + edge, a + nxt, b + nxt, b + edge))
    mesh = bpy.data.meshes.new("handle")
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("handle", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(kit.mat("teak_dark"))
    mod = obj.modifiers.new("soft handle edges", "BEVEL")
    mod.width, mod.segments, mod.limit_method = 0.009, 1, "ANGLE"
    return obj


def flared_side(sign):
    """One solid tray cheek, widening toward the back and outward at its rim."""
    # Keep the outer face within the 0.70 m specification while still giving
    # the tray a modest outward flare toward its broad rear end.
    sections = [(-0.30, 0.266, 0.296), (0.54, 0.306, 0.3103)]
    top_z = 0.620 if sign > 0 else 0.616  # slight hand-built asymmetry
    verts = []
    for y, lower, upper in sections:
        verts.extend(((sign * lower, y, 0.355), (sign * (lower + 0.04), y, 0.355),
                      (sign * upper, y, top_z), (sign * (upper + 0.04), y, top_z)))
    faces = [(0, 4, 6, 2), (1, 3, 7, 5), (0, 1, 5, 4), (2, 6, 7, 3),
             (0, 2, 3, 1), (4, 5, 7, 6)]
    mesh = bpy.data.meshes.new("tray_cheek")
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("tray_cheek", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(kit.mat("teak"))
    bevel = obj.modifiers.new("soft board edges", "BEVEL")
    bevel.width, bevel.segments, bevel.limit_method = 0.008, 1, "ANGLE"
    return obj


def radial_spoke(angle):
    """One of eight stout wooden spokes in the wheel's YZ plane."""
    direction = Vector((0, math.cos(angle), math.sin(angle)))
    center = Vector((0, -0.525, 0.225)) + direction * 0.095
    obj = kit.box("spoke", (0.04, 0.04, 0.19), center, "teak_dark", bevel=0.005)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    return obj


def annular_rim(name, inner_radius, outer_radius, width, center, material, bevel):
    """Sixteen-sided rectangular wheel rim with softly bevelled edges."""
    verts, faces = [], []
    half = width / 2
    for i in range(16):
        angle = 2 * math.pi * i / 16
        ca, sa = math.cos(angle), math.sin(angle)
        verts.extend(((-half, inner_radius * ca, inner_radius * sa),
                      (-half, outer_radius * ca, outer_radius * sa),
                      (half, inner_radius * ca, inner_radius * sa),
                      (half, outer_radius * ca, outer_radius * sa)))
    for i in range(16):
        j = (i + 1) % 16
        a, b = i * 4, j * 4
        faces.extend(((a + 1, b + 1, b + 3, a + 3),  # outer circumference
                      (a, a + 2, b + 2, b),            # inner circumference
                      (a, b, b + 1, a + 1),            # near side
                      (a + 2, a + 3, b + 3, b + 2)))  # far side
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    obj.location = center
    mesh.materials.append(kit.mat(material))
    mod = obj.modifiers.new("soft rim edges", "BEVEL")
    mod.width, mod.segments, mod.limit_method = bevel, 1, "ANGLE"
    return obj


def main():
    kit.reset()
    parts = []

    # A single substantial floor board keeps the tray stiff and the silhouette
    # legible at gameplay distance.
    parts.append(kit.box("tray_floor", (0.62, 0.80, 0.045),
                         (0, 0.11, 0.355), "teak", bevel=0.006))
    # A full-width bearer bridges the recessed handle shafts up to the tray
    # underside, tying the carried load into the wheel and leg frame.
    parts.append(kit.box("tray_bearer", (0.62, 0.08, 0.08),
                         (0, 0.15, 0.32), "teak_dark", bevel=0.008))
    parts.extend((flared_side(-1), flared_side(1)))
    # Transverse end boards close the tray. Their subtly different widths follow
    # the cheeks' flare without creating thin decorative strips.
    parts.append(kit.box("tray_front", (0.56, 0.045, 0.26),
                         (0, -0.292, 0.485), "teak_dark", bevel=0.008))
    parts.append(kit.box("tray_rear", (0.66, 0.045, 0.26),
                         (0, 0.5325, 0.485), "teak", bevel=0.008))

    # The 0.45 m wooden wheel sits ahead of the tray. An iron tyre wraps its rim.
    # The tyre is 0.45 m across and rests on the ground.
    wheel_center = (0, -0.525, 0.225)
    parts.append(kit.cyl("axle", 0.026, 0.62, wheel_center, "iron",
                         rot=(0, 90, 0), verts=8, bevel=0.005))
    for i in range(8):
        parts.append(radial_spoke(2 * math.pi * i / 8))
    parts.append(annular_rim("wooden_felloe", 0.165, 0.207, 0.080,
                             wheel_center, "teak_dark", bevel=0.004))
    parts.append(annular_rim("iron_tyre", 0.205, 0.225, 0.040,
                             wheel_center, "iron", bevel=0.003))
    parts.append(kit.cyl("wheel_hub", 0.058, 0.14, wheel_center, "teak",
                         rot=(0, 90, 0), verts=8, bevel=0.006))

    # Continuous handles lie under the tray floor, then rise outside its rear
    # board into individual hand grips. Their forward ends meet the axle.
    for x in (-0.265, 0.265):
        parts.append(bent_handle(x))
        support = beam("support_leg", (x, 0.12, 0.29), (x, 0.39, 0.014),
                       0.052, 0.045, "teak", bevel=0.009)
        bpy.context.view_layer.update()
        evaluated = support.evaluated_get(bpy.context.evaluated_depsgraph_get())
        eval_mesh = evaluated.to_mesh()
        foot_low = min((evaluated.matrix_world @ vertex.co).z for vertex in eval_mesh.vertices)
        evaluated.to_mesh_clear()
        support.location.z -= foot_low
        parts.append(support)
        parts.append(beam("grip", (x, 0.64, 0.54), (x, 0.75, 0.54),
                          0.056, 0.052, "teak", bevel=0.012))
    # A cross stretcher braces the two legs beneath the tray.
    parts.append(kit.box("leg_brace", (0.52, 0.045, 0.045),
                         (0, 0.31, 0.105), "teak_dark", bevel=0.008))

    wheelbarrow = kit.join("wheelbarrow", parts)
    bpy.context.view_layer.update()
    bounds = [wheelbarrow.matrix_world @ vertex.co for vertex in wheelbarrow.data.vertices]
    low = Vector((min(v.x for v in bounds), min(v.y for v in bounds), min(v.z for v in bounds)))
    high = Vector((max(v.x for v in bounds), max(v.y for v in bounds), max(v.z for v in bounds)))
    dims = high - low
    expected = Vector((0.70, 1.50, 0.62))
    assert all(abs(a - b) < 0.003 for a, b in zip(dims, expected)), (tuple(dims), tuple(expected))
    assert abs(low.z) < 0.003 and abs((low.x + high.x) / 2) < 0.003
    assert abs((low.y + high.y) / 2) < 0.003
    assert {m.name for m in wheelbarrow.data.materials} <= {
        "E1919_teak", "E1919_teak_dark", "E1919_iron"
    }
    assert kit.triangles([wheelbarrow]) <= 1700, kit.triangles([wheelbarrow])
    kit.set_origin(wheelbarrow, Vector((0, 0, 0)))
    wheelbarrow.location = (0, 0, 0)
    kit.export("assets/candidates/af01/wheelbarrow.glb", [wheelbarrow])


if __name__ == "__main__":
    main()
