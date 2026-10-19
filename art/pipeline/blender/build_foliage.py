"""Build the flat-colour cocoa and banana foliage kits in headless Blender.

Run: blender -b --factory-startup -P art/pipeline/blender/build_foliage.py
"""
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import kit
import bpy
from mathutils import Vector


def finish(asset_id, parts):
    """Bake the assembly around its bottom-centre, with an identity transform."""
    obj = kit.join(asset_id, parts)
    kit.set_origin(obj, kit.bottom_centre([obj]))
    obj.location = (0, 0, 0)
    bpy.context.view_layer.update()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for face in obj.data.polygons:
        face.use_smooth = False
    kit.export(f"assets/models/{asset_id}.glb", [obj])


def build_cocoa():
    rng = random.Random(1919)
    parts = [kit.cyl("shrub_cocoa_trunk", 0.12, 0.70, (0, 0, 0.35),
                     "teak_dark", verts=6, radius_top=0.065, bevel=0)]
    # Four overlapping low lobes and a lighter crown, rather than one ball.
    lobes = [(-0.35, -0.35, 0.73), (0.35, -0.35, 0.73),
             (0.35, 0.35, 0.73), (-0.35, 0.35, 0.73),
             (0.04, 0.02, 1.12)]
    for i, centre in enumerate(lobes):
        location = tuple(c + rng.uniform(-0.025, 0.025) for c in centre)
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1,
                                             location=location)
        obj = bpy.context.object
        obj.name = f"shrub_cocoa_leaves_{i:02d}"
        obj.rotation_euler.z = rng.uniform(-0.35, 0.35)
        # Set real dimensions after yaw so the broad, flattened lobes stay low.
        obj.dimensions = (rng.uniform(1.26, 1.36), rng.uniform(1.26, 1.36),
                          0.96 if i < 4 else 0.94)
        obj.data.materials.append(kit.mat("foliage_light" if i == 4
                                          else "foliage_deep"))
        parts.append(obj)
    finish("shrub_cocoa", parts)


def paddle_leaf(index, root, yaw, material):
    """Five quad-strip segments, folded across a raised midrib.

    Narrow but nonzero end rows avoid collapsed quads. The palette material
    is double-sided, so the open folded sheet also reads from underneath.
    The centreline rises, arches, then drops toward the pointed paddle tip.
    """
    forward = Vector((math.cos(yaw), math.sin(yaw), 0))
    sideways = Vector((-math.sin(yaw), math.cos(yaw), 0))
    # (outward reach, rise, full width); centreline length is about 1.6 m.
    # r04 G3: v1 leaves rose almost as much as they reached and read as upright
    # spikes; banana leaves arch outward and droop, so reach > rise, wider blade.
    rows = [(0, 0, 0.04), (0.20, 0.32, 0.34),
            (0.48, 0.55, 0.48), (0.78, 0.58, 0.48),
            (1.04, 0.42, 0.36), (1.22, 0.16, 0.03)]
    vertices, faces = [], []
    for reach, rise, width in rows:
        midrib = Vector(root) + forward * reach + Vector((0, 0, rise))
        fold = min(0.045, width * 0.18)
        for side in (-1, 0, 1):
            point = midrib + sideways * (side * width / 2)
            point.z -= abs(side) * fold
            vertices.append(tuple(point))
    for row in range(len(rows) - 1):
        for side in range(2):
            a = row * 3 + side
            faces.append((a, a + 3, a + 4, a + 1))
    name = f"banana_clump_leaf_{index:02d}"
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    palette_material = kit.mat(material)
    palette_material.use_backface_culling = False
    obj.data.materials.append(palette_material)
    return obj


def build_banana():
    rng = random.Random(1920)
    parts, tops = [], []
    # Mirrored tall stems and a shorter central shoot keep the footprint centred.
    for i, (base, top) in enumerate([
        ((0.07, 0, 0), (0.16, 0, 1.90)),
        ((-0.07, 0, 0), (-0.16, 0, 1.90)),
        ((0, 0.04, 0), (0, 0.12, 1.45)),
    ]):
        base, top = Vector(base), Vector(top)
        axis = top - base
        stem = kit.cyl(f"banana_clump_stem_{i:02d}", 0.075, axis.length,
                       (base + top) / 2, "foliage_light", verts=6,
                       radius_top=0.045, bevel=0)
        stem.rotation_euler = axis.to_track_quat("Z", "Y").to_euler()
        parts.append(stem)
        tops.append(top)
    # Opposite pairs balance X/Y bounds; the lower pair fills the diagonal gap.
    diagonal = math.radians(45 + rng.uniform(-4, 4))
    leaves = [(0, 0), (1, math.pi), (0, math.pi / 2),
              (1, 3 * math.pi / 2), (2, diagonal), (2, diagonal + math.pi),
              (0, diagonal - math.pi / 2), (1, diagonal + math.pi / 2)]
    for i, (stem_index, yaw) in enumerate(leaves):
        parts.append(paddle_leaf(i, tops[stem_index], yaw,
                                 "foliage_deep" if i % 2 == 0
                                 else "foliage_light"))
    finish("banana_clump", parts)


def main():
    kit.reset()
    kit._mats.clear()
    build_cocoa()
    # Factory reset invalidates Blender material references held by the kit.
    kit.reset()
    kit._mats.clear()
    build_banana()


if __name__ == "__main__":
    main()
