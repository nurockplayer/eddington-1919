#!/usr/bin/env python3
"""Collect benchmark bookmark statistics into a tab-separated table."""
import csv
import json
import sys
from pathlib import Path

IMAGE_KEYS = ("luma_mean", "luma_p05", "luma_p50", "luma_p95", "sat_mean",
              "sat_low_mean", "clip_white_pct", "clip_black_pct")
FIELDS = ("variant", "bookmark", "lighting", "forced_draw_ms_avg", "draw_calls", *IMAGE_KEYS)


def collect(out_dir):
    rows = []
    for path in sorted(Path(out_dir).glob("*/benchmark.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        for bookmark in data["bookmarks"]:
            row = {key: bookmark.get(key, "") for key in FIELDS[1:5]}
            row["variant"] = path.parent.name
            row.update({key: bookmark.get("image", {}).get(key, "") for key in IMAGE_KEYS})
            rows.append(row)
    return rows


def main(argv):
    out_dir = Path(argv[1])
    if not any(out_dir.glob("*/benchmark.json")):
        print("no benchmark.json found", file=sys.stderr)
        return 1
    path = out_dir / "stats.tsv"
    with path.open("w", encoding="utf-8", newline="") as output:
        writer = csv.DictWriter(output, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
        writer.writeheader()
        writer.writerows(collect(out_dir))
    print(path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
