import unittest

from contrast import contrast_ratio, measure, missing_control_gap


class ContrastTests(unittest.TestCase):
    def test_unsampled_control_gap_is_reported_alongside_sampled_sibling(self):
        sampled = {"surface": "dialog", "text": "Visible title"}
        unsampled = {"surface": "dialog", "text": "Nearly invisible label"}

        gaps = [missing_control_gap("cfg state case", control) for control in (sampled, unsampled)[1:]]

        self.assertEqual(gaps, [
            "cfg state case / dialog / Nearly invisible label: no differing glyph pixels in the visible bounds."
        ])

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
