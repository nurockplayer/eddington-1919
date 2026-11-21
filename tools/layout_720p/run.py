#!/usr/bin/env python3
"""Row 8 main/fix counts and native 720p captures, inside one heavy host job."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from datetime import datetime
from zoneinfo import ZoneInfo
from PIL import Image

REPO = Path(__file__).resolve().parents[2]
MAIN = '3d392c21df9074753f77d4ed2b550bd04c66dc56'
OBSERVATION = '7350970'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=REPO, text=True).strip()


def run(args, cwd, log, env, expected=0):
    with log.open('w') as output:
        result = subprocess.run(args, cwd=cwd, env=env, stdout=output,
                                stderr=subprocess.STDOUT, timeout=1500)
    text = log.read_text()
    if result.returncode != expected or 'SCRIPT ERROR' in text or 'Parse Error' in text:
        raise RuntimeError(f'{args}: exit {result.returncode}; see {log}')
    return text


def main():
    if shutil.disk_usage('/Volumes/KIOXIA').free < 3 * 1024**3:
        raise RuntimeError('KIOXIA has under 3 GB free; stopped')
    head = git('rev-parse', 'HEAD')
    out = Path('/Volumes/KIOXIA/eddington-1919-cache/director/fix/layout-720p') / head
    out.mkdir(parents=True, exist_ok=False)
    report = {'head': head, 'main': MAIN,
              'at': datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%Y-%m-%d %H:%M:%S JST')}
    with tempfile.TemporaryDirectory(prefix='layout381-') as temp:
        scratch = Path(temp) / 'main'
        git('worktree', 'add', '--detach', str(scratch), MAIN)
        try:
            env = dict(os.environ, EDD_SETTINGS_PATH=str(Path(temp) / 'settings.cfg'))
            # Main's drawing is unchanged: only record the rectangles it paints.
            (scratch / 'scripts/chart.gd').write_text(git('show', f'{OBSERVATION}:scripts/chart.gd') + '\n')
            shutil.copyfile(REPO / 'tests/test_layout_bounds.gd', scratch / 'tests/test_layout_bounds.gd')
            script = 'res://tools/layout_720p/capture.gd'
            (scratch / 'tools/layout_720p').mkdir()
            shutil.copyfile(REPO / 'tools/layout_720p/capture.gd', scratch / 'tools/layout_720p/capture.gd')
            for name, cwd in [('main', scratch), ('fix', REPO)]:
                folder = out / name
                folder.mkdir()
                run(['godot', '--headless', '--path', '.', '--import'], cwd, out / f'{name}-import.log', env)
                for gd in ['res://scripts/ui.gd', 'res://scripts/chart.gd',
                           'res://tests/test_layout_bounds.gd', script]:
                    run(['godot', '--headless', '--path', '.', '--check-only', '--script', gd],
                        cwd, out / f'{name}-{Path(gd).stem}-parse.log', env)
                result = run(['godot', '--headless', '--path', '.', '--script',
                              'res://tests/test_layout_bounds.gd', '--', '--plate-pause-only'],
                             cwd, out / f'{name}-bounds.log', env, expected=1 if name == 'main' else 0)
                match = re.search(r'test_layout_bounds plate/pause: (\d+) checks, (\d+) failures', result)
                if not match or (name == 'main' and int(match[2]) == 0):
                    raise RuntimeError(f'{name}: missing expected bounds result')
                report[name] = match[0]
                print(f'{name}: {match[0]}', flush=True)
                if name == 'main':
                    (scratch / 'scripts/chart.gd').write_text(git('show', f'{MAIN}:scripts/chart.gd') + '\n')
                    run(['godot', '--headless', '--path', '.', '--check-only', '--script', script],
                        cwd, out / 'main-native-parse.log', env)
                run(['godot', '--path', '.', '--windowed', '--resolution', '1280x720',
                     '--fixed-fps', '60', '--always-on-top', '--script', script, '--', str(folder)],
                    cwd, out / f'{name}-capture.log', env)
            pairs = out / 'side-by-side'
            pairs.mkdir()
            for frame in sorted((out / 'fix').glob('*.png')):
                with Image.open(out / 'main' / frame.name) as before, Image.open(frame) as after:
                    assert before.size == after.size == (1280, 720)
                    pair = Image.new('RGB', (2560, 720))
                    pair.paste(before, (0, 0))
                    pair.paste(after, (1280, 0))
                    pair.save(pairs / frame.name)
        finally:
            git('worktree', 'remove', '--force', str(scratch))
            for name in ['tests/test_second_contact_fade.gd.uid',
                         'tools/day_returns/handoff.gd.uid', 'tools/panel_toast/capture.gd.uid']:
                (REPO / name).unlink(missing_ok=True)
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'layout_720p: counts and 48 named PNGs saved to {out}', flush=True)


if __name__ == '__main__':
    main()
