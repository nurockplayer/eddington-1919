#!/usr/bin/env python3
"""Run under job-run --id menus-page-shots -- orb-test --heavy --host."""
from datetime import datetime
import json
import os
from pathlib import Path
import subprocess
from zoneinfo import ZoneInfo

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


def contrast(image, rect, background):
    # Only pixels changed by suppressing this text belong to its glyphs.
    left, top, right, bottom = rect
    visible = (max(0, left), max(0, top), min(image.width, right), min(image.height, bottom))
    foreground = image.convert('RGB')
    background = background.convert('RGB')
    pixels = {}
    for y in range(visible[1], visible[3]):
        for x in range(visible[0], visible[2]):
            ink, paper = foreground.getpixel((x, y)), background.getpixel((x, y))
            if ink != paper:
                lo, hi = sorted((luminance(ink), luminance(paper)))
                pixels[x, y] = ((hi + 0.05) / (lo + 0.05), ink, paper)
    if not pixels:
        raise ValueError('No captured text pixels in contrast region')
    glyphs = []
    while pixels:
        point, sample = pixels.popitem()
        pending = [point]
        strongest = sample
        while pending:
            x, y = pending.pop()
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1),
                           (-1, -1), (-1, 1), (1, -1), (1, 1)):
                neighbour = (x + dx, y + dy)
                if neighbour in pixels:
                    sample = pixels.pop(neighbour)
                    if sample[0] > strongest[0]:
                        strongest = sample
                    pending.append(neighbour)
        # The strongest coverage excludes antialias edges within each glyph;
        # the weakest glyph determines whether the assessed text passes.
        glyphs.append(strongest)
    return min(glyphs, key=lambda sample: sample[0])


def main():
    from PIL import Image, ImageDraw

    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    out = Path('/Volumes/KIOXIA/eddington-1919-cache/director/menus-page') / head
    out.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    settings = out / 'settings'
    settings.mkdir(exist_ok=True)
    env['EDD_SETTINGS_PATH'] = str(settings / 'settings.cfg')
    run(['godot', '--headless', '--path', '.', '--import'], out / 'import.log', env)
    for test in ['test_pause_help', 'test_layout_bounds']:
        script = f'res://tests/{test}.gd'
        run(['godot', '--headless', '--path', '.', '--check-only', '--script', script], out / f'{test}-parse.log', env)
        run(['godot', '--headless', '--path', '.', '--script', script], out / f'{test}.log', env)
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
             'Contrast uses pixels changed by suppressing the assessed body/focused text, paired '
             'with the same pixels in the lossless text-background capture. Each connected glyph '
             'uses its strongest coverage to exclude antialias edges; the weakest glyph is reported. '
             'Lossless frame/background pairs, RGB samples and separate ratios are retained.', '',
             '| Frame | Body | Focused row | Body RGB (ink/paper) | Focus RGB (ink/paper) |',
             '|---|---:|---:|---|---|']
    for record in records:
        frame = record['frame']
        with Image.open(out / f'{frame}.png') as source:
            image = source.convert('RGB')
            with Image.open(out / record['text_background']) as background:
                body, blo, bhi = contrast(image, record['body'], background)
                focus, flo, fhi = contrast(image, record['focus'], background)
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
    print(f'menus-page: {len(records)} frames, 4 JPEG sheets, all measured contrast >= 4.5:1; {out}', flush=True)


if __name__ == '__main__':
    main()
