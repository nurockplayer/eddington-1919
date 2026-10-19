"""Build a period character GLB from art/people/people.toml (stage S3c, MPFB route).

    eval "$(art/pipeline/setup_mpfb.sh --env)"
    blender -b --python art/pipeline/blender/build_person.py -- eddington

Pipeline, deterministic for a given spec:
  MPFB 2 human (macro sliders, low-poly body proxy, game_engine rig)
  + CC0 system assets only (hair, eyebrows, eyes, suit, shoes; licences in art/people/LICENSES.md)
  → palette materials (art/palette.toml) instead of MPFB textures: no photo skin,
    no uncanny detail; faces read as sculpted forms under the game's light
  → natural standing pose (arms down) + a baked 4 s breathing idle ("idle")
  → procedural period hat (kit.py) parented to the head bone
  → decimate clothes/hair to the spec budget, drop the hidden base mesh
  → assets/models/<id>.glb (validated by validate.py, gate G2)
"""
import math
import re
import sys
import tomllib
from pathlib import Path

import addon_utils
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402

addon_utils.enable("bl_ext.user_default.mpfb", default_set=True)
from bl_ext.user_default.mpfb.services.humanservice import HumanService  # noqa: E402
from bl_ext.user_default.mpfb.services.locationservice import LocationService  # noqa: E402
from bl_ext.user_default.mpfb.services.targetservice import TargetService  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
FPS = 30


def age_value(years: float) -> float:
    """MPFB age slider: 0.5 = 25 years, 1.0 = 90 years (linear between)."""
    return 0.5 + (years - 25.0) / (90.0 - 25.0) * 0.5 if years >= 25 else years / 25.0 * 0.5


def aim(pb: bpy.types.PoseBone, rig: bpy.types.Object, world_dir: Vector) -> None:
    """Rotate a pose bone so its head→tail points along world_dir, measured from
    its CURRENT posed frame (parents already posed). r06 review: using the rest
    matrix compounded the upper-arm rotation into a ~33° forearm error."""
    pb.rotation_mode = "QUATERNION"
    pb.rotation_quaternion = (1, 0, 0, 0)
    bpy.context.view_layer.update()
    m = (rig.matrix_world @ pb.matrix).to_3x3().normalized()  # posed frame, own rotation = identity
    cur = m @ Vector((0, 1, 0))
    q_world = cur.rotation_difference(world_dir.normalized())
    pb.rotation_quaternion = (m.inverted() @ q_world.to_matrix() @ m).to_quaternion()
    bpy.context.view_layer.update()


CC0_DECL = re.compile(r"^#\s*This asset was explicitly released as CC0\b", re.M)


def assert_cc0(path: Path) -> None:
    """Licence gate: the file header must affirmatively declare a CC0 release (a
    mere mention of "CC0" is not enough), and so must the geometry it references."""
    head = "".join(path.read_text(errors="replace").splitlines(True)[:15])
    if not CC0_DECL.search(head):
        raise SystemExit(f"licence gate: {path} has no CC0 release declaration in its header")
    for line in path.read_text(errors="replace").splitlines():
        if line.startswith("obj_file "):
            obj = path.parent / line.split(None, 1)[1].strip()
            if not obj.exists() or not CC0_DECL.search("".join(obj.read_text(errors="replace").splitlines(True)[:15])):
                raise SystemExit(f"licence gate: referenced geometry {obj} lacks a CC0 release declaration")


def hat(spec: dict, top: Vector, name: str) -> list:
    """Procedural period hats; sizes in metres, palette materials."""
    kind, parts = spec["kind"], []
    if kind == "sun_helmet":  # cork/pith sun helmet, RECONSTRUCTION
        crown = kit.cyl(f"{name}_crown", 0.115, 0.13, (0, 0, 0.06), spec.get("material", "canvas"), verts=20, radius_top=0.085, bevel=0.01, segments=2)
        brim = kit.cyl(f"{name}_brim", 0.19, 0.012, (0, -0.01, 0.0), spec.get("material", "canvas"), verts=24, bevel=0.004)
        brim.scale = (1.0, 1.12, 1.0)
        band = kit.cyl(f"{name}_band", 0.118, 0.025, (0, 0, 0.012), "teak_dark", verts=20, bevel=0)
        parts = [crown, brim, band]
    elif kind == "straw_hat":  # boater-like straw hat, RECONSTRUCTION
        crown = kit.cyl(f"{name}_crown", 0.105, 0.085, (0, 0, 0.045), spec.get("material", "straw"), verts=20, bevel=0.006)
        brim = kit.cyl(f"{name}_brim", 0.175, 0.01, (0, 0, 0.004), spec.get("material", "straw"), verts=24, bevel=0.003)
        band = kit.cyl(f"{name}_band", 0.107, 0.022, (0, 0, 0.02), "teak_dark", verts=20, bevel=0)
        parts = [crown, brim, band]
    elif kind == "felt_hat":  # soft felt brimmed hat (Thrapston photo c.1910), RECONSTRUCTION for 1919
        crown = kit.cyl(f"{name}_crown", 0.1, 0.11, (0, 0, 0.055), spec.get("material", "felt"), verts=20, radius_top=0.088, bevel=0.012, segments=2)
        crown.scale = (1.0, 1.15, 1.0)
        brim = kit.cyl(f"{name}_brim", 0.165, 0.01, (0, 0, 0.004), spec.get("material", "felt"), verts=24, bevel=0.004)
        brim.scale = (1.0, 1.12, 1.0)
        band = kit.cyl(f"{name}_band", 0.102, 0.02, (0, 0, 0.018), "teak_dark", verts=20, bevel=0)
        band.scale = (1.0, 1.15, 1.0)
        parts = [crown, brim, band]
    for p in parts:
        p.location = Vector(p.location) + top + Vector(spec.get("offset", (0, 0, 0)))
    return parts


def face_anchor(eyes: bpy.types.Object) -> tuple:
    """Centre between the eyes and the face front (-Y), from the eye mesh."""
    pts = [eyes.matrix_world @ v.co for v in eyes.data.vertices]
    c = sum(pts, Vector()) / len(pts)
    front = min(p.y for p in pts)
    return c, front


def glasses(c: Vector, front: float, name: str) -> list:
    """Thin rimless-style spectacles (c.1915 portrait): two fine rims + bridge."""
    parts = []
    for sx in (-1, 1):
        r = kit.torus(f"{name}_rim", 0.017, 0.0012, (c.x + sx * 0.032, front - 0.008, c.z), "iron", rot=(90, 0, 0), major_seg=16, minor_seg=4)
        parts.append(r)
    parts.append(kit.cyl(f"{name}_bridge", 0.0012, 0.03, (c.x, front - 0.01, c.z + 0.004), "iron", rot=(0, 90, 0), verts=4, bevel=0))
    return parts


def moustache(c: Vector, front: float, name: str, material: str) -> list:
    """Full Edwardian moustache (Thrapston photo c.1910): wide across the upper lip
    with slightly drooping ends. Deliberately NOT a narrow block (r06 try3 read as a
    "toothbrush" moustache, an unwanted association)."""
    y = front - 0.004
    z = c.z - 0.054
    mid = kit.cyl(f"{name}_moustache", 0.034, 0.012, (c.x, y, z), material, rot=(90, 0, 0), verts=14, bevel=0.004)
    mid.scale = (1.0, 0.42, 1.0)
    parts = [mid]
    for sx in (-1, 1):
        end = kit.cyl(f"{name}_moustache_end", 0.012, 0.01, (c.x + sx * 0.03, y + 0.003, z - 0.012), material, rot=(90, 0, sx * 25), verts=8, bevel=0.003)
        end.scale = (0.7, 1.0, 1.0)
        parts.append(end)
    return parts


def main() -> None:
    pid = sys.argv[sys.argv.index("--") + 1]
    spec = tomllib.loads((ROOT / "art/people/people.toml").read_text())["person"][pid]
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    data = Path(LocationService.get_user_data())

    macro = TargetService.get_default_macro_info_dict()
    for k, v in spec.get("macro", {}).items():
        macro[k] = v
    macro["age"] = age_value(spec["age_years"])
    base = HumanService.create_human(macro_detail_dict=macro)
    HumanService.add_builtin_rig(base, "game_engine")
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")

    # Licence gate: every third-party asset file must declare CC0 in its header
    # (MakeHuman system assets do: "explicitly released as CC0 in september 2020").
    # CC-BY or unlabelled assets are refused rather than silently shipped.
    for slot, (rel, _typ) in spec["assets"].items():
        assert_cc0(data / rel)

    added = {}
    for slot, (rel, typ) in spec["assets"].items():
        added[slot] = HumanService.add_mhclo_asset(str(data / rel), base, asset_type=typ, subdiv_levels=0)

    # Uniform scale to the target standing height (MPFB scale is metres).
    h = base.dimensions.z
    s = spec["height_m"] / h
    rig.scale = (s, s, s)
    bpy.context.view_layer.update()
    # Bake the height fit into the data so every exported node has unit scale (G2).
    bpy.ops.object.select_all(action="DESELECT")
    for o in [rig] + list(rig.children_recursive):
        o.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    # Soles on the ground: MPFB grounds the body, but shoes reach ~2 cm lower.
    deps = bpy.context.evaluated_depsgraph_get()
    low = min((o.matrix_world @ v.co).z for o in rig.children_recursive if o.type == "MESH"
              for v in o.evaluated_get(deps).to_mesh().vertices)
    rig.location.z -= low
    bpy.context.view_layer.update()
    bpy.ops.object.transform_apply(location=True, rotation=False, scale=False)

    # Palette materials: one flat palette material per slot (BIBLE §3/§4).
    for slot, obj in added.items():
        key = spec["materials"].get(slot)
        if obj is None or key is None:
            continue
        obj.data.materials.clear()
        obj.data.materials.append(kit.mat(key))
        obj.name = f"{pid}_{slot}"

    # Two-tone garments (e.g. shirt above / trousers below the waist): faces whose
    # centre is below the spine_01 joint get the second palette material.
    for slot, lower in spec.get("split_below_waist", {}).items():
        obj = added[slot]
        waist = (rig.matrix_world @ rig.data.bones["spine_01"].head_local).z
        obj.data.materials.append(kit.mat(lower))
        inv = obj.matrix_world
        for poly in obj.data.polygons:
            if (inv @ poly.center).z < waist:
                poly.material_index = 1

    # Tie: a narrow front-centre strip of the suit between chest and collar gets a
    # dark material, so a single-colour linen suit still reads as jacket + shirt + tie.
    if "tie" in spec:
        obj = added["suit"]
        t = spec["tie"]
        neck = (rig.matrix_world @ rig.data.bones["neck_01"].head_local).z
        chest = neck - t.get("length", 0.30)
        obj.data.materials.append(kit.mat(t["material"]))
        idx = len(obj.data.materials) - 1
        for poly in obj.data.polygons:
            c = obj.matrix_world @ poly.center
            n = (obj.matrix_world.to_3x3() @ poly.normal).normalized()
            if abs(c.x) < t.get("half_width", 0.03) and chest < c.z < neck - 0.02 and n.y < -0.5:
                poly.material_index = idx

    # The hidden full-resolution base mesh is not shipped (the proxy is the body).
    bpy.data.objects.remove(base)

    # Budget: decimate dense clothes/hair (armature weights survive collapse).
    for slot, ratio in spec.get("decimate", {}).items():
        m = added[slot].modifiers.new("decimate", "DECIMATE")
        m.ratio = ratio

    # Pose: arms down along the sides, slight elbow bend, relaxed shoulders.
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    pbs = rig.pose.bones
    for side, sx in (("l", 1), ("r", -1)):
        aim(pbs[f"upperarm_{side}"], rig, Vector((sx * 0.13, 0.03, -1.0)))
        aim(pbs[f"lowerarm_{side}"], rig, Vector((sx * 0.06, -0.18, -1.0)))
    base_pose = {pb.name: pb.rotation_quaternion.copy() for pb in pbs if pb.rotation_mode == "QUATERNION"}

    # Idle: 4 s loop, breathing in the upper spine plus a slow, small head drift.
    scene = bpy.context.scene
    scene.render.fps = FPS
    rig.animation_data_create()
    act = bpy.data.actions.new("idle")
    rig.animation_data.action = act
    breath = math.radians(spec.get("breath_deg", 1.4))
    for f, k in ((0, 0.0), (60, 1.0), (120, 0.0)):
        scene.frame_set(f)
        for name, q in base_pose.items():
            pbs[name].rotation_quaternion = q
            pbs[name].keyframe_insert("rotation_quaternion", frame=f)
        for bone, amt in (("spine_03", breath * k), ("neck_01", -breath * 0.5 * k)):
            pbs[bone].rotation_mode = "QUATERNION"
            pbs[bone].rotation_quaternion = Matrix.Rotation(amt, 4, "X").to_quaternion()
            pbs[bone].keyframe_insert("rotation_quaternion", frame=f)
    scene.frame_start, scene.frame_end = 0, 120
    scene.frame_set(0)
    bpy.ops.object.mode_set(mode="OBJECT")

    # Hat on the head bone, sitting on the hair.
    parts = []
    if "hat" in spec:
        hair = added.get("hair")
        top_z = max((hair.matrix_world @ v.co).z for v in hair.data.vertices) if hair else spec["height_m"]
        head = rig.matrix_world @ rig.data.bones["head"].head_local
        top = Vector((head.x, head.y, top_z - spec["hat"].get("sink", 0.03)))
        parts.append(kit.join(f"{pid}_hat", hat(spec["hat"], top, f"{pid}_hat")))
    if "eyes" in added and (spec.get("glasses") or spec.get("moustache")):
        c, front = face_anchor(added["eyes"])
        if spec.get("glasses"):
            parts.append(kit.join(f"{pid}_glasses", glasses(c, front, f"{pid}_glasses")))
        if spec.get("moustache"):
            parts.append(kit.join(f"{pid}_moustache", moustache(c, front, pid, spec["materials"].get("hair", "hair_dark"))))
    for obj in parts:  # head accessories follow the head bone (idle breathing, look-at)
        mw = obj.matrix_world.copy()
        obj.parent = rig
        obj.parent_type = "BONE"
        obj.parent_bone = "head"
        obj.matrix_world = mw

    rig.name = f"{pid}_rig"
    out = ROOT / spec["export"]
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True, export_apply=True,
                              export_yup=True, export_animations=True, export_animation_mode="ACTIONS",
                              export_skins=True, export_morph=False)
    tris = 0
    deps = bpy.context.evaluated_depsgraph_get()
    for o in bpy.data.objects:
        if o.type == "MESH":
            me = o.evaluated_get(deps).to_mesh()
            tris += sum(len(p.vertices) - 2 for p in me.polygons)
            o.evaluated_get(deps).to_mesh_clear()
    print(f"exported {out} ({tris} tris, scale {s:.3f})")


if __name__ == "__main__":
    main()
