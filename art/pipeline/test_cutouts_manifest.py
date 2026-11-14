import json
import struct
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUN = ROOT / 'art/runs/p4-leaves'
IDS = {'coconut_frond', 'coconut_frond_dry', 'cacao_branch', 'banana_leaf',
       'undergrowth', 'forest_edge'}
KEYS = {'id', 'variant', 'prompt', 'tool_model', 'time', 'retries',
        'raw_sha256', 'raw_path', 'cut', 'size', 'coverage', 'fringe', 'chroma'}


class ManifestTest(unittest.TestCase):
    def test_manifest_and_images(self):
        rows = [json.loads(line) for line in (RUN / 'manifest.jsonl').read_text().splitlines()]
        self.assertEqual(len(rows), 12)
        self.assertEqual({(r['id'], r['variant']) for r in rows},
                         {(name, variant) for name in IDS for variant in (1, 2)})
        for row in rows:
            with self.subTest(image=(row['id'], row['variant'])):
                self.assertTrue(KEYS <= row.keys())
                self.assertGreaterEqual(row['chroma'], 8)
                path = ROOT / row['cut']
                self.assertLess(path.stat().st_size, 2_500_000)
                with path.open('rb') as f:
                    header = f.read(33)
                self.assertEqual(header[:8], b'\x89PNG\r\n\x1a\n')
                self.assertEqual(header[12:16], b'IHDR')
                width, height, depth, colour = struct.unpack('>IIBB', header[16:26])
                self.assertEqual((depth, colour), (8, 6))
                if row['id'] == 'forest_edge':
                    self.assertEqual(width, 2048)
                else:
                    self.assertEqual(max(width, height), 1024)


if __name__ == '__main__':
    unittest.main()
