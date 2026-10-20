"""Validate an exported GLB against its spec in art/assets.toml (Blender, headless).

    blender -b --factory-startup -P art/pipeline/blender/validate.py -- assets/models/coelostat.glb coelostat

Checks (gate G2 in art/PIPELINE.md): triangle budget, material count, texture size,
real-world dimensions within tolerance, bounds at bottom-centre, per-object
origins (static parts at 0,0,0; moving parts on their declared `pivots`),
unit scale, no loose or zero-area geometry, names follow the convention.
Writes <glb>.report.json next to art/validation/ and exits 1 on any failure.
"""
import json
import sys
import tomllib
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]


def main() -> int:
    argv = sys.argv[sys.argv.index("--") + 1 :]
    glb, asset_id = Path(argv[0]).resolve(), argv[1]
    spec = tomllib.loads((ROOT / "art/assets.toml").read_text())["asset"][asset_id]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(glb))
    # The glTF importer creates display meshes for bones (e.g. "Icosphere"); they
    # are not in the file, so they are not part of the asset.
    bone_shapes = {pb.custom_shape for a in bpy.context.scene.objects if a.type == "ARMATURE"
                   for pb in a.pose.bones if pb.custom_shape}
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o not in bone_shapes]
    deps = bpy.context.evaluated_depsgraph_get()

    tris, mats, tex_max, degenerate, loose = 0, set(), 0, 0, 0
    lo, hi = Vector((1e9,) * 3), Vector((-1e9,) * 3)
    for o in meshes:
        ev = o.evaluated_get(deps)
        me = ev.to_mesh()
        bm = bmesh.new()
        bm.from_mesh(me)
        bmesh.ops.triangulate(bm, faces=bm.faces[:])
        tris += len(bm.faces)
        degenerate += sum(1 for f in bm.faces if f.calc_area() < 1e-8)
        loose += sum(1 for v in bm.verts if not v.link_faces)
        for v in bm.verts:
            w = o.matrix_world @ v.co
            lo = Vector(map(min, lo, w))
            hi = Vector(map(max, hi, w))
        bm.free()
        ev.to_mesh_clear()
        for slot in o.material_slots:
            if slot.material:
                mats.add(slot.material.name)
    for img in bpy.data.images:
        if img.size[0]:
            tex_max = max(tex_max, *img.size)

    # Blender is Z-up; glTF import converts Godot/glTF Y-up back to Z-up.
    dims = hi - lo  # x width, y depth, z height
    target = spec["dims_m"]  # [width, depth, height] in metres
    tol = spec.get("dims_tolerance", 0.15)
    dim_ok = all(abs(d - t) <= t * tol for d, t in zip(dims, target))
    centre = (lo + hi) / 2
    # Assets with a deliberate overhang (e.g. the coelostat's drive box) keep the
    # origin on their footprint and declare where the bounds centre should be.
    exp_x, exp_y = spec.get("bounds_centre_offset_m", [0.0, 0.0])
    origin_ok = (abs(lo.z) < 0.01 and abs(centre.x - exp_x) < 0.05 * max(dims.x, 0.2)
                 and abs(centre.y - exp_y) < 0.05 * max(dims.y, 0.2))
    names_ok = all(o.name.startswith(asset_id) for o in meshes)
    # Per-object origins: static parts sit on the asset origin; moving parts on their pivot.
    pivots = spec.get("pivots", {})
    origins, origins_ok = {}, True
    for o in meshes:
        loc = o.matrix_world.translation
        want = Vector(pivots.get(o.name, (0.0, 0.0, 0.0)))
        sc = o.matrix_world.to_scale()
        ok = (loc - want).length < 0.01 and all(abs(c - 1.0) < 1e-3 for c in sc)
        origins[o.name] = {"origin": [round(c, 3) for c in loc], "expected": list(want), "scale": [round(c, 3) for c in sc], "ok": ok}
        origins_ok &= ok

    checks = {
        "triangles": {"value": tris, "max": spec["tri_budget"], "ok": tris <= spec["tri_budget"]},
        "materials": {"value": sorted(mats), "max": spec["max_materials"], "ok": len(mats) <= spec["max_materials"]},
        "texture_px": {"value": tex_max, "max": spec["max_texture_px"], "ok": tex_max <= spec["max_texture_px"]},
        "dimensions_m": {"value": [round(d, 3) for d in dims], "target": target, "tolerance": tol, "ok": dim_ok},
        "origin_bottom_centre": {"value": [round(c, 3) for c in (centre.x, centre.y, lo.z)], "ok": origin_ok},
        "object_origins": {"value": origins, "ok": origins_ok},
        "degenerate_faces": {"value": degenerate, "ok": degenerate == 0},
        "loose_vertices": {"value": loose, "ok": loose == 0},
        "names_prefixed": {"value": [o.name for o in meshes], "ok": names_ok},
    }
    for name in spec.get("skip_checks", []):  # declared, justified exemptions only
        if name in checks:
            checks[name]["ok"] = True
            checks[name]["skipped"] = True
    passed = all(c["ok"] for c in checks.values())
    report = {"asset": asset_id, "file": str(glb.relative_to(ROOT)) if glb.is_relative_to(ROOT) else str(glb), "pass": passed, "checks": checks}
    out = ROOT / "art/validation" / f"{asset_id}.g2.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2, ensure_ascii=False))
    for k, c in checks.items():
        print(("PASS " if c["ok"] else "FAIL ") + k + ": " + json.dumps(c["value"]))
    print("G2", "PASS" if passed else "FAIL", out)
    return 0 if passed else 1


if __name__ == "__main__":
    code = main()
    sys.stdout.flush()
    import os

    os._exit(code)
