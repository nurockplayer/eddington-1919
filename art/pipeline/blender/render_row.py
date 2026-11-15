"""Render imported prop GLBs on a neutral floor, or the warm bench arrangement."""
import math
import sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index('--') + 1:]
out, paths = args[0], args[1:]
bench = Path(out).stem == 'bench'
closeup = Path(out).stem == 'closeup'
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = 1600, 600, 100
scene.render.image_settings.file_format = 'PNG'
scene.world = bpy.data.worlds.new('World')
scene.world.use_nodes = True
background = scene.world.node_tree.nodes['Background']
background.inputs['Color'].default_value = ((.025,.022,.02,1) if bench else (.18,.18,.18,1))
background.inputs['Strength'].default_value = .15 if bench else .55


def import_prop(path, position=None):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(Path(path).resolve()))
    objects = [o for o in bpy.context.scene.objects if o not in before and o.type == 'MESH']
    if position is not None:
        for o in objects:
            o.location += Vector(position)
    return objects


def bounds(objects):
    pts = [o.matrix_world @ Vector(c) for o in objects for c in o.bound_box]
    return min(p.x for p in pts), max(p.x for p in pts)


if bench:
    for x in (-.45, 0, .45):
        import_prop(paths[0], (x,0,0))
        import_prop(paths[1], (x,.29,0))
    import_prop(paths[2], (.85,.05,0))
    centre, span = Vector((.18,.12,.10)), 1.75
else:
    x = 0
    for path in paths:
        objs = import_prop(path)
        if closeup and Path(path).stem == 'dr_jug':
            for o in objs:
                o.matrix_world = Matrix.Rotation(math.pi/2,4,'Z') @ o.matrix_world
        bpy.context.view_layer.update()
        lo, hi = bounds(objs)
        for o in objs:
            o.location.x += x - lo
        x += hi - lo + .13
    centre, span = Vector(((x-.13)/2,0,.12)), x

floor = bpy.data.materials.new('floor')
floor.diffuse_color = (.075,.075,.075,1) if bench else (.3,.3,.3,1)
bpy.ops.mesh.primitive_plane_add(size=200, location=(0,0,-.002))
bpy.context.object.data.materials.append(floor)
light_data = bpy.data.lights.new('key', 'POINT' if bench else 'SUN')
light_data.energy = 200 if bench else 2
if bench:
    light_data.color = (1,.80,.58)
    light_data.shadow_soft_size = .45
light = bpy.data.objects.new('key', light_data)
bpy.context.collection.objects.link(light)
light.location = (centre.x + 1, -1, 2.5) if bench else (centre.x - 2, -3, 5)
light.rotation_euler = (Vector(centre) - light.location).to_track_quat('-Z','Y').to_euler()
camera_data = bpy.data.cameras.new('Camera')
camera = bpy.data.objects.new('Camera', camera_data)
bpy.context.collection.objects.link(camera)
camera.location = centre + Vector((span*.26,-span*.85,span*.55))
camera.rotation_euler = (centre-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type = 'ORTHO'
camera_data.ortho_scale = span * 1.18
scene.camera = camera
scene.render.filepath = str(Path(out).resolve())
bpy.ops.render.render(write_still=True)
