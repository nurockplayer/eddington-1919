#!/usr/bin/env python3
"""Director evidence: fixed world mask, consecutive changes and main comparisons."""
import csv
import json
import math
from array import array
from datetime import datetime
from pathlib import Path
import shutil
import subprocess
import sys
from zoneinfo import ZoneInfo
from PIL import Image, ImageChops, ImageDraw, ImageMath, ImageStat


def changed(a, b, mask):
    channels = ImageChops.difference(a, b).split()
    maximum = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2])
    binary = maximum.point(lambda value: 255 if value >= 16 else 0)
    count = ImageChops.multiply(binary, mask).histogram()[255]
    means = ImageStat.Stat(ImageChops.difference(a, b), mask).mean
    return count, sum(means) / 3 / 255


def summarize(folder, out):
    records = [json.loads(line) for line in (folder / 'receipts.jsonl').read_text().splitlines()]
    reference = Image.open(folder / records[-1]['frame']).convert('RGB')
    width, height = reference.size
    forward, sun = records[0]['camera_forward'], records[0]['sun_dir']
    length = math.hypot(forward[0], forward[2])
    right = [-forward[2] / length, 0, forward[0] / length]
    up = [-forward[1] * forward[0] / length, length, -forward[1] * forward[2] / length]
    scale = math.tan(math.radians(records[0]['fov']) / 2)
    values = array('f')
    for y in range(height):
        py = (1 - 2 * (y + .5) / height) * scale
        for x in range(width):
            px = (2 * (x + .5) / width - 1) * scale * width / height
            ray = [forward[i] + px * right[i] + py * up[i] for i in range(3)]
            norm = math.sqrt(sum(v * v for v in ray))
            values.append(math.acos(max(-1, min(1, sum(ray[i] * sun[i] for i in range(3)) / norm))))
    angles = Image.frombytes('F', (width, height), values.tobytes())
    world = Image.new('L', (width, height))
    draw = ImageDraw.Draw(world)
    draw.rectangle((0, 80, width - 1, height - 221), fill=255)
    # The portrait arriving at +4.5 s was inside the old world mask. Exclude
    # the union of UI rectangles for ALL frames, including the ordinary interval.
    for record in records:
        for x, y, w, h in record['ui_rects']:
            draw.rectangle((int(x)-1, int(y)-1, math.ceil(x+w)+1, math.ceil(y+h)+1), fill=0)
    world.save(out / (folder.name + '-world-mask.png'))
    linear = [round(((i / 255 / 12.92) if i / 255 <= .04045 else ((i / 255 + .055) / 1.055) ** 2.4) * 255) for i in range(256)]

    def luminance(image, mask):
        means = [ImageStat.Stat(channel.point(linear), mask).mean[0] / 255 for channel in image.split()]
        return sum(v * w for v, w in zip(means, (.2126, .7152, .0722)))

    rows, previous = [], None
    screen_max = max(values)
    left = None
    with (out / (folder.name + '-luminance.tsv')).open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['contact_s', 'front_left', 'behind_pixels', 'mean_linear_luminance', 'same_pixels_at_plus6', 'delta', 'changed_pixels_vs_plus6_6pct', 'consecutive_changed_pixels_6pct', 'consecutive_mean_abs_rgb'])
        for record in records:
            radius = record['front_radius']
            trailing = radius - record['front_band'] if radius >= .06 else -1
            if record['contact_s'] >= 3 and radius < 0: trailing = math.pi + 1
            if left is None and trailing >= screen_max: left = record['contact_s']
            mask = ImageMath.unsafe_eval("convert((a < r) * 255, 'L')", a=angles, r=trailing)
            mask = ImageChops.multiply(mask, world)
            count = mask.histogram()[255]
            image = Image.open(folder / record['frame']).convert('RGB')
            current, final = (luminance(image, mask), luminance(reference, mask)) if count else (None, None)
            against_final = changed(image, reference, mask)[0] if count else 0
            pair_count, pair_mean = changed(image, previous, world) if previous else (0, 0)
            row = [record['contact_s'], left is not None, count, current, final,
                   current - final if count else None, against_final, pair_count, pair_mean]
            writer.writerow(row)
            rows.append(row)
            if previous: previous.close()
            previous = image
    previous.close()
    ordinary = [r for r in rows if 5 < r[0] <= 6]
    level = max(r[7] for r in ordinary)
    exceeds = [r for r in rows if left is not None and r[0] > left and r[7] > level]
    with (out / (folder.name + '-above-ordinary.tsv')).open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['contact_s', 'consecutive_changed_pixels_6pct', 'ordinary_max_6pct'])
        writer.writerows((r[0], r[7], level) for r in exceeds)
    summary = {'variant': folder.name, 'front_left_s': left, 'world_pixels': world.histogram()[255],
               'ordinary_max_changed': level, 'ordinary_mean_changed': sum(r[7] for r in ordinary)/len(ordinary),
               'ordinary_max_mean_abs_rgb': max(r[8] for r in ordinary), 'exceedances': len(exceeds),
               'post_front_max_changed': max(r[7] for r in rows if left is not None and r[0] > left)}
    if folder.name.startswith('delay-06'):
        # Native pixels: no enlargement or resampling. 19 crops, -0.2..+1.6 s.
        sheet = Image.new('RGB', (1500, 4 * 324), '#efe6d2')
        label = ImageDraw.Draw(sheet)
        for i in range(19):
            target = -.2 + i * .1
            record = min(records, key=lambda r: abs(r['contact_s'] - target))
            x, y = record['sun_pixel']
            image = Image.open(folder / record['frame']).convert('RGB')
            crop = image.crop((round(x)-150, round(y)-150, round(x)+150, round(y)+150))
            sheet.paste(crop, (i % 5 * 300, i // 5 * 324))
            label.text((i % 5 * 300 + 4, i // 5 * 324 + 302), f"{record['contact_s']:+.2f} s, native pixels", fill='#221c18')
        sheet.save(out / 'sheets' / (folder.name + '-sun-1x.png'))
    if folder.name == 'delay-06-7':
        prior = Path('/Volumes/KIOXIA/eddington-1919-cache/director/day-returns/d70ba99/clips/delay-06-7.mp4')
        decoder = subprocess.Popen(['ffmpeg', '-nostdin', '-loglevel', 'error', '-i', str(prior),
                                    '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'], stdout=subprocess.PIPE)
        sheet = Image.new('RGB', (600, 4 * 324), '#efe6d2')
        labels = ImageDraw.Draw(sheet)
        selected = {min(range(len(records)), key=lambda i: abs(records[i]['contact_s'] - t)): t
                    for t in (2.0, 2.5, 3.0, 3.5)}
        with (out / 'd70ba99-world-comparison.tsv').open('w') as file:
            writer = csv.writer(file, delimiter='\t')
            writer.writerow(['contact_s', 'world_changed_pixels_6pct', 'world_mean_abs_rgb'])
            for i, record in enumerate(records):
                data = decoder.stdout.read(width * height * 3)
                assert len(data) == width * height * 3, 'short d70ba99 clip'
                control = Image.frombytes('RGB', (width, height), data)
                candidate = Image.open(folder / record['frame']).convert('RGB')
                count, mean = changed(candidate, control, world)
                writer.writerow([record['contact_s'], count, mean])
                if i in selected:
                    row = list(selected).index(i)
                    x, y = map(round, record['sun_pixel'])
                    box = (x-150, y-150, x+150, y+150)
                    for col, picture in enumerate((control, candidate)):
                        sheet.paste(picture.crop(box), (col*300, row*324))
                        labels.text((col*300+4, row*324+302), f"{('d70ba99', 'candidate')[col]} {selected[i]:+.1f} s", fill='#221c18')
        decoder.stdout.close()
        assert decoder.wait() == 0
        sheet.save(out / 'sheets/glow-vs-d70ba99-sun-1x.png')
    if folder.name.startswith('thick'):
        peak = min(records, key=lambda r: abs(r['contact_s'] - .7))
        a = Image.open(folder / peak['frame']).convert('RGB')
        b = Image.open(folder / 'diamond-off.png').convert('RGB')
        x, y = peak['sun_pixel']
        mask = Image.new('L', a.size)
        ImageDraw.Draw(mask).rectangle((x-150, y-150, x+149, y+149), fill=255)
        summary['thick_peak_vs_diamond_off_6pct'] = changed(a, b, mask)[0]
        summary['thick_fixture'] = 'practice_cloud=0.97; third_contact_gap=0; presentation only'
        shutil.copyfile(folder / peak['frame'], out / 'thick-peak.png')
    (out / (folder.name + '-summary.json')).write_text(json.dumps(summary, indent=2) + '\n')


def report(out, main_sha, sha):
    comparisons = []
    main_records = [json.loads(line) for line in (out / 'compare-main/receipts.jsonl').read_text().splitlines()]
    candidate_records = [json.loads(line) for line in (out / 'compare-candidate/receipts.jsonl').read_text().splitlines()]
    for control, candidate in zip(main_records, candidate_records, strict=True):
        assert control['frame'] == candidate['frame']
        a = Image.open(out / 'compare-main' / control['frame']).convert('RGB')
        b = Image.open(out / 'compare-candidate' / candidate['frame']).convert('RGB')
        mask = Image.new('L', a.size, 255)
        if 'region' in control:
            x, y, w, h = control['region']
            mask = Image.new('L', a.size)
            ImageDraw.Draw(mask).rectangle((x, y, x+w-1, y+h-1), fill=255)
        delta = ImageChops.difference(a, b)
        exact = ImageChops.lighter(ImageChops.lighter(*delta.split()[:2]), delta.split()[2]).point(lambda v: 255 if v else 0)
        comparisons.append([control['frame'], ImageChops.multiply(exact, mask).histogram()[255], changed(a,b,mask)[0]])
    with (out / 'main-comparisons.tsv').open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['frame', 'changed_pixels_any', 'changed_pixels_6pct'])
        writer.writerows(comparisons)
    summaries = [json.loads(p.read_text()) for p in sorted(out.glob('*-summary.json'))]
    costs = []
    for path in sorted(out.glob('*-cost.tsv')):
        rows = list(csv.DictReader(path.open(), delimiter='\t'))
        for rep in range(3):
            values = sorted(float(r['forced_draw_ms']) for r in rows if int(r['rep']) == rep)
            p95 = values[math.ceil(.95 * len(values))-1]
            limit = 14.0 if path.stem.startswith('horizon-') and 'crossing' in path.stem else 11.1
            costs.append([path.stem, rep, sum(values)/len(values), p95, limit, p95 <= limit])
    with (out / 'frame-cost.tsv').open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['view', 'rep', 'forced_draw_mean_ms', 'forced_draw_p95_ms', 'limit_ms', 'within_budget'])
        writer.writerows(costs)
    cold = []
    for path in sorted(out.glob('cold-*-first-30.tsv')):
        rows = list(csv.DictReader(path.open(), delimiter='\t'))
        worst = max(rows, key=lambda r: float(r['process_and_draw_ms']))
        cold.append((path.stem, int(worst['frame_after_contact']), float(worst['forced_draw_ms']), float(worst['process_and_draw_ms'])))
    lines = [f'# Day returns follow-up 3\n\nCandidate `{sha}`; main control `{main_sha}`. Written {datetime.now(ZoneInfo("Asia/Tokyo")).strftime("%F %T JST")}.',
             '## Picture and implementation\n\nDefault delay is 0.6 s, crossing 1.8 s, band 2 degrees. Native 4× MSAA is retained on both endpoint worlds. The hidden day world stops drawing before the front. During the final 1.5 s ease, the native world renders geometry once; the day endpoint renders only its fixed sky print, which the native engraving pass blends into the live sky. The blend is cleared before its endpoint texture is released. Endpoint allocation and shader warm-up run under the real second-contact black fade. The native lighting tween, second-contact HUD handoff and star keyline from main are unchanged; the day endpoint has darkness zero and therefore no star rings.',
             'Clips: default seeds 7 and 1919, horizon and thick cloud in `clips/`. Sun-centred 300×300 crops at native pixels every 0.1 s from −0.2 to +1.6 s are in `sheets/`. `glow-vs-d70ba99-sun-1x.png` pairs +2.0, +2.5, +3.0, +3.5 s with the accepted delay-06-7 clip. `d70ba99-world-comparison.tsv` compares the fixed world region against that H.264 clip at every frame; it includes codec error, ordinary motion and main’s added star keyline. No threshold was relaxed.',
             '## Continuity\n\nThe director accepted the old five above-ordinary pairs as ordinary motion. The same fixed world mask and 16/255 channel threshold remain; all current pairs above the +5..+6 s ordinary maximum are retained in the TSVs. This list alone is not a new rejection of the accepted motion.',
             '| View | Front leaves (s) | Ordinary max / mean pixels | Post-front max | Above ordinary |\n|---|---:|---:|---:|---:|']
    for r in summaries:
        lines.append(f"| {r['variant']} | {r['front_left_s']} | {r['ordinary_max_changed']} / {r['ordinary_mean_changed']:.1f} | {r['post_front_max_changed']} | {r['exceedances']} |")
    lines += ['## Frame cost\n\n1280×720 native forced draws, 30 warm-up draws then 3 × 120 samples per stage. No present or PNG encoding is timed. The bead is +0.7 s, crossing +1.5 s, late +3.5 s, day +6 s. Main baselines use the identical two cameras and native contact route, totality immediately before third contact and day at +6 s. Horizon crossing alone has the decided 14.0 ms allowance for its 1.8 s; every other stage is limited to 11.1 ms. Crossing retains both native 4× worlds because the picture contains the night page and day page at once. The sky-only day endpoint replaces the second geometry pass during the late ease without lowering MSAA.',
              '| View / stage | Rep | Mean ms | p95 ms | Limit ms | Pass |\n|---|---:|---:|---:|---:|---|']
    lines += [f'| {view} | {rep} | {mean:.3f} | {p95:.3f} | {limit:.1f} | {ok} |' for view,rep,mean,p95,limit,ok in costs]
    lines += ['## First frames\n\nFresh Godot process per camera; real second-contact preparation happens before third contact. The first 30 frames include third-contact setup and forced drawing, with vsync disabled. Shader disk caches are not deleted. `process_and_draw_ms` includes game processing and activation on the first frame; PNG encoding is excluded. Raw values are retained.',
              '| View | Worst frame (0-based) | Draw ms | Process + draw ms |\n|---|---:|---:|---:|']
    lines += [f'| {view} | {frame} | {draw:.3f} | {total:.3f} |' for view,frame,draw,total in cold]
    second = [r for r in comparisons if 'second_' in r[0]]
    lines.append(f'## Main comparisons\n\nSecond contact: {len(second)} native-route samples, every 5 frames over 5 s; max changed pixels {max(r[1] for r in second)} exact / {max(r[2] for r in second)} at 6%. Paired sources for plate viewer, loupe, micrometer and result chart are retained in `compare-*/frames/`; counts in `main-comparisons.tsv`.')
    lines += [f'- {name}: {exact} exact / {threshold} at 6%.' for name,exact,threshold in comparisons if 'second_' not in name]
    thick = next(r for r in summaries if r['variant'].startswith('thick'))
    lines.append(f"## Thick cloud\n\nDensity 0.97 with the contact gap disabled, presentation only. Peak versus same-frame diamond-off control: {thick['thick_peak_vs_diamond_off_6pct']} changed Sun-region pixels at 6%.")
    lines.append('## Remaining gate\n\nDirector acceptance remains pending in a PR comment; #392 stays draft. Budget failures and nonzero main comparisons remain blocking. Windowed logs were checked for shader/script errors. Lossless clip frames and the temporary main snapshot were deleted after clips and tables were generated.')
    (out / 'report.md').write_text('\n\n'.join(lines) + '\n')


if sys.argv[1] == '--report':
    report(Path(sys.argv[2]), sys.argv[3], sys.argv[4])
else:
    summarize(*map(Path, sys.argv[1:]))
