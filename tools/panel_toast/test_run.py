#!/usr/bin/env python3
"""Retry policy on temporary capture directories; no windowed capture."""
import importlib.util
from pathlib import Path
import shutil
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('panel_toast_run', Path(__file__).with_name('run.py'))
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class RetryTests(unittest.TestCase):
    def test_incomplete_directories_can_be_retried(self):
        for existing in (('main',), ('fixed',), ('main', 'fixed')):
            with self.subTest(existing=existing), tempfile.TemporaryDirectory() as scratch:
                out = Path(scratch) / 'commit'
                for name in existing:
                    (out / name).mkdir(parents=True)
                    (out / name / 'partial.png').write_bytes(b'partial')
                (out / 'report.json').write_text('{}')  # Failed before final receipt checks.
                runner.prepare_output(out)
                source = Path(scratch) / 'baseline'
                source.mkdir()
                shutil.copytree(source, out / 'main')
                (out / 'fixed').mkdir()
                self.assertFalse((out / 'report.md').exists())
                self.assertFalse(list(out.glob('*/partial.png')))

    def test_complete_capture_is_preserved(self):
        with tempfile.TemporaryDirectory() as scratch:
            out = Path(scratch)
            for name in ('main', 'fixed'):
                (out / name).mkdir()
                (out / name / 'clip.mp4').write_bytes(b'complete')
            (out / 'report.md').write_text('Successful capture')
            with self.assertRaisesRegex(SystemExit, '--overwrite'):
                runner.prepare_output(out)
            self.assertEqual((out / 'report.md').read_text(), 'Successful capture')
            for name in ('main', 'fixed'):
                self.assertEqual((out / name / 'clip.mp4').read_bytes(), b'complete')

    def test_explicit_overwrite_invalidates_completion(self):
        with tempfile.TemporaryDirectory() as scratch:
            out = Path(scratch)
            (out / 'fixed').mkdir()
            (out / 'report.md').write_text('Successful capture')
            runner.prepare_output(out, overwrite=True)
            self.assertFalse((out / 'report.md').exists())
            self.assertFalse((out / 'fixed').exists())


if __name__ == '__main__':
    unittest.main()
