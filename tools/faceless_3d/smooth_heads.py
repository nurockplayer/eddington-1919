#!/usr/bin/env python3
"""Apply row 8's unfinished faces after build_person.py; only skin data changes.

Close the proxy's eye/mouth openings and fair their surrounding relief onto
smooth convex patches. Retain the nose, jaw, ears, accessories and skin weights.
Run once on freshly generated eddington.glb and cottingham.glb.
"""
import collections
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]


def smooth(name):
    path = ROOT / 'assets/models' / (name + '.glb')
    raw = path.read_bytes()
    size = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + size])
    blob = bytearray(raw[28 + size:])

    def read(index):
        a = doc['accessors'][index]
        view = doc['bufferViews'][a['bufferView']]
        width = {'SCALAR': 1, 'VEC3': 3}[a['type']]
        fmt = '<' + {5123: 'H', 5125: 'I', 5126: 'f'}[a['componentType']] * width
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        stride = view.get('byteStride', struct.calcsize(fmt))
        return [struct.unpack_from(fmt, blob, start + i * stride) for i in range(a['count'])]

    def append(data, kind, component):
        while len(blob) % 4:
            blob.append(0)
        fmt = '<' + {5125: 'I', 5126: 'f'}[component] * len(data[0])
        packed = b''.join(struct.pack(fmt, *v) for v in data)
        view = len(doc['bufferViews'])
        doc['bufferViews'].append({'buffer': 0, 'byteOffset': len(blob), 'byteLength': len(packed)})
        blob.extend(packed)
        a = {'bufferView': view, 'componentType': component, 'count': len(data), 'type': kind}
        if kind == 'VEC3':
            a.update(min=[min(v[i] for v in data) for i in range(3)],
                     max=[max(v[i] for v in data) for i in range(3)])
        doc['accessors'].append(a)
        return len(doc['accessors']) - 1

    node = next(n for n in doc['nodes'] if n.get('name') == name + '_body')
    prim = doc['meshes'][node['mesh']]['primitives'][0]
    positions = read(prim['attributes']['POSITION'])
    normals = read(prim['attributes']['NORMAL'])
    indices = [v[0] for v in read(prim['indices'])]
    # Weld UV seams only for finding the three anatomical openings. Keep the
    # original vertices/UVs/weights and all non-head triangles unchanged.
    representatives = {}
    welded = [representatives.setdefault(v, i) for i, v in enumerate(positions)]
    edges = collections.Counter()
    directed = {}
    for a, b, c in zip(indices[::3], indices[1::3], indices[2::3]):
        for u, v in [(a, b), (b, c), (c, a)]:
            u, v = welded[u], welded[v]
            key = tuple(sorted((u, v)))
            edges[key] += 1
            directed[key] = (u, v)
    boundary = {u: v for key, (u, v) in directed.items() if edges[key] == 1}
    loops = []
    while boundary:
        first = next(iter(boundary))
        loop, current = [], first
        while True:
            loop.append(current)
            current = boundary.pop(current)
            if current == first:
                break
        if all(positions[i][1] > 1.54 and positions[i][2] > .11 for i in loop):
            loops.append(loop)
    assert len(loops) == 3, f'{name}: expected two eye openings and one mouth, got {len(loops)}'
    mouth = min(sum(positions[i][1] for i in loop) / len(loop) for loop in loops)
    eye = max(sum(positions[i][1] for i in loop) / len(loop) for loop in loops)
    front = .152 if name == 'eddington' else .145

    def weight(value, inner, outer):
        t = max(0.0, min(1.0, (abs(value) - inner) / (outer - inner)))
        return 1 - t * t * (3 - 2 * t)

    def depth(x, y, z):
        for centre, halfwidth, curvature in [(eye, .070, 1.4), (mouth, .055, 2.0)]:
            w = weight(x, halfwidth * .7, halfwidth) * weight(y - centre, .018, .035)
            target = front - curvature * x * x - (y - centre) ** 2
            z += (target - z) * w
        return z

    changed = 0
    for i, (x, y, z) in enumerate(positions):
        if z < .11 or y < mouth - .035 or y > eye + .035:
            continue
        new_z = depth(x, y, z)
        if new_z == z:
            continue
        positions[i] = (x, y, new_z)
        # Analytic patch normals keep the ruling continuous over the filled
        # openings, including the proxy's former inward-facing lip vertices.
        epsilon = .0001
        dx = (depth(x + epsilon, y, z) - depth(x - epsilon, y, z)) / (2 * epsilon)
        dy = (depth(x, y + epsilon, z) - depth(x, y - epsilon, z)) / (2 * epsilon)
        length = math.sqrt(dx * dx + dy * dy + 1)
        normals[i] = (-dx / length, -dy / length, 1 / length)
        changed += 1
    for loop in loops:
        for j in range(1, len(loop) - 1):
            indices.extend((loop[0], loop[j + 1], loop[j]))
    prim['attributes']['POSITION'] = append(positions, 'VEC3', 5126)
    prim['attributes']['NORMAL'] = append(normals, 'VEC3', 5126)
    prim['indices'] = append([(i,) for i in indices], 'SCALAR', 5125)
    doc['buffers'][0]['byteLength'] = len(blob)
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    blob.extend(b'\0' * (-len(blob) % 4))
    path.write_bytes(struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(blob))
                     + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
                     + struct.pack('<II', len(blob), 0x004E4942) + blob)
    print(f'{name}: {changed} skin vertices faired; {len(loops)} openings closed')


if __name__ == '__main__':
    for person in ['eddington', 'cottingham']:
        smooth(person)
