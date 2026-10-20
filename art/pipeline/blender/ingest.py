"""Clean a generated source mesh to its spec and export a candidate GLB (stage S3a ingest).

    blender -b --factory-startup -P art/pipeline/blender/ingest.py -- \
        art/sources/meshy/<asset>/<task>.glb <asset> --registry art/factory/af01/batch.toml \
        --export assets/candidates/af01/<asset>.glb

What it does, in order (art/BIBLE.md §6):
  * drops cameras, lights, empties and armatures; joins all meshes into ONE object
    named <asset> (G2 name prefix)
  * uniform scale so the bounds best fit dims_m (least log error over the three
    axes; proportions are never distorted), origin at bottom-centre
  * removes degenerate faces and loose vertices
  * decimates to 90 % of tri_budget when over it
  * renames materials E1919_tex_<asset>[_n] and downsizes textures to
    max_texture_px; leaves the albedo itself alone (palette/value check is G3)
Writes a JSON receipt next to the export (<asset>.ingest.json in the batch's g2 dir).
"""
import hashlib
import json
import math
import sys
import tomllib
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[3]


def bounds(o):
    pts = [o.matrix_world @ v.co for v in o.data.vertices]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    return lo, hi


def clean(o, scale: float = 1.0) -> int:
    """Merge coincident verts; drop zero-area faces and loose geometry. Thresholds are G2's
    absolute ones at scale 1 (metres, after fitting); before fitting, pass the mesh's own
    size so a tiny-unit source is not wiped out."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5 * scale)
    bmesh.ops.dissolve_degenerate(bm, dist=1e-6 * scale, edges=bm.edges)
    bad = [f for f in bm.faces if f.calc_area() < 1e-8 * scale * scale]
    bmesh.ops.delete(bm, geom=bad, context="FACES_ONLY")
    bmesh.ops.delete(bm, geom=[e for e in bm.edges if not e.link_faces], context="EDGES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(o.data)
    bm.free()
    return len(bad)


def seat(o) -> None:
    """Origin at bottom-centre of the current bounds."""
    lo, hi = bounds(o)
    o.data.transform(Matrix.Translation(-Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))))
    o.data.update()


def tris(o) -> int:
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1 :]
    raw, asset = Path(argv[0]).resolve(), argv[1]
    opts = dict(zip(argv[2::2], argv[3::2]))
    registry = ROOT / opts.get("--registry", "art/assets.toml")
    spec = tomllib.loads(registry.read_text())["asset"][asset]
    export = (ROOT / opts["--export"]).resolve()
    if not export.is_relative_to((ROOT / "assets/candidates").resolve()):
        raise SystemExit(f"refusing to export outside assets/candidates/: {export}")
    receipt_dir = ROOT / opts.get("--out", str(registry.parent.relative_to(ROOT) / "g2"))

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(raw))
    scene = bpy.context.scene
    meshes = [o for o in scene.objects if o.type == "MESH"]
    for o in meshes:  # bake parent transforms before deleting the hierarchy
        mw = o.matrix_world.copy()
        o.parent = None
        o.matrix_world = mw
    for o in [o for o in scene.objects if o.type != "MESH"]:
        bpy.data.objects.remove(o, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    o.name = o.data.name = asset
    raw_tris = tris(o)
    lo, hi = bounds(o)
    # Before fitting: stray verts/slivers must not drive scale, turn or centre. Relative
    # tolerance: the source's units are unknown (1e-4 m cubes and 200 m rocks both occur).
    removed = clean(o, scale=max((hi - lo).length, 1e-9))
    lo, hi = bounds(o)
    raw_size = hi - lo

    # Generators do not know which way is "front": if the footprint matches the
    # spec better turned 90° (X and Y swapped), turn it. Then scale with ONE
    # uniform factor (least squared log error over the axes) and put the origin
    # at bottom-centre.
    target = spec["dims_m"]

    def misfit(sz):
        logs = [math.log(t / s) for t, s in zip(target, sz) if s > 1e-6]
        mean = sum(logs) / len(logs)
        return sum((l - mean) ** 2 for l in logs), math.exp(mean)

    size = raw_size.copy()
    turned = misfit((size.y, size.x, size.z))[0] < misfit(size)[0] - 1e-3
    if turned:
        o.data.transform(Matrix.Rotation(math.radians(90), 4, "Z"))
        lo, hi = bounds(o)
        size = hi - lo
    _, k = misfit(size)
    o.data.transform(Matrix.Scale(k, 4))
    removed += clean(o)  # again at final scale: G2's zero-area threshold is absolute
    seat(o)

    budget = spec["tri_budget"]
    if tris(o) > budget:
        d = o.modifiers.new("decimate", "DECIMATE")
        d.ratio = 0.9 * budget / tris(o)
        d.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier=d.name)
        removed += clean(o)
        seat(o)  # decimation can move the bounds

    for i, slot in enumerate(o.material_slots):
        if slot.material:
            slot.material.name = f"E1919_tex_{asset}" + (f"_{i}" if i else "")
    cap = spec.get("max_texture_px", 0)
    resized = []
    for img in bpy.data.images:
        if img.size[0] and cap and max(img.size) > cap:
            f = cap / max(img.size)
            resized.append([img.name, list(img.size)])
            img.scale(max(1, round(img.size[0] * f)), max(1, round(img.size[1] * f)))
            img.pack()

    export.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(export), export_format="GLB", use_selection=True,
                              export_apply=True, export_yup=True, export_materials="EXPORT",
                              export_image_format="JPEG", export_jpeg_quality=88)
    lo, hi = bounds(o)
    receipt = {"asset": asset, "raw": str(raw.relative_to(ROOT)) if raw.is_relative_to(ROOT) else str(raw),
               "export": str(export.relative_to(ROOT)) if export.is_relative_to(ROOT) else str(export), "scale_factor": round(k, 4), "turned_90": turned, "degenerate_removed": removed,
               "raw_dims_m": [float(f"{c:.4g}") for c in raw_size], "dims_m": [round(c, 3) for c in hi - lo],
               "raw_triangles": raw_tris, "triangles": tris(o), "materials": [s.material.name for s in o.material_slots if s.material],
               "textures_resized": resized, "glb_sha256": hashlib.sha256(export.read_bytes()).hexdigest()}
    receipt_dir.mkdir(parents=True, exist_ok=True)
    (receipt_dir / f"{asset}.ingest.json").write_text(json.dumps(receipt, indent=2))
    print("INGEST", json.dumps(receipt))
    return 0


if __name__ == "__main__":
    code = main()
    sys.stdout.flush()
    import os

    os._exit(code)
