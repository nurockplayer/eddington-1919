import importlib.util
from pathlib import Path
import unittest

from PIL import Image, ImageDraw

spec = importlib.util.spec_from_file_location('menus_page', Path(__file__).with_name('run.py'))
menus = importlib.util.module_from_spec(spec)
spec.loader.exec_module(menus)


class ContrastTests(unittest.TestCase):
    rect = (0, 0, 80, 40)

    def capture(self, ink, paper, decoration=True):
        background = Image.new('RGB', (80, 40), paper)
        if decoration:
            draw = ImageDraw.Draw(background)
            draw.rectangle((0, 0, 79, 2), fill='black')
            draw.rectangle((0, 37, 79, 39), fill='white')
        frame = background.copy()
        draw = ImageDraw.Draw(frame)
        # Two synthetic H glyphs, including partial coverage at their edges.
        edge = tuple(round((a + b) / 2) for a, b in zip(ink, paper))
        for x in (20, 40):
            draw.rectangle((x - 1, 10, x + 9, 29), fill=edge)
            draw.rectangle((x, 10, x + 2, 29), fill=ink)
            draw.rectangle((x + 6, 10, x + 8, 29), fill=ink)
            draw.rectangle((x, 18, x + 8, 21), fill=ink)
        return frame, background

    def test_low_contrast_glyphs_fail_despite_repeated_black_white_decoration(self):
        frame, background = self.capture((150, 150, 150), (180, 180, 180))
        ratio, ink, paper = menus.contrast(frame, self.rect, background)
        self.assertLess(ratio, 4.5)
        self.assertEqual((ink, paper), ((150, 150, 150), (180, 180, 180)))

    def test_sufficient_contrast_glyphs_pass(self):
        frame, background = self.capture((30, 30, 30), (230, 230, 230))
        self.assertGreaterEqual(menus.contrast(frame, self.rect, background)[0], 4.5)

    def test_reversed_focus_preserves_foreground_background_order(self):
        frame, background = self.capture((230, 230, 230), (30, 30, 30))
        ratio, ink, paper = menus.contrast(frame, self.rect, background)
        self.assertGreaterEqual(ratio, 4.5)
        self.assertEqual((ink, paper), ((230, 230, 230), (30, 30, 30)))

    def test_unrelated_pixels_cannot_improve_ratio(self):
        plain = self.capture((150, 150, 150), (180, 180, 180), decoration=False)
        decorated = self.capture((150, 150, 150), (180, 180, 180))
        self.assertEqual(menus.contrast(plain[0], self.rect, plain[1]),
                         menus.contrast(decorated[0], self.rect, decorated[1]))

    def test_strong_glyph_cannot_hide_a_weak_glyph(self):
        frame, background = self.capture((150, 150, 150), (180, 180, 180))
        ImageDraw.Draw(frame).rectangle((60, 10, 64, 29), fill='black')
        self.assertLess(menus.contrast(frame, self.rect, background)[0], 4.5)


if __name__ == '__main__':
    unittest.main()
