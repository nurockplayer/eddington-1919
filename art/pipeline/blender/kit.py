"""Shared Blender helpers for procedural asset builds (pipeline stage S3b).

Every build script does: kit.reset() → build primitives with palette materials →
kit.finish(asset_id, parts) → kit.export(path). Rules enforced here rather than
by hand (art/BIBLE.md §6):
  * metres, Z-up in Blender (exported Y-up for Godot), front of the asset faces -Y
    in Blender, which becomes +Z in Godot
  * origin at bottom-centre of the static part; moving parts get their own object
    with the origin on the pivot
  * soft bevels on every hard edge (the "hand-built diorama" read, BIBLE §3)
  * materials come only from art/palette.toml, so assets share one colour language
"""
import math
import tomllib
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[3]
PALETTE = tomllib.loads((ROOT / "art/palette.toml").read_text())["swatch"]


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.unit_settings.system = "METRIC"


_mats: dict = {}


def mat(key: str) -> bpy.types.Material:
    """Palette material: flat base colour + roughness/metallic, no textures."""
    if key in _mats:
        return _mats[key]
    sw = PALETTE[key]
    hexs = sw["hex"].lstrip("#")
    rgb = [srgb_to_linear(int(hexs[i : i + 2], 16) / 255) for i in (0, 2, 4)]
    m = bpy.data.materials.new(f"E1919_{key}")
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = sw.get("roughness", 0.8)
    bsdf.inputs["Metallic"].default_value = sw.get("metallic", 0.0)
    m.diffuse_color = (*rgb, 1.0)
    _mats[key] = m
    return m


def _obj(name: str, mesh: bpy.types.Mesh, material: str, bevel: float, segments: int) -> bpy.types.Object:
    o = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(o)
    o.data.materials.append(mat(material))
    if bevel > 0:
        b = o.modifiers.new("bevel", "BEVEL")
        b.width = bevel
        b.segments = segments
        b.limit_method = "ANGLE"
        b.harden_normals = False
    return o


def box(name, size, loc, material, rot=(0, 0, 0), bevel=0.012, segments=1):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bm.to_mesh(me)
    bm.free()
    o = _obj(name, me, material, bevel, segments)
    o.location = loc
    o.rotation_euler = [math.radians(r) for r in rot]
    return o


def cyl(name, radius, depth, loc, material, rot=(0, 0, 0), verts=16, radius_top=None, bevel=0.008, segments=1):
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=verts, radius1=radius,
                          radius2=radius if radius_top is None else radius_top, depth=depth)
    bm.to_mesh(me)
    bm.free()
    o = _obj(name, me, material, bevel, segments)
    o.location = loc
    o.rotation_euler = [math.radians(r) for r in rot]
    return o


def torus(name, major, minor, loc, material, rot=(0, 0, 0), major_seg=24, minor_seg=6):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=major_seg,
                                     minor_segments=minor_seg, location=loc,
                                     rotation=[math.radians(r) for r in rot])
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat(material))
    return o


def join(name: str, objs: list) -> bpy.types.Object:
    """Apply modifiers and merge parts into one object named `name`."""
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    for o in objs:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    o.data.name = name
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return o


def set_origin(o: bpy.types.Object, point: Vector) -> None:
    """Move the object's origin to a world-space point without moving the mesh."""
    offset = point - o.matrix_world.translation
    o.data.transform(Matrix.Translation(-offset))
    o.location = o.location + offset


def bottom_centre(objs: list) -> Vector:
    pts = [o.matrix_world @ v.co for o in objs for v in o.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))


def triangles(objs: list) -> int:
    n = 0
    for o in objs:
        for p in o.data.polygons:
            n += len(p.vertices) - 2
    return n


def export(path: str, objs: list) -> None:
    out = ROOT / path
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True, export_materials="EXPORT")
    print(f"exported {out} ({triangles(objs)} tris)")
