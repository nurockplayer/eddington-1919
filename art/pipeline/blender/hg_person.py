"""Human Generator (HG) character prototype — evaluation route, NOT a shipping build.

    blender -b --python art/pipeline/blender/hg_person.py -- <out_dir> [--person=<name>] [--stills] [--hair=<json path>]

Requires full Human Generator content in the isolated Blender user directory
/Volumes/KIOXIA/eddington-1919-cache/hg-full/blender_user (evaluation only).
Builds a character from Human Generator 4 content; `--person=` picks the entry in
PERSONS (default `eddington`, unchanged behaviour):
  eddington — HG base male (Caucasian 1 preset)
    + face/age livekeys tuned toward the REFERENCE.md likeness
    + Short Side Part hair, eyebrows, 43 ARKit-style FACS shape keys (face_rig.json)
    + painted skin (trial skin maps are watermarked) and the MPFB CC0 suit retargeted
      onto the HG body (HG trial has no period outfit)
  kit — c03 bake-off against the MPFB route: female Caucasian 1 preset, age 23,
    a slight jaw/brow neutralising push, Bob Short hair, no makeup, no beard shadow,
    the same suit retargeted but with the flat palette `linen` material (the MPFB
    route uses palette materials, so the bake-off compares like with like), plus
    the kit.py spectacles from build_person.py on the head bone.
  → <out_dir>/<person>_hg.blend and, with --stills, lit EEVEE portrait renders
    hg_<person>_<mood>.png / hg_<person>_front.png.

Licence: HG meshes/textures may not be redistributed, and this repo is public.
Outputs therefore stay OUTSIDE the repo (KIOXIA cache); only this script is
committed. See docs/HG_PROTOTYPE.md.
"""
import math
import sys
from pathlib import Path

import addon_utils
import bmesh
import bpy
from mathutils import Matrix, Vector

addon_utils.enable("HumGen3D", default_set=True)
from HumGen3D import Human  # noqa: E402
from HumGen3D.backend.preferences.preference_func import get_prefs  # noqa: E402

sys.path.insert(0, str(Path(__file__).resolve().parent))
import kit  # noqa: E402

# One entry per character. `--person=` selects one in main(); eddington is the
# default. Hair paths are relative to the HG content dir.
PERSONS = {
    "eddington": {
        "preset": "models/male/Caucasian Presets/Caucasian 1.json",
        "hair": "hair/head/male/Regular/Slicked Back Side Part.json",
        "age": 35,
        # Reference likeness (art/people/REFERENCE.md): long narrow face, high
        # forehead, deep-set eyes, slim build, dark short hair parted on the left,
        # clean-shaven.
        "livekeys": {
            "forehead_size": 0.5,
            "browridge_center_size": 0.8,
            "browridge_loc_vertical": 0.15,
            "temple_size": -0.35,
            "Eye Depth": 0.6,
            "Eye Scale": 0.0,
            "Eye Distance": -0.10,
            "skinny": 0.7,
            "aged_male": 0.45,
            "height_200": 0.15,
            "height_150": 0.0,
            "jaw_width": -0.45,
            "jaw_location_vertical": 0.5,
            "chin_width": 0.1,
            "chin_size": 0.2,
            "chin_height": 0.55,
            "nose_height": 0.6,
            "nose_bridge_height": 0.45,
            "nose_bridge_width": -0.1,
            "nose_tip_length": 0.4,
            "nose_tip_size": 0.15,
            "lip_height": -0.2,
            "cheek_zygomatic_bone": 0.3,
            "cheek_fullness": -0.6,
        },
        # Distances are metres; narrowing values are dimensionless fractions.
        "face": {
            "chin_drop": 0.0,
            "lower_narrow": 0.0,
            "jaw_in": 0.0,
            "chin_narrow": 0.0,
            "chin_fwd": 0.0,
            "cheek_hollow": 0.0,
            "nose_tip_fwd": 0.0,
            "nose_tip_down": 0.0,
            "ear_out": 0.0,
        },
        "hair_colour": (("Lightness", 0.025), ("Redness", 0.25), ("Pepper & Salt", 0.0),
                        ("Fast/Accurate", 1.0), ("Roughness", 0.4)),
        "pupil": [0.16, 0.13, 0.10, 1.0],
        "sclera": [0.93, 0.9, 0.86, 1.0],
        "face_shape": True,   # eddington_face sculpt key
        "beard_shadow": True,
        "suit": "wool_tint",  # diffuse texture × tint
        "glasses": False,
        "zero_makeup": False,
    },
    "kit": {  # c03 bake-off against the MPFB route (people.toml [person.kit])
        "preset": "models/female/Caucasian presets/Caucasian 1.json",
        # c03 r2 (lead): Bob Short read as a blunt fringe wig; the design's hair is
        # side-parted and pushed back, no fringe.
        "hair": "hair/head/male/Long/Medium Side Part.json",
        "age": 23,
        "height_cm": 168,
        # A slight neutralising push only (Kit reads neither as a woman nor as
        # butch); the c03 values are all this character gets.
        "livekeys": {"skinny": 0.55, "jaw_width": 0.15, "browridge_center_size": 0.25},
        "face": {},           # no eddington_face sculpt for Kit
        "hair_colour": (("Lightness", 0.09), ("Redness", 0.35), ("Pepper & Salt", 0.0),
                        ("Fast/Accurate", 1.0), ("Roughness", 0.45)),
        "pupil": [0.20, 0.15, 0.10, 1.0],
        "sclera": [0.93, 0.9, 0.86, 1.0],
        "face_shape": False,
        "beard_shadow": False,
        "suit": "linen",      # flat palette material, like the MPFB route
        "glasses": True,
        "zero_makeup": True,
    },
}
PERSON = PERSONS["eddington"]

# FACS shape-key mixes (HG face_rig.json names, 0–1). Small values: the target is
# a quiet, readable performance (Tell Me Why / LiS:TC), not a mugging face.
MOODS = {
    "neutral": {"mouthPress_L": 0.15, "mouthPress_R": 0.15, "browInnerUp": 0.1},
    "intent": {"browInnerUp": 0.35, "browDown_L": 0.35, "browDown_R": 0.35, "eyeSquint_L": 0.45,
               "eyeSquint_R": 0.45, "mouthPress_L": 0.45, "mouthPress_R": 0.45, "jaw_L": 0.0},
    "warm": {"mouthSmile_L": 0.8, "mouthSmile_R": 0.7, "cheekSquint_L": 0.55, "cheekSquint_R": 0.5,
             "eyeSquint_L": 0.45, "eyeSquint_R": 0.4, "browInnerUp": 0.15, "mouthDimple_L": 0.3},
    "doubt": {"browInnerUp": 0.85, "browDown_L": 0.45, "browOuterUp_R": 0.3, "mouthFrown_L": 0.45,
              "mouthFrown_R": 0.3, "mouthPress_L": 0.4, "mouthRollLower": 0.25, "mouth_L": 0.2,
              "eyeLookDownLeft": 0.3, "eyeLookDownRight": 0.3},
    "blink": {"eyeBlink_L": 1.0, "eyeBlink_R": 1.0},
}

SUIT_OBJ = "extensions/.user/user_default/mpfb/data/clothes/male_elegantsuit01/male_elegantsuit01.obj"
BASE_OBJ = "extensions/user_default/mpfb/data/3dobjs/base.obj"
SLIM = 0.86  # suit cross-section vs. height ratio: the MakeHuman default body is fuller than this HG build
MPFB_USER = [Path("/Volumes/KIOXIA/eddington-1919-cache/mpfb/blender_user"),
             Path("/private/tmp/eddington-1919-cache/mpfb/blender_user")]


def build(hair: str = "") -> Human:
    for o in list(bpy.data.objects):
        bpy.data.objects.remove(o)
    h = Human.from_preset(PERSON["preset"], bpy.context)
    if get_prefs().is_trial:
        raise RuntimeError("Full HG content required; set BLENDER_USER_RESOURCES to hg-full/blender_user")
    h.age.set(PERSON["age"])
    print_face_measure("base", h)
    print("HG_LIVEKEYS", [k.name for k in h.keys.all_livekeys], flush=True)
    applied = []
    for k in h.keys.all_livekeys:
        if k.name in PERSON["livekeys"]:
            k.value = PERSON["livekeys"][k.name]
            applied.append((k.name, k.value))
    print("HG_LIVEKEYS_SET", applied, flush=True)
    if "height_cm" in PERSON:
        h.height.set(PERSON["height_cm"], bpy.context)
    print("HG_HEIGHT cm", h.height.centimeters, flush=True)
    h.hair.regular_hair.set(hair or PERSON["hair"])
    hair_colour(h)
    h.eyes.set_from_dict({"pupil_color": PERSON["pupil"], "sclera_color": PERSON["sclera"]})
    if PERSON["zero_makeup"]:
        zero_makeup(h)
    h.expression.load_facial_rig()
    return h


def hair_colour(h: Human) -> None:
    for mat in [m for m in bpy.data.materials if m.name.startswith(".HG_Hair")]:
        for n in mat.node_tree.nodes:
            if n.type == "GROUP":
                for name, v in PERSON["hair_colour"]:
                    if name in n.inputs:
                        n.inputs[name].default_value = v


MAKEUP_KEYS = ("foundation_amount", "blush_opacity", "lipstick_opacity", "eyeliner_opacity")


def zero_makeup(h: Human) -> None:
    """HG female presets carry makeup controls; Kit wears none. Prints every
    control it touched with the value the preset had."""
    skin = h.skin.gender_specific
    zeroed = []
    for name in MAKEUP_KEYS:
        inp = getattr(skin, name, None)
        if inp is None:
            continue
        before = inp.value
        inp.value = 0.0
        zeroed.append((name, round(float(before), 3)))
    print("HG_MAKEUP_ZEROED", zeroed, flush=True)


def arms_down(h: Human) -> None:
    rig = h.objects.rig
    for side, sgn in (("L", 1), ("R", -1)):
        ua = rig.pose.bones[f"upper_arm.{side}"]
        aim(ua, rig, Vector((0.12 * sgn, 0.02, -1.0)))
        fa = rig.pose.bones[f"forearm.{side}"]
        aim(fa, rig, Vector((0.05 * sgn, -0.25, -1.0)))
    head = rig.pose.bones["head"]
    head.rotation_mode = "XYZ"
    head.rotation_euler = (math.radians(4), math.radians(-6), 0)
    bpy.context.view_layer.update()


def aim(pb, rig, world_dir: Vector) -> None:
    """Same contract as build_person.aim: measured from the posed parent frame."""
    pb.rotation_mode = "QUATERNION"
    pb.rotation_quaternion = (1, 0, 0, 0)
    bpy.context.view_layer.update()
    m = (rig.matrix_world @ pb.matrix).to_3x3().normalized()
    q = (m @ Vector((0, 1, 0))).rotation_difference(world_dir.normalized())
    pb.rotation_quaternion = (m.inverted() @ q.to_matrix() @ m).to_quaternion()
    bpy.context.view_layer.update()


def facs_keys(h: Human) -> dict:
    body = h.objects.body
    ad = body.data.shape_keys.animation_data
    if ad:
        for d in list(ad.drivers):
            ad.drivers.remove(d)
    return {kb.name: kb for kb in body.data.shape_keys.key_blocks}


def set_mood(keys: dict, mood: str) -> None:
    for name in MOODS:
        for k in MOODS[name]:
            if k in keys:
                keys[k].value = 0.0
    for k, v in MOODS[mood].items():
        if k in keys:
            keys[k].value = v
        else:
            print("MISSING_KEY", k)


def gaze(h: Human, target: Vector) -> None:
    rig = h.objects.rig
    pb = rig.pose.bones["eyeball_lookat_master"]
    loc_world = rig.matrix_world @ pb.matrix
    m = loc_world.copy()
    m.translation = target
    pb.matrix = rig.matrix_world.inverted() @ m
    bpy.context.view_layer.update()


def landmarks(h: Human) -> dict:
    """Face landmarks in world space from the unposed, shape-keyed body."""
    body = h.objects.body
    subs = [m for m in body.modifiers if m.type != "ARMATURE" and m.show_viewport]
    for m in subs:
        m.show_viewport = False
    dg = bpy.context.evaluated_depsgraph_get()
    ev = body.evaluated_get(dg)
    me = ev.to_mesh()
    co = [body.matrix_world @ v.co for v in me.vertices]
    ev.to_mesh_clear()
    for m in subs:
        m.show_viewport = True
    eyes = h.objects.eyes
    ew = [eyes.matrix_world @ v.co for v in eyes.data.vertices]
    eye_l = sum((p for p in ew if p.x > 0), Vector()) / max(1, sum(1 for p in ew if p.x > 0))
    eye_r = sum((p for p in ew if p.x < 0), Vector()) / max(1, sum(1 for p in ew if p.x < 0))
    ez = (eye_l.z + eye_r.z) / 2
    nose = min((p for p in co if abs(p.x) < 0.006 and ez - 0.075 < p.z < ez - 0.02), key=lambda p: p.y)
    mouth = min((p for p in co if abs(p.x) < 0.006 and nose.z - 0.05 < p.z < nose.z - 0.025), key=lambda p: p.y)
    return {"co": co, "eye_l": eye_l, "eye_r": eye_r, "nose": nose, "mouth": mouth}


def face_measures(lm: dict) -> tuple:
    """(eye_to_chin, jaw_width, bizygomatic_width, nose_forward) in mm, from a
    landmarks() dict. Fixed vertex bands keep separate calls comparable."""
    points = lm["co"]
    el, er, nose, mouth = lm["eye_l"], lm["eye_r"], lm["nose"], lm["mouth"]
    ez = (el.z + er.z) / 2
    ey = (el.y + er.y) / 2
    chin_z = mouth.z - 0.05
    chin_ids = [i for i, p in enumerate(points) if abs(p.x) < 0.015 and
                chin_z - 0.025 < p.z < chin_z + 0.012 and p.y < mouth.y + 0.03]
    jaw_ids = [i for i, p in enumerate(points) if abs(p.z - mouth.z) < 0.005 and
               0.035 < abs(p.x) < 0.09 and mouth.y < p.y < ey + 0.06]
    cheek_ids = [i for i, p in enumerate(points) if abs(p.z - (ez - 0.025)) < 0.008 and
                 0.03 < abs(p.x) < 0.09 and p.y < ey + 0.04]
    nose_id = min(range(len(points)), key=lambda i: (points[i] - nose).length_squared)
    chin = min(points[i].z for i in chin_ids)
    width = lambda ids: max(points[i].x for i in ids) - min(points[i].x for i in ids)
    return (1000 * (ez - chin), 1000 * width(jaw_ids), 1000 * width(cheek_ids),
            1000 * (ey - points[nose_id].y))


def print_face_measure(label: str, h: Human) -> None:
    values = face_measures(landmarks(h))
    print("FACE_MEASURE %s mm eye_to_chin=%.2f jaw_width=%.2f bizygomatic_width=%.2f nose_forward=%.2f" %
          ((label,) + values), flush=True)


def face_shape(h: Human, lm: dict) -> None:
    """Sculpt symmetric, localized displacements in the unposed world-space head."""
    body = h.objects.body
    keys = body.data.shape_keys.key_blocks
    sk = body.shape_key_add(name="eddington_face", from_mix=False)
    cfg = PERSON["face"]
    el, er, nose, mouth = lm["eye_l"], lm["eye_r"], lm["nose"], lm["mouth"]
    ez = (el.z + er.z) / 2
    ey = (el.y + er.y) / 2
    chin_z = mouth.z - 0.05
    inv = body.matrix_world.inverted().to_3x3()

    def smooth(a, b, v):
        t = max(0.0, min(1.0, (v - a) / (b - a)))
        return t * t * (3.0 - 2.0 * t)

    def gauss(v, centre, radius):
        return math.exp(-((v - centre) / radius) ** 2)

    before = lm["co"]
    for i, p in enumerate(before):
        ax = abs(p.x)
        sign = 1 if p.x >= 0 else -1
        q = p.copy()
        # Ear displacement is independent of the below-eye face mask.
        ear = (smooth(0.065, 0.080, ax) * smooth(ey + 0.05, ey + 0.065, p.y)
               * (1 - smooth(ey + 0.10, ey + 0.115, p.y))
               * gauss(p.z, ez - 0.01, 0.045))
        q.x += sign * cfg["ear_out"] * ear
        face = ((1 - smooth(ez - 0.005, ez, p.z))
                * smooth(chin_z - 0.06, chin_z - 0.025, p.z)
                * (1 - smooth(0.09, 0.105, ax))
                * (1 - smooth(ey + 0.06, ey + 0.085, p.y)))
        lower = smooth(chin_z, ez, ez + chin_z - p.z)
        jaw = (gauss(ax, 0.062, 0.015) * gauss(p.z, mouth.z - 0.03, 0.025)
               * smooth(mouth.y + 0.005, mouth.y + 0.035, p.y))
        chin = gauss(ax, 0, 0.020) * gauss(p.z, chin_z, 0.020) * gauss(p.y, mouth.y + 0.012, 0.035)
        cheek = (gauss(ax, 0.045, 0.015) * gauss(p.z, nose.z - 0.015, 0.020)
                 * gauss(p.y, nose.y + 0.025, 0.035))
        tip = gauss(ax, 0, 0.012) * gauss(p.z, nose.z, 0.012) * gauss(p.y, nose.y, 0.018)
        q.x -= sign * face * (ax * (cfg["lower_narrow"] * lower + cfg["chin_narrow"] * chin)
                              + cfg["jaw_in"] * jaw + cfg["cheek_hollow"] * cheek)
        q.y -= face * (cfg["chin_fwd"] * chin + cfg["nose_tip_fwd"] * tip)
        # The lip guard is exactly zero within 1 cm of the mouth landmark.
        lip_guard = smooth(0.010, 0.018, abs(p.z - mouth.z))
        drop = smooth(0.012, 0.035, mouth.z - p.z)
        q.z -= face * lip_guard * (cfg["chin_drop"] * drop + cfg["nose_tip_down"] * tip)
        sk.data[i].co = keys["Basis"].data[i].co + inv @ (q - p)
    sk.value = 1.0


def skin_zones(h: Human, lm: dict) -> None:
    """Paint a 'zones' colour attribute: R redness, G beard shadow, B darkening, A shine.
    Painted-skin approach (LiS/Tell Me Why): soft value/hue zones instead of photo
    albedo. The HG trial albedo/normal/roughness maps are watermarked, so unusable."""
    body = h.objects.body
    me = body.data
    att = me.color_attributes.get("zones") or me.color_attributes.new("zones", "FLOAT_COLOR", "POINT")
    el, er, nose, mouth = lm["eye_l"], lm["eye_r"], lm["nose"], lm["mouth"]

    def g(p, c, r, sx=1.0, sy=1.0, sz=1.0):
        d = Vector(((p.x - c.x) / sx, (p.y - c.y) / sy, (p.z - c.z) / sz))
        return math.exp(-(d.length / r) ** 2)

    cheeks = [Vector((e.x + 0.012 * (1 if e.x > 0 else -1), e.y - 0.004, e.z - 0.038)) for e in (el, er)]
    ears = [Vector((0.075 * s, el.y + 0.085, el.z - 0.01)) for s in (1, -1)]
    chin = Vector((0, mouth.y + 0.012, mouth.z - 0.045))
    head_c = (el + er) / 2 + Vector((0, 0.06, 0.03))
    vals = []
    for p in lm["co"]:
        front = p.y < head_c.y - 0.01
        red = max(g(p, cheeks[0], 0.026, sz=0.8), g(p, cheeks[1], 0.026, sz=0.8)) * 0.55
        red = max(red, g(p, nose, 0.014) * 0.6, g(p, mouth, 0.016, sx=1.6, sz=0.6) * 0.95)
        red = max(red, max(g(p, ears[0], 0.03, sz=1.6), g(p, ears[1], 0.03, sz=1.6)) * 0.5)
        beard = 0.0
        if PERSON["beard_shadow"] and front and p.z < nose.z - 0.008 and p.z > chin.z - 0.03:
            beard = 0.75 * (1 - g(p, mouth, 0.011, sx=1.8, sz=0.5))
            beard *= min(1.0, abs(p.x) / 0.01 + 0.6) if p.z > mouth.z + 0.003 else 1.0
        if PERSON["beard_shadow"] and p.z < chin.z - 0.03 and p.y < head_c.y:
            beard = max(beard, 0.4 * g(p, chin + Vector((0, 0.03, -0.035)), 0.05))
        dark = max(g(p, e + Vector((0, -0.004, -0.014)), 0.014, sx=1.5) for e in (el, er)) * 0.7
        dark = max(dark, max(g(p, e + Vector((0, 0.004, 0.002)), 0.018, sx=1.3) for e in (el, er)) * 0.35)
        shine = max(g(p, nose, 0.018) * 0.8, g(p, head_c + Vector((0, -0.07, 0.07)), 0.04) * 0.5,
                    g(p, chin, 0.015) * 0.4, g(p, mouth, 0.012, sx=1.8, sz=0.6) * 0.7)
        vals.extend((red, beard, dark, shine))
    att.data.foreach_set("color", vals)


def skin_material(h: Human) -> None:
    mat = bpy.data.materials.new("Skin_Painted")
    nt = mat.node_tree
    N = nt.nodes
    L = nt.links
    bsdf = next(n for n in N if n.type == "BSDF_PRINCIPLED")
    attr = N.new("ShaderNodeVertexColor")
    attr.layer_name = "zones"
    sep = N.new("ShaderNodeSeparateColor")
    L.new(attr.outputs["Color"], sep.inputs[0])

    def mix(a, b_col, fac_socket, k, blend="MIX"):
        m = N.new("ShaderNodeMix")
        m.data_type = "RGBA"
        m.blend_type = blend
        mul = N.new("ShaderNodeMath")
        mul.operation = "MULTIPLY"
        L.new(fac_socket, mul.inputs[0])
        mul.inputs[1].default_value = k
        L.new(mul.outputs[0], m.inputs["Factor"])
        if isinstance(a, tuple):
            m.inputs["A"].default_value = a
        else:
            L.new(a, m.inputs["A"])
        m.inputs["B"].default_value = b_col
        return m.outputs["Result"]

    tc = N.new("ShaderNodeTexCoord")
    mottle = N.new("ShaderNodeTexNoise")
    mottle.inputs["Scale"].default_value = 55.0
    mottle.inputs["Detail"].default_value = 4.0
    L.new(tc.outputs["Object"], mottle.inputs["Vector"])
    base = (0.46, 0.26, 0.17, 1)
    c = mix(base, (0.50, 0.19, 0.15, 1), sep.outputs["Red"], 0.75)
    c = mix(c, (0.30, 0.25, 0.25, 1), sep.outputs["Green"], 0.5)
    c = mix(c, (0.70, 0.58, 0.58, 1), sep.outputs["Blue"], 0.6, "MULTIPLY")
    c = mix(c, (0.62, 0.38, 0.32, 1), mottle.outputs["Fac"], 0.12)
    L.new(c, bsdf.inputs["Base Color"])
    rough = N.new("ShaderNodeMath")
    rough.operation = "MULTIPLY_ADD"
    L.new(attr.outputs["Alpha"], rough.inputs[0])
    rough.inputs[1].default_value = -0.16
    rough.inputs[2].default_value = 0.52
    L.new(rough.outputs[0], bsdf.inputs["Roughness"])
    pores = N.new("ShaderNodeTexNoise")
    pores.inputs["Scale"].default_value = 900.0
    pores.inputs["Detail"].default_value = 6.0
    L.new(tc.outputs["Object"], pores.inputs["Vector"])
    bump = N.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = 0.08
    bump.inputs["Distance"].default_value = 0.0004
    L.new(pores.outputs["Fac"], bump.inputs["Height"])
    wr = bpy.data.images.load(str(Path(get_prefs().filepath) / "textures/layers/aged_layer_normal_4K.png"),
                              check_existing=True)
    wr.colorspace_settings.name = "Non-Color"
    wt = N.new("ShaderNodeTexImage")
    wt.image = wr
    nm = N.new("ShaderNodeNormalMap")
    nm.inputs["Strength"].default_value = 0.7
    L.new(wt.outputs["Color"], nm.inputs["Color"])
    L.new(nm.outputs["Normal"], bump.inputs["Normal"])
    L.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Subsurface Weight"].default_value = 0.2
    bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.42, 0.26)
    bsdf.inputs["Subsurface Scale"].default_value = 0.005
    bsdf.inputs["Specular IOR Level"].default_value = 0.38
    body = h.objects.body
    body.data.materials[0] = mat


def import_obj(path: Path, split: bool = False) -> list:
    before = set(bpy.data.objects)
    bpy.ops.wm.obj_import(filepath=str(path), use_split_groups=split)
    return [o for o in bpy.data.objects if o not in before and o.type == "MESH"]


def retarget(ob: bpy.types.Object, mh: dict, hg: dict, segs: list) -> None:
    """Warp a mesh from MakeHuman joint space to HG joint space: each bone segment
    maps by rotation + along-bone stretch + uniform cross-section scale; vertices
    blend the segment maps by inverse 4th-power distance (linear blend skinning
    without a rig)."""
    c = (hg["head"] - hg["foot.L"]).length / (mh["head"] - mh["l-ankle"]).length
    maps = []
    for ma, mb, ha, hb in segs:
        a, b, a2, b2 = mh[ma], mh[mb], hg[ha], hg[hb]
        u, u2 = (b - a).normalized(), (b2 - a2).normalized()
        maps.append((a, b, a2, u, (b - a).length, (b2 - a2).length / (b - a).length, u.rotation_difference(u2)))
    mw = ob.matrix_world
    inv = mw.inverted()
    for v in ob.data.vertices:
        p = mw @ v.co
        acc, wsum = Vector(), 0.0
        for a, b, a2, u, ln, k, q in maps:
            t = max(0.0, min(ln, (p - a).dot(u)))
            w = 1.0 / ((p - (a + u * t)).length ** 4 + 1e-6)
            d = p - a
            along = d.dot(u)
            perp = d - u * along
            acc += (a2 + q @ (u * along * k + perp * c * SLIM)) * w
            wsum += w
        v.co = inv @ (acc / wsum)
    ob.data.update()


def tighten(ob: bpy.types.Object, body: bpy.types.Object, ease: float = 0.012, k: float = 0.65) -> None:
    """Pull cloth that floats more than `ease` off the body part-way back: the
    MakeHuman suit is cut for a fuller default body. Lapels sit within the ease
    and keep their shape."""
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get()
    tree = BVHTree.FromObject(body, dg)
    bi = body.matrix_world.inverted()
    mw = ob.matrix_world
    inv = mw.inverted()
    for v in ob.data.vertices:
        p = bi @ (mw @ v.co)
        loc, _n, _i, d = tree.find_nearest(p)
        if loc is None or d <= ease:
            continue
        p = p + (loc - p).normalized() * (d - ease) * k
        v.co = inv @ (body.matrix_world @ p)
    ob.data.update()


def suit_fit(ob: bpy.types.Object, body: bpy.types.Object) -> str:
    """Suit-fit numbers for the c03 report: vertices still inside the body, the
    deepest remaining penetration and the suit bounding box. A failed retarget
    shows up as a bbox far from a human's ~0.6 x 0.4 x 1.4 m."""
    from mathutils.bvhtree import BVHTree
    dg = bpy.context.evaluated_depsgraph_get()
    tree = BVHTree.FromObject(body, dg)
    bi = body.matrix_world.inverted()
    pts = [ob.matrix_world @ v.co for v in ob.data.vertices]
    inside, deep = 0, 0.0
    for p in pts:
        lp = bi @ p
        loc, nrm, _i, d = tree.find_nearest(lp)
        if loc is None:
            continue
        if (lp - loc).dot(nrm) < 0:
            inside += 1
            deep = max(deep, d)
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    size = hi - lo
    return "verts=%d inside=%d max_pen=%.1fmm bbox=%.2fx%.2fx%.2fm" % (
        len(pts), inside, 1000 * deep, size.x, size.y, size.z)


def suit(h: Human) -> bpy.types.Object:
    """Fit the MPFB CC0 male_elegantsuit01 onto the HG body.

    The suit is warped from MakeHuman's hm08 joint positions (base.obj joint
    groups) to the HG rig's joints (retarget), then only vertices that end up
    inside the body are pushed out, so the drape and lapels survive. Weights come from the HG body (Data Transfer); body faces
    under the suit are masked to stop poke-through.
    Rejected: HG's own add_obj (A-pose correction collapsed the suit onto the skin)
    Surface Deform via a shrinkwrapped base mesh (bad nearest-point matches
    dragged the collar up to the chin), and a uniform height fit (HG shoulders
    sit higher, so the push-out made a skin-tight suit)."""
    root = next(p for p in MPFB_USER if (p / SUIT_OBJ).exists())
    path = root / SUIT_OBJ
    base_path = root / BASE_OBJ
    for f in (path.with_suffix(".mhclo"), base_path):
        assert "explicitly released as CC0" in f.read_text(errors="ignore")[:600], f"{f.name} is not CC0"
    ob = import_obj(path)[0]
    ob.name = "HG_Suit"
    parts = import_obj(base_path, split=True)
    joints = {}
    for o in parts:
        key = o.name.split(".")[0]
        if key.startswith("joint-"):
            joints[key[6:]] = sum((o.matrix_world @ v.co for v in o.data.vertices), Vector()) / len(o.data.vertices)
        bpy.data.objects.remove(o)
    rig = h.objects.rig
    body = h.objects.body
    bpy.context.view_layer.update()
    hg = {n: rig.matrix_world @ rig.pose.bones[n].head for n in
          ("spine", "neck", "head", "shoulder.L", "shoulder.R", "upper_arm.L", "upper_arm.R", "forearm.L",
           "forearm.R", "hand.L", "hand.R", "thigh.L", "thigh.R", "shin.L", "shin.R", "foot.L", "foot.R")}
    segs = [("pelvis", "neck", "spine", "neck"), ("neck", "head", "neck", "head")]
    sides = (("l", "L"), ("r", "R")) if joints["l-shoulder"].x * hg["upper_arm.L"].x > 0 else (("l", "R"), ("r", "L"))
    for mh_s, hg_s in sides:
        segs += [("neck", f"{mh_s}-clavicle", "neck", f"shoulder.{hg_s}"),
                 (f"{mh_s}-clavicle", f"{mh_s}-shoulder", f"shoulder.{hg_s}", f"upper_arm.{hg_s}"),
                 (f"{mh_s}-shoulder", f"{mh_s}-elbow", f"upper_arm.{hg_s}", f"forearm.{hg_s}"),
                 (f"{mh_s}-elbow", f"{mh_s}-hand", f"forearm.{hg_s}", f"hand.{hg_s}"),
                 ("pelvis", f"{mh_s}-upper-leg", "spine", f"thigh.{hg_s}"),
                 (f"{mh_s}-upper-leg", f"{mh_s}-knee", f"thigh.{hg_s}", f"shin.{hg_s}"),
                 (f"{mh_s}-knee", f"{mh_s}-ankle", f"shin.{hg_s}", f"foot.{hg_s}")]
    retarget(ob, joints, hg, segs)
    tighten(ob, body)
    print("DBG suitfit pre", suit_fit(ob, body), flush=True)
    bpy.context.view_layer.objects.active = ob
    ob.select_set(True)
    push = ob.modifiers.new("clear", "SHRINKWRAP")
    push.target = body
    push.wrap_method = "NEAREST_SURFACEPOINT"
    push.wrap_mode = "OUTSIDE"  # only vertices inside the body move
    push.offset = 0.006
    bpy.ops.object.modifier_apply(modifier=push.name)
    print("DBG suitfit post", suit_fit(ob, body), flush=True)
    # Heat-map weights from the HG rig: data-transferred body weights mixed
    # torso into the sleeves at the armpit, so sleeves stayed half in A-pose.
    for x in bpy.context.selected_objects:
        x.select_set(False)
    ob.select_set(True)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.parent_set(type="ARMATURE_AUTO")
    print("DBG suit groups", len(ob.vertex_groups), [m.type for m in ob.modifiers])
    mask_under(h, ob)
    if PERSON["suit"] == "linen":
        # Flat palette material, the same one the MPFB route uses: the bake-off
        # compares the two bodies under one material, not two different surfaces.
        mat = kit.mat("linen")
    else:
        mat = bpy.data.materials.new("Suit_Wool")
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
        tex.image = bpy.data.images.load(str(path.with_name("male_elegantsuit01_diffuse.png")), check_existing=True)
        tint = mat.node_tree.nodes.new("ShaderNodeMix")
        tint.data_type = "RGBA"
        tint.blend_type = "MULTIPLY"
        tint.inputs["Factor"].default_value = 1.0
        tint.inputs["B"].default_value = (1.0, 0.95, 0.9, 1)  # midtone slate wool: dark coats vanish in the study (CAMBRIDGE_PEOPLE.md)
        mat.node_tree.links.new(tex.outputs["Color"], tint.inputs["A"])
        mat.node_tree.links.new(tint.outputs["Result"], bsdf.inputs["Base Color"])
        bsdf.inputs["Roughness"].default_value = 0.82
        bsdf.inputs["Sheen Weight"].default_value = 0.5
        bsdf.inputs["Sheen Roughness"].default_value = 0.4
    ob.data.materials.clear()
    ob.data.materials.append(mat)
    ob.modifiers.new("sub", "SUBSURF").levels = 1
    return ob


def mask_under(h: Human, cloth: bpy.types.Object) -> None:
    """Hide every body vertex the suit covers: all but head, neck and hands.
    A distance test left inner-arm skin poking through the sleeves once posed."""
    body = h.objects.body
    names = {vg.index: vg.name for vg in body.vertex_groups}
    keep = ("head", "neck", "hand", "palm", "f_", "thumb", "eye", "jaw")
    hide = body.vertex_groups.get("hg_under_suit") or body.vertex_groups.new(name="hg_under_suit")
    idx = [v.index for v in body.data.vertices
           if sum(g.weight for g in v.groups if names.get(g.group, "").startswith(keep)) < 0.3]
    hide.add(idx, 1.0, "REPLACE")
    m = body.modifiers.new("hide_under_suit", "MASK")
    m.vertex_group = hide.name
    m.invert_vertex_group = True
    body.modifiers.move(body.modifiers.find(m.name), 1)  # right after the armature


def glasses(c: Vector, front: float, name: str) -> list:
    """Thin rimless-style spectacles (c.1915 portrait): two fine rims + bridge.
    Ported from build_person.py:109-117 so both routes wear the same spectacles."""
    parts = []
    for sx in (-1, 1):
        r = kit.torus(f"{name}_rim", 0.017, 0.0012, (c.x + sx * 0.032, front - 0.008, c.z), "iron", rot=(90, 0, 0), major_seg=16, minor_seg=4)
        parts.append(r)
    parts.append(kit.cyl(f"{name}_bridge", 0.0012, 0.03, (c.x, front - 0.01, c.z + 0.004), "iron", rot=(0, 90, 0), verts=4, bevel=0))
    return parts


def spectacles(h: Human, lm: dict) -> bpy.types.Object:
    """Join the spectacles into Kit_Glasses and hang them on the head bone, so
    they follow the head pose like the MPFB route's accessories. The face points
    -Y on both routes (landmarks() finds the nose at min y), so `front` is the
    eye mesh's frontmost vertex and the rims sit 8 mm ahead of it."""
    eyes = h.objects.eyes
    pts = [eyes.matrix_world @ v.co for v in eyes.data.vertices]
    c = (lm["eye_l"] + lm["eye_r"]) / 2  # midpoint of the two eyeball centres
    front = min(p.y for p in pts)
    ob = kit.join("Kit_Glasses", glasses(c, front, "Kit_Glasses"))
    rig = h.objects.rig
    mw = ob.matrix_world.copy()
    ob.parent = rig
    ob.parent_type = "BONE"
    ob.parent_bone = "head"
    ob.matrix_world = mw
    # Diagnostic: how far the eye front sits behind the skin band around it. A
    # large gap means HG eyeballs are inset and the rims would sink into the face.
    band = [p.y for p in lm["co"] if abs(p.z - c.z) < 0.015 and abs(p.x) < 0.045]
    print("DBG glasses c=(%.4f, %.4f, %.4f) eye_front=%.4f face_front=%.4f" %
          (c.x, c.y, c.z, front, min(band) if band else float("nan")), flush=True)
    return ob


def lights_camera(h: Human, look: str = "lamp") -> bpy.types.Object:
    sc = bpy.context.scene
    rig = h.objects.rig
    head = rig.matrix_world @ rig.pose.bones["head"].head
    eye = head + Vector((0, 0, 0.09))
    for o in [o for o in bpy.data.objects if o.type in ("LIGHT", "CAMERA")]:
        bpy.data.objects.remove(o)

    def light(name, kind, loc, energy, color, size):
        ld = bpy.data.lights.new(name, kind)
        ld.energy = energy
        ld.color = color
        if kind == "AREA":
            ld.size = size
        ob = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(ob)
        ob.location = loc
        d = (eye - Vector(loc)).normalized()
        ob.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        return ob

    # Warm desk-lamp key low camera-left, cool window fill right, warm rim behind.
    light("Key", "AREA", eye + Vector((0.75, -0.35, 0.18)), 45, (1.0, 0.78, 0.55), 0.35)
    light("Fill", "AREA", eye + Vector((-1.0, -0.7, 0.2)), 9, (0.62, 0.72, 0.95), 1.2)
    light("Rim", "AREA", eye + Vector((-0.55, 0.7, 0.35)), 45, (1.0, 0.85, 0.65), 0.4)
    camd = bpy.data.cameras.new("Cam")
    camd.lens = 85
    camd.dof.use_dof = True
    camd.dof.aperture_fstop = 2.8
    cam = bpy.data.objects.new("Cam", camd)
    sc.collection.objects.link(cam)
    aim_at = eye + Vector((0, 0, -0.05))
    cam.location = eye + Vector((0.32, -1.15, -0.02))
    cam.rotation_euler = (aim_at - cam.location).to_track_quat("-Z", "Y").to_euler()
    camd.dof.focus_distance = (eye - cam.location).length
    sc.camera = cam
    w = bpy.data.worlds.get("World") or bpy.data.worlds.new("World")
    sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = (0.03, 0.024, 0.019, 1)
    bg.inputs["Strength"].default_value = 1.0
    return cam


def render(path: Path, res=(1024, 1280)) -> None:
    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE_NEXT"
    except TypeError:
        sc.render.engine = "BLENDER_EEVEE"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.resolution_percentage = 100
    sc.eevee.taa_render_samples = 64
    if hasattr(sc.eevee, "use_raytracing"):
        sc.eevee.use_raytracing = True
    try:
        sc.view_settings.view_transform = "AgX"
        sc.view_settings.look = "AgX - Medium High Contrast"
    except TypeError:
        pass
    sc.render.image_settings.file_format = "PNG"
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def main() -> None:
    global PERSON
    argv = sys.argv[sys.argv.index("--") + 1:]
    out = Path(argv[0])
    out.mkdir(parents=True, exist_ok=True)
    person = next((a.split("=", 1)[1] for a in argv if a.startswith("--person=")), "eddington")
    if person not in PERSONS:
        raise SystemExit(f"--person must be one of {sorted(PERSONS)}")
    PERSON = PERSONS[person]
    print("HG_PERSON", person, flush=True)
    hair = next((a.split("=", 1)[1] for a in argv if a.startswith("--hair=")), PERSON["hair"])
    h = build(hair)
    lm = landmarks(h)
    if PERSON["face_shape"]:
        face_shape(h, lm)
    print_face_measure("final", h)
    skin_zones(h, lm)
    skin_material(h)
    suit(h)
    if PERSON["glasses"]:
        spectacles(h, lm)
    arms_down(h)
    keys = facs_keys(h)
    cam = lights_camera(h)
    set_mood(keys, "neutral")
    bpy.ops.wm.save_as_mainfile(filepath=str(out / f"{person}_hg.blend"))
    if "--stills" in argv:
        rig = h.objects.rig
        eye = rig.matrix_world @ rig.pose.bones["head"].head + Vector((0, 0, 0.09))
        moods = [m for m in argv[1:] if m in MOODS] or ["neutral", "intent", "warm", "doubt"]
        looks = {"neutral": (0.25, -1.0, 0.02), "intent": (0.1, -1.0, -0.05), "warm": (0.3, -1.0, 0.03),
                 "doubt": (-0.2, -1.0, -0.12), "blink": (0.25, -1.0, 0.02)}
        for mood in moods:
            set_mood(keys, mood)
            gaze(h, eye + Vector(looks[mood]))
            render(out / f"hg_{person}_{mood}.png")
        if "--front" in argv:
            set_mood(keys, "neutral")
            head = rig.pose.bones["head"]
            old_rotation = head.rotation_euler.copy()
            head.rotation_euler = (0, 0, 0)
            bpy.context.view_layer.update()
            front_eye = rig.matrix_world @ head.head + Vector((0, 0, 0.09))
            distance = (cam.location - eye).length
            cam.location = front_eye + Vector((0, -distance, 0))
            cam.rotation_euler = (front_eye - cam.location).to_track_quat("-Z", "Y").to_euler()
            cam.data.dof.focus_distance = distance
            gaze(h, cam.location)
            render(out / f"hg_{person}_front.png")
            head.rotation_euler = old_rotation
            bpy.context.view_layer.update()
        if "--wide" in argv:
            set_mood(keys, "neutral")
            cam.data.lens = 40
            cam.data.dof.aperture_fstop = 5.6
            cam.location = eye + Vector((0.9, -2.6, -0.35))
            cam.rotation_euler = ((eye + Vector((0, 0, -0.45))) - cam.location).to_track_quat("-Z", "Y").to_euler()
            cam.data.dof.focus_distance = (eye - cam.location).length
            render(out / f"hg_{person}_wide.png", (1600, 900))


main()
