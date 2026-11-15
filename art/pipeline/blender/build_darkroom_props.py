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


def sharpen(obj, deg):
    data = obj.data
    data.update()
    data.set_sharp_from_angle(angle=math.radians(deg))
    for face in data.polygons[:2]:
        for loop in face.loop_indices:
            data.edges[data.loops[loop].edge_index].use_edge_sharp = True
    data.update()


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
    # Interpolate the inner wall at the surface, then leave a 1 mm gap.
    t = (.03-.005)/(.046-.005)
    liquid = mesh('liquid', outline(.144+(.163-.144)*t-.001,
                                   .114+(.133-.114)*t-.001,.03),
                  [tuple(range(8))], 'tray_liquid')
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
    p = [lathe('pail',[(.10,0),(.135,.232),(.141,.236),(.143,.242),
                       (.139,.247),(.133,.245),(.130,.238),(.095,.008)],'zinc')]
    body = p[0]
    sharpen(body, 75)
    # Split the wall from the first rolled-rim band as well as the bottom cap.
    for face in body.data.polygons[2:26]:
        body.data.edges[body.data.loops[face.loop_start+2].edge_index].use_edge_sharp = True
    body.data.update()
    wall_z = [body.data.corner_normals[loop].vector.z
              for face in body.data.polygons[2:26] for loop in face.loop_indices]
    print(f'pail outer wall corner normal z: min={min(wall_z):.6f} max={max(wall_z):.6f}', flush=True)
    assert all(abs(z) < .3 for z in wall_z), 'pail outer wall corner normals'
    # Half a wire ring, swung 80 degrees from upright toward -Y.
    tilt = math.radians(80)
    vertices = []
    for i in range(15):
        angle = math.pi*i/14
        for j in range(6):
            wire = 2*math.pi*j/6
            radius = .142+.004*math.cos(wire)
            normal = .004*math.sin(wire)
            vertices.append((radius*math.cos(angle),
                             -radius*math.sin(angle)*math.sin(tilt)+normal*math.cos(tilt),
                             .240+radius*math.sin(angle)*math.cos(tilt)+normal*math.sin(tilt)))
    faces = [tuple(reversed(range(6))), tuple(range(84,90))]
    faces += [(i*6+j,i*6+(j+1)%6,(i+1)*6+(j+1)%6,(i+1)*6+j)
              for i in range(14) for j in range(6)]
    p.append(mesh('bail',vertices,faces,'zinc',True))
    for x in (-.139,.139):
        p.append(kit.box('ear',(.012,.004,.024),(x,0,.240),'zinc',bevel=0))
    return p


def jug():
    body = lathe('jug',[(.060,0),(.068,.008),(.080,.07),(.076,.13),(.058,.19),
                        (.056,.205),(.066,.24),(.062,.24),(.053,.205),
                        (.072,.10),(.056,.012)],'enamel')
    limit = math.radians(35)
    for vertex in body.data.vertices:
        x,y,z = vertex.co
        angle = math.atan2(x,-y)
        if z >= .20 and abs(angle) <= limit:
            offset = .02*math.cos(angle/limit*math.pi/2)**2
            radius = math.hypot(x,y)
            vertex.co = (x*(1+offset/radius),y*(1+offset/radius),z+offset/5)
    sharpen(body, 75)
    # The band shares the displaced mouth vertices, so it follows the spout.
    body.data.materials.append(kit.mat('iron'))
    for face in body.data.polygons[2+6*24:2+7*24]:
        face.material_index = 1
    path = [(.058,.188),(.085,.196),(.108,.180),(.116,.150),
            (.112,.115),(.098,.088),(.078,.076)]
    path[0] = (path[0][0]-.003,path[0][1])
    path[-1] = (path[-1][0]-.003,path[-1][1])
    resampled = []
    for i in range(len(path)-1):
        p0,p1,p2,p3 = path[max(0,i-1)],path[i],path[i+1],path[min(len(path)-1,i+2)]
        resampled.append(p1)
        resampled.append(tuple((-p0[j]+9*p1[j]+9*p2[j]-p3[j])/16 for j in range(2)))
    resampled.append(path[-1])
    path = resampled
    vertices = []
    for i,(y,z) in enumerate(path):
        before,after = path[max(0,i-1)],path[min(len(path)-1,i+1)]
        dy,dz = after[0]-before[0],after[1]-before[1]
        length = math.hypot(dy,dz)
        for x,side in [(-.010,-1),(.010,-1),(.010,1),(-.010,1)]:
            vertices.append((x,y-side*.002*dz/length,z+side*.002*dy/length))
    faces = [tuple(range(4)),tuple(reversed(range(48,52)))]
    faces += [(i*4+j,(i+1)*4+j,(i+1)*4+(j+1)%4,i*4+(j+1)%4)
              for i in range(12) for j in range(4)]
    return [body,mesh('handle',vertices,faces,'enamel')]


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
