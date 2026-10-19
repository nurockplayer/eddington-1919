#!/usr/bin/env python3
"""Side-by-side sheet of in-game benchmark runs (gate G4), one row per bookmark.

    python3 art/pipeline/compare.py art/validation/g4-baseline-v0.1 art/validation/g4-r03 \
        --out art/validation/g4-r03/compare.jpg

Each cell is labelled with draw calls, primitives and average frame time, and the
script prints a perf delta table (last run vs first) for the review notes.
Screenshots are also re-saved as 960px JPEGs (shots/*.jpg) so runs can be
committed without the full-size PNGs.
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("runs", nargs="+", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--cell", type=int, default=560)
    a = ap.parse_args()
    data = [json.loads((r / "benchmark.json").read_text()) for r in a.runs]
    names = [b["bookmark"] for b in data[0]["bookmarks"]]
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 15)
    except OSError:
        font = ImageFont.load_default()
    cw, ch = a.cell, int(a.cell * 9 / 16)
    pad, lab = 8, 24
    sheet = Image.new("RGB", (pad + len(a.runs) * (cw + pad), lab + pad + len(names) * (ch + lab + pad)), (24, 24, 26))
    d = ImageDraw.Draw(sheet)
    for c, r in enumerate(a.runs):
        d.text((pad + c * (cw + pad), 6), r.name, fill=(240, 200, 120), font=font)
    for c, (run, dat) in enumerate(zip(a.runs, data)):
        by = {b["bookmark"]: b for b in dat["bookmarks"]}
        (run / "shots").mkdir(exist_ok=True)
        for i, n in enumerate(names):
            b = by.get(n)
            if not b:
                continue
            src = run / b["screenshot"] if (run / b["screenshot"]).exists() else run / "shots" / (n + ".jpg")
            im = Image.open(src).convert("RGB")
            small = im.copy()
            small.thumbnail((960, 960))
            small.save(run / "shots" / (n + ".jpg"), "JPEG", quality=82)
            im = im.resize((cw, ch))
            x, y = pad + c * (cw + pad), lab + pad + i * (ch + lab + pad)
            sheet.paste(im, (x, y))
            d.text((x + 2, y + ch + 4), f"{n} [{b['lighting']}]  dc {int(b['draw_calls'])}  prim {int(b['primitives'] / 1000)}k  {b['frame_ms_avg']} ms",
                   fill=(225, 220, 205), font=font)
    a.out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(a.out, "JPEG", quality=85)
    if len(data) > 1:
        print("| bookmark | draw calls | primitives | frame ms avg |")
        print("|---|---|---|---|")
        first = {b["bookmark"]: b for b in data[0]["bookmarks"]}
        for b in data[-1]["bookmarks"]:
            f = first.get(b["bookmark"])
            if f:
                print(f"| {b['bookmark']} | {int(f['draw_calls'])} → {int(b['draw_calls'])} | "
                      f"{int(f['primitives'] / 1000)}k → {int(b['primitives'] / 1000)}k | {f['frame_ms_avg']} → {b['frame_ms_avg']} |")
    print(a.out)


if __name__ == "__main__":
    main()
