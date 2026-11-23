#!/usr/bin/env python3
"""PR #404 painted-caption revert check and selected/unselected plate-grid captures."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
from datetime import datetime
from zoneinfo import ZoneInfo

REPO = Path(__file__).resolve().parents[2]
BASELINE = 'fe3d3dac62138ad434005b025378bb463ff9eed1'


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
    revision_out = Path('/Volumes/KIOXIA/eddington-1919-cache/director/fix/layout-720p') / head
    revision_out.mkdir(parents=True, exist_ok=True)
    out = Path(tempfile.mkdtemp(prefix='run-', dir=revision_out))
    report = {'head': head, 'baseline': BASELINE,
              'at': datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%Y-%m-%d %H:%M:%S JST')}
    with tempfile.TemporaryDirectory(prefix='layout381-') as temp:
        scratch = Path(temp) / 'baseline'
        git('worktree', 'add', '--detach', str(scratch), BASELINE)
        try:
            env = dict(os.environ, EDD_SETTINGS_PATH=str(Path(temp) / 'settings.cfg'))
            shutil.copyfile(REPO / 'tests/test_layout_bounds.gd', scratch / 'tests/test_layout_bounds.gd')
            for relative in ['tools/layout_720p/capture.gd', 'tools/layout_720p/native_caption.gd']:
                shutil.copyfile(REPO / relative, scratch / relative)
            script = 'res://tools/layout_720p/capture.gd' 
            for name, cwd in [('baseline', scratch), ('fix', REPO)]:
                run(['godot', '--headless', '--path', '.', '--import'], cwd, out / f'{name}-import.log', env)
                for gd in ['res://tests/test_layout_bounds.gd', script]:
                    run(['godot', '--headless', '--path', '.', '--check-only', '--script', gd],
                        cwd, out / f'{name}-{Path(gd).stem}-parse.log', env)
                if name == 'baseline':
                    probe = out / 'native-probe'
                    probe.mkdir()
                    run(['godot', '--path', '.', '--windowed', '--resolution', '1280x720',
                         '--fixed-fps', '60', '--always-on-top', '--script', script, '--',
                         str(probe), '--native-probe'], cwd, out / 'native-probe.log', env)
                    report['native_probe'] = json.loads((probe / 'probe.json').read_text())
                    print(f"baseline native probe: {report['native_probe']}", flush=True)
                result = run(['godot', '--path', '.', '--windowed', '--resolution', '1280x720',
                              '--fixed-fps', '60', '--always-on-top', '--script',
                              'res://tests/test_layout_bounds.gd', '--', '--plate-pause-only'],
                             cwd, out / f'{name}-bounds.log', env, expected=1 if name == 'baseline' else 0)
                match = re.search(r'test_layout_bounds plate/pause: (\d+) checks, (\d+) failures', result)
                if not match or (name == 'baseline' and int(match[2]) == 0):
                    raise RuntimeError(f'{name}: missing expected bounds result')
                report[name] = match[0]
                print(f'{name}: {match[0]}', flush=True)
                overflows = re.findall(r'^Caption (\S+) tile (\d+) .* overflow ([0-9.]+) image_overlap (true|false) ink', result, re.M)
                semantics = re.findall(r'^Caption semantic (\S+) tile (\d+) .* violation (true|false) lines (.*)$', result, re.M)
                if name == 'baseline' and not any(language == 'zh_TW' and tile == '12'
                                                  and violation == 'true' and ' / 讀' in lines
                                                  for language, tile, violation, lines in semantics):
                    raise RuntimeError('baseline: no shown zh_TW plate 12 lone-character violation reproduced')
                report[f'{name}_captions'] = {}
                for locale in ['en', 'ja', 'zh_TW', 'ko']:
                    cases = [(int(tile), float(value), overlap == "true")
                             for language, tile, value, overlap in overflows if language == locale]
                    values = [value for _, value, _ in cases]
                    if len(values) != 156 or {tile for tile, _, _ in cases} != set(range(13)):
                        raise RuntimeError(f'{name} {locale}: expected 156 painted-caption cases across all 13 tiles, got {len(values)}')
                    summary = {'cases': len(values), 'overflows': sum(value > 0 for value in values),
                               'max_overflow': max(values),
                               'image_overlaps': sum(overlap for _, _, overlap in cases),
                               'semantic_violations': sum(violation == 'true' for language, _, violation, _ in semantics if language == locale)}
                    report[f'{name}_captions'][locale] = summary
                    print(f'{name} captions {locale}: {summary}', flush=True)
            folder = out / 'fix'
            folder.mkdir()
            run(['godot', '--path', '.', '--windowed', '--resolution', '1280x720',
                 '--fixed-fps', '60', '--always-on-top', '--script', script, '--', str(folder)],
                REPO, out / 'fix-capture.log', env)
        finally:
            git('worktree', 'remove', '--force', str(scratch))
    (out / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'layout_720p: counts and 10 Oxford PNGs saved to {out}', flush=True)


if __name__ == '__main__':
    main()
