#!/usr/bin/env python3
"""Capture the paired row 8d receipt under one heavy host reservation."""
from datetime import datetime
import json
import os
from pathlib import Path
from statistics import median
import struct
import subprocess
import sys
import tempfile
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parents[2]
CACHE = Path("/Volumes/KIOXIA/eddington-1919-cache/director/accept/row8d")
JST = ZoneInfo("Asia/Tokyo")
SETTINGS = """[ui]
language="en"
text_scale=1.0
reduced_motion=false
[video]
quality="standard"
fullscreen=false
[audio]
music_enabled=false
"""


def capture(project, settings, folder, size, perf=False):
    command = [
        sys.executable, str(ROOT / "tools/windowed_capture.py"),
        "--project", str(project), "--settings", str(settings),
        "--wall-seconds", "220", "--first-frame-seconds", "80",
        "--engine-arg=--audio-driver", "--engine-arg=Dummy",
        "--engine-arg=--resolution", f"--engine-arg={size}",
    ]
    patterns = ["1:shelter-totality.png", "1:perf.json"] if perf else [
        "4:day-*.png", "4:safelight-*.png", "1:walking.json",
    ]
    for pattern in patterns:
        command.extend(["--expect", pattern])
    command.extend([str(folder), "res://tools/row8_survey/face_capture.gd", "--"])
    command.extend(["--seed=7", "--bench-quality=standard", "--bench-cloud-t=215"])
    if perf:
        command.append("--perf")
    attempt = Path(subprocess.check_output(command, cwd=ROOT, text=True,
                                           env=dict(os.environ, EDD_LOCALE="en")).strip())
    for png in attempt.glob("*.png"):
        with png.open("rb") as image:
            image.seek(16)
            width, height = struct.unpack(">II", image.read(8))
        if f"{width}x{height}" != size:
            raise ValueError(f"{png} has size {width}x{height}, expected {size}")
    return attempt


def link(out, file):
    return f"[{file.name}]({file.relative_to(out)})"


def stamp(file):
    return datetime.fromtimestamp(file.stat().st_mtime, JST).strftime("%F %T %Z")


def main(base, head, pr):
    out = CACHE / head
    out.mkdir(parents=True, exist_ok=True)
    views = {}
    pairs = []
    with tempfile.TemporaryDirectory(prefix="edd-row8d-") as temp:
        scratch = Path(temp)
        settings = scratch / "settings.cfg"
        settings.write_text(SETTINGS)
        projects = {}
        for label, sha in [("main", base), ("candidate", head)]:
            project = scratch / label
            project.mkdir()
            with subprocess.Popen(
                ["git", "archive", sha, "--", "project.godot", "icon.svg", "icon.svg.import",
                 "assets", "locale", "scenes", "scripts", "shaders", "tests", "art/palette.toml"],
                cwd=ROOT, stdout=subprocess.PIPE,
            ) as archive:
                subprocess.run(["tar", "-x", "-C", project], stdin=archive.stdout, check=True)
                archive.stdout.close()
                if archive.wait():
                    raise RuntimeError(f"git archive failed for {sha}")
            script = project / "tools/row8_survey/face_capture.gd"
            script.parent.mkdir(parents=True)
            script.write_bytes((ROOT / "tools/row8_survey/face_capture.gd").read_bytes())
            projects[label] = project

        for rep, order in enumerate([("main", "candidate"), ("candidate", "main"), ("main", "candidate")], 1):
            pairs.append({label: capture(projects[label], settings, out / label / f"perf-{rep}", "1280x720", True)
                          for label in order})
        for size in ["1920x1080", "1280x720"]:
            for label, project in projects.items():
                views[label, size] = capture(project, settings, out / label / size, size)

    lines = ["# Row 8d — faces and hat at walking reach", "",
             f"Main `{base}`. Candidate `{head}`. PR #{pr}.", "",
             "Seed 7, locale en, text scale 1.0, reduced motion off, standard quality.", "",
             "The survey samples standing poses at 2.5° and 0.025 m, then walks the first-person player "
             "from the phase spawn through collision-routed waypoints using movement input. The walking receipts "
             "include the camera position, sampled limit, measured camera-to-iris distance and cumulative travel.", "",
             "| Build | State | View | Size | Iris distance | Walked from spawn | Frame | Capture time | Command |",
             "|---|---|---|---|---:|---:|---|---|---|"]
    for (label, size), folder in views.items():
        walking = folder / "walking.json"
        for row in json.loads(walking.read_text()):
            png = folder / row["file"]
            if row["walked_m"] <= 0:
                raise ValueError(f"No walking evidence for {png}")
            lines.append(f"| {label} | {row['state']} | {row['view']} | {size} | "
                         f"{row['eye_to_iris_m']:.3f} m | {row['walked_m']:.2f} m | {link(out, png)} | "
                         f"{stamp(png)} | {link(out, folder / 'render.log')} |")
    lines.extend(["", "Walking receipts " + ", ".join(link(out, folder / "walking.json") for folder in views.values()),
                  "", "## Row 9 frame cost", "",
                  "Shelter at totality, 1280×720, vsync off. Three adjacent main/candidate pairs with "
                  "alternating order, 240 forced draws without present per run.", "",
                  "| Pair | Main p95 | Candidate p95 | Delta | Main run | Candidate run |",
                  "|---|---:|---:|---:|---|---|"])
    deltas = []
    candidate_p95 = []
    for rep, pair in enumerate(pairs, 1):
        files = {label: folder / "perf.json" for label, folder in pair.items()}
        p95 = {label: json.loads(file.read_text())["p95_ms"] for label, file in files.items()}
        delta = p95["candidate"] - p95["main"]
        deltas.append(delta)
        candidate_p95.append(p95["candidate"])
        receipts = []
        for label in ["main", "candidate"]:
            folder = pair[label]
            receipts.append(f"{link(out, files[label])}, {link(out, folder / 'shelter-totality.png')}, "
                            f"{stamp(files[label])}, {link(out, folder / 'render.log')}")
        lines.append(f"| {rep} | {p95['main']:.2f} ms | {p95['candidate']:.2f} ms | {delta:+.2f} ms | "
                     + " | ".join(receipts) + " |")
    typical = median(deltas)
    worst = max(deltas)
    lines.extend(["", f"Median paired delta {typical:+.2f} ms. Worst paired delta {worst:+.2f} ms. "
                  f"Worst candidate p95 ×3 is {3 * max(candidate_p95):.2f} ms.",
                  f"All pairs within +0.30 ms: {'yes' if round(worst, 2) <= 0.30 else 'no'}.", "",
                  "Awaiting edd-art acceptance."])
    (out / "index.md").write_text("\n".join(lines) + "\n")
    (out / ".archive-pr").write_text(pr + "\n")
    print(out / "index.md")


if __name__ == "__main__":
    main(*sys.argv[1:])
