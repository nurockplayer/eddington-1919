#!/usr/bin/env python3
"""job-run --id panel-toast-capture -- tachi-run --heavy --host -- python3 tools/panel_toast/run.py"""
import argparse
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


def prepare_output(out, overwrite=False):
    # report.md is written only after capture, encoding and every receipt check pass.
    complete = out / 'report.md'
    if complete.exists() and not overwrite:
        raise SystemExit(f'Complete capture at {out}; use --overwrite to replace it. Existing output was preserved.')
    complete.unlink(missing_ok=True)
    for name in ('main', 'fixed'):
        folder = out / name
        if folder.exists():
            shutil.rmtree(folder)
    out.mkdir(parents=True, exist_ok=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--overwrite', action='store_true', help='replace a complete capture')
    args = parser.parse_args()
    if shutil.disk_usage('/Volumes/KIOXIA').free < 3 * 1024**3:
        raise RuntimeError('KIOXIA has under 3 GB free; capture stopped')
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    out = Path('/Volumes/KIOXIA/eddington-1919-cache/director/panel-toast') / head[:7]
    prepare_output(out, args.overwrite)
    previous = out.parent / '2e62b35'
    shutil.copytree(previous / 'main', out / 'main')
    metadata = {'head': head, 'main': BASE, 'at': datetime.now(ZoneInfo('Asia/Tokyo')).isoformat()}
    name = 'fixed'
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
    (out / 'report.json').write_text(json.dumps(metadata, indent=2) + '\n')
    lines = [f"# Panel toast: sideways clearance", "", f"Candidate: {head}.",
             f"Completed: {metadata['at']}.", "", "## Tests", ""]
    for name in ['main', 'fixed']:
        log_path = out / 'checks' / f'{name}.log'
        if not log_path.exists():
            lines.append(f"- {name}: checks not run (optional log absent: {log_path}).")
            continue
        log = log_path.read_text()
        result = next(line for line in reversed(log.splitlines()) if line.startswith('test_layout_bounds totality toast:'))
        lines.append(f"- {name}: `{result}`")
    lines += ["", "## Capture", "", "Seed 7, totality_live, original 1600x900 canvas, full-size 1280x720 PNGs.",
              f"Main frames and clip reused from {previous / 'main'}.",
              "Fixed capture: `tachi-run --heavy --host -- python3 tools/panel_toast/run.py`.",
              "Protected corona: projected Sun centre and three solar radii in fixed/capture.json.", ""]
    centre = receipt['sun_pixels']
    radius = receipt['corona_radius_pixels']
    main_receipt = json.loads((out / 'main' / 'capture.json').read_text())
    for offset, label in [(72, 'plus-1.2s'), (150, 'plus-2.5s')]:
        frame = receipt['frames'][contact + offset]['hud']
        baseline = main_receipt['frames'][main_receipt['contact_frame'] + offset]['hud']
        x, y, w, h = frame['toast']['rect']
        nearest = [max(x, min(centre[0], x + w)), max(y, min(centre[1], y + h))]
        distance = ((nearest[0] - centre[0])**2 + (nearest[1] - centre[1])**2)**0.5
        gap = frame['tot_panel']['rect'][0] - (x + w)
        assert distance >= radius and gap >= 12.0 - 0.01, (label, distance, radius, gap)
        for key in ['tot_panel', 'clock_label', 'prompt_label', 'dialog_panel']:
            assert frame[key] == baseline[key], (label, key, frame[key], baseline[key])
        lines.append(f"- fixed/{label}.png: toast {[x, y, w, h]}, sideways gap {gap:.2f} px; corona radius {radius:.2f} px, nearest toast {distance:.2f} px. Other HUD receipts match main.")
    lines += ["", "## Assumptions", "", "Main's initial 90 px toast ends 60 canvas px above the bottom; additional lines grow upward from that edge. Fonts are unchanged. PR #398 stays draft.",
              "", "## Follow-ups", "", "Art-director acceptance; cx-exec runs the full Test command.", "", "## Blocked", "", "None."]
    (out / 'report.md').write_text('\n'.join(lines) + '\n')
    print(f'panel-toast capture: main/fixed clips and four 1280x720 PNGs saved to {out}')


if __name__ == '__main__':
    main()
