#!/usr/bin/env python3
"""Exercise the report command with tiny lossless inputs; no Godot or ffmpeg."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image


class ReportTests(unittest.TestCase):
    def report(self, out, failed=()):
        summary = {
            'variant': 'thick-06-7',
            'whole_exceedances': int('whole-frame continuity' in failed),
            'whole_max_ratio': 1.6 if 'whole-frame continuity' in failed else 1.5,
            'scene_failures': int('scene presence' in failed),
            'scene_minimum_share': .24 if 'scene presence' in failed else .25,
            'whole_plus3': [3.0, 15, 10, 10, 15, 1.5, True, ''],
            'old_plus3_decoded': 15,
            'new_plus3_decoded': 15,
            'thick_peak_vs_diamond_off_6pct': 1,
        }
        (out / 'thick-summary.json').write_text(json.dumps(summary))
        for side in ('main', 'candidate'):
            folder = out / f'compare-{side}'
            folder.mkdir()
            (folder / 'receipts.jsonl').write_text(json.dumps({'frame': 'second_000.png'}) + '\n')
            # A one-level RGB difference must fail even below the 6% threshold.
            value = 1 if side == 'candidate' and 'main comparison' in failed else 0
            Image.new('RGB', (2, 2), (value, 0, 0)).save(folder / 'second_000.png')
        for stage, limit in (('bead', 11.1), ('crossing', 14.0)):
            p95 = limit + .01 if 'frame budget' in failed else limit
            # One over-budget repetition alone does not fail the median gate.
            rows = [f'{rep}\t{value}\n' for rep, value in enumerate((p95, p95, 100))]
            (out / f'{stage}-cost.tsv').write_text('rep\tforced_draw_ms\n' + ''.join(rows))
        return subprocess.run(
            [sys.executable, str(Path(__file__).with_name('finish.py')), '--report',
             str(out), 'main-sha', 'candidate-sha'], capture_output=True, text=True)

    def assert_outputs(self, out):
        for name in ('main-comparisons.tsv', 'frame-cost-medians.tsv',
                     'continuity-plus3p0.tsv', 'frame-cost.tsv', 'report.md'):
            self.assertTrue((out / name).is_file(), name)
        self.assertIn('candidate-sha', (out / 'report.md').read_text())

    def test_passing_report_at_limits(self):
        with tempfile.TemporaryDirectory() as scratch:
            out = Path(scratch)
            result = self.report(out)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assert_outputs(out)

    def test_each_failed_gate_and_all_failures_are_reported(self):
        gates = ('whole-frame continuity', 'scene presence', 'frame budget', 'main comparison')
        for failed in [(gate,) for gate in gates] + [gates]:
            with self.subTest(failed=failed), tempfile.TemporaryDirectory() as scratch:
                out = Path(scratch)
                result = self.report(out, failed)
                self.assertNotEqual(result.returncode, 0)
                for gate in failed:
                    self.assertIn(f'FAIL {gate}:', result.stderr)
                self.assert_outputs(out)


if __name__ == '__main__':
    unittest.main()
