#!/usr/bin/env python3
import csv
import json
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("look_matrix_stats", Path(__file__).with_name("look_matrix_stats.py"))
stats = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stats)


class MatrixStatsTest(unittest.TestCase):
    def test_collect_and_write(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for variant in ("zeta", "alpha"):
                directory = root / variant
                directory.mkdir()
                (directory / "benchmark.json").write_text(json.dumps({"bookmarks": [
                    {"bookmark": "second", "lighting": "night", "forced_draw_ms_avg": 1.5,
                     "draw_calls": 42, "image": {key: 0.25 for key in stats.IMAGE_KEYS}},
                    {"bookmark": "first", "lighting": "day", "forced_draw_ms_avg": 2,
                     "draw_calls": 30},
                ]}), encoding="utf-8")
            rows = stats.collect(root, ["zeta", "alpha"])
            self.assertEqual([(r["variant"], r["bookmark"]) for r in rows],
                             [("alpha", "second"), ("alpha", "first"),
                              ("zeta", "second"), ("zeta", "first")])
            self.assertEqual((rows[0]["lighting"], rows[0]["forced_draw_ms_avg"], rows[0]["draw_calls"]),
                             ("night", 1.5, 42))
            self.assertTrue(all(rows[0][key] == 0.25 for key in stats.IMAGE_KEYS))
            self.assertTrue(all(rows[1][key] == "" for key in stats.IMAGE_KEYS))
            self.assertEqual(stats.main(["stats", str(root), "zeta", "alpha"]), 0)
            with (root / "stats.tsv").open(encoding="utf-8", newline="") as f:
                written = list(csv.DictReader(f, delimiter="\t"))
            self.assertEqual(len(written), 4)
            self.assertEqual(written[1]["luma_mean"], "")

    def test_empty(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(stats.main(["stats", tmp]), 1)
            self.assertFalse((Path(tmp) / "stats.tsv").exists())

    def test_stale_variant_directory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for name in ("current", "stale"):
                (root / name).mkdir()
                (root / name / "benchmark.json").write_text(
                    '{"bookmarks": [{"bookmark": "first"}]}', encoding="utf-8")
            self.assertEqual(stats.main(["stats", tmp, "current"]), 0)
            with (root / "stats.tsv").open(encoding="utf-8", newline="") as f:
                self.assertEqual([r["variant"] for r in csv.DictReader(f, delimiter="\t")],
                                 ["current"])

    def test_failed_variant(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "failed").mkdir()
            (root / "failed" / "benchmark.json").write_text(
                '{"bookmarks": [{"bookmark": "first"}]}', encoding="utf-8")
            self.assertEqual(stats.collect(root, []), [])
            self.assertEqual(stats.main(["stats", tmp]), 1)
            self.assertFalse((root / "stats.tsv").exists())


if __name__ == "__main__":
    unittest.main()
