"""Build a fitted teak instrument chest with a hinged lid and period hardware."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import kit
import bpy
import bmesh
from mathutils import Vector


def end_wall_with_pocket(sx):
    """Make one beveled end wall with a rectangular recessed handhold."""
    # Set the end grain back 2 mm from the cap faces for a readable flush-fit.
    wall = kit.box("end_wall", (0.054, 0.39, 0.354),
                   (sx * 0.421, 0, 0.223), "teak", bevel=0)
    cutter = kit.box("temporary_pocket_cutter", (0.08, 0.26, 0.20),
                     (sx * 0.422, 0, 0.27), "teak", bevel=0)
    boolean = wall.modifiers.new("handhold_recess", "BOOLEAN")
    boolean.operation = "DIFFERENCE"
    boolean.solver = "EXACT"
    boolean.object = cutter
    bpy.context.view_layer.objects.active = wall
    bpy.ops.object.modifier_apply(modifier=boolean.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
    bevel = wall.modifiers.new("bevel", "BEVEL")
    bevel.width = 0.008
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    return wall


def clean_sliver_faces(obj):
    """Dissolve sub-millimetre boolean slivers without changing the form."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.dissolve_degenerate(bm, dist=0.001, edges=bm.edges[:])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(obj.data)
    bm.free()


def hinge_knuckle(x):
    """Make the visible inward half of a barrel centred on the lid pivot."""
    segments = 10
    radius = 0.014
    half_depth = 0.020
    vertices = []
    for x_pos in (x - half_depth, x + half_depth):
        for i in range(segments + 1):
            angle = math.pi / 2 + math.pi * i / segments
            vertices.append((x_pos,
                             0.25 + radius * math.cos(angle),
                             0.40 + radius * math.sin(angle)))
    faces = [tuple(range(segments + 1)),
             tuple(range(2 * segments + 1, segments, -1))]
    for i in range(segments):
        faces.append((i, i + 1, segments + 2 + i, segments + 1 + i))
    faces.append((0, segments + 1, 2 * segments + 1, segments))
    mesh = bpy.data.meshes.new("hinge_knuckle")
    mesh.from_pydata(vertices, [], faces)
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("hinge_knuckle", mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(kit.mat("brass"))
    bevel = obj.modifiers.new("bevel", "BEVEL")
    bevel.width = 0.003
    bevel.segments = 1
    bevel.limit_method = "ANGLE"
    return obj


def main():
    kit.reset()
    body_parts = []

    # A floor set flush to the bottom and four overlapping boards form a sturdy
    # open carcass. The exterior remains exactly 0.90 x 0.50 m.
    body_parts.append(kit.box("chest_floor", (0.86, 0.46, 0.046),
                              (0, 0, 0.023), "teak", bevel=0.008))
    for y in (-0.222, 0.222):
        body_parts.append(kit.box("long_wall", (0.86, 0.056, 0.354),
                                  (0, y, 0.223), "teak", bevel=0.008))
    for sx in (-1, 1):
        # The framed recess lets the loop sit proud of its backboard without
        # increasing the 0.90 m case width.
        body_parts.append(end_wall_with_pocket(sx))
        body_parts.append(kit.box("handle_pocket_back", (0.02, 0.31, 0.25),
                                  (sx * 0.40, 0, 0.27), "teak", bevel=0.006))

    # Brass corner plates sit 2 mm proud of the inset end-grain face, with their
    # outer faces exactly on the case envelope.
    for sx in (-1, 1):
        for sy in (-1, 1):
            body_parts.append(kit.box("corner_cap_end", (0.022, 0.045, 0.11),
                                      (sx * 0.439, sy * 0.205, 0.335),
                                      "brass", bevel=0.006))

    # End drop handles: each ring meets two iron mounting shoes and hangs clear
    # of the case so it reads as carrying hardware from the gameplay camera.
    for sx in (-1, 1):
        for sy in (-1, 1):
            body_parts.append(kit.box("handle_mount", (0.025, 0.042, 0.045),
                                      (sx * 0.422, sy * 0.052, 0.292),
                                      "iron", bevel=0.006))
        body_parts.append(kit.torus("drop_handle", 0.055, 0.010,
                                    (sx * 0.44, 0, 0.292), "iron",
                                    rot=(0, 90, 0), major_seg=8, minor_seg=6))

    # Two brass strap hinges cross the rear seam. Both halves touch their
    # respective boards, with barrels aligned on the declared lid pivot axis.
    for x in (-0.27, 0.27):
        body_parts.append(kit.box("hinge_leaf_body", (0.09, 0.020, 0.055),
                                  (x, 0.24, 0.37), "brass", bevel=0.004))

    body = kit.join("instrument_chest", body_parts)
    clean_sliver_faces(body)
    kit.set_origin(body, Vector((0, 0, 0)))
    body.location = (0, 0, 0)

    # The 60 mm lid closes directly onto the carcass; the front hasp is visible.
    lid_board = kit.box("lid_board", (0.90, 0.50, 0.06),
                        (0, 0, 0.43), "teak", bevel=0.009)
    # A slight hand-planed crown across the top face; the bearing face stays flat.
    for vertex in lid_board.data.vertices:
        if vertex.co.z > 0 and not (vertex.co.x < 0 and vertex.co.y < 0):
            vertex.co.z -= 0.0008
    lid_parts = [lid_board]
    # The latch's vertical strap crosses the front seam and touches the lid.
    lid_parts.append(kit.box("hasp", (0.065, 0.020, 0.09),
                             (0, -0.24, 0.395), "brass", bevel=0.005))
    for x in (-0.27, 0.27):
        lid_parts.append(hinge_knuckle(x))
        lid_parts.append(kit.box("hinge_leaf_lid", (0.08, 0.020, 0.04),
                                 (x, 0.24, 0.43), "brass", bevel=0.004))

    lid = kit.join("instrument_chest_lid", lid_parts)
    clean_sliver_faces(lid)
    pivot = Vector((0, 0.25, 0.40))
    kit.set_origin(lid, pivot)
    lid.location = pivot
    kit.export("assets/candidates/af01/instrument_chest.glb", [body, lid])


if __name__ == "__main__":
    main()
