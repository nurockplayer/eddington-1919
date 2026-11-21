#!/usr/bin/env python3
"""Run via job-run -- tachi-run --heavy --host -- python3 tools/faceless_3d/run.py."""
from datetime import datetime
import json
from pathlib import Path
import shutil
import subprocess
from zoneinfo import ZoneInfo

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]
CACHE = Path('/Volumes/KIOXIA/eddington-1919-cache/director/faceless-3d')


def run(args, cwd, log):
    with log.open('w') as f:
        subprocess.run(args, cwd=cwd, stdout=f, stderr=subprocess.STDOUT, check=True, timeout=1500)
    # Windowed execution is required: headless does not compile these shaders.
    with log.open() as f:
        for line in f:
            if any(s in line for s in ['SCRIPT ERROR', 'SHADER ERROR', 'Shader compilation failed']):
                raise RuntimeError(f'{log}: {line.strip()}')


def main():
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    out = CACHE / head
    out.mkdir(parents=True, exist_ok=False)
    reference = CACHE / 'reference-fc6aeb2'
    manifest = {'captured_at': datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%F %T JST'),
                'head': head, 'main': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=reference, text=True).strip()}
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    for label, repo in [('main', reference), ('head', REPO)]:
        dest = out / label
        dest.mkdir()
        capture = repo / 'tools/faceless_3d/capture.gd'
        if repo != REPO:
            capture.parent.mkdir(parents=True)
            shutil.copyfile(REPO / 'tools/faceless_3d/capture.gd', capture)
        run(['godot', '--headless', '--path', '.', '--import'], repo, dest / 'import.log')
        run(['godot', '--headless', '--path', '.', '--check-only', '--script', 'res://tools/faceless_3d/capture.gd'], repo, dest / 'parse.log')
        if label == 'head':
            run(['godot', '--headless', '--path', '.', '--script', 'res://tests/test_night_dress.gd'], repo, dest / 'test_night_dress.log')
        run(['godot', '--path', '.', '--resolution', '1280x720', '--fixed-fps', '60', '--always-on-top',
             '--script', 'res://tools/faceless_3d/capture.gd', '--', '--out=' + str(dest / 'measurements.json'),
             '--capture=' + str(dest / 'frames')], repo, dest / 'windowed.log')
    measurements = json.loads((out / 'head/measurements.json').read_text())
    cases = []
    for person in ['eddington', 'cottingham']:
        cases.append(('totality_' + person, None))
        closest = min((r for r in measurements if r['scene'] == 'day' and r['character'] == person), key=lambda r: r['metres'])
        cases.append((f'day_{person}_{closest["direction"]}', closest['metres']))
    sheet = Image.new('RGB', (1000, len(cases) * 540), 'white')
    draw = ImageDraw.Draw(sheet)
    for row, (name, distance) in enumerate(cases):
        draw.text((8, row * 540 + 8), f'{name}: main left / head right' + (f'; {distance:.3f} m' if distance else ''), fill='black')
        for col, label in enumerate(['main', 'head']):
            frame = Image.open(out / label / 'frames' / (name + '.png')).convert('RGB')
            sheet.paste(frame.crop((390, 80, 890, 580)), (col * 500, row * 540 + 35))
    sheet.save(out / 'main-vs-head-faces.png')
    differences = {}
    for phase in ['day', 'totality']:
        paths = [str(out / label / 'frames' / (phase + '_wide.png')) for label in ['main', 'head']]
        recipe = ['-compose', 'difference', '-composite', '-separate', '-evaluate-sequence', 'max', '-threshold', '6%']
        count = subprocess.check_output(['magick', *paths, *recipe, '-format', '%[fx:mean*w*h]', 'info:'], text=True)
        differences[phase] = int(float(count))
        subprocess.run(['magick', *paths, *recipe, str(out / (phase + '-difference.png'))], check=True)
        subprocess.run(['magick', *paths, '+append', str(out / (phase + '-main-vs-head.png'))], check=True)
    (out / 'wide-differences.json').write_text(json.dumps(differences, indent=2) + '\n')
    print('Wide differences (>6% in any channel):', differences)
    print('Face packet:', out)
    print('faceless capture: completed')


if __name__ == '__main__':
    main()
