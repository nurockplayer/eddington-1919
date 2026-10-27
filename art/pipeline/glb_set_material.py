#!/usr/bin/env python3
"""Swap one palette material inside an existing GLB without rebuilding it.

Usage: glb_set_material.py <file.glb> <old swatch> <new swatch>

Geometry, rig and animation stay byte-identical; only the material's name,
base colour and roughness change (values from art/palette.toml). This lets a
material change be judged in game apart from an MPFB rebuild (c02, Owner
2026-10-27). A later build_person.py run from people.toml gives the same
material.
"""
import json
import struct
import sys
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def main() -> int:
    path, old, new = Path(sys.argv[1]), sys.argv[2], sys.argv[3]
    swatch = tomllib.loads((ROOT / "art/palette.toml").read_text())["swatch"][new]
    hexv = swatch["hex"].lstrip("#")
    rgb = [srgb_to_linear(int(hexv[i:i + 2], 16) / 255) for i in (0, 2, 4)]
    data = path.read_bytes()
    json_len = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + json_len])
    hits = [m for m in gltf["materials"] if m.get("name") == f"E1919_{old}"]
    if len(hits) != 1:
        sys.exit(f"{path.name}: expected one E1919_{old} material, found {len(hits)}")
    mat = hits[0]
    mat["name"] = f"E1919_{new}"
    pbr = mat.setdefault("pbrMetallicRoughness", {})
    pbr["baseColorFactor"] = rgb + [1.0]
    pbr["roughnessFactor"] = swatch["roughness"]
    blob = json.dumps(gltf, separators=(",", ":")).encode()
    blob += b" " * (-len(blob) % 4)
    rest = data[20 + json_len:]
    out = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(blob) + len(rest))
    out += struct.pack("<I4s", len(blob), b"JSON") + blob + rest
    path.write_bytes(out)
    print(f"{path.name}: E1919_{old} -> E1919_{new} {swatch['hex']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
