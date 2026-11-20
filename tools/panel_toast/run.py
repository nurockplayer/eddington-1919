#!/usr/bin/env python3
"""job-run --id panel-toast-capture -- orb-test --heavy --host -- python3 tools/panel_toast/run.py"""
import json
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
from zoneinfo import ZoneInfo

REPO = Path(__file__).resolve().parents[2]
BASE = '8131b169af4a709cfcff134af9fedd405704a266'


def run(argv, log):
    with log.open('w') as output:
        subprocess.run(argv, cwd=REPO, stdout=output, stderr=subprocess.STDOUT, check=True)
    if any(token in log.read_text() for token in ('SCRIPT ERROR', 'SHADER ERROR', 'Parse Error')):
        raise RuntimeError(f'Godot error: {log}')


def main():
    if shutil.disk_usage('/Volumes/KIOXIA').free < 3 * 1024**3:
        raise RuntimeError('KIOXIA has under 3 GB free; capture stopped')
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    out = Path('/Volumes/KIOXIA/eddington-1919-cache/director/panel-toast') / head[:7]
    out.mkdir(parents=True, exist_ok=True)
    source = REPO / 'scripts/hud_paper.gd'
    fixed = source.read_bytes()
    baseline = subprocess.check_output(['git', 'show', f'{BASE}:scripts/hud_paper.gd'], cwd=REPO)
    metadata = {'head': head, 'main': BASE, 'at': datetime.now(ZoneInfo('Asia/Tokyo')).isoformat()}
    try:
        for name, layout in [('main', baseline), ('fixed', fixed)]:
            source.write_bytes(layout)
            folder = out / name
            folder.mkdir()
            script = 'res://tools/panel_toast/capture.gd'
            run(['godot', '--headless', '--path', '.', '--check-only', '--script', script], out / f'{name}-parse.log')
            command = ['godot', '--path', '.', '--windowed', '--resolution', '1280x720',
                       '--fixed-fps', '60', '--always-on-top', '--script', script, '--', f'--out={folder}']
            run(command, out / f'{name}-capture.log')
            receipt = json.loads((folder / 'capture.json').read_text())
            assert receipt['seed'] == 7 and receipt['content_scale_size'] == [1600, 900], receipt
            contact = receipt['contact_frame']
            assert contact >= 60, receipt
            for offset, label in [(72, 'plus-1.2s'), (150, 'plus-2.5s')]:
                shutil.copyfile(folder / f'f_{contact + offset:05}.png', folder / f'{label}.png')
            run(['ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error', '-framerate', '60',
                 '-start_number', str(contact - 60), '-i', str(folder / 'f_%05d.png'),
                 '-frames:v', '241', '-c:v', 'libx264', '-crf', '10', '-pix_fmt', 'yuv420p',
                 '-movflags', '+faststart', str(folder / 'second-contact.mp4')], out / f'{name}-encode.log')
            # Only this run's intermediate lossless sequence is removed.
            for frame in folder.glob('f_*.png'):
                frame.unlink()
            metadata[name] = {'command': command, 'contact_frame': contact, 'receipt': str(folder / 'capture.json')}
    finally:
        source.write_bytes(fixed)
    (out / 'report.json').write_text(json.dumps(metadata, indent=2) + '\n')
    print(f'panel-toast capture: main/fixed clips and four 1280x720 PNGs saved to {out}')


if __name__ == '__main__':
    main()
