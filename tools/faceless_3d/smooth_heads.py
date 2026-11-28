#!/usr/bin/env python3
"""Refit the Príncipe heads after build_person.py, using the unmodified exports."""
import argparse
import collections
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]


def smooth(name, source):
    path = ROOT / 'assets/models' / (name + '.glb')
    raw = (source / path.name).read_bytes()
    size = struct.unpack_from('<I', raw, 12)[0]
    doc = json.loads(raw[20:20 + size])
    blob = bytearray(raw[28 + size:])

    def read(index):
        a = doc['accessors'][index]
        view = doc['bufferViews'][a['bufferView']]
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[a['type']]
        fmt = '<' + {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[a['componentType']] * width
        start = view.get('byteOffset', 0) + a.get('byteOffset', 0)
        stride = view.get('byteStride', struct.calcsize(fmt))
        return [struct.unpack_from(fmt, blob, start + i * stride) for i in range(a['count'])]

    def append(data, kind, component):
        while len(blob) % 4:
            blob.append(0)
        fmt = '<' + {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}[component] * len(data[0])
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
    attributes = {key: read(index) for key, index in prim['attributes'].items()}
    positions = attributes['POSITION']
    normals = attributes['NORMAL']
    source_indices = [v[0] for v in read(prim['indices'])]

    # Take out the folded front completely. Capping individual holes leaves
    # doubled lip and eyelid surfaces that show through under grazing light.
    observer = name == 'eddington'
    offset = 0 if observer else .056
    centre = 1.67 if observer else 1.594
    front = .151 if observer else .145
    top = 1.75 if observer else 1.72
    representatives = {}
    welded = [representatives.setdefault(v, i) for i, v in enumerate(positions)]
    edges = collections.Counter()
    directed = {}
    indices = []
    for i in range(0, len(source_indices), 3):
        a, b, c = source_indices[i:i + 3]
        x, y, z = (sum(positions[j][axis] for j in (a, b, c)) / 3 for axis in range(3))
        if not (abs(x) < .065 and 1.54 - offset < y < top - offset and z > .10):
            indices.extend((a, b, c))
            continue
        for u, v in ((a, b), (b, c), (c, a)):
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
        loops.append(loop)
    rim = max(loops, key=len)

    def add_vertex(pos, normal, landmark):
        index = len(positions)
        attrs = {'POSITION': pos, 'NORMAL': normal}
        for key, values in attributes.items():
            values.append(attrs.get(key, values[landmark]))
        return index

    # Concentric rings give the new patch a continuous convex contour. Their
    # outer ring meets the original cheek, chin and forehead exactly.
    landmark = min(rim, key=lambda i: abs(positions[i][0]) + abs(positions[i][1] - centre))
    middle = add_vertex((0, centre, front), (0, 0, 1), landmark)
    rings = []
    for radius in (.33, .66):
        ring = []
        for i in rim:
            x, y, z = positions[i]
            px, py = radius * x, radius * (y - centre)
            target = front - 2.5 * px * px - 1.6 * py * py
            boundary_target = front - 2.5 * x * x - 1.6 * (y - centre) ** 2
            depth = target + radius ** 3 * (z - boundary_target)
            normal = tuple((1 - radius) * a + radius * b
                           for a, b in zip((5 * px, 3.2 * py, 1), normals[i]))
            length = math.sqrt(sum(v * v for v in normal))
            ring.append(add_vertex((px, centre + py, depth), tuple(v / length for v in normal), i))
        rings.append(ring)
    for i in range(len(rim)):
        j = (i + 1) % len(rim)
        indices.extend((middle, rings[0][i], rings[0][j]))
        for inner, outer in zip(rings, [rings[1], rim]):
            indices.extend((inner[i], outer[i], outer[j], inner[i], outer[j], inner[j]))

    used = sorted(set(indices))
    remap = {index: i for i, index in enumerate(used)}
    for key, values in attributes.items():
        accessor = doc['accessors'][prim['attributes'][key]]
        prim['attributes'][key] = append([values[i] for i in used], accessor['type'], accessor['componentType'])
    prim['indices'] = append([(remap[i],) for i in indices], 'SCALAR', 5125)

    if observer:
        hat = next(n for n in doc['nodes'] if n.get('name') == 'eddington_hat')
        # Put the attachment origin at the brim so leveling the hat keeps its seat.
        hat['translation'][1] -= .043
        hat['translation'][2] += .025
        for surface in doc['meshes'][hat['mesh']]['primitives']:
            attrs = surface['attributes']
            positions = read(attrs['POSITION'])
            normals = read(attrs['NORMAL'])
            band = doc['materials'][surface['material']]['name'] == 'E1919_teak_dark'
            shaped = []
            corrected = []
            for (x, y, z), (nx, ny, nz) in zip(positions, normals):
                height = y + .044
                # A lower, slightly tapered crown and an oval, closer-cut brim.
                brim = not band and x * x + z * z > .115 ** 2
                scale = .78 if brim else .98 - 1.2 * height
                shaped.append((x * scale, height * .74, z * scale * 1.12))
                normal = (nx / scale, ny / .74, nz / (scale * 1.12))
                length = math.sqrt(sum(v * v for v in normal))
                corrected.append(tuple(v / length for v in normal))
            attrs['POSITION'] = append(shaped, 'VEC3', 5126)
            attrs['NORMAL'] = append(corrected, 'VEC3', 5126)
    doc['buffers'][0]['byteLength'] = len(blob)
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    blob.extend(b'\0' * (-len(blob) % 4))
    path.write_bytes(struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(blob))
                     + struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
                     + struct.pack('<II', len(blob), 0x004E4942) + blob)
    print(f'{name}: replaced the face with a {len(rim)}-point patch')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=ROOT / 'assets/models')
    args = parser.parse_args()
    for person in ['eddington', 'cottingham']:
        smooth(person, args.source)
