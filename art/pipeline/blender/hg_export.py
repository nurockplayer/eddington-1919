"""Export the HG prototype (hg_person.py output) to a Godot-ready GLB.

    blender -b <out_dir>/<person>_hg.blend --python art/pipeline/blender/hg_export.py -- <out_dir>

  particle hair/eyebrows → HG haircards (convert_to_haircards)
  painted skin + suit node graphs → baked 2K albedo images (Cycles emission bake)
  masked body under the suit → deleted (shape keys kept), subsurf dropped
  posed arms → one-frame "idle" action; FACS shape keys → glTF morph targets
  → <out_dir>/<person>_hg.glb (named from the opened .blend)

The GLB contains HG assets: it stays outside the public repo (see hg_person.py).
"""
import sys
from pathlib import Path

import addon_utils
import bmesh
import bpy

addon_utils.enable("HumGen3D", default_set=True)
from HumGen3D import Human  # noqa: E402

BAKE = 2048
HAIR = (0.018, 0.012, 0.009, 1.0)
# Strand colour per exported blend (linear); HG's Lightness/Redness only reach its own shader.
HAIR_BY_STEM = {"kit_hg": (0.06, 0.034, 0.018, 1.0)}


def haircards(h: Human) -> list:
    """Particle hair → thin ribbon strips, plus a hair-coloured scalp in the bake.
    HG's own convert_to_haircards needs hair/haircards/* which the trial lacks
    (Errno 2 on HairMediumLength_zones.json), so this is a stand-in."""
    global HAIR
    HAIR = HAIR_BY_STEM.get(Path(bpy.data.filepath).stem, HAIR)
    body = h.objects.body
    objs = []
    for m in [m for m in body.modifiers if m.type == "PARTICLE_SYSTEM"]:
        st = m.particle_system.settings
        if not (m.show_render and m.show_viewport) or st.count == 0:
            continue
        # HG female content names head systems A_base_*/B_strands, not hair_*:
        # only eyebrow/eyelash systems take the fine-brow branch.
        head = not m.particle_system.name.lower().startswith(("eyebrow", "brow", "eyelash"))
        if head:  # ~3000 strands per system: enough to read as hair, cheap in Godot
            st.child_percent = max(1, min(100, int(100 * 3000 / (st.count * max(1, st.rendered_child_count)))))
        else:  # brows: fewer, finer hairs so they read as hair, not a painted bar
            st.child_percent = 45
        for x in bpy.context.selected_objects:
            x.select_set(False)
        bpy.context.view_layer.objects.active = body
        body.select_set(True)
        before = set(bpy.data.objects)
        bpy.ops.object.modifier_convert(modifier=m.name)
        ob = next(o for o in bpy.data.objects if o not in before)
        for x in bpy.context.selected_objects:
            x.select_set(False)
        ob.select_set(True)
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.convert(target="CURVE")
        ob.data.extrude = 0.0009 if head else 0.00018
        ob.data.twist_mode = "MINIMUM"
        bpy.ops.object.convert(target="MESH")
        ob.name = ("Hair_" if head else "Brow_") + m.particle_system.name
        mat = bpy.data.materials.new("Hair_Strands")
        bsdf = next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        bsdf.inputs["Base Color"].default_value = HAIR
        bsdf.inputs["Roughness"].default_value = 0.42
        ob.data.materials.clear()
        ob.data.materials.append(mat)
        # skin to the head bone
        vg = ob.vertex_groups.new(name="head")
        vg.add(list(range(len(ob.data.vertices))), 1.0, "REPLACE")
        arm = ob.modifiers.new("arm", "ARMATURE")
        arm.object = h.objects.rig
        ob.parent = h.objects.rig
        print("DBG strands", ob.name, len(ob.data.polygons))
        objs.append(ob)
    for m in [m for m in body.modifiers if m.type == "PARTICLE_SYSTEM"]:
        body.modifiers.remove(m)
    return objs


def scalp_zone(body: bpy.types.Object, strands: list, z_min: float) -> None:
    """Mark scalp skin under the strands ('scalp' attribute, mixed to hair colour
    in the bake), so gaps between strands read as hair, not skin. Only above
    z_min (just over the eyes): long hair hanging past the cheeks otherwise
    paints the face hair-coloured (c03 HG Kit read as bearded in game)."""
    from mathutils.kdtree import KDTree
    pts = [o.matrix_world @ v.co for o in strands if o.name.startswith("Hair_") for v in o.data.vertices]
    kd = KDTree(len(pts))
    for i, p in enumerate(pts):
        kd.insert(p, i)
    kd.balance()
    att = body.data.color_attributes.new("scalp", "FLOAT_COLOR", "POINT")
    vals = []
    # Evaluated positions (shape keys + pose), where the strands are: the raw
    # base-mesh coordinates sit elsewhere and painted a beard on Kit (c03).
    # Keep topology: evaluate with only the armature modifier on.
    off = [m for m in body.modifiers if m.type != "ARMATURE" and m.show_viewport]
    for m in off:
        m.show_viewport = False
    ev = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
    me = ev.to_mesh()
    for m in off:
        m.show_viewport = True
    assert len(me.vertices) == len(body.data.vertices), (len(me.vertices), len(body.data.vertices))
    for v in me.vertices:
        w = body.matrix_world @ v.co
        _co, _i, d = kd.find(w)
        f = 0.0 if d is None or w.z < z_min else max(0.0, min(1.0, (0.012 - d) / 0.006))
        vals.extend((f, f, f, 1.0))
    ev.to_mesh_clear()
    att.data.foreach_set("color", vals)
    print("DBG scalp marked", sum(1 for i in range(0, len(vals), 4) if vals[i] > 0), "of", len(vals) // 4, flush=True)


def bake_surface(ob: bpy.types.Object, out: Path) -> tuple:
    """Bake the intact skin shader before albedo cleanup removes its inputs."""
    nt = ob.data.materials[0].node_tree
    bump = next(n for n in nt.nodes if n.type == "BUMP")
    bump.inputs["Strength"].default_value = 0.0
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 4
    sc.cycles.device = "GPU"
    for o in bpy.context.selected_objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    images = []
    for name, bake_type in (("skin_rough", "ROUGHNESS"), ("skin_normal", "NORMAL")):
        img = bpy.data.images.new(name, BAKE, BAKE)
        img.colorspace_settings.name = "Non-Color"
        targets = []
        for i, mat in enumerate(ob.data.materials):
            tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
            tex.image = img if i == 0 else bpy.data.images.new("_surface_scratch", 8, 8)
            mat.node_tree.nodes.active = tex
            targets.append((mat.node_tree, tex))
        if bake_type == "NORMAL":
            bpy.ops.object.bake(type=bake_type, normal_space="TANGENT", margin=8)
        else:
            bpy.ops.object.bake(type=bake_type, margin=8)
        img.filepath_raw = str(out / f"{name}.png")
        img.file_format = "PNG"
        img.save()
        for tree, tex in targets:
            scratch = tex.image if tex.image != img else None
            tree.nodes.remove(tex)
            if scratch:
                bpy.data.images.remove(scratch)
        images.append(img)
    return tuple(images)


def export_surface(ob: bpy.types.Object, rough: bpy.types.Image, normal: bpy.types.Image) -> None:
    """Replace the original skin normal and roughness graph with baked maps."""
    nt = ob.data.materials[0].node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    for n in list(nt.nodes):
        if n.type in ("BUMP", "NORMAL_MAP") or (
                n.type == "TEX_IMAGE" and n.image and n.image.name.startswith("aged_layer_normal_4K")):
            nt.nodes.remove(n)
    rt = nt.nodes.new("ShaderNodeTexImage")
    rt.image = rough
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nt.links.new(rt.outputs["Color"], sep.inputs[0])
    nt.links.new(sep.outputs["Green"], bsdf.inputs["Roughness"])
    for n in list(nt.nodes):
        if n.type == "MATH" and not n.outputs[0].links:
            nt.nodes.remove(n)
    normal_tex = nt.nodes.new("ShaderNodeTexImage")
    normal_tex.image = normal
    normal_map = nt.nodes.new("ShaderNodeNormalMap")
    normal_map.inputs["Strength"].default_value = 1.0
    nt.links.new(normal_tex.outputs["Color"], normal_map.inputs["Color"])
    nt.links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])


def bake_albedo(ob: bpy.types.Object, name: str, out: Path, slot: int = 0) -> bpy.types.Image:
    """Bake the material's Base Color input through an emission shader."""
    mat = ob.data.materials[slot]
    nt = mat.node_tree
    bsdf = next(n for n in nt.nodes if n.type == "BSDF_PRINCIPLED")
    outn = next(n for n in nt.nodes if n.type == "OUTPUT_MATERIAL")
    link = bsdf.inputs["Base Color"].links
    src = link[0].from_socket if link else None
    if src is None:
        rgb = nt.nodes.new("ShaderNodeRGB")
        rgb.outputs[0].default_value = bsdf.inputs["Base Color"].default_value
        src = rgb.outputs[0]
    if ob.data.color_attributes.get("scalp"):
        sa = nt.nodes.new("ShaderNodeVertexColor")
        sa.layer_name = "scalp"
        mx = nt.nodes.new("ShaderNodeMix")
        mx.data_type = "RGBA"
        nt.links.new(sa.outputs["Color"], mx.inputs["Factor"])
        nt.links.new(src, mx.inputs["A"])
        mx.inputs["B"].default_value = tuple(c * 1.4 for c in HAIR[:3]) + (1,)
        src = mx.outputs["Result"]
    em = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(src, em.inputs["Color"])
    nt.links.new(em.outputs[0], outn.inputs["Surface"])
    img = bpy.data.images.new(name, BAKE, BAKE)
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = img
    nt.nodes.active = tex
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.samples = 4
    sc.cycles.device = "GPU"
    for o in bpy.context.selected_objects:
        o.select_set(False)
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    # only the baked slot's faces matter; others bake into the same image harmlessly
    for i, m in enumerate(ob.data.materials):
        if i != slot:
            t2 = m.node_tree.nodes.new("ShaderNodeTexImage")
            t2.image = bpy.data.images.new("_scratch", 8, 8)
            m.node_tree.nodes.active = t2
    bpy.ops.object.bake(type="EMIT", margin=8)
    img.filepath_raw = str(out / f"{name}.png")
    img.file_format = "PNG"
    img.save()
    nt.links.new(bsdf.outputs[0], outn.inputs["Surface"])
    nt.nodes.remove(em)
    # simple glTF-friendly graph: baked image → Base Color
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    for n in list(nt.nodes):
        if n.type in ("VERTEX_COLOR", "MIX", "TEX_NOISE", "SEPARATE_COLOR") or (
                n.type == "MATH" and not n.outputs[0].links):
            nt.nodes.remove(n)
    return img


def bake_base_keys(ob: bpy.types.Object) -> None:
    """Fold HG's base keys (Male/Female, LIVE_KEY_*) and our eddington_face into
    the mesh, as HG's own exporter does (_apply_base_shape_keys); every other key
    keeps its offset. Without this Godot shows the raw base head (morph weights
    default 0) and the eye sockets no longer meet the eyeballs. `female` matters
    for the c03 Kit bake-off, whose body is the female base."""
    keys = ob.data.shape_keys
    if not keys:
        return
    kb = keys.key_blocks
    basis = kb[0]
    n = len(ob.data.vertices)
    folded = []
    for name in [k.name for k in kb[1:]]:
        if not name.lower().startswith(("male", "female", "live_key", "eddington_face")):
            continue
        folded.append(name)
        sk = kb[name]
        rel = sk.relative_key
        delta = [(sk.data[i].co - rel.data[i].co) * sk.value for i in range(n)]
        for other in kb:
            if other.name == name:
                continue
            for i in range(n):
                other.data[i].co += delta[i]
        ob.shape_key_remove(sk)
    for i in range(n):
        ob.data.vertices[i].co = basis.data[i].co
    print("DBG baked keys", ob.name, folded, len(ob.data.shape_keys.key_blocks))


def drop_masked(body: bpy.types.Object) -> None:
    m = next((m for m in body.modifiers if m.type == "MASK"), None)
    if not m:
        return
    vg = body.vertex_groups[m.vertex_group].index
    bm = bmesh.new()
    bm.from_mesh(body.data)
    dl = bm.verts.layers.deform.active
    kill = [v for v in bm.verts if dl and v[dl].get(vg, 0.0) > 0.5]
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    bm.to_mesh(body.data)
    bm.free()
    body.modifiers.remove(m)


def idle_action(rig: bpy.types.Object) -> None:
    rig.animation_data_create()
    act = bpy.data.actions.new("idle")
    rig.animation_data.action = act
    for pb in rig.pose.bones:
        if pb.rotation_mode == "QUATERNION" and tuple(pb.rotation_quaternion) == (1, 0, 0, 0) and pb.name != "head":
            continue
        for f in (1, 2):
            pb.keyframe_insert("rotation_quaternion" if pb.rotation_mode == "QUATERNION" else "rotation_euler", frame=f)
            pb.keyframe_insert("location", frame=f)


def main() -> None:
    out = Path(sys.argv[sys.argv.index("--") + 1])
    rig = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    h = Human.from_existing(rig)
    body = h.objects.body
    native = bpy.data.objects.get("HG_Suit") is None
    if native:
        cards = [h.hair.regular_hair.convert_to_haircards("high", bpy.context),
                 h.hair.eyebrows.convert_to_haircards("high", bpy.context)]
        for o in cards:
            print("HG_CARD", o.name, "faces", len(o.data.polygons), "materials",
                  [(m.name, [n.image.name for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image])
                   for m in o.data.materials if m and m.use_nodes], flush=True)
        baking = h.process.baking
        baking.resolution_body = 4096
        baking.resolution_clothes = 2048
        baking.resolution_eyes = 1024
        # HG's baker requires a linked source for every non-normal bake. The
        # painted skin uses the Principled default specular, so expose that same
        # value as a node without changing the shader's appearance.
        skin = body.data.materials[0]
        bsdf = next(n for n in skin.node_tree.nodes if n.type == "BSDF_PRINCIPLED")
        spec = bsdf.inputs.get("Specular IOR Level") or bsdf.inputs.get("Specular")
        if spec and not spec.is_linked:
            value = skin.node_tree.nodes.new("ShaderNodeValue")
            value.outputs[0].default_value = spec.default_value
            skin.node_tree.links.new(value.outputs[0], spec)
            print("HG_SKIN_SPECULAR", spec.name, value.outputs[0].default_value, flush=True)
        print("HG_BAKE_LIST", [(b.bake_object.name, b.material_slot, b.texture_type) for b in baking.get_baking_list()], flush=True)
        print("HG_SKIN_BUMP", [(m.name, n.inputs["Strength"].default_value)
              for m in body.data.materials if m and m.use_nodes for n in m.node_tree.nodes if n.type == "BUMP"], flush=True)
        bake_dir = out / "bake"
        bake_dir.mkdir(parents=True, exist_ok=True)
        baking.bake_all(folder_path=str(bake_dir), samples=4)
        for img in bpy.data.images:
            if img.filepath_raw and Path(bpy.path.abspath(img.filepath_raw)).parent == bake_dir:
                print("HG_BAKE_IMAGE", img.filepath_raw, tuple(img.size), flush=True)
        garments = list(h.clothing.outfit.objects) + list(h.clothing.footwear.objects)
    else:
        cards = haircards(h)
        eyes_ev = h.objects.eyes.evaluated_get(bpy.context.evaluated_depsgraph_get())
        eyes_top = max((h.objects.eyes.matrix_world @ v.co).z for v in eyes_ev.to_mesh().vertices)
        eyes_ev.to_mesh_clear()
        scalp_zone(body, cards, eyes_top + 0.02)
        rough, normal = bake_surface(body, out)
        bake_albedo(body, "skin_albedo", out)
        export_surface(body, rough, normal)
        eyes = h.objects.eyes
        inner = next(i for i, m in enumerate(eyes.data.materials) if "Inner" in m.name)
        bake_albedo(eyes, "eye_albedo", out, inner)
        suit = bpy.data.objects["HG_Suit"]
        for m in [m for m in suit.modifiers if m.type == "SUBSURF"]:
            suit.modifiers.remove(m)
        for p in suit.data.polygons:
            p.use_smooth = True
        bake_albedo(suit, "suit_albedo", out)
        garments = [suit]
    for o in (body, h.objects.eyes, h.objects.lower_teeth, h.objects.upper_teeth):
        bake_base_keys(o)
    drop_masked(body)
    idle_action(rig)
    objs = [rig, body, h.objects.eyes, h.objects.lower_teeth, h.objects.upper_teeth] + garments + cards
    if body.data.shape_keys:
        assert all(len(k.data) == len(body.data.vertices) for k in body.data.shape_keys.key_blocks)
    glasses = bpy.data.objects.get("Kit_Glasses")  # procedural, parented to the head bone
    if glasses:
        objs.append(glasses)
    for o in bpy.data.objects:
        o.select_set(o in objs)
    print("DBG export", [(o.name, o.type, len(o.data.vertices) if o.type == "MESH" else 0,
                          len(o.data.shape_keys.key_blocks) if o.type == "MESH" and o.data.shape_keys else 0) for o in objs])
    bpy.ops.export_scene.gltf(filepath=str(out / (Path(bpy.data.filepath).stem + ".glb")), export_format="GLB", use_selection=True,
                              export_apply=False, export_morph=True, export_skins=True, export_animations=True,
                              export_copyright="Human Generator Asset License — not for redistribution")
    print("HG_GLB_BYTES", (out / (Path(bpy.data.filepath).stem + ".glb")).stat().st_size, flush=True)


main()
