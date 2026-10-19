#!/usr/bin/env python3
"""Lay out a run's images in a labelled grid for side-by-side review.

    python3 art/pipeline/contact_sheet.py art/runs/r01-directions [--cols 4] [--filter key_station]

Writes <run>/contact.jpg. Labels come from manifest.jsonl (id · model · seconds).
"""
import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("run")
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--filter", default="")
    ap.add_argument("--out", default="contact.jpg")
    ap.add_argument("--cell", type=int, default=480)
    a = ap.parse_args()
    run = Path(a.run)
    rows = [json.loads(l) for l in (run / "manifest.jsonl").read_text().splitlines() if l.strip()]
    rows = [r for r in rows if r.get("ok") and a.filter in r["id"]]
    seen, items = set(), []
    for r in rows:  # last entry per id wins (regenerations append)
        seen.discard(r["id"])
        items = [x for x in items if x["id"] != r["id"]] + [r]
    items.sort(key=lambda r: r["id"])
    cw = a.cell
    thumbs = []
    for r in items:
        im = Image.open(run / r["file"]).convert("RGB")
        im.thumbnail((cw, cw))
        thumbs.append((r, im))
    ch = max(im.height for _, im in thumbs) + 34
    cols = min(a.cols, len(thumbs))
    nrows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * (cw + 8) + 8, nrows * (ch + 8) + 8), (24, 24, 26))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 15)
    except OSError:
        font = ImageFont.load_default()
    for i, (r, im) in enumerate(thumbs):
        x = 8 + (i % cols) * (cw + 8)
        y = 8 + (i // cols) * (ch + 8)
        sheet.paste(im, (x, y))
        model = r["model"].split("/")[0].replace("codex:", "gpt via ")
        d.text((x + 2, y + im.height + 6), f"{r['id']}  ·  {model}  ·  {r['seconds'] or '?'}s", fill=(225, 220, 205), font=font)
    sheet.save(run / a.out, "JPEG", quality=85)
    print(run / a.out)


if __name__ == "__main__":
    main()
