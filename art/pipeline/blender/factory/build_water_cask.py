"""Build a coopered pine expedition water cask with four fitted iron hoops."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.dont_write_bytecode = True
import bmesh
import bpy
import kit


SIDES = 16
PROFILE = ((0.000, 0.238), (0.200, 0.264), (0.400, 0.280),
           (0.600, 0.264), (0.800, 0.238))
# A few millimetres of stave-to-stave variation break the lathed look. The four
# cardinal vertices stay exact so the overall 0.56 m footprint remains exact.
STAVE_DELTA = (0.0, -0.0010, 0.0008, -0.0014, 0.0, 0.0011, -0.0007,
               0.0015, 0.0, -0.0012, 0.0006, 0.0013, 0.0, -0.0008,
               0.0010, -0.0011)


def profile_radius(z):
    for (za, ra), (zb, rb) in zip(PROFILE, PROFILE[1:]):
        if za <= z <= zb:
            t = (z - za) / (zb - za)
            return ra + (rb - ra) * t
    return PROFILE[0][1] if z < PROFILE[0][0] else PROFILE[-1][1]


def make_mesh(name, vertices, faces, material, bevel):
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
    if bevel:
        mod = obj.modifiers.new("soft coopered edge", "BEVEL")
        mod.width = bevel
        mod.segments = 1
        mod.limit_method = "ANGLE"
    return obj


def staved_body():
    # Five cross-section rings create four long stave courses; the bottom is
    # closed, while the recessed head closes the visible top.
    vertices = []
    for ring, (z, base_radius) in enumerate(PROFILE):
        phase = 0.0015 if ring in (1, 3) else 0.0
        for i in range(SIDES):
            angle = 2 * math.pi * i / SIDES + phase
            variation = STAVE_DELTA[i] * (0.55 if ring in (0, 4) else 1.0)
            radius = base_radius + variation
            vertices.append((radius * math.cos(angle), radius * math.sin(angle), z))
    faces = []
    for ring in range(len(PROFILE) - 1):
        for i in range(SIDES):
            j = (i + 1) % SIDES
            faces.append((ring * SIDES + i, ring * SIDES + j,
                          (ring + 1) * SIDES + j, (ring + 1) * SIDES + i))
    faces.append(tuple(reversed(range(SIDES))))
    return make_mesh("water_cask_staves", vertices, faces, "pine", 0.002)


def hoop(z_center):
    """A fitted 16-sided iron band that stands 6 mm proud of the staves."""
    half_width = 0.020
    z_low, z_high = z_center - half_width, z_center + half_width
    vertices = []
    # Lower and upper edges sit just inside the wood. The broad center course
    # rises 6 mm proud, so the two sloped chamfers stay in contact throughout.
    for z, relief in ((z_low, -0.002), (z_center, 0.006),
                      (z_high, -0.002)):
        base = profile_radius(z)
        for i in range(SIDES):
            angle = 2 * math.pi * i / SIDES
            local_delta = STAVE_DELTA[i]
            radius = base + local_delta + relief
            vertices.append((radius * math.cos(angle), radius * math.sin(angle), z))
    faces = []
    for i in range(SIDES):
        j = (i + 1) % SIDES
        for row in range(2):
            a, b = row * SIDES + i, row * SIDES + j
            c, d = (row + 1) * SIDES + j, (row + 1) * SIDES + i
            faces.append((a, b, c, d))
    return make_mesh("water_cask_iron_hoop", vertices, faces, "iron", 0.0)


def main():
    kit.reset()
    parts = [staved_body()]
    for z in (0.12, 0.25, 0.55, 0.70):
        parts.append(hoop(z))

    # The head sits 25 mm below the stave rim; the bung rests directly on it.
    # Overlap the inside of the stave rim slightly so the recessed head seats
    # into the open barrel wall with no visible annular gap.
    head_radius = 0.243
    head_vertices = [(head_radius * math.cos(2 * math.pi * i / SIDES),
                      head_radius * math.sin(2 * math.pi * i / SIDES), 0.776)
                     for i in range(SIDES)]
    parts.append(make_mesh("water_cask_head", head_vertices,
                           [tuple(range(SIDES))], "teak_dark", 0.0))
    bung = kit.cyl("water_cask_bung", 0.023, 0.024, (0.034, -0.018, 0.788),
                   "teak_dark", verts=8, bevel=0.003)
    # Keep the small end bevel, while leaving the eight longitudinal stock
    # edges simple; this avoids bevel-generated triangles on hidden seams.
    bung.modifiers[0].angle_limit = math.radians(50)
    parts.append(bung)

    cask = kit.join("water_cask", parts)
    bpy.context.view_layer.update()
    kit.set_origin(cask, kit.bottom_centre([cask]))
    cask.location = (0, 0, 0)
    kit.export("assets/candidates/af01/water_cask.glb", [cask])


if __name__ == "__main__":
    main()
