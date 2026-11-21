#!/usr/bin/env python3
"""Run under job-run --id menus-page-shots -- orb-test --heavy --host."""
from collections import Counter
from datetime import datetime
import json
import os
from pathlib import Path
import subprocess
from zoneinfo import ZoneInfo

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]


def run(command, log, env):
    with log.open('w') as output:
        subprocess.run(command, cwd=REPO, env=env, stdout=output,
                       stderr=subprocess.STDOUT, check=True, timeout=1500)
    errors = ('SCRIPT ERROR', 'SHADER ERROR', 'Parse Error')
    for line in log.read_text().splitlines():
        if any(error in line for error in errors):
            raise RuntimeError(f'{log}: {line}')
    print(f'{log.name}: ' + '\n'.join(log.read_text().splitlines()[-3:]), flush=True)


def luminance(rgb):
    linear = [v / 255 / 12.92 if v / 255 <= 0.04045 else ((v / 255 + 0.055) / 1.055) ** 2.4 for v in rgb]
    return sum(a * b for a, b in zip(linear, (0.2126, 0.7152, 0.0722)))


def contrast(image, rect):
    # Solid glyph interiors and paper, measured in the captured lossless frame.
    # Ignore antialias edge coverage; no palette constants enter the calculation.
    left, top, right, bottom = rect
    visible = (max(0, left), max(0, top), min(image.width, right), min(image.height, bottom))
    colours = Counter(image.crop(visible).convert('RGB').getdata())
    samples = [rgb for rgb, count in colours.items() if count >= 3]
    lo, hi = min(samples, key=luminance), max(samples, key=luminance)
    return (luminance(hi) + 0.05) / (luminance(lo) + 0.05), lo, hi


def main():
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    out = Path('/Volumes/KIOXIA/eddington-1919-cache/director/menus-page') / head
    out.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    settings = out / 'settings'
    settings.mkdir(exist_ok=True)
    env['EDD_SETTINGS_PATH'] = str(settings / 'settings.cfg')
    run(['godot', '--headless', '--path', '.', '--import'], out / 'import.log', env)
    script = 'res://tools/menus_page/capture.gd'
    run(['godot', '--headless', '--path', '.', '--check-only', '--script', script], out / 'capture-parse.log', env)
    run(['godot', '--path', '.', '--windowed', '--resolution', '1280x720',
         '--fixed-fps', '60', '--always-on-top', '--script', script, '--', f'--out={out}'], out / 'capture.log', env)
    records = json.loads((out / 'frames.json').read_text())
    lines = ['# Menus on the engraved page', '', f'Code candidate: `{head}`.',
             f'Captured: {datetime.now(ZoneInfo("Asia/Tokyo")).strftime("%Y-%m-%d %H:%M JST")}.', '',
             'Seed 7; windowed 1280×720, fixed 60 fps; project canvas and stretch settings unchanged. '
             'Every screen has its opening focus. Options are opened from title; pause/help/history from camp; '
             'ending uses the real run record. The English default set includes pause after the native second-contact transition.', '',
             'Sheets: `sheet-en.jpg`, `sheet-ja.jpg`, `sheet-zh_TW.jpg`, `sheet-ko.jpg`. '
             'Each tile and native JPEG is named `<locale>_<default|max>_<screen>`. '
             'Maximum text size is 1.2. Focus uses reversed ink and a heavier rule.', '',
             'Contrast uses the darkest and lightest repeated solid pixels (at least three occurrences) '
             'inside the recorded body/focused-text rectangles in `frames.json`, before JPEG encoding. '
             'Antialias edge coverage is excluded; RGB samples and ratios are retained below.', '',
             '| Frame | Body | Focused row | Body RGB (ink/paper) | Focus RGB (ink/paper) |',
             '|---|---:|---:|---|---|']
    for record in records:
        frame = record['frame']
        with Image.open(out / f'{frame}.png') as source:
            image = source.convert('RGB')
            body, blo, bhi = contrast(image, record['body'])
            focus, flo, fhi = contrast(image, record['focus'])
            assert min(body, focus) >= 4.5, (frame, body, focus)
            record.update(body_contrast=body, focus_contrast=focus,
                          body_rgb=[blo, bhi], focus_rgb=[flo, fhi])
            image.save(out / f'{frame}.jpg', quality=94, subsampling=0)
        lines.append(f'| {frame} | {body:.2f}:1 | {focus:.2f}:1 | {blo}/{bhi} | {flo}/{fhi} |')
    for locale in ['en', 'ja', 'zh_TW', 'ko']:
        frames = [record['frame'] for record in records if record['frame'].startswith(locale + '_')]
        columns = 4 if len(frames) > 8 else 3
        width = 1280 // columns
        height = round(width * 720 / 1280)
        tile_height = height + 26
        sheet = Image.new('RGB', (width * columns, tile_height * ((len(frames) + columns - 1) // columns)), '#efe6d2')
        draw = ImageDraw.Draw(sheet)
        for i, frame in enumerate(frames):
            x, y = (i % columns) * width, (i // columns) * tile_height
            with Image.open(out / f'{frame}.jpg') as image:
                sheet.paste(image.resize((width, height), Image.Resampling.LANCZOS), (x, y + 26))
            draw.text((x + 6, y + 6), frame, fill='#221c18')
        sheet.save(out / f'sheet-{locale}.jpg', quality=94, subsampling=0)
    (out / 'frames.json').write_text(json.dumps(records, indent=2) + '\n')
    (out / 'report.md').write_text('\n'.join(lines) + '\n')
    # Delete only lossless scratch produced by this capture, after all sheets exist.
    for record in records:
        (out / f"{record['frame']}.png").unlink()
    print(f'menus-page: {len(records)} frames, 4 JPEG sheets, all measured contrast >= 4.5:1; {out}', flush=True)


if __name__ == '__main__':
    main()
