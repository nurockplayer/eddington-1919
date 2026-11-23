#!/usr/bin/env python3
"""Reproducible windowed census. Public entry: tools/capture_phase0.py --commit SHA."""
import argparse
from datetime import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
from zoneinfo import ZoneInfo

REPO = Path(__file__).resolve().parents[1]
ROOT = Path('/Volumes/KIOXIA/eddington-1919-cache/director/phase0')
REASON = 'Live GPU shader TIME, particle animation and temporal rendering history; fixed seed and 60 Hz do not guarantee identical pixels.'
GOLDENS = dict(arrival='prep_early', shelter='prep_late', coelostat='prep_early',
               house='prep_early', totality_sky='totality', totality_horizon='totality', darkroom='night')
STILLS = {f'golden_{name}': (state, 'hidden', [1280, 720], 'en') for name, state in GOLDENS.items()}
STILLS.update({f'{name}_{w}x{h}': (GOLDENS[name], 'hidden', [w, h], 'en')
               for name in ('arrival', 'totality_sky') for w, h in ((1920, 1080), (2560, 1440))})
STILLS.update({name: ('prep', 'hud', [1280, 720], 'en') for name in ('nearest_npc', 'sign_approach', 'under_roof')})
STILLS.update({name: ('title' if name == 'title' else 'prep', name, [1280, 720], 'en')
               for name in ('title', 'settings', 'pause')})
STILLS.update({f'{name}_{locale}': (state, ui, [1280, 720], locale)
               for locale in ('en', 'ja', 'zh_TW', 'ko')
               for name, state, ui in (('hud', 'prep', 'hud'), ('dialogue', 'prep', 'dialogue'),
                                       ('plate', 'night', 'plate_inspection'), ('results', 'night', 'measurement_results'))})
CLIPS = dict(arrival_walk_turn=990, second_contact=330, dialogue_open_close=330)


def require(condition, message):
    if not condition:
        raise ValueError(f'Invalid Phase-0 capture: {message}')


def validate_metadata(record, frame):
    for key in ('scene', 'state', 'ui_state', 'locale', 'phase'):
        require(isinstance(record[key], str) and record[key], f'missing {key}')
    require(record['scene'] == 'res://scenes/main.tscn', 'scene')
    require(record['seed'] == 7 and record['text_scale'] == 1.2, 'seed/text scale')
    camera = record['camera_transform']
    require(len(camera) == 4 and all(len(row) == 3 for row in camera), 'camera transform')
    require(all(isinstance(v, (int, float)) and math.isfinite(v) for row in camera for v in row), 'camera values')
    require(isinstance(record['fov'], (int, float)) and 0 < record['fov'] < 180, 'fov')
    event = record['event_time']
    require(event['frame'] == frame and event['clock'] == 'simulation' and event['zone'] == 'JST'
            and math.isclose(event['seconds'], frame / 60, abs_tol=0.00001), 'event frame/time')


def validate_receipts(out, receipts):
    for key in ('renderer', 'godot_version'):
        require(isinstance(receipts[key], str) and receipts[key], key)
    captures = receipts['captures']
    require(len(captures) == 36 and {c['id'] for c in captures} == STILLS.keys() | CLIPS.keys(),
            'expected 33 named stills and three named clips')
    for capture in captures:
        name = capture['id']
        validate_metadata(capture, -30 if name in CLIPS else 0)
        if name in STILLS:
            state, ui, resolution, locale = STILLS[name]
            require(capture['kind'] == 'still' and capture['file'] == name + '.png', f'{name}: still file')
            require((capture['state'], capture['ui_state'], capture['resolution'], capture['locale'])
                    == (state, ui, resolution, locale), f'{name}: still metadata')
            require((out / capture['file']).stat().st_size > 0, f'{name}: empty still')
            continue
        count = CLIPS[name]
        require(capture['kind'] == 'clip' and capture['file'] == name + '.mp4', f'{name}: clip file')
        require((capture['fps'], capture['frame_count'], capture['trigger_frame'], capture['pre_trigger_seconds'],
                 capture['close_trigger_frame']) == (60, count, 30, 0.5, 180 if name == 'dialogue_open_close' else None),
                f'{name}: frame/trigger contract')
        frames = capture['frames']
        require(len(frames) == count, f'{name}: missing frame receipts')
        folder = out / 'scratch' / name
        require({p.name for p in folder.glob('*.png')} == {f'f_{i:05}.png' for i in range(count)},
                f'{name}: missing scratch frames')
        for i, record in enumerate(frames):
            validate_metadata(record, i - 30)
            require(record['resolution'] == [1280, 720] and record['locale'] == 'en'
                    and record['state'] == name, f'{name}: frame metadata')
            require((folder / f'f_{i:05}.png').stat().st_size > 0, f'{name}: empty frame')
            require(isinstance(record['fade_alpha'], (int, float)) and 0 <= record['fade_alpha'] <= 1,
                    f'{name}: fade receipt')
            phase = 'totality' if name == 'second_contact' and i >= 30 else 'prep'
            ui = 'dialogue' if name == 'dialogue_open_close' and 30 <= i < 180 else 'hud'
            require(record['phase'] == phase and record['ui_state'] == ui, f'{name}: missing phase/UI transition')
        require(all(capture[key] == value for key, value in frames[0].items()), f'{name}: initial frame receipt')
        if name == 'second_contact':
            require(frames[0]['fade_alpha'] < 0.01 and max(f['fade_alpha'] for f in frames) > 0.9
                    and frames[-1]['fade_alpha'] < 0.01, 'second contact: missing fade transition')
        if name == 'arrival_walk_turn':
            require(frames[30]['camera_transform'][3] != frames[330]['camera_transform'][3]
                    and frames[630]['camera_transform'][:3] != frames[810]['camera_transform'][:3],
                    'arrival: missing walk/turn')


def call(argv, **kwargs):
    return subprocess.run(list(map(str, argv)), check=True, timeout=1500, **kwargs)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def comparable(manifest):
    value = json.loads(json.dumps(manifest))
    for entry in value['files']:
        if entry.get('nondeterministic'):
            entry.pop('sha256')
    return value


def render(sha):
    base = ROOT / sha
    base.mkdir(parents=True, exist_ok=True)
    number = 1
    while (base / f'run-{number:03}').exists():
        number += 1
    out = base / f'run-{number:03}'
    out.mkdir()
    scratch = out / 'scratch'
    tree = scratch / 'project'
    tree.mkdir(parents=True)
    started = datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%F %T JST')
    env = dict(os.environ, TZ='Asia/Tokyo', TMPDIR=str(scratch),
               EDD_SETTINGS_PATH=str(scratch / 'settings.cfg'))
    (scratch / 'settings.cfg').write_text('[ui]\ntext_scale=1.2\nlanguage="en"\n')
    try:
        with (scratch / 'source.tar').open('wb') as archive:
            call(['git', '-C', REPO, 'archive', sha], stdout=archive)
        with tarfile.open(scratch / 'source.tar') as archive:
            archive.extractall(tree, filter='data')
        shutil.copytree(REPO / 'tools/phase0', tree / 'tools/phase0', dirs_exist_ok=True)
        # Import/cache/log/temp output lives only on KIOXIA; no shader cache on SSD.
        (tree / 'override.cfg').write_text('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir="' + str(scratch / 'user') + '"\n[rendering]\nshader_compiler/shader_cache/enabled=false\n')
        with (out / 'import.log').open('w') as log:
            call(['godot', '--headless', '--path', tree, '--import', '--log-file', scratch / 'import-engine.log'], stdout=log, stderr=subprocess.STDOUT, env=env)
        with (out / 'parse.log').open('w') as log:
            call(['godot', '--headless', '--path', tree, '--check-only', '--script',
                  'res://tools/phase0/capture.gd', '--log-file', scratch / 'parse-engine.log'],
                 stdout=log, stderr=subprocess.STDOUT, env=env)
        argv = ['godot', '--path', str(tree), '--windowed', '--resolution', '1280x720',
                '--fixed-fps', '60', '--always-on-top', '--log-file', str(scratch / 'engine.log'),
                '--script', 'res://tools/phase0/capture.gd', '--', '--seed=7', f'--out={out}']
        with (out / 'capture.log').open('w') as log:
            call(argv, stdout=log, stderr=subprocess.STDOUT, env=env)
        log_text = (out / 'capture.log').read_text()
        if any(error in log_text for error in ('SCRIPT ERROR', 'SHADER ERROR', 'Assertion failed', 'Shader compilation failed')):
            raise RuntimeError(f'Godot capture failed: {out}/capture.log')
        receipts = json.loads((out / 'receipts.json').read_text())
        validate_receipts(out, receipts)
        captures = receipts['captures']
        for capture in captures:
            if capture['kind'] == 'clip':
                call(['ffmpeg', '-nostdin', '-v', 'error', '-framerate', '60', '-i',
                      scratch / capture['id'] / 'f_%05d.png', '-c:v', 'libx264', '-crf', '10',
                      '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out / capture['file']])
                require((out / capture['file']).stat().st_size > 0, f"{capture['id']}: empty clip")
        stills = [capture for capture in captures if capture['kind'] == 'still']
        tiles = []
        for capture in stills:
            tiles.extend(['-label', capture['id'], str(out / capture['file'])])
        call(['magick', 'montage', '-font', '/System/Library/Fonts/Helvetica.ttc', *tiles,
              '-resize', '320x180', '-tile', '4x', '-geometry', '+6+6', '-background', '#202020',
              '-fill', 'white', out / 'contact-sheet.jpg'])
        coverage = []
        for scene in sorted(tree.glob('scenes/*.tscn')):
            path = 'res://' + str(scene.relative_to(tree))
            coverage.append({'scene': path, 'state': 'scene', 'status': 'captured' if scene.name == 'main.tscn' else 'not_reviewed'})
        states = ['title', 'prep', 'prep_early', 'prep_late', 'totality', 'night', 'coda',
                  'rehearsal', 'hud', 'dialogue', 'dialogue_choices', 'plate_inspection',
                  'measurement_results', 'plate_loupe', 'plate_micrometer', 'plate_blink',
                  'settings', 'pause', 'help', 'log', 'credits', 'ending']
        for state in states:
            ids = [c['id'] for c in captures if state in (c['state'], c['ui_state'])]
            coverage.append({'scene': 'res://scenes/main.tscn', 'state': state,
                             'status': 'captured' if ids else 'not_reviewed', 'captures': ids})
        files = [{'file': c['file'], 'sha256': digest(out / c['file']),
                  'nondeterministic': True, 'reason': REASON} for c in captures]
        files.append({'file': 'contact-sheet.jpg', 'sha256': digest(out / 'contact-sheet.jpg'),
                      'nondeterministic': True, 'reason': 'Derived from nondeterministic GPU stills.'})
        files.append({'file': 'receipts.json', 'sha256': digest(out / 'receipts.json')})
        for name in ('import.log', 'parse.log', 'capture.log'):
            files.append({'file': name, 'sha256': digest(out / name), 'nondeterministic': True,
                          'reason': 'Engine startup and import logs contain runtime timings and run-specific paths.'})
        (out / 'execution.json').write_text(json.dumps({'started': started,
            'finished': datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%F %T JST')}, indent=2) + '\n')
        files.append({'file': 'execution.json', 'sha256': digest(out / 'execution.json'),
                      'nondeterministic': True, 'reason': 'Actual run wall-clock times in JST.'})
        manifest = {'capture_id': f'phase0-{sha}', 'commit_sha': sha,
                    'capture_command': f'tools/capture_phase0.py --commit {sha}',
                    'driver_sha256': digest(REPO / 'tools/phase0/capture.gd'),
                    'launcher_sha256': digest(Path(__file__)),
                    'godot_command': ['godot', '--path', '${RUN}/scratch/project', '--windowed',
                        '--resolution', '1280x720', '--fixed-fps', '60', '--always-on-top',
                        '--script', 'res://tools/phase0/capture.gd', '--', '--seed=7', '--out=${RUN}'],
                    'plate_fixture': 'Two native 6 s exposures at simulation 210 and 222 s, cloud density 1/30; strict rule; readings 0.87 and 1.75 arcsec.',
                    'execution_receipt': 'execution.json records JST wall times outside the stable manifest; manifest.json excludes its own hash.',
                    'golden_source': 'tests/benchmark.gd BOOKMARKS[0:7]; tools/look_shots.gd frame/UI/save helpers',
                    'renderer': receipts['renderer'], 'godot_version': receipts['godot_version'],
                    'time_zone': 'JST', 'captures': captures, 'coverage': coverage, 'files': files}
        candidate = out / 'candidate-manifest.json'
        candidate.write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n')
        previous = [marker.parent / 'manifest.json' for marker in sorted(base.glob('run-*/success'))]
        for path in previous:
            if comparable(json.loads(path.read_text())) != comparable(manifest):
                raise RuntimeError(f'Repeat manifest differs beyond declared pixel hashes: {path} vs {candidate}')
        candidate.rename(out / 'manifest.json')
        (out / 'success').write_text('Output validation and repeat comparison passed.\n')
        print(f'PHASE0 PASS: {len(stills)} stills, 3 clips, {len(previous)} repeat comparisons; {out}/manifest.json')
    finally:
        if not (out / 'execution.json').exists():
            (out / 'execution.json').write_text(json.dumps({'started': started,
                'finished': datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%F %T JST')}, indent=2) + '\n')
        shutil.rmtree(scratch)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--commit', required=True)
    parser.add_argument('--render', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    sha = subprocess.check_output(['git', '-C', REPO, 'rev-parse', '--verify', args.commit + '^{commit}'], text=True).strip()
    if not Path('/Volumes/KIOXIA').is_mount():
        raise RuntimeError('KIOXIA must be mounted; refusing SSD output')
    if args.render:
        render(sha)
    else:
        job_env = dict(os.environ, JOB_RUN_STATE=str(ROOT / '.jobs'))
        call(['job-run', '--id', f'phase0-{sha[:7]}-{os.getpid()}', '--artifact', ROOT / sha,
              '--', 'tachi-run', '--heavy', '--host', '--', 'python3', Path(__file__).resolve(), '--render', '--commit', sha], env=job_env)


if __name__ == '__main__':
    main()
