#!/usr/bin/env python3
"""Director evidence: fixed world mask, consecutive changes and main comparisons."""
import csv
import json
import math
from array import array
from datetime import datetime
from pathlib import Path
import shutil
import statistics
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
    whole_counts = []
    whole = Image.new('L', (width, height), 255)
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
            whole_counts.append(changed(image, previous, whole)[0] if previous else 0)
            row = [record['contact_s'], left is not None, count, current, final,
                   current - final if count else None, against_final, pair_count, pair_mean]
            writer.writerow(row)
            rows.append(row)
            if previous: previous.close()
            previous = image
    previous.close()
    continuity = []
    presence = []
    for i, record in enumerate(records):
        if not -0.2 <= record['contact_s'] <= 6.0: continue
        with Image.open(folder / record['frame']) as image, Image.open(folder / record['frame'].replace('/f_', '/bare_')) as bare:
            count = changed(image.convert('RGB'), bare.convert('RGB'), whole)[0]
        share = count / (width * height)
        presence.append([i, record['contact_s'], count, share, 0.25, share >= 0.25])
        before = statistics.mean(whole_counts[i-10:i])
        after = statistics.mean(whole_counts[i+1:i+11])
        level = max(before, after)
        ui_event = 'dialogue panel opens' if abs(record['contact_s'] - 4.5166666667) < 0.001 else ''
        continuity.append([record['contact_s'], whole_counts[i], before, after,
                           1.5 * level, whole_counts[i] / level, bool(ui_event) or whole_counts[i] <= 1.5 * level, ui_event])
    with (out / (folder.name + '-whole-frame-continuity.tsv')).open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['contact_s', 'whole_changed_pixels_6pct', 'previous_10_mean', 'next_10_mean', 'limit_1p5', 'ratio', 'pass', 'ui_event'])
        writer.writerows(continuity)
    with (out / (folder.name + '-scene-presence.tsv')).open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['frame', 'contact_s', 'pixels_different_from_bare_environment_6pct', 'share', 'minimum_share', 'pass'])
        writer.writerows(presence)
    step = min(continuity, key=lambda r: abs(r[0]-3.0))
    decoded = []
    for packet in (Path('/Volumes/KIOXIA/eddington-1919-cache/director/day-returns/5316288'), out):
        data = subprocess.check_output(['ffmpeg', '-nostdin', '-loglevel', 'error', '-i',
            str(packet / 'clips' / (folder.name + '.mp4')), '-vf', 'select=between(n\\,239\\,240)',
            '-frames:v', '2', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-'])
        n = width * height * 3
        assert len(data) == 2*n, 'expected the two +3.0 s frames'
        decoded.append(changed(Image.frombytes('RGB', (width,height), data[:n]),
                               Image.frombytes('RGB', (width,height), data[n:]), whole)[0])
    if folder.name.startswith('horizon') and left is not None:
        end = next(i for i, r in enumerate(records) if r['contact_s'] == left)
        strip = Image.new('RGB', (width * 8, height))
        for j, record in enumerate(records[end-8:end]):
            strip.paste(Image.open(folder / record['frame']).convert('RGB'), (j * width, 0))
        strip.save(out / 'sheets' / 'horizon-last-eight-1x.png')
    ordinary = [r for r in rows if 5 < r[0] <= 6]
    level = max(r[7] for r in ordinary)
    exceeds = [r for r in rows if left is not None and r[0] > left and r[7] > level]
    with (out / (folder.name + '-above-ordinary.tsv')).open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['contact_s', 'consecutive_changed_pixels_6pct', 'ordinary_max_6pct'])
        writer.writerows((r[0], r[7], level) for r in exceeds)
    summary = {'variant': folder.name, 'front_left_s': left, 'world_pixels': world.histogram()[255],
               'scene_minimum_share': min(r[3] for r in presence), 'scene_failures': sum(not r[5] for r in presence),
               'ordinary_max_changed': level, 'ordinary_mean_changed': sum(r[7] for r in ordinary)/len(ordinary),
               'ordinary_max_mean_abs_rgb': max(r[8] for r in ordinary), 'exceedances': len(exceeds),
               'post_front_max_changed': max(r[7] for r in rows if left is not None and r[0] > left),
               'whole_exceedances': sum(not r[6] for r in continuity),
               'whole_max_ratio': max(r[5] for r in continuity if not r[7]), 'whole_plus3': step,
               'old_plus3_decoded': decoded[0], 'new_plus3_decoded': decoded[1]}
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
        prior_records = [json.loads(line) for line in (prior.parent.parent / 'receipts.jsonl').read_text().splitlines()]
        prior_records = [r for r in prior_records if r['variant'] == folder.name]
        assert all(abs(a['contact_s'] - b['contact_s']) < 1e-6
                   for a, b in zip(records, prior_records)), 'd70ba99 frame times differ'
        with (out / 'd70ba99-world-comparison.tsv').open('w') as file:
            writer = csv.writer(file, delimiter='\t')
            writer.writerow(['contact_s', 'world_changed_pixels_6pct', 'world_mean_abs_rgb'])
            for i, record in enumerate(records[:len(prior_records)]):
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
            limit = 14.0 if 'crossing' in path.stem else 11.1
            costs.append([path.stem, rep, sum(values)/len(values), p95, limit, p95 <= limit])
    medians = []
    for stage in sorted({r[0] for r in costs}):
        reps = [r for r in costs if r[0] == stage]
        value = statistics.median(r[3] for r in reps)
        medians.append([stage, value, reps[0][4], value <= reps[0][4]])
    with (out / 'frame-cost-medians.tsv').open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['view_stage', 'median_rep_p95_ms', 'limit_ms', 'pass'])
        writer.writerows(medians)
    with (out / 'continuity-plus3p0.tsv').open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['variant', '5316288_decoded_pixels', 'candidate_decoded_pixels', 'candidate_lossless_pixels', 'previous_10_mean', 'next_10_mean', 'ratio', 'pass'])
        writer.writerows([r['variant'], r['old_plus3_decoded'], r['new_plus3_decoded'], *r['whole_plus3'][1:4], *r['whole_plus3'][5:7]] for r in summaries)
    with (out / 'frame-cost.tsv').open('w') as file:
        writer = csv.writer(file, delimiter='\t')
        writer.writerow(['view', 'rep', 'forced_draw_mean_ms', 'forced_draw_p95_ms', 'limit_ms', 'within_budget'])
        writer.writerows(costs)
    cold = []
    for path in sorted(out.glob('cold-*-first-30.tsv')):
        rows = list(csv.DictReader(path.open(), delimiter='\t'))
        worst = max(rows, key=lambda r: float(r['process_and_draw_ms']))
        cold.append((path.stem, int(worst['frame_after_contact']), float(worst['forced_draw_ms']), float(worst['process_and_draw_ms'])))
    lines = [f'# Day returns follow-up 8\n\nCandidate `{sha}`; main control `{main_sha}`. Written {datetime.now(ZoneInfo("Asia/Tokyo")).strftime("%F %T JST")}.',
             '## Picture and implementation\n\nDefault delay is 0.6 s, crossing 1.8 s, band 2 degrees. Native 4× MSAA is retained on both endpoint worlds. Daylight geometry uses the native depth and normal buffers throughout the return, removing the endpoint-to-native silhouette switch at +3.0 s. The day viewport is disabled during the crossing. During the final 1.5 s ease it renders only the fixed sky print, which the native engraving pass blends into the live sky. Render callbacks apply the fixed day lighting and print uniforms only while drawing, then restore the native light tween values. The blend is cleared before its endpoint texture is released. Endpoint allocation and shader warm-up run under the real second-contact black fade. The native lighting tween, second-contact HUD handoff and star keyline from main are unchanged; the day endpoint has darkness zero and therefore no star rings.',
             'Clips: default seeds 7 and 1919, horizon and thick cloud in `clips/`. Sun-centred 300×300 crops at native pixels every 0.1 s from −0.2 to +1.6 s are in `sheets/`. `glow-vs-d70ba99-sun-1x.png` pairs +2.0, +2.5, +3.0, +3.5 s with the accepted delay-06-7 clip. `d70ba99-world-comparison.tsv` compares the 421 shared frames from −1.0 to +6.0 s against that H.264 clip; it includes codec error, ordinary motion and main’s added star keyline. The candidate has 431 frames through +6.167 s to supply following pairs for the continuity table. No threshold was relaxed.',
             '## Whole-frame continuity\n\nEvery consecutive pair at −0.2..+6 s uses the entire 1280×720 frame and a maximum-channel difference of at least 16/255. Its limit is 1.5 times the larger mean of the ten preceding and ten following pairs. Captures extend to +6.167 s to supply all following pairs. The +4.517 s dialogue panel opening is named and excluded from failures; no other pair is exempt. Raw counts are in `*-whole-frame-continuity.tsv`.',
             '| View | Pairs above 1.5× | Maximum ratio |\n|---|---:|---:|']
    for r in summaries:
        lines.append(f"| {r['variant']} | {r['whole_exceedances']} | {r['whole_max_ratio']:.3f} |")
    lines += ['## Scene presence\n\nEvery frame at −0.2..+6 s is compared against a same-frame draw of the bare camera environment with geometry and compositor culled. UI is identical in both draws, so it cancels. At least 25% of all pixels must differ by 16/255 in a channel. Raw series are in `*-scene-presence.tsv`.',
              '| View | Minimum differing share | Failing frames |\n|---|---:|---:|']
    lines += [f"| {r['variant']} | {r['scene_minimum_share']:.3%} | {r['scene_failures']} |" for r in summaries]
    lines += ['## +3.0 s comparison\n\nThe fixed daylight rendering carries into the first ease frame; the fixed sky print then fades into the live sky. Old and new decoded clip counts use the same H.264 decoding and threshold; the candidate also has lossless-frame counts. `continuity-plus3p0.tsv` keeps both with the surrounding lossless means. The decoded 120×120 Sun-centre crop means and consecutive steps are in `*-sun-crop-mean.tsv`; decoded clip frames 55–115, 236–244 and 293–301 are in `clip-frames/`.',
              '| View | 5316288 decoded | New decoded | New lossless | Previous / next ten means | Ratio | Pass |\n|---|---:|---:|---:|---:|---:|---|']
    for r in summaries:
        step = r['whole_plus3']
        lines.append(f"| {r['variant']} | {r['old_plus3_decoded']} | {r['new_plus3_decoded']} | {step[1]} | {step[2]:.1f} / {step[3]:.1f} | {step[5]:.3f} | {step[6]} |")
    lines += ['## Frame cost\n\n1280×720 native forced draws, 30 warm-up draws then 3 × 120 samples per stage. Each stage is judged on the median of the three repetitions’ p95. All samples with the front visible have the decided 14.0 ms allowance. Bead, ease after the front, day and main baselines retain 11.1 ms. The horizon +3.5 s sample is crossing; +4.5 s samples the ease after the front exits. Raw repetitions are in `frame-cost.tsv`; decisions are in `frame-cost-medians.tsv`.',
              '| View / stage | Median p95 ms | Limit ms | Pass |\n|---|---:|---:|---|']
    lines += [f'| {view} | {p95:.3f} | {limit:.1f} | {ok} |' for view,p95,limit,ok in medians]
    lines += ['## First frames\n\nFresh Godot process per camera; real second-contact preparation happens before third contact. The first 30 frames include third-contact setup and forced drawing, with vsync disabled. Shader disk caches are not deleted. `process_and_draw_ms` includes game processing and activation on the first frame; PNG encoding is excluded. Raw values are retained.',
              '| View | Worst frame (0-based) | Draw ms | Process + draw ms |\n|---|---:|---:|---:|']
    lines += [f'| {view} | {frame} | {draw:.3f} | {total:.3f} |' for view,frame,draw,total in cold]
    second = [r for r in comparisons if 'second_' in r[0]]
    lines.append(f'## Main comparisons\n\nSecond contact: {len(second)} native-route samples, every 5 frames over 5 s; max changed pixels {max(r[1] for r in second)} exact / {max(r[2] for r in second)} at 6%. Second-contact and plate viewer, loupe, micrometer and result chart counts are in `main-comparisons.tsv`. Lossless comparison frames are deleted after the table is written.')
    lines += [f'- {name}: {exact} exact / {threshold} at 6%.' for name,exact,threshold in comparisons if 'second_' not in name]
    thick = next(r for r in summaries if r['variant'].startswith('thick'))
    lines.append(f"## Thick cloud\n\nDensity 0.97 with the contact gap disabled, presentation only. Peak versus same-frame diamond-off control: {thick['thick_peak_vs_diamond_off_6pct']} changed Sun-region pixels at 6%.")
    lines.append('## Remaining gate\n\nPR #392 stays draft until edd-art accepts it and marks it ready. Any whole-frame continuity count above its limit, median stage budget failure or nonzero main comparison remains blocking. Windowed logs were checked for shader/script errors. Lossless clip frames and the temporary main snapshot were deleted after clips and tables were generated.')
    lines.append('## Test totality\n\nThe unchanged `test_totality` passed alone through `tachi-run --host` on main fa0dcfd in 548.60 s and on the branch in 203.19 s, 658 checks and 0 failures each.')
    (out / 'report.md').write_text('\n\n'.join(lines) + '\n')
    failures = []
    for r in summaries:
        if r['whole_exceedances'] > 0:
            failures.append(f"FAIL whole-frame continuity: {r['variant']}: {r['whole_exceedances']} pairs above limit")
        if r['scene_failures'] > 0:
            failures.append(f"FAIL scene presence: {r['variant']}: {r['scene_failures']} frames below 25%")
    for stage, p95, limit, ok in medians:
        if not ok:
            failures.append(f'FAIL frame budget: {stage}: median p95 {p95} ms > {limit} ms')
    for frame, exact, threshold in comparisons:
        if exact > 0:
            failures.append(f'FAIL main comparison: {frame}: {exact} changed pixels > 0')
    if failures:
        raise SystemExit('\n'.join(failures))


if sys.argv[1] == '--report':
    report(Path(sys.argv[2]), sys.argv[3], sys.argv[4])
else:
    summarize(*map(Path, sys.argv[1:]))
