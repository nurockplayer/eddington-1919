"""RECONSTRUCTION: small field-darkroom equipment, built in metres."""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import bpy
import kit


def mesh(name, vertices, faces, material, smooth=False):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    data.materials.append(kit.mat(material))
    if smooth:
        for face in data.polygons:
            face.use_smooth = True
    return obj


def lathe(name, profile, material):
    n = 24
    vertices = [(r * math.cos(i * 2 * math.pi / n), r * math.sin(i * 2 * math.pi / n), z)
                for r, z in profile for i in range(n)]
    faces = [tuple(reversed(range(n))), tuple((len(profile) - 1) * n + i for i in range(n))]
    faces += [(j*n+i, j*n+(i+1)%n, (j+1)*n+(i+1)%n, (j+1)*n+i)
              for j in range(len(profile)-1) for i in range(n)]
    return mesh(name, vertices, faces, material, True)


def outline(x, y, z):
    c = 0.012
    return [(-x+c,-y,z), (x-c,-y,z), (x,-y+c,z), (x,y-c,z),
            (x-c,y,z), (-x+c,y,z), (-x,y-c,z), (-x,-y+c,z)]


def tray():
    rings = [outline(.15,.12,0), outline(.17,.14,.05), outline(.163,.133,.046), outline(.144,.114,.005)]
    verts = sum(rings, [])
    faces = [tuple(reversed(range(8))), tuple(range(24,32))]
    faces += [(j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i)
              for j in range(3) for i in range(8)]
    body = mesh('tray', verts, faces, 'enamel')
    rim = mesh('rim', rings[1]+outline(.165,.135,.047),
               [(i,(i+1)%8,8+(i+1)%8,8+i) for i in range(8)], 'iron')
    liquid = mesh('liquid', outline(.157,.127,.04), [tuple(range(8))], 'tray_liquid')
    return [body,rim,liquid]


def bottle():
    parts = [lathe('glass', [(.043,0),(.045,.008),(.045,.15),(.042,.164),(.019,.195),(.0175,.215),(.022,.218),(.022,.225)], 'amber_glass'),
             kit.cyl('cork', .017, .015, (0,0,.2325), 'pine', verts=24, bevel=0),
             kit.box('label', (.05,.001,.06), (0,-.0455,.09), 'canvas', bevel=0)]
    return parts


def holder():
    p = [kit.box('frame',(.32,.27,.025),(0,0,.0125),'teak_dark',bevel=.002),
         kit.box('slide',(.27,.21,.002),(0,0,.026),'ebonite',bevel=0)]
    for x in (-.137,.137):
        for y in (-.112,.112):
            p.append(kit.box('clip',(.025,.014,.003),(x,y,.0275),'brass',bevel=0))
    p.append(kit.box('tab',(.02,.035,.004),(0,-.13,.028),'brass',bevel=0))
    return p


def rack():
    p = [kit.box('base',(.30,.16,.018),(0,0,.009),'teak',bevel=.003)]
    for x in (-.142,.142):
        p.append(kit.box('rail',(.016,.16,.03),(x,0,.025),'teak',bevel=.002))
    for i in range(6):
        p.append(kit.box('plate',(.254,.003,.203),(0,-.055+i*.022,.12),'plate_dark',rot=(6,0,0),bevel=0))
    return p


def pail():
    p = [lathe('pail',[(.10,0),(.135,.24),(.13,.24),(.095,.008)],'zinc'),
         kit.torus('rim',.135,.005,(0,0,.24),'zinc',major_seg=24,minor_seg=4)]
    # Bail rests against one side, kept within the pail's footprint.
    p.append(kit.torus('bail',.105,.002,(0,0,.151),'zinc',rot=(72,0,0),major_seg=24,minor_seg=4))
    return p


def jug():
    p = [lathe('jug',[(.065,0),(.075,.01),(.08,.06),(.078,.16),(.068,.22),(.068,.235),(.063,.235),(.063,.219)],'enamel'),
         kit.torus('rim',.068,.003,(0,0,.235),'iron',major_seg=24,minor_seg=3),
         kit.torus('handle',.05,.004,(.035,0,.12),'iron',rot=(90,0,0),major_seg=24,minor_seg=3)]
    # The pointed pouring lip sits at the front of the rim.
    p.append(mesh('spout',[(-.02,-.065,.23),(.02,-.065,.23),(0,-.079,.235)],[(0,1,2)],'enamel'))
    return p


def plate_box():
    return [kit.box('body',(.30,.24,.051),(0,0,.0255),'pine',bevel=.002),
            kit.box('lid',(.30,.24,.018),(0,0,.061),'pine',bevel=.002),
            kit.box('label',(.10,.07,.001),(0,0,.0705),'canvas',bevel=0)]


def main():
    kit.reset()
    for name, build in [('dr_tray',tray),('dr_bottle',bottle),('dr_plate_holder',holder),
                        ('dr_plate_rack',rack),('dr_pail',pail),('dr_jug',jug),('dr_plate_box',plate_box)]:
        bpy.ops.object.select_all(action='SELECT')
        bpy.ops.object.delete(use_global=False)
        obj = kit.join(name, build())
        bpy.context.view_layer.update()
        kit.set_origin(obj, kit.bottom_centre([obj]))
        obj.location = (0,0,0)
        kit.export('assets/models/' + name + '.glb', [obj])


if __name__ == '__main__':
    main()
