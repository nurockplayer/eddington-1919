#!/usr/bin/env python3
"""Launch only via job-run -- orb-test --heavy --host -- python3 this.py OUT.
Windowed captures run sequentially. The same argument interface as style_motion.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
from datetime import datetime
from zoneinfo import ZoneInfo

REPO = Path(__file__).resolve().parents[2]
SURVEY = Path('/Volumes/KIOXIA/eddington-1919-cache/director/row-verdicts/595792a/tools/capture.gd')
VARIANTS = [
    ('default-7', 7, 1.2, 2, 0, False),
    ('fast-7', 7, .8, 2, 0, False),
    ('slow-7', 7, 1.8, 2, 0, False),
    ('wide-7', 7, 1.2, 6, 0, False),
    ('delayed-7', 7, 1.2, 2, .2, False),
    ('default-1919', 1919, 1.2, 2, 0, False),
    ('horizon-7', 7, 1.2, 2, 0, True),
]

def run(argv, log):
    with log.open('w') as output:
        subprocess.run(argv, cwd=REPO, stdout=output, stderr=subprocess.STDOUT, check=True,
                       env=dict(os.environ, TZ='Asia/Tokyo'))
    text = log.read_text()
    if any(token in text for token in ('SHADER ERROR', 'SCRIPT ERROR', 'STYLE ERROR', 'Shader compilation failed')):
        raise RuntimeError(f'Godot error in {log}')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('out', type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(exist_ok=False)
    for name in ('tools', 'clips', 'sheets'):
        (out / name).mkdir()
    sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    for name in ('capture.gd', 'run.py', 'finish.py'):
        shutil.copyfile(REPO / 'tools/day_returns' / name, out / 'tools' / name)
    # Reuse the survey's native state, framing and receipt helpers. Its inherited
    # _run is replaced; the canvas stays at the game's actual play scale.
    survey = SURVEY.read_text().split('func sky_mask(')[0]
    survey = survey.replace('seed(7)', 'seed(_capture_seed())')
    survey = survey.replace('root.add_child(game)', 'game.next_seed = _capture_seed()\n\troot.add_child(game)')
    (out / 'tools/survey.gd').write_text(survey + '\nfunc _capture_seed() -> int:\n\tfor arg in OS.get_cmdline_user_args():\n\t\tif arg.begins_with("--seed="):\n\t\t\treturn int(arg.trim_prefix("--seed="))\n\treturn 7\n\nfunc _run() -> void:\n\tpass\n')
    for script in ('survey.gd', 'capture.gd'):
        run(['godot', '--headless', '--path', str(REPO), '--check-only', '--script', str(out / 'tools' / script)], out / 'tools' / (script + '-parse.log'))
    with (out / 'receipts.jsonl').open('w') as receipts:
        for name, seed, crossing, width, delay, horizon in VARIANTS:
            folder = out / name
            (folder / 'scratch').mkdir(parents=True)
            overrides = f'return_seconds={crossing},return_width={width},return_delay={delay}'
            argv = ['godot', '--path', str(REPO), '--windowed', '--resolution', '1280x720',
                    '--fixed-fps', '60', '--always-on-top', '--script', str(out / 'tools/capture.gd'),
                    '--', f'--out={folder}', f'--sha={sha}', f'--seed={seed}', f'--style-set={overrides}']
            if horizon:
                argv.append('--horizon')
            with (out / 'tools/commands.jsonl').open('a') as commands:
                commands.write(json.dumps({'at': datetime.now(ZoneInfo('Asia/Tokyo')).isoformat() + ' JST', 'argv': argv}) + '\n')
            run(argv, out / 'tools' / (name + '-windowed.log'))
            # Inspect shader errors before trusting or encoding a single frame.
            run(['ffmpeg', '-nostdin', '-hide_banner', '-loglevel', 'error', '-framerate', '60',
                 '-i', str(folder / 'scratch/f_%05d.png'), '-c:v', 'libx264', '-crf', '10',
                 '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(out / 'clips' / (name + '.mp4'))],
                out / 'tools' / (name + '-encode.log'))
            subprocess.run(['python3', str(out / 'tools/finish.py'), str(folder), str(out)], check=True)
            for line in (folder / 'receipts.jsonl').read_text().splitlines():
                record = json.loads(line)
                record['variant'] = name
                record['clip'] = f'clips/{name}.mp4'
                receipts.write(json.dumps(record) + '\n')
            shutil.rmtree(folder)
    (out / 'report.md').write_text(f'''# Row 5 day return\n\nCandidate `{sha}`. Written {datetime.now(ZoneInfo('Asia/Tokyo')).strftime('%F %T JST')}.\n\nSeven whole-frame 60 fps native contact clips, -1 to +6 s. Defaults on seeds 7 and 1919; crossing 0.8/1.2/1.8 s, band 2/6 degrees and delay 0/0.2 s. Horizon uses the default. Shader logs checked before encoding.\n\n`*-luminance.tsv` contains every frame's mean luminance behind the front and the exact same pixels at +6 s, with white-band pixels excluded. Changed pixels use maximum RGB channel difference >=16 (6 percent). The day-page comparison excludes HUD and moving foreground; receipts retain each frame's camera, native state and pass values.\n\n## Follow-ups\n\nArt acceptance, unchanged-against-main captures (including second contact and plate/chart), and thick-cloud/no-diamond proof remain separate required gates.\n''')
    print(f'CAPTURE COMPLETE {out}/report.md JST')

if __name__ == '__main__':
    main()
