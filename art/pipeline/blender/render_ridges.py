"""Render the six skyline bearings and their silhouettes."""
import math
from pathlib import Path
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / 'art/validation/p3-ridges'
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT / 'assets/models/principe_ridges.glb'))
ridges = [o for o in bpy.context.scene.objects if o.type == 'MESH']

def rgb(value):
    values = [int(value[i:i+2], 16)/255 for i in (0, 2, 4)]
    return tuple(c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4 for c in values)

def material(name, color, emission=False):
    m = bpy.data.materials.new(name)
    m.diffuse_color = (*rgb(color), 1)
    m.use_nodes = True
    nodes = m.node_tree.nodes
    if emission:
        nodes.clear()
        shader = nodes.new('ShaderNodeEmission')
        shader.inputs['Color'].default_value = (*rgb(color), 1)
        output = nodes.new('ShaderNodeOutputMaterial')
        m.node_tree.links.new(shader.outputs[0], output.inputs['Surface'])
    else:
        nodes.get('Principled BSDF').inputs['Base Color'].default_value = (*rgb(color), 1)
    return m

bpy.ops.mesh.primitive_circle_add(vertices=128, radius=70, fill_type='NGON')
bpy.context.object.data.materials.append(material('ground', '3F5A2A'))
world = bpy.data.worlds.new('sky')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (*rgb('C9D2D6'), 1)
bpy.context.scene.world = world
bpy.ops.object.light_add(type='SUN')
sun = bpy.context.object
bearing, altitude = map(math.radians, (-38, 56))
direction = Vector((math.sin(bearing)*math.cos(altitude), math.cos(bearing)*math.cos(altitude), math.sin(altitude)))
sun.rotation_euler = (-direction).to_track_quat('-Z', 'Y').to_euler()
sun.data.energy = 2
bpy.ops.object.camera_add(location=(0, 0, 1.6))
camera = bpy.context.object
camera.data.sensor_fit = 'VERTICAL'
camera.data.angle = math.radians(60)
scene = bpy.context.scene
scene.camera = camera
scene.render.resolution_x, scene.render.resolution_y = 1280, 720
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
for silhouette in (False, True):
    if silhouette:
        black = material('silhouette', '101418', True)
        for obj in ridges:
            obj.data.materials.clear()
            obj.data.materials.append(black)
    for angle in (-37, -20, 52, 142, 200, 270):
        t = math.radians(angle)
        direction = Vector((math.sin(t)*math.cos(math.radians(6)), math.cos(t)*math.cos(math.radians(6)), math.sin(math.radians(6))))
        camera.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = str(OUT / (('silhouette_' if silhouette else 'view_') + str(angle) + '.png'))
        bpy.ops.render.render(write_still=True)
