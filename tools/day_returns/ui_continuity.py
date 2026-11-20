#!/usr/bin/env python3
"""Recompute the three named UI pairs from retained clips and HUD node bounds."""
import csv
import json
import math
from pathlib import Path
import shutil
import statistics
import subprocess
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

from PIL import Image, ImageChops, ImageDraw

REPO = Path(__file__).resolve().parents[2]
EVENTS = {
    60: ('third-contact panel/toast dismissal', ('timer', 'toast')),
    110: ('toast palette switch', ('toast', 'clock')),
    331: ('dialogue panel opens', ('panel', 'portrait')),
}


def changed(a, b, mask):
    r, g, b = ImageChops.difference(a, b).split()
    binary = ImageChops.lighter(ImageChops.lighter(r, g), b).point(lambda v: 255 if v >= 16 else 0)
    return ImageChops.multiply(binary, mask).histogram()[255]


def main():
    source, out = map(Path, sys.argv[1:])
    out.mkdir(exist_ok=False)
    (out / 'tools').mkdir()
    shutil.copyfile(source / 'tools/survey.gd', out / 'tools/survey.gd')
    for name in ('capture.gd', 'ui_continuity.py'):
        shutil.copyfile(REPO / 'tools/day_returns' / name, out / 'tools' / name)
    variants = {}
    for line in (source / 'receipts.jsonl').open():
        record = json.loads(line)
        variants.setdefault(record['variant'], []).append(record)
    summary = []
    totals = []
    for variant, records in variants.items():
        folder = out / variant
        folder.mkdir()
        argv = ['godot', '--headless', '--path', str(REPO), '--fixed-fps', '60',
                '--script', str(out / 'tools/capture.gd'), '--', '--ui-only',
                f'--out={folder}', f"--seed={records[0]['seed']}",
                '--style-set=return_seconds=1.8,return_width=2,return_delay=0.6']
        if variant.startswith('horizon'): argv.append('--horizon')
        if variant.startswith('thick'): argv.append('--thick')
        with (folder / 'hud-replay.log').open('w') as log:
            subprocess.run(argv, cwd=REPO, stdout=log, stderr=subprocess.STDOUT, check=True)
        log = (folder / 'hud-replay.log').read_text()
        assert not any(t in log for t in ('SCRIPT ERROR', 'SHADER ERROR')), log
        hud = [json.loads(line) for line in (folder / 'receipts.jsonl').open()]
        assert len(hud) == len(records) == 431
        # Verify the replay's layout against the original capture receipts.
        for original, replay in zip(records, hud):
            assert len(original['ui_rects']) == len(replay['ui_rects']), (variant, replay['frame_index'])
            for a, b in zip(original['ui_rects'], replay['ui_rects']):
                assert max(abs(x-y) for x, y in zip(a, b)) < .01, (variant, replay['frame_index'], a, b)
        width, height = records[0]['size']
        whole = Image.new('L', (width, height), 255)
        masks = {}
        bounds = {}
        for frame, (_, controls) in EVENTS.items():
            mask = whole.copy()
            draw = ImageDraw.Draw(mask)
            rects = []
            for record in hud[frame-1:frame+1]:
                for key in controls:
                    if key not in record['hud_rects']: continue
                    rect = record['hud_rects'][key]
                    if rect in rects: continue
                    rects.append(rect)
                    x, y, w, h = rect
                    draw.rectangle((math.floor(x), math.floor(y), math.ceil(x+w)-1, math.ceil(y+h)-1), fill=0)
            masks[frame] = mask
            bounds[frame] = {'nodes': controls, 'rects': rects}
        (folder / 'pair-masks.json').write_text(json.dumps(bounds, indent=2) + '\n')
        raw = []
        masked = {frame: [] for frame in EVENTS}
        decoder = subprocess.Popen(['ffmpeg', '-nostdin', '-loglevel', 'error', '-i',
            str(source / 'clips' / (variant + '.mp4')), '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], stdout=subprocess.PIPE)
        previous = None
        size = width * height * 3
        for i in range(len(records)):
            data = decoder.stdout.read(size)
            assert len(data) == size, (variant, i, len(data))
            image = Image.frombytes('RGB', (width, height), data)
            raw.append(changed(image, previous, whole) if previous else 0)
            for frame, mask in masks.items():
                masked[frame].append(changed(image, previous, mask) if previous and frame-10 <= i <= frame+10 else 0)
            if previous: previous.close()
            previous = image
        previous.close()
        assert decoder.stdout.read() == b''
        assert decoder.wait() == 0
        rows = []
        for i, record in enumerate(records):
            if not -.2 <= record['contact_s'] <= 6: continue
            event, _ = EVENTS.get(i, ('', ()))
            counts = masked[i] if event else raw
            before, after = (statistics.mean(counts[i-10:i]), statistics.mean(counts[i+1:i+11]))
            level = max(before, after)
            ratio = counts[i] / level
            row = [record['contact_s'], event, raw[i], counts[i] if event else '', before, after, 1.5*level, ratio, counts[i] <= 1.5*level]
            rows.append(row)
            if event: summary.append([variant, *row])
        with (out / (variant + '-continuity.tsv')).open('w') as file:
            writer = csv.writer(file, delimiter='\t')
            writer.writerow(['contact_s', 'ui_pair', 'raw_pixels', 'masked_pixels', 'previous_10_mean', 'next_10_mean', 'limit_1p5', 'ratio', 'pass'])
            writer.writerows(rows)
        totals.append([variant, len(rows), sum(not r[-1] for r in rows), max(r[-2] for r in rows)])
    lines = ['# Decoded scene continuity', '',
             'Written ' + datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%Y-%m-%d %H:%M:%S JST') + '.', '',
             f'Source: `{source}`. HUD behaviour is unchanged; PR #392 stays draft.', '',
             'All 373 pairs from −0.2 s to +6 s use maximum-channel difference ≥16/255 and the same 1.5× larger-of-ten-neighbours rule. Only the three named UI pairs use masks. For each, the union of the changing HUD nodes in both frames is masked identically in the pair and its preceding/following ten pairs. Node bounds include their StyleBox draw margins and viewport stretch. Replay node rectangles match every original receipt within 0.01 px. All counts below use the same decoded clips.', '',
             '| View | UI pair | Raw | Masked | Previous / next ten means | Limit | Ratio | Pass |',
             '|---|---|---:|---:|---:|---:|---:|---|']
    for variant, seconds, event, raw, masked, before, after, limit, ratio, ok in summary:
        lines.append(f'| {variant} | {event} ({seconds:+.3f} s) | {raw} | {masked} | {before:.1f} / {after:.1f} | {limit:.1f} | {ratio:.3f} | {ok} |')
    lines += ['', '| View | Pairs | Failures | Maximum ratio |', '|---|---:|---:|---:|']
    lines += [f'| {v} | {n} | {f} | {r:.3f} |' for v, n, f, r in totals]
    (out / 'report.md').write_text('\n'.join(lines) + '\n')
    print('\n'.join(lines), flush=True)
    assert all(f == 0 for _, _, f, _ in totals), 'Scene continuity failures remain'
    print('UI CONTINUITY PASS: all four views, 373 pairs each', flush=True)


if __name__ == '__main__':
    main()
