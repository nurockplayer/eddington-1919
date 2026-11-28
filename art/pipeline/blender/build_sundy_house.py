"""Roça Sundy reconstruction. Blender front is -Y, origin at grade under the house."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import bmesh
import bpy
from mathutils import Vector
import kit


def slab(name, corners, thickness, material):
    corners = [p for i, p in enumerate(corners) if p != corners[i - 1]]
    mesh = bpy.data.meshes.new(name)
    count = len(corners)
    mesh.from_pydata([tuple(p) for p in corners]
                     + [(p.x, p.y, p.z - thickness) for p in corners], [],
                     [tuple(range(count)), tuple(range(count, 2 * count))]
                     + [(i, (i + 1) % count, (i + 1) % count + count, i + count)
                        for i in range(count)])
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(mesh)
    bm.free()
    return kit._obj(name, mesh, material, 0, 1)


def box(name, size, at, material, rot=(0, 0, 0), bevel=0.018):
    obj = kit.box(name, size, at, material, rot=rot, bevel=0)
    if bevel:
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.bevel(bm, geom=bm.edges[:], offset=bevel, segments=1,
                        affect="EDGES", clamp_overlap=True)
        bm.to_mesh(obj.data)
        bm.free()
    return obj


def tile_pitch(parts, foot_a, foot_b, high_a, high_b, courses):
    """Trim staggered tile courses to the slope's hips."""
    foot_a, foot_b, high_a, high_b = map(Vector, (foot_a, foot_b, high_a, high_b))
    parts.append(slab("roof deck", [foot_a, foot_b, high_b, high_a], 0.17, "roof_tile"))
    for row in range(courses):
        low = row / courses
        high = min(1, (row + 1.12) / courses)
        a, b = foot_a.lerp(high_a, low), foot_b.lerp(high_b, low)
        c, d = foot_a.lerp(high_a, high), foot_b.lerp(high_b, high)
        tiles = math.ceil((b - a).length / 0.90)
        joints = [0] + [(n + 0.5 * (row % 2)) / tiles for n in range(1, tiles)] + [1]
        lift = Vector((0, 0, 0.065))
        for start, end in zip(joints, joints[1:]):
            gap = min(0.007, 0.006 / (b - a).length)
            parts.append(slab("clay tile", [a.lerp(b, start + gap) + lift,
                                           a.lerp(b, end - gap) + lift,
                                           c.lerp(d, end - gap) + lift * 0.4,
                                           c.lerp(d, start + gap) + lift * 0.4],
                              0.075, "roof_tile"))


def roof(parts):
    front_l, front_r = (-7.65, -4.65, 5.05), (7.65, -4.65, 5.05)
    back_l, back_r = (-7.65, 4.65, 5.05), (7.65, 4.65, 5.05)
    ridge_l, ridge_r = (-3.15, 0, 7.48), (3.15, 0, 7.48)
    for pitch in [(front_l, front_r, ridge_l, ridge_r), (back_r, back_l, ridge_r, ridge_l),
                  (front_r, back_r, ridge_r, ridge_r), (back_l, front_l, ridge_l, ridge_l)]:
        tile_pitch(parts, *pitch, courses=7)
    for start, end in [(front_l, ridge_l), (back_l, ridge_l), (front_r, ridge_r),
                       (back_r, ridge_r), (ridge_l, ridge_r)]:
        start, end = Vector(start), Vector(end)
        cap = box("hip and ridge cap", ((end - start).length + 0.12, 0.21, 0.15),
                      (start + end) / 2 + Vector((0, 0, 0.10)), "roof_tile", bevel=0.035)
        cap.rotation_euler = (end - start).to_track_quat("X", "Z").to_euler()
        parts.append(cap)
    tile_pitch(parts, (-7.5, -6.77, 3.95), (7.5, -6.77, 3.95),
               (-7.5, -3.94, 4.76), (7.5, -3.94, 4.76), courses=4)


def opening(parts, x, y, heading, door=False):
    """Timber trim and a pair of solid doors or louvered shutters in a dark reveal."""
    width, height = (1.6, 2.52) if door else (1.35, 1.74)
    base = 0.9 if door else 1.95
    angle = math.radians(heading)

    def detail(name, size, loc, material, bevel=0, tilt=0):
        along, depth, z = loc
        pos = (x + along * math.cos(angle) - depth * math.sin(angle),
               y + along * math.sin(angle) + depth * math.cos(angle), base + z)
        parts.append(box(name, size, pos, material, (tilt, 0, heading), bevel=bevel))

    detail("shadowed reveal", (width, 0.12, height), (0, -0.04, height / 2), "iron")
    for side in (-1, 1):
        detail("jamb", (0.15, 0.19, height + 0.18), (side * width / 2, -0.11, height / 2), "teak")
        leaf = side * (width / 4 - 0.015)
        detail("door leaf" if door else "shutter leaf",
               (width / 2 - 0.09, 0.11, height - 0.17), (leaf, -0.115, height / 2), "teak_dark")
        for edge in (-1, 1):
            detail("leaf stile", (0.075, 0.08, height - 0.16),
                   (leaf + edge * (width / 4 - 0.067), -0.18, height / 2), "teak")
        if door:
            for z in (0.18, 1.08, height - 0.27):
                detail("door cross rail", (width / 2 - 0.13, 0.09, 0.14), (leaf, -0.18, z), "teak")
            detail("door latch", (0.12, 0.12, 0.065), (side * 0.10, -0.225, 1.12), "iron")
        else:
            for n in range(7):
                detail("louvre", (width / 2 - 0.18, 0.10, 0.18),
                       (leaf, -0.18, 0.26 + n * 0.20), "teak", bevel=0, tilt=-24)
    detail("lintel", (width + 0.33, 0.23, 0.16), (0, -0.11, height + 0.09), "whitewash")
    if not door:
        detail("projecting sill", (width + 0.38, 0.31, 0.14), (0, -0.13, -0.025), "whitewash")


def build():
    kit.reset()
    parts = []

    def put(name, size, xyz, material, bevel=0.018, rot=(0, 0, 0)):
        parts.append(box(name, size, xyz, material, rot=rot, bevel=bevel))

    put("masonry house", (14, 8, 4.44), (0, 0, 3.08), "whitewash", 0.03)
    put("plinth", (14.4, 10.4, 0.79), (0, -1.2, 0.395), "stone", 0.03)
    put("plinth foot", (14.48, 10.48, 0.16), (0, -1.2, 0.08), "stone")
    put("verandah deck and plinth cap", (14.48, 10.48, 0.13), (0, -1.2, 0.835), "whitewash")
    put("eave cornice", (14.28, 8.26, 0.17), (0, 0, 4.91), "whitewash")
    for side in (-1, 1):
        for y in (-3.92, 3.92):
            put("corner pier", (0.37, 0.33, 4.02), (side * 6.88, y, 2.90), "whitewash")
        for y in (-1.95, 1.85):
            opening(parts, side * 7, y, side * 90)
    for x in (-5.4, -2.72, 2.72, 5.4):
        opening(parts, x, -4, 0)
    opening(parts, 0, -4, 0, door=True)
    for x in (-4.5, 4.5):
        opening(parts, x, 4, 180)
    opening(parts, 0, 4, 180)

    # Timber gallery: a wide central stair opening, with braced posts and short returns.
    put("gallery fascia", (15.02, 0.18, 0.23), (0, -6.61, 3.81), "teak_dark")
    put("gallery beam", (14.56, 0.22, 0.25), (0, -6.23, 3.73), "teak")
    posts = (-7.05, -4.25, -1.45, 1.45, 4.25, 7.05)
    for x in posts:
        put("post foot", (0.34, 0.34, 0.15), (x, -6.23, 0.975), "stone")
        put("gallery post", (0.22, 0.22, 2.67), (x, -6.23, 2.385), "teak")
        put("post capital", (0.31, 0.29, 0.13), (x, -6.23, 3.57), "teak_dark")
        for side in (-1, 1) if abs(x) < 7 else (-math.copysign(1, x),):
            put("knee brace", (0.13, 0.13, 0.76), (x + side * 0.27, -6.23, 3.40),
                "teak", rot=(0, side * 48, 0))
    for left, right in zip(posts, posts[1:]):
        if left < 0 < right:
            continue
        for z in (1.08, 1.86):
            put("gallery rail", (right - left, 0.13, 0.12), ((left + right) / 2, -6.23, z), "teak_dark")
        for n in range(1, 8):
            put("square baluster", (0.085, 0.085, 0.75), (left + (right - left) * n / 8, -6.23, 1.47), "teak", 0)
    for x in (posts[0], posts[-1]):
        for z in (1.08, 1.86):
            put("return rail", (0.13, 2.27, 0.12), (x, -5.095, z), "teak_dark")
        for n in range(1, 7):
            put("return baluster", (0.085, 0.085, 0.75), (x, -6.23 + 2.27 * n / 7, 1.47), "teak", 0)

    for n in range(5):
        height = 0.18 * (n + 1)
        depth = 1.64 - 0.328 * n
        put("stone stair riser", (2.74 - n * 0.045, depth, height),
            (0, -6.40 - depth / 2, height / 2), "stone")
        put("stone nosing", (2.80 - n * 0.045, 0.108, 0.08),
            (0, -6.40 - depth + 0.035, height - 0.04), "whitewash")
    roof(parts)
    house = kit.join("sundy_house", parts)
    bpy.context.view_layer.update()
    kit.set_origin(house, Vector((0, 0, 0)))
    kit.export("assets/models/sundy_house.glb", [house])
    print(f"House geometry: {kit.triangles([house])} triangles, {len(house.data.materials)} material surfaces")


def stills(directory):
    directory.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x, scene.render.resolution_y = 1280, 720
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.display.render_aa = "16"
    shade = scene.display.shading
    shade.light = "STUDIO"
    shade.color_type = "MATERIAL"
    shade.background_type = "WORLD"
    shade.show_cavity = True
    shade.cavity_type = "WORLD"
    shade.curvature_ridge_factor = 1.1
    shade.show_shadows = True
    scene.world = bpy.data.worlds.new("Plate background")
    scene.world.color = (0.13, 0.13, 0.13)
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    scene.collection.objects.link(camera)
    scene.camera = camera
    camera.data.type = "ORTHO"
    for name, eye, target, width in [
        ("front", (0, -29, 9), (0, -1.4, 3.63), 17.8),
        ("three-quarter", (21, -27, 14), (0, -1.4, 3.55), 20.0),
        ("verandah-close", (5.8, -12.2, 3.0), (0.8, -5.3, 2.20), 8.5),
    ]:
        camera.location = eye
        camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()
        camera.data.ortho_scale = width
        scene.render.filepath = str(directory / f"blender-{name}.png")
        bpy.ops.render.render(write_still=True)


if __name__ == "__main__":
    arguments = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if arguments:
        kit.reset()
        bpy.ops.import_scene.gltf(filepath=str(kit.ROOT / "assets/models/sundy_house.glb"))
        stills(Path(arguments[0]))
    else:
        build()
