#!/usr/bin/env python3
"""Evidence only: exact same pixel mask for each frame and its +6 s reference."""
import csv
import json
import math
from array import array
from pathlib import Path
import sys
from PIL import Image, ImageChops, ImageDraw, ImageMath, ImageStat

folder, out = map(Path, sys.argv[1:])
records = [json.loads(line) for line in (folder / 'receipts.jsonl').read_text().splitlines()]
reference = Image.open(folder / records[-1]['frame']).convert('RGB')
width, height = reference.size
forward = records[0]['camera_forward']
sun = records[0]['sun_dir']
# Camera has no roll in native play. The director's aim() retains yaw and pitch.
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
# UI furniture is measured separately via state; exclude its top/bottom strips.
world = Image.new('L', (width, height))
ImageDraw.Draw(world).rectangle((0, 80, width - 1, height - 221), fill=255)
linear = [round(((i / 255 / 12.92) if i / 255 <= .04045 else ((i / 255 + .055) / 1.055) ** 2.4) * 255) for i in range(256)]

def luminance(image, mask):
    means = [ImageStat.Stat(channel.point(linear), mask).mean[0] / 255 for channel in image.split()]
    return sum(v * w for v, w in zip(means, (.2126, .7152, .0722)))

with (out / (folder.name + '-luminance.tsv')).open('w') as file:
    writer = csv.writer(file, delimiter='\t')
    writer.writerow(['contact_s', 'behind_pixels', 'mean_linear_luminance', 'same_pixels_at_plus6', 'delta', 'changed_pixels_max_rgb_6pct'])
    for record in records:
        radius = record['front_radius']
        trailing = radius - record['front_band']
        if radius < 2 * .03:
            trailing = -1
        if record['contact_s'] >= 3 and radius < 0:
            trailing = math.pi + 1
        mask = ImageMath.unsafe_eval("convert((a < r) * 255, 'L')", a=angles, r=trailing)
        mask = ImageChops.multiply(mask, world)
        count = mask.histogram()[255]
        image = Image.open(folder / record['frame']).convert('RGB')
        if count:
            current, final = luminance(image, mask), luminance(reference, mask)
            channels = ImageChops.difference(image, reference).split()
            changed = ImageChops.lighter(ImageChops.lighter(channels[0], channels[1]), channels[2]).point(lambda value: 255 if value >= 16 else 0)
            changed = ImageChops.multiply(changed, mask).histogram()[255]
            writer.writerow([record['contact_s'], count, current, final, current - final, changed])
        else:
            writer.writerow([record['contact_s'], 0, '', '', '', 0])
        image.close()
if folder.name == 'default-7':
    selected = []
    for tick in range(25):
        target = tick * .25
        selected.append(min(records, key=lambda record: abs(record['contact_s'] - target)))
    sheet = Image.new('RGB', (1280, 5 * 202), '#efe6d2')
    draw = ImageDraw.Draw(sheet)
    for i, record in enumerate(selected):
        image = Image.open(folder / record['frame']).convert('RGB')
        image.thumbnail((256, 180))
        x, y = i % 5 * 256, i // 5 * 202
        sheet.paste(image, (x, y))
        draw.text((x + 4, y + 181), f"+{record['contact_s']:.3f} s", fill='#221c18')
    sheet.save(out / 'sheets/default-quarter-seconds.jpg', quality=95)
