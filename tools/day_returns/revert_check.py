#!/usr/bin/env python3
"""Run the delay visibility regression, then prove the old layer assignment fails."""
from pathlib import Path
import re
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[2]
out = Path(sys.argv[1]).resolve()
out.mkdir(exist_ok=False)


def run(name, path, *args):
    command = ['godot', '--headless', '--path', str(path), *args]
    with (out / f'{name}.log').open('w') as log:
        result = subprocess.run(command, cwd=repo, stdout=log, stderr=subprocess.STDOUT)
    text = (out / f'{name}.log').read_text()
    print(name, 'exit', result.returncode, flush=True)
    for line in text.splitlines():
        if line.startswith('test_day_return:'):
            print(line, flush=True)
    return result.returncode, text


code, text = run('fixed', repo, '--script', 'res://tests/test_day_return.gd')
assert code == 0 and '0 failures' in text, text[-3000:]
with tempfile.TemporaryDirectory(prefix='day-return-revert-', dir=out) as scratch:
    control = Path(scratch)
    archive = subprocess.Popen(['git', 'archive', 'HEAD'], cwd=repo, stdout=subprocess.PIPE)
    subprocess.run(['tar', '-x', '-C', str(control)], stdin=archive.stdout, check=True)
    archive.stdout.close()
    assert archive.wait() == 0
    source = control / 'scripts/styles/day_return.gd'
    fixed = '\t\tcompositor.layers = compositor_layers if started() else 1 << 19'
    assert source.read_text().count(fixed) == 1
    source.write_text(source.read_text().replace(fixed, '\t\tcompositor.layers = compositor_layers'))
    code, text = run('reverted-import', control, '--editor', '--import')
    assert code == 0, text[-3000:]
    code, text = run('reverted', control, '--script', 'res://tests/test_day_return.gd')
    failures = [line for line in text.splitlines() if line.startswith('FAIL:')]
    assert code == 1 and len(failures) == 102, text[-3000:]
    assert all('return compositor is visible to the camera at frame' in line for line in failures)
    assert re.search(r'test_day_return: \d+ checks, 102 failures', text)
print('REVERT CHECK PASS: fixed passes; old delay layer fails 102 visibility checks', flush=True)
