import unittest
import json
import runpy
import subprocess
import sys
import tempfile
import types
from pathlib import Path

from contrast import contrast_ratio, measure


class FixtureImage:
    def __init__(self, width, height, pixels):
        self.width, self.height, self.pixels = width, height, pixels

    def __enter__(self):
        return self

    def __exit__(self, *args):
        pass

    def convert(self, mode):
        return self

    def crop(self, box):
        x0, y0, x1, y1 = box
        return FixtureImage(x1 - x0, y1 - y0, [
            self.pixels[y * self.width + x]
            for y in range(y0, y1) for x in range(x0, x1)
        ])

    def get_flattened_data(self):
        return self.pixels

    def paste(self, image, position):
        pass

    def resize(self, size, resampling):
        return FixtureImage(*size, [(255, 255, 255)] * (size[0] * size[1]))

    def save(self, path, **kwargs):
        Path(path).write_bytes(b"fixture")


def fixture_pil_modules():
    image = types.ModuleType("PIL.Image")
    image.Resampling = types.SimpleNamespace(LANCZOS=0)

    def open(path):
        pixels = [(255, 255, 255)] * (32 * 16)
        if Path(path).name != "background.png":
            for y in range(2, 10):
                for x in range(2, 8):
                    pixels[y * 32 + x] = (0, 0, 0)
        return FixtureImage(32, 16, pixels)

    image.open = open
    image.new = lambda mode, size, color: FixtureImage(
        *size, [tuple(bytes.fromhex(color.removeprefix("#")))] * (size[0] * size[1])
    )
    draw = types.ModuleType("PIL.ImageDraw")
    draw.Draw = lambda target: types.SimpleNamespace(text=lambda *args, **kwargs: None)
    pil = types.ModuleType("PIL")
    pil.Image, pil.ImageDraw = image, draw
    return {"PIL": pil, "PIL.Image": image, "PIL.ImageDraw": draw}


class ContrastTests(unittest.TestCase):
    def test_unsampled_control_gap_is_reported_alongside_sampled_sibling(self):
        with tempfile.TemporaryDirectory() as directory:
            out = Path(directory)
            for name in ("frame.png", "background.png", "repeat.png"):
                (out / name).touch()
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
            sha = "fixture"

            previous_argv = sys.argv
            previous_check_output = subprocess.check_output
            previous_modules = {name: sys.modules.get(name) for name in ("PIL", "PIL.Image", "PIL.ImageDraw")}
            sys.modules.update(fixture_pil_modules())
            try:
                sys.argv = ["report.py", str(out), sha]
                subprocess.check_output = lambda *args, **kwargs: ""
                runpy.run_path(str(Path(__file__).with_name("report.py")), run_name="__main__")
            finally:
                sys.argv = previous_argv
                subprocess.check_output = previous_check_output
                for name, module in previous_modules.items():
                    if module is None:
                        sys.modules.pop(name, None)
                    else:
                        sys.modules[name] = module

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
