import unittest
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

from contrast import contrast_ratio, measure


class ContrastTests(unittest.TestCase):
    def test_unsampled_control_gap_is_reported_alongside_sampled_sibling(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            frame = Image.new("RGB", (32, 16), "white")
            for x in range(2, 8):
                for y in range(2, 10):
                    frame.putpixel((x, y), (0, 0, 0))
            frame.save(out / "frame.png")
            Image.new("RGB", (32, 16), "white").save(out / "background.png")
            frame.save(out / "repeat.png")
            (out / "commands.tsv").write_text("cfg\tfixture command\n")
            (out / "sheets").mkdir()
            (out / ".work").mkdir()
            (out / ".work" / "completed.txt").write_text("720-100\n1080-100\n720-120\n")
            row = {
                "config": "cfg", "state": "state", "case": "case", "clause": "text",
                "frame": "frame.png", "background": "background.png", "repeat": "repeat.png",
                "text": [
                    {"surface": "dialog", "text": "Visible title", "rect": [0, 0, 15, 12], "node": "a"},
                    {"surface": "dialog", "text": "Nearly invisible label", "rect": [16, 0, 32, 12], "node": "b"},
                ],
            }
            (out / "receipts-fixture.jsonl").write_text(json.dumps(row) + "\n")
            sha = subprocess.check_output(["git", "rev-parse", "HEAD"], text=True).strip()

            subprocess.run(
                [sys.executable, str(Path(__file__).with_name("report.py")), str(out), sha],
                check=True,
            )

            expected = "cfg state case / dialog / Nearly invisible label: no differing glyph pixels in the visible bounds."
            self.assertIn(expected, (out / "index.md").read_text())

    def test_wcag_ratio(self):
        self.assertAlmostEqual(contrast_ratio((0, 0, 0), (255, 255, 255)), 21)
        self.assertEqual(contrast_ratio((12, 34, 56), (12, 34, 56)), 1)
        self.assertAlmostEqual(contrast_ratio((255, 255, 255), (119, 119, 119)), 4.47808945)
        self.assertAlmostEqual(contrast_ratio((10, 0, 0), (0, 0, 0)), 1.0129059673)

    def test_changed_paper_and_small_edge_fragment(self):
        paper, ink = (239, 230, 210), (34, 28, 24)
        visible = [paper] * 96
        for y in range(1, 6):
            visible[y * 12 + 2:y * 12 + 4] = [ink, ink]
        visible[65] = (170, 162, 148)
        hidden = [(200, 180, 160)] * len(visible)

        sample = measure(visible, hidden, visible, 12)

        self.assertEqual(sample[:3], (contrast_ratio(ink, paper), ink, paper))
        self.assertEqual(sample[4], 2)

    def test_weak_rendered_glyphs_still_count(self):
        paper, gray, bright = (13, 11, 10), (95, 90, 82), (239, 230, 210)
        hidden = [paper] * 96
        visible = hidden.copy()
        for y in range(1, 6):
            visible[y * 12 + 2:y * 12 + 4] = [gray, gray]
            visible[y * 12 + 7:y * 12 + 9] = [bright, bright]
        visible[0] = bright  # This change does not persist in the repeat.
        restored = [paper, *visible[1:]]

        sample = measure(visible, hidden, restored, 12)

        self.assertLess(sample[0], 4.5)
        self.assertEqual(sample[1:3], (gray, paper))
        self.assertEqual(sample[4], 2)


    def test_short_dim_run_in_long_caption(self):
        paper, dim, bright = (13, 11, 10), (95, 90, 82), (239, 230, 210)
        width, height = 60, 16
        hidden = [paper] * (width * height)
        visible = hidden.copy()
        for y in range(3, 13):
            for left, right, ink in ((3, 11, dim), (16, 34, bright), (39, 57, bright)):
                visible[y * width + left:y * width + right] = [ink] * (right - left)

        sample = measure(visible, hidden, visible, width)

        self.assertLess(sample[0], 4.5)
        self.assertEqual(sample[1:3], (dim, paper))


if __name__ == "__main__":
    unittest.main()
