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
    return (math.sin(5*t + phase) + 0.45*math.sin(10*t + 1.7*phase) + 0.2*math.sin(15*t - phase)) / 1.65

def build(name, index):
    verts, faces = [], []
    for i in range(N):
        t = 2 * math.pi * i / N
        deg = 360 * i / N
        low = window(deg, 290 if index else 300, 350 if index else 345, 14)
        n = noise(t, 1.2 + index)
        if index == 0:
            radius = 112 + 14*noise(t, 2.3)
            height = 11.5 + 4*n + 1.2*math.sin(2*math.pi*radius*t/8)
            radius = radius*(1-low) + 100*low
            height = height*(1-low) + 5*low
            width = 22
        elif index == 1:
            radius = 230 + 26*noise(t, 3.4)
            height = 31 + 7*n
            height += (45-height)*window(deg, 59, 61, 20)
            height += (40-height)*window(deg, 204, 206, 22)
            height = height*(1-low) + 7*low
            width = 29
        else:
            radius = 470 + 40*noise(t, 4.5)
            height = 55 + 12*n
            mass = window(deg, 125, 185, 15)
            height = height*(1-mass) + 95*mass
            height += 55*window(deg, 138.5, 141.5, 4.7)
            height += 25*window(deg, 166.5, 169.5, 3.4)
            height = height*(1-low) + 28*low
            width = 34
        for row in range(9):
            u = (row - 4) / 4
            r = radius + width*u
            y = -2 + (height+2)*(1 - abs(u)**0.65)
            if 0 < row < 8 and row != 4:
                r += height*0.12*math.sin(math.pi*abs(u))*noise(t*3, index+row*0.8)
            verts.append((r*math.sin(t), r*math.cos(t), y))
    for i in range(N):
        j = (i+1) % N
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
    kit.export('assets/models/principe_ridges.glb', [build('ridge_near', 0), build('ridge_mid', 1), build('ridge_far', 2)])

if __name__ == '__main__':
    main()
