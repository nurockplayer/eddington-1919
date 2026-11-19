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
    ('delay-06-7', 7, .6, False, False),
    ('delay-06-1919', 1919, .6, False, False),
    ('horizon-06-7', 7, .6, True, False),
    ('thick-06-7', 7, .6, False, True),
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
    if shutil.disk_usage('/Volumes/KIOXIA').free < 4 * 1024**3:
        raise RuntimeError('KIOXIA has under 4 GB free; capture stopped')
    out.mkdir(exist_ok=False)
    for name in ('tools', 'clips', 'sheets'):
        (out / name).mkdir()
    sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=REPO, text=True).strip()
    for name in ('capture.gd', 'compare.gd', 'run.py', 'finish.py'):
        shutil.copyfile(REPO / 'tools/day_returns' / name, out / 'tools' / name)
    # Reuse the survey's native state, framing and receipt helpers. Its inherited
    # _run is replaced; the canvas stays at the game's actual play scale.
    source = SURVEY.read_text()
    survey = source.split('func sky_mask(')[0]
    survey += source[source.index('func prepare_plates('):source.index('func ', source.index('func evidence(') + 5)]
    survey = survey.replace('[r.position.x,r.position.y,r.size.x,r.size.y]', 'rect_array(root.get_stretch_transform() * r)')
    survey = survey.replace('var sun_pixel: Vector2=cam.unproject_position(cam.global_position+game.sim.sun_dir*100)', 'var sun_pixel: Vector2=root.get_stretch_transform() * cam.unproject_position(cam.global_position+game.sim.sun_dir*100)')
    survey = survey.replace('seed(7)', 'seed(_capture_seed())')
    survey = survey.replace('root.add_child(game)', 'game.next_seed = _capture_seed()\n\troot.add_child(game)')
    (out / 'tools/survey.gd').write_text(survey + '\nfunc _capture_seed() -> int:\n\tfor arg in OS.get_cmdline_user_args():\n\t\tif arg.begins_with("--seed="):\n\t\t\treturn int(arg.trim_prefix("--seed="))\n\treturn 7\n\nfunc _run() -> void:\n\tpass\n')
    for script in ('survey.gd', 'capture.gd', 'compare.gd'):
        run(['godot', '--headless', '--path', str(REPO), '--check-only', '--script', str(out / 'tools' / script)], out / 'tools' / (script + '-parse.log'))
    with (out / 'receipts.jsonl').open('w') as receipts:
        for name, seed, delay, horizon, thick in VARIANTS:
            if shutil.disk_usage('/Volumes/KIOXIA').free < 4 * 1024**3:
                raise RuntimeError('KIOXIA has under 4 GB free; capture stopped')
            folder = out / name
            (folder / 'scratch').mkdir(parents=True)
            overrides = f'return_seconds=1.8,return_width=2,return_delay={delay}'
            argv = ['godot', '--path', str(REPO), '--windowed', '--resolution', '1280x720',
                    '--fixed-fps', '60', '--always-on-top', '--script', str(out / 'tools/capture.gd'),
                    '--', f'--out={folder}', f'--sha={sha}', f'--seed={seed}', f'--style-set={overrides}']
            if horizon: argv.append('--horizon')
            if thick: argv.append('--thick')
            if name in ('delay-06-7', 'horizon-06-7'): argv.append('--cost')
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
            for cost in folder.glob('cost-*.tsv'): shutil.copyfile(cost, out / (name + '-' + cost.stem + '-cost.tsv'))
            if (folder / 'diamond-off.png').exists(): shutil.copyfile(folder / 'diamond-off.png', out / 'thick-diamond-off.png')
            shutil.rmtree(folder)
    # Compare the immutable main snapshot and candidate using the same native route.
    main_sha = subprocess.check_output(['git', 'rev-parse', 'origin/main'], cwd=REPO, text=True).strip()
    control = out / 'main-scratch'
    control.mkdir()
    archive = subprocess.Popen(['git', 'archive', main_sha], cwd=REPO, stdout=subprocess.PIPE)
    subprocess.run(['tar', '-x', '-C', str(control)], stdin=archive.stdout, check=True)
    archive.stdout.close()
    if archive.wait(): raise RuntimeError('git archive main failed')
    run(['godot', '--headless', '--path', str(control), '--import'], out / 'tools/main-import.log')
    for side, repo, revision in [('main', control, main_sha), ('candidate', REPO, sha)]:
        folder = out / ('compare-' + side)
        (folder / 'frames').mkdir(parents=True)
        run(['godot', '--path', str(repo), '--windowed', '--resolution', '1280x720',
             '--fixed-fps', '60', '--script', str(out / 'tools/compare.gd'), '--',
             f'--out={folder}', f'--sha={revision}'], out / 'tools' / (side + '-windowed.log'))
    for side, repo, flag in [('main', control, '--baseline'), ('cold', REPO, '--cold')]:
        for view in ('sky', 'horizon'):
            folder = out / (side + '-' + view)
            folder.mkdir()
            argv = ['godot', '--path', str(repo), '--windowed', '--resolution', '1280x720',
                    '--fixed-fps', '60', '--script', str(out / 'tools/capture.gd'), '--',
                    f'--out={folder}', flag]
            if view == 'horizon': argv.append('--horizon')
            run(argv, out / 'tools' / (side + '-' + view + '-windowed.log'))
            for cost in folder.glob('cost-*.tsv'):
                shutil.copyfile(cost, out / (side + '-' + view + '-' + cost.stem + '-cost.tsv'))
            if side == 'cold': shutil.copyfile(folder / 'first-30.tsv', out / ('cold-' + view + '-first-30.tsv'))
            shutil.rmtree(folder)
    shutil.rmtree(control)
    subprocess.run(['python3', str(out / 'tools/finish.py'), '--report', str(out), main_sha, sha], check=True)
    print(f'CAPTURE COMPLETE {out}/report.md JST')

if __name__ == '__main__':
    main()
