"""Create the requested native-resolution comparisons and measurement receipts."""
import json
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

out = Path(sys.argv[1])
head = sys.argv[2]
base = sys.argv[3]
frames = out / 'frames'
sheets = out / 'sheets'
sheets.mkdir(exist_ok=True)
records = [json.loads(line) for line in (out / 'receipts.jsonl').read_text().splitlines()]
lookup = {Path(r['frame']).stem: r for r in records}
font = ImageFont.truetype('/System/Library/Fonts/Menlo.ttc', 20)
rows = []
for size in ('1280x720', '1920x1080'):
    for state in ('night', 'coda'):
        for obj in ('mentor_loupe', 'departure_workbook'):
            for distance in ('3.0', '1.5'):
                label = f'{size}-{state}-{obj}-{distance}'
                names = [f'{side}-{label}' for side in ('main', 'head')]
                images = [Image.open(frames / (n + '.png')).convert('RGB') for n in names]
                w, h = images[0].size
                sheet = Image.new('RGB', (w * 2, h + 35), '#efe8d7')
                draw = ImageDraw.Draw(sheet)
                for i, (image, side) in enumerate(zip(images, ('main', 'head'))):
                    sheet.paste(image, (i * w, 35))
                    draw.text((i*w+8, 6), f'{side} {base[:7] if i == 0 else head[:7]} | {label}', font=font, fill='black')
                sheet.save(sheets / (label + '.png'))
                excluded = Image.new('L', (w, h), 0)
                overlaps = {}
                for n in names:
                    rec = lookup[n]
                    assert rec['ray_id'] == obj and rec['prompt_visible'] and rec['prompt'], n
                    x, y, rw, rh = rec['prompt_rect']
                    scale = h / 900.0
                    rect = (round(x*scale), round(y*scale), round((x+rw)*scale), round((y+rh)*scale))
                    slip = Image.new('L', (w, h), 0)
                    ImageDraw.Draw(slip).rectangle(rect, fill=255)
                    for target in ('mentor_loupe', 'departure_workbook'):
                        mask = Image.open(frames / f'{n}-{target}-mask.png').convert('L').point(lambda v: 255 if v >= 128 else 0)
                        overlap = ImageChops.multiply(mask, slip).histogram()[255]
                        overlaps[f'{n}:{target}'] = overlap
                        excluded = ImageChops.lighter(excluded, mask)
                        if n.startswith('head-') and state == 'night' and distance == '1.5' and target == obj and size == '1920x1080':
                            bounds = mask.getbbox()
                            assert bounds, n + ' empty object mask'
                            bounds = (max(0,bounds[0]-12), max(0,bounds[1]-12), min(w,bounds[2]+12), min(h,bounds[3]+12))
                            images[1].crop(bounds).save(sheets / f'{target}-native-crop.png')
                excluded = excluded.filter(ImageFilter.MaxFilter(17))
                allowed = ImageChops.invert(excluded)
                allowed.save(out / 'frames' / (label + '-held-mask.png'))
                for image, side in zip(images, ('main', 'head')):
                    Image.composite(image, Image.new('RGB',(w,h)), allowed).save(out / 'frames' / f'{side}-{label}-held.png')
                cmd = ['magick', str(frames/f'main-{label}-held.png'), str(frames/f'head-{label}-held.png'), '-compose','difference','-composite','-separate','-evaluate-sequence','max','-threshold','6%','-format','%[fx:mean*w*h]','info:']
                changed = int(float(subprocess.check_output(cmd, text=True)))
                rows.append({'view':label,'changed_outside_objects':changed,'prompt_overlap_pixels':overlaps,'distance_m':lookup[names[1]]['distance_m']})
(out/'measurements.json').write_text(json.dumps(rows, indent=2)+'\n')
perfs = {size:json.loads((out/f'perf-{size}.json').read_text()) for size in ('1280x720','1920x1080')}
worst = min(rep['estimate_fps_x3'] for rep in perfs['1280x720'])
with (out/'report.md').open('w') as f:
    f.write(f'# Loupe and workbook: row 8 item 3\n\nMain `{base}`; head `{head}`. All capture times in receipts are JST.\n\n')
    f.write('Windowed, fixed 60 Hz, 72° player FOV, eye 1.62 m above standing floor. Screenshots preserve source resolution. Main and head share camera positions. Ray receipts identify the targeted object. Object masks are depth-tested and dilated by 8 px before held-surface comparison. The prescribed ImageMagick difference command is applied to blacked-out object masks. Prompt overlap uses the row 8 expanded prompt rectangle and each visible object mask.\n\n')
    f.write('| View | Changed pixels outside objects | Prompt/object overlaps |\n|---|---:|---:|\n')
    for r in rows: f.write(f"| [{r['view']}](sheets/{r['view']}.png) | {r['changed_outside_objects']} | {max(r['prompt_overlap_pixels'].values())} |\n")
    f.write(f'\nForced-draw estimate at ×3, 720p: {worst:.2f} fps worst of three. Full timings: `perf-1280x720.json`.\n\n')
    f.write('Visual identification remains for edd-art to judge.\n')
assert all(max(r['prompt_overlap_pixels'].values()) == 0 for r in rows), 'Prompt overlaps an object'
assert worst > 30, f'Worst ×3 estimate {worst:.2f} fps <= 30'
print(f'PACKET: {len(rows)} comparisons; worst ×3 {worst:.2f} fps; prompt overlaps zero')
