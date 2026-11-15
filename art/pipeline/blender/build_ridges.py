"""Composed Príncipe skyline, in Blender metres (Z up)."""
import math
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.dont_write_bytecode = True
import bpy
import kit

N = 480

def window(angle, start, end, fade):
    a = (angle - start) % 360
    span = (end - start) % 360
    if a <= span:
        return 1.0
    d = min(a - span, 360 - a)
    return 0.5 + 0.5 * math.cos(math.pi * d / fade) if d < fade else 0.0

def noise(t, phase):
    return (math.sin(5*t + phase) + 0.45*math.sin(10*t + 1.7*phase)
            + 0.2*math.sin(15*t - phase) + 0.22*math.sin(27*t + 2.3*phase)
            + 0.12*math.sin(52*t - 0.7*phase)) / 1.99

def tower(x, points):
    for (left, bottom), (right, top) in zip(points, points[1:]):
        if left <= x <= right:
            return bottom + (top-bottom)*(x-left)/(right-left)
    return 0.0

def build(name, index):
    verts, faces = [], []
    angles = [360*i/N for i in range(N)]
    if index == 2:
        angles = ([0.75*i for i in range(160)]
                  + [120 + 0.25*i for i in range(280)]
                  + [190 + 0.75*i for i in range(227)])
    towers = []
    for deg in angles:
        towers.append(tower(math.radians(deg-140)*470, [
            (-44, 0), (-30, 5), (-21, 14), (-15, 34), (-11, 52),
            (-7, 61), (-3, 65), (2, 65), (6, 60), (9, 44),
            (11, 20), (14, 8), (24, 0)])
            + tower(math.radians(deg-168)*470, [
            (-30, 0), (-20, 4), (-13, 12), (-9, 26), (-5, 32),
            (0, 33), (4, 30), (7, 20), (10, 8), (18, 0)]))
    towers = [(towers[i-1] + 2*h + towers[(i+1) % len(angles)])/4
              for i, h in enumerate(towers)]
    phase = 0.0
    if index == 0:
        near_radii = []
        for deg in angles:
            t = math.radians(deg)
            low = window(deg, 300, 345, 20)
            near_radii.append((112 + 14*noise(t, 2.3))*(1-low)
                              + (101 + 4*noise(t, 2.3))*low)
        steps = []
        for i, deg in enumerate(angles):
            t = math.radians(deg)
            ds = (near_radii[i-1] + near_radii[i])/2 * (2*math.pi/N)
            period = 11 + 3.5*math.sin(7*t + 0.6) + 1.5*math.sin(19*t + 2.1)
            steps.append(ds/period)
        total = sum(steps)
        phase_scale = round(total)/total
    for i, deg in enumerate(angles):
        t = math.radians(deg)
        low = window(deg, 290 if index else 300, 350 if index else 345,
                     20 if index == 0 else 14)
        n = noise(t, 1.2 + index)
        if index == 0:
            radius = near_radii[i]
            if i:
                phase += steps[i]*phase_scale
            billow = (0.7 + 0.3*math.sin(13*t + 1.1)) * (2*abs(math.sin(math.pi*phase)) - 1)
            height = (11.5 + 3.5*n)*(1-low) + (6 + 0.5*math.sin(8*t))*low + billow
            if 300 <= deg <= 345:
                assert 4.5 <= height <= 7.5, (deg, height)
            width = 22
        elif index == 1:
            radius = 230 + 26*noise(t, 3.4)
            height = 31 + 7*n
            height += (45-height)*window(deg, 59, 61, 20)
            height += (40-height)*window(deg, 204, 206, 22)
            height = height*(1-low) + (11.5 + 2.5*math.cos(12*(t-math.radians(300))))*low
            width = 29
        else:
            radius = 470 + 40*noise(t, 4.5)
            height = 55 + 12*n
            mass = window(deg, 125, 185, 15)
            massif_height = 90 + 4*math.sin(4*(t-math.radians(125))) + 1.2*math.sin(27*t) + 0.8*math.sin(52*t)
            height = height*(1-mass) + massif_height*mass + towers[i]
            radius = radius*(1-mass) + (470 + 5*noise(t, 4.5))*mass
            height = height*(1-low) + (22.5 + 3.5*noise(t, 6.1))*low
            width = 34
        gully = (1 + (math.sin(40*t + index) + 0.5*math.sin(90*t - index))/1.5)/2
        previous_r = -math.inf
        for row in range(9):
            u = (row - 4) / 4
            r = radius + width*u
            assert r > previous_r, (name, deg, row)
            previous_r = r
            y = -2 + (height+2)*(1 - abs(u)**0.65)
            if 0 < row < 8 and row != 4:
                y -= 0.12*height*gully*math.sin(math.pi*abs(u))
            verts.append((r*math.sin(t), r*math.cos(t), y))
    for i in range(len(angles)):
        j = (i+1) % len(angles)
        for row in range(8):
            faces.append((i*9+row, j*9+row, j*9+row+1, i*9+row+1))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    mesh.materials.append(kit.mat('hill_near' if index == 0 else 'hill_far'))
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    return obj

def main():
    kit.reset()
    kit.export('assets/models/principe_ridges.glb', [
        build('principe_ridges_near', 0), build('principe_ridges_mid', 1),
        build('principe_ridges_far', 2)])

if __name__ == '__main__':
    main()
