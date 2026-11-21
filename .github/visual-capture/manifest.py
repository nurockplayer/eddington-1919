"""Check the captured frames and write manifest.jsonl, one JSON line per frame.

Run by capture.sh: manifest.py <out dir> <width> <height>. Fails when a requested
view has no PNG or a PNG is not exactly the capture size.
"""
import json
import os
import struct
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

JST = timezone(timedelta(hours=9))


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as f:
        head = f.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n" or head[12:16] != b"IHDR":
        raise ValueError(f"{path} is not a PNG")
    return struct.unpack(">II", head[16:24])


def when(seconds: float) -> str:
    return datetime.fromtimestamp(seconds, JST).isoformat(timespec="seconds")


def main() -> int:
    out = Path(sys.argv[1])
    width, height = int(sys.argv[2]), int(sys.argv[3])
    env = os.environ
    summary = json.loads((out / "frames" / "benchmark.json").read_text())
    started = float((out / ".started").read_text())
    finished = float((out / ".finished").read_text())
    run_url = f"{env.get('GITHUB_SERVER_URL', '')}/{env.get('GITHUB_REPOSITORY', '')}/actions/runs/{env.get('GITHUB_RUN_ID', '')}"
    common = {
        "ref": env.get("REF", ""),
        "sha": env.get("SHA", ""),
        "godot": summary.get("godot", ""),
        "adapter": summary.get("renderer", ""),
        "viewport": summary.get("viewport"),
        "quality": summary.get("quality"),
        "seed": summary.get("seed"),
        "cloud_t": env.get("CLOUD_T", ""),
        "style_set": env.get("STYLE_SET", ""),
        "run_url": run_url,
    }
    wanted = [v for v in env.get("VIEWS", "").split(",") if v]
    rows, problems = [], []
    previous = started
    # benchmark.json lists the bookmarks in the order they were shot.
    for bookmark in summary.get("bookmarks", []):
        view = bookmark["bookmark"]
        png = out / "frames" / f"{view}.png"
        if not png.is_file():
            problems.append(f"{view}: no PNG")
            continue
        size = png_size(png)
        if size != (width, height):
            problems.append(f"{view}: PNG is {size[0]}x{size[1]}, not {width}x{height}")
        shot = png.stat().st_mtime
        rows.append({
            "kind": "frame", "view": view, "file": f"frames/{view}.png",
            "width": size[0], "height": size[1], "lighting": bookmark.get("lighting"),
            **common,
            "captured_at": when(shot), "wall_s": round(shot - previous, 1),
            "image": bookmark.get("image", {}),
        })
        previous = shot
    for view in wanted:
        if view not in {r["view"] for r in rows}:
            problems.append(f"{view}: requested but not captured")
    with (out / "manifest.jsonl").open("w") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
    for name in (".started", ".finished"):
        (out / name).unlink()
    report = [
        f"Rendered `{common['sha'][:12]}` ({common['ref']}) at {width}x{height} on {common['adapter']}, "
        f"Godot {common['godot']}; frames run {round(finished - started)} s.",
        "", "| view | size | captured_at | wall_s |", "|---|---|---|---|",
    ]
    report += [f"| {r['view']} | {r['width']}x{r['height']} | {r['captured_at']} | {r.get('wall_s', '')} |" for r in rows]
    print("\n".join(report))
    if env.get("GITHUB_STEP_SUMMARY"):
        with open(env["GITHUB_STEP_SUMMARY"], "a") as f:
            f.write("\n".join(report) + "\n")
    for problem in problems:
        print(f"::error::{problem}")
    return 1 if problems or not rows else 0


if __name__ == "__main__":
    sys.exit(main())
