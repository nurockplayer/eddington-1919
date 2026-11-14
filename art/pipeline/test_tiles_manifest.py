#!/usr/bin/env python3
"""Validate the Príncipe surface tile handoff."""

import json
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUN = ROOT / "art/runs/p5-tiles"
IDS = (
    "laterite_wet", "laterite", "ground_cover", "leaf_litter", "whitewash",
    "roof_tile", "brick", "teak", "canvas", "iron_sheet", "palm_bark",
)
KEYS = {
    "id", "variant", "prompt", "tool_model", "time", "retries",
    "raw_sha256", "raw_path", "tile", "match_hex", "wrap_x", "wrap_y", "mean",
}


def jpeg_size(path):
    with path.open("rb") as image:
        if image.read(2) != b"\xff\xd8":
            raise ValueError("missing JPEG SOI")
        while True:
            if image.read(1) != b"\xff":
                raise ValueError("invalid JPEG marker")
            marker = image.read(1)
            while marker == b"\xff":
                marker = image.read(1)
            if not marker or marker in (b"\xd9", b"\xda"):
                raise ValueError("JPEG has no SOF")
            if marker == b"\x01" or b"\xd0" <= marker <= b"\xd7":
                continue
            length_data = image.read(2)
            if len(length_data) != 2:
                raise ValueError("truncated JPEG marker")
            length = struct.unpack(">H", length_data)[0]
            if length < 2:
                raise ValueError("invalid JPEG marker length")
            if marker[0] in (0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
                             0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF):
                data = image.read(5)
                if len(data) != 5:
                    raise ValueError("truncated JPEG SOF")
                height, width = struct.unpack(">HH", data[1:])
                return width, height
            image.seek(length - 2, 1)


class TileManifestTest(unittest.TestCase):
    def test_manifest_and_tiles(self):
        records = [json.loads(line) for line in (RUN / "manifest.jsonl").read_text().splitlines()]
        self.assertEqual(len(records), 22)
        self.assertCountEqual(
            [(row["id"], row["variant"]) for row in records],
            [(name, variant) for name in IDS for variant in (1, 2)],
        )
        for row in records:
            with self.subTest(id=row["id"], variant=row["variant"]):
                self.assertTrue(KEYS <= row.keys(), KEYS - row.keys())
                self.assertRegex(row["raw_sha256"], r"^[0-9a-fA-F]{64}$")
                self.assert_tile(ROOT / row["tile"])
        for name in ("teak_dark", "pine"):
            for variant in (1, 2):
                with self.subTest(id=name, variant=variant):
                    self.assert_tile(RUN / "tiles" / f"{name}-v{variant}.jpg")

    def assert_tile(self, path):
        self.assertTrue(path.is_file(), str(path))
        self.assertLess(path.stat().st_size, 700_000)
        self.assertEqual(jpeg_size(path), (1024, 1024))


if __name__ == "__main__":
    unittest.main()
