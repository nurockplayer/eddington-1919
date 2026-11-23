import contextlib
import copy
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

REPO = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('capture_phase0', os.environ.get(
    'PHASE0_TEST_SOURCE', REPO / 'tools/capture_phase0.py'))
capture = importlib.util.module_from_spec(spec)
spec.loader.exec_module(capture)


def metadata(state, ui, resolution=None, locale='en', frame=0, phase='prep'):
    return dict(scene='res://scenes/main.tscn', state=state, ui_state=ui,
                resolution=resolution or [1280, 720], locale=locale, phase=phase,
                camera_transform=[[1, 0, 0], [0, 1, 0], [0, 0, 1], [0, 0, 0]],
                fov=55, seed=7, text_scale=1.2,
                event_time=dict(frame=frame, seconds=frame / 60, clock='simulation', zone='JST'))


def receipts():
    records = []
    goldens = [('arrival', 'prep_early'), ('shelter', 'prep_late'), ('coelostat', 'prep_early'),
               ('house', 'prep_early'), ('totality_sky', 'totality'), ('totality_horizon', 'totality'), ('darkroom', 'night')]
    def still(name, state, ui, resolution=None, locale='en'):
        records.append(dict(metadata(state, ui, resolution, locale), id=name, file=name + '.png', kind='still'))
    for name, state in goldens:
        still('golden_' + name, state, 'hidden')
    for w, h in ((1920, 1080), (2560, 1440)):
        for name, state in (goldens[0], goldens[4]):
            still(f'{name}_{w}x{h}', state, 'hidden', [w, h])
    for name in ('nearest_npc', 'sign_approach', 'under_roof'):
        still(name, 'prep', 'hud')
    for name in ('title', 'settings', 'pause'):
        still(name, 'title' if name == 'title' else 'prep', name)
    for locale in ('en', 'ja', 'zh_TW', 'ko'):
        for name, state, ui in (('hud', 'prep', 'hud'), ('dialogue', 'prep', 'dialogue'),
                                ('plate', 'night', 'plate_inspection'), ('results', 'night', 'measurement_results')):
            still(name + '_' + locale, state, ui, locale=locale)
    for name, count in (('arrival_walk_turn', 990), ('second_contact', 330), ('dialogue_open_close', 330)):
        frames = []
        for i in range(count):
            ui = 'dialogue' if name == 'dialogue_open_close' and 30 <= i < 180 else 'hud'
            phase = 'totality' if name == 'second_contact' and i >= 30 else 'prep'
            record = metadata(name, ui, frame=i - 30, phase=phase)
            record['fade_alpha'] = 1 if name == 'second_contact' and 60 <= i < 90 else 0
            if name == 'arrival_walk_turn':
                record['camera_transform'][3][0] = i / 60
                record['camera_transform'][0][0] = i / 990
            frames.append(record)
        records.append(dict(copy.deepcopy(frames[0]), id=name, file=name + '.mp4', kind='clip',
                            fps=60, frame_count=count, trigger_frame=30, pre_trigger_seconds=0.5,
                            close_trigger_frame=180 if name == 'dialogue_open_close' else None, frames=frames))
    return dict(renderer='gl_compatibility', godot_version='4.7.2', captures=records)


def write_captures(out, value):
    (out / 'receipts.json').write_text(json.dumps(value))
    for record in value['captures']:
        if record['kind'] == 'still':
            (out / record['file']).write_bytes(b'pixels')
        else:
            folder = out / 'scratch' / record['id']
            folder.mkdir(parents=True)
            for i in range(record['frame_count']):
                (folder / f'f_{i:05}.png').write_bytes(b'pixels')


class CapturePhase0Tests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.value = receipts()
        self.commands = []

    def fake_call(self, argv, **kwargs):
        argv = list(map(str, argv))
        self.commands.append(argv)
        if argv[0] == 'git':
            with tarfile.open(fileobj=kwargs['stdout'], mode='w') as archive:
                entry = tarfile.TarInfo('scenes/main.tscn')
                entry.size = 0
                archive.addfile(entry, io.BytesIO())
        elif argv[0] == 'godot' and '--windowed' in argv:
            out = Path(next(a.removeprefix('--out=') for a in argv if a.startswith('--out=')))
            write_captures(out, self.value)
        elif argv[0] in ('ffmpeg', 'magick'):
            Path(argv[-1]).write_bytes(b'encoded pixels')

    def render(self):
        with patch.object(capture, 'ROOT', self.root), patch.object(capture, 'REPO', REPO), \
                patch.object(capture, 'call', side_effect=self.fake_call), contextlib.redirect_stdout(io.StringIO()) as output:
            capture.render('a' * 40)
        return output.getvalue()

    def test_successful_a_failed_b_then_valid_a(self):
        self.assertIn('33 stills, 3 clips, 0 repeat comparisons', self.render())
        self.value['godot_version'] = 'different-engine'
        with self.assertRaisesRegex(RuntimeError, 'Repeat manifest differs'):
            self.render()
        self.value['godot_version'] = '4.7.2'
        self.assertIn('1 repeat comparisons', self.render())
        base = self.root / ('a' * 40)
        failed = base / 'run-002'
        self.assertTrue((failed / 'candidate-manifest.json').is_file())
        self.assertTrue((failed / 'receipts.json').is_file())
        self.assertFalse((failed / 'manifest.json').exists())
        self.assertFalse((failed / 'success').exists())
        self.assertTrue((base / 'run-003/success').is_file())
        self.assertFalse(any(base.glob('run-*/scratch')))

    def test_legacy_manifest_is_not_success_evidence(self):
        old = self.root / ('a' * 40) / 'run-001'
        old.mkdir(parents=True)
        (old / 'manifest.json').write_text('{}')
        self.assertIn('0 repeat comparisons', self.render())

    def test_declared_hash_differences_only(self):
        self.render()
        manifest_path = self.root / ('a' * 40) / 'run-001/manifest.json'
        manifest = json.loads(manifest_path.read_text())
        for entry in manifest['files']:
            if entry.get('nondeterministic'):
                entry['sha256'] = 'different hash'
        manifest_path.write_text(json.dumps(manifest))
        self.assertIn('1 repeat comparisons', self.render())
        manifest['files'][-1]['reason'] = 'different declaration'
        manifest_path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(RuntimeError, 'Repeat manifest differs'):
            self.render()

    def test_deterministic_receipt_hash_mismatch(self):
        self.render()
        path = self.root / ('a' * 40) / 'run-001/manifest.json'
        manifest = json.loads(path.read_text())
        next(f for f in manifest['files'] if f['file'] == 'receipts.json')['sha256'] = 'changed'
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(RuntimeError, 'Repeat manifest differs'):
            self.render()

    def test_invalid_receipt_never_publishes_success(self):
        self.value['captures'].pop()
        with self.assertRaisesRegex(ValueError, '33 named stills'):
            self.render()
        out = self.root / ('a' * 40) / 'run-001'
        self.assertTrue((out / 'receipts.json').exists())
        self.assertFalse((out / 'manifest.json').exists())
        self.assertFalse((out / 'success').exists())
        self.assertFalse((out / 'scratch').exists())

    def test_receipt_contract_rejects_missing_metadata_and_transitions(self):
        write_captures(self.root, self.value)
        capture.validate_receipts(self.root, self.value)
        mutations = [
            lambda r: r['captures'].pop(0),
            lambda r: r['captures'][0].update(id='unknown'),
            lambda r: r['captures'][0].pop('camera_transform'),
            lambda r: r['captures'][0].update(camera_transform=[[float('nan')] * 3] * 4),
            lambda r: r['captures'][0].update(seed=8),
            lambda r: r['captures'][0].update(resolution=[1, 1]),
            lambda r: r['captures'][-1].update(trigger_frame=31),
            lambda r: r['captures'][-1].update(close_trigger_frame=181),
            lambda r: r['captures'][-1]['frames'].pop(),
            lambda r: r['captures'][-1]['frames'][30].update(ui_state='hud'),
            lambda r: r['captures'][-1]['frames'][180].update(ui_state='dialogue'),
            lambda r: r['captures'][-2]['frames'][30].update(phase='prep'),
            lambda r: [f.update(fade_alpha=0) for f in r['captures'][-2]['frames']],
            lambda r: r['captures'][-3]['frames'][330].update(camera_transform=r['captures'][-3]['frames'][30]['camera_transform']),
            lambda r: r['captures'][-1]['frames'][40]['event_time'].update(frame=0),
            lambda r: r.update(renderer=''),
        ]
        for index, mutate in enumerate(mutations):
            with self.subTest(case=index):
                value = copy.deepcopy(self.value)
                mutate(value)
                with self.assertRaises((ValueError, KeyError)):
                    capture.validate_receipts(self.root, value)

    def test_missing_and_empty_artifacts(self):
        write_captures(self.root, self.value)
        for path in (self.root / 'golden_arrival.png', self.root / 'scratch/second_contact/f_00030.png'):
            with self.subTest(file=path.name):
                path.write_bytes(b'')
                with self.assertRaisesRegex(ValueError, 'empty'):
                    capture.validate_receipts(self.root, self.value)
                path.unlink()
                with self.assertRaises((ValueError, FileNotFoundError)):
                    capture.validate_receipts(self.root, self.value)
                path.write_bytes(b'pixels')

    def test_public_launcher_submits_detached_job(self):
        for _ in range(2):
            with patch('sys.argv', ['tools/capture_phase0.py', '--commit', 'HEAD']), \
                    patch.object(capture.subprocess, 'check_output', return_value='a' * 40 + '\n'), \
                    patch.object(Path, 'is_mount', return_value=True), patch.object(capture, 'call') as submit:
                capture.main()
            argv = list(map(str, submit.call_args.args[0]))
            self.assertEqual(argv[0], 'job-run')
            self.assertEqual(argv[argv.index('--') + 1:][:5], ['tachi-run', '--heavy', '--host', '--', 'python3'])
            self.assertEqual(argv[-3:], ['--render', '--commit', 'a' * 40])

    def test_driver_metadata_and_still_receipt_headless(self):
        # Execute inherited metadata/still methods; replace only the GPU save.
        with tempfile.TemporaryDirectory(prefix='_phase0_', dir=REPO / 'tests') as directory:
            path = Path(directory) / 'driver.gd'
            path.write_text('''extends "res://tools/phase0/capture.gd"
func _run() -> void:
    out_dir = OS.get_environment("PHASE0_TEST_OUT")
    var camera := Camera3D.new()
    root.add_child(camera)
    game = {"player": {"camera": camera}, "Phase": {"TITLE": 0, "PREP": 1}, "phase": 1}
    Settings.text_scale = 1.2
    await still("probe", "prep", "hud")
    var file := FileAccess.open(out_dir.path_join("driver.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(records))
    file.close()
    camera.free()
    quit()
func _save(label: String) -> void:
    var file := FileAccess.open(out_dir.path_join(label + ".png"), FileAccess.WRITE)
    file.store_string("test pixels")
    file.close()
''')
            command = ['godot', '--headless', '--path', str(REPO), '--script', 'res://' + str(path.relative_to(REPO))]
            env = dict(os.environ, PHASE0_TEST_OUT=str(self.root))
            for args in (command + ['--check-only'], command):
                result = subprocess.run(['perl', '-e', 'alarm shift; exec @ARGV', '1500', *args],
                                        env=env, capture_output=True, text=True, timeout=1500)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertNotIn('SCRIPT ERROR', result.stdout + result.stderr)
            record, = json.loads((self.root / 'driver.json').read_text())
            capture.validate_metadata(record, 0)
            self.assertEqual((record['id'], record['kind'], record['file'], record['phase']),
                             ('probe', 'still', 'probe.png', 'prep'))


if __name__ == '__main__':
    unittest.main()
