#!/usr/bin/env python3
"""Reproducible windowed census. Public entry: tools/capture_phase0.py --commit SHA."""
import argparse
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
from zoneinfo import ZoneInfo

REPO = Path(__file__).resolve().parents[1]
ROOT = Path('/Volumes/KIOXIA/eddington-1919-cache/director/phase0')
REASON = 'Live GPU shader TIME, particle animation and temporal rendering history; fixed seed and 60 Hz do not guarantee identical pixels.'


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
        captures = receipts['captures']
        for capture in captures:
            if capture['kind'] == 'clip':
                call(['ffmpeg', '-nostdin', '-v', 'error', '-framerate', '60', '-i',
                      scratch / capture['id'] / 'f_%05d.png', '-c:v', 'libx264', '-crf', '10',
                      '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out / capture['file']])
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
        (out / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + '\n')
        previous = sorted(base.glob('run-*/manifest.json'))[:-1]
        for path in previous:
            if comparable(json.loads(path.read_text())) != comparable(manifest):
                raise RuntimeError(f'Repeat manifest differs beyond declared pixel hashes: {path} vs {out}/manifest.json')
        print(f'PHASE0 PASS: {len(stills)} stills, 3 clips, {len(previous)} repeat comparisons; {out}/manifest.json')
    finally:
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
        call(['job-run', '--id', f'phase0-{sha[:7]}-{os.getpid()}', '--artifact', ROOT / sha,
              '--', 'tachi-run', '--heavy', '--host', '--', 'python3', Path(__file__).resolve(), '--render', '--commit', sha])


if __name__ == '__main__':
    main()
