#!/usr/bin/env python3
"""Summarise repeated G4 benchmark runs per build, keeping metrics separate.

    python3 art/pipeline/perf_summary.py art/validation/perf-r04 v01 r03 r04 > art/validation/perf-r04/SUMMARY.md

Expects <dir>/<label>-rep<N>/benchmark.json. For each bookmark it prints the
median over repetitions of:
  draw calls, primitives                      (scene submission / geometry load)
  frame ms avg / p95                          (wall clock: display-capped, ~8.3 ms)
  forced-draw ms avg / p95                    (uncapped render cost, no present)
and the min–max spread of forced-draw avg, so a difference smaller than the
spread is reported as noise rather than a speed-up.
"""
import json
import statistics as st
import sys
from pathlib import Path


def load(root: Path, label: str) -> list[dict]:
    runs = sorted(root.glob(f"{label}-rep*/benchmark.json"))
    if not runs:
        sys.exit(f"no runs for {label} in {root}")
    return [json.loads(r.read_text()) for r in runs]


def med(runs, bm, key):
    vals = [b[key] for r in runs for b in r["bookmarks"] if b["bookmark"] == bm and key in b]
    return (st.median(vals), min(vals), max(vals), len(vals)) if vals else None


def main() -> None:
    root, labels = Path(sys.argv[1]), sys.argv[2:]
    data = {l: load(root, l) for l in labels}
    bms = [b["bookmark"] for b in data[labels[0]][0]["bookmarks"]]
    meta = data[labels[-1]][0]
    print(f"# Performance summary ({', '.join(labels)})\n")
    print(f"Godot {meta['godot']} · {meta['renderer']} · viewport {meta['viewport'][0]}×{meta['viewport'][1]} · seed {meta['seed']} · "
          f"{len(data[labels[0]])} repetitions per build (median shown).\n")
    print("Wall-clock frame time is capped by the display refresh (~8.3 ms); **forced-draw** renders without presenting "
          "and is the uncapped render-cost figure. Geometry and draw-call changes are reported separately and are not "
          "frame-rate claims.\n")
    cols = [("draw_calls", "draw calls", 0), ("primitives", "primitives (k)", 1000),
            ("frame_ms_avg", "frame avg ms", None), ("frame_ms_p95", "frame p95 ms", None),
            ("forced_draw_ms_avg", "forced avg ms", None), ("forced_draw_ms_p95", "forced p95 ms", None)]
    for key, name, div in cols:
        print(f"\n## {name}\n")
        print("| bookmark | " + " | ".join(labels) + (" | spread (forced avg, min–max) |" if key == "forced_draw_ms_avg" else " |"))
        print("|---" * (len(labels) + 1 + (1 if key == "forced_draw_ms_avg" else 0)) + "|")
        for bm in bms:
            cells, spread = [], []
            for l in labels:
                m = med(data[l], bm, key)
                if m is None:
                    cells.append("n/a")
                    continue
                v = m[0] / div if div else m[0]
                cells.append(f"{v:.0f}" if div is not None else f"{v:.2f}")
                spread.append(f"{l} {m[1]:.2f}–{m[2]:.2f}")
            extra = f" {'; '.join(spread)} |" if key == "forced_draw_ms_avg" else ""
            print(f"| {bm} | " + " | ".join(cells) + " |" + extra)


if __name__ == "__main__":
    main()
