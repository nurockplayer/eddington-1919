#!/usr/bin/env python3
"""Measure consecutive visible crops from native third-contact frame sequences."""
import csv
import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageStat

REGIONS = ("panel", "portrait")
SCALES = ("1.0", "1.2")
HUE_ANGLES = [i * math.tau / 255 for i in range(256)]


def measure(crop):
    r, g, b = ImageStat.Stat(crop).mean
    hue, saturation, _ = crop.convert("HSV").split()
    counts = hue.histogram(saturation)
    x = sum(n * math.cos(a) for n, a in zip(counts, HUE_ANGLES))
    y = sum(n * math.sin(a) for n, a in zip(counts, HUE_ANGLES))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b, math.degrees(math.atan2(y, x)) % 360


def sequence(folder, scale):
    metadata = json.loads((folder / "receipts.json").read_text())
    assert metadata["text_scale"] == float(scale), folder
    assert metadata["size"] == [1280, 720] and metadata["fps"] == 60, folder
    frames = metadata["frames"]
    assert len(frames) == 601, folder
    peaks = {region: [0.0, 0.0, 0.0, 0.0] for region in REGIONS}
    previous = {}
    with (folder / "measurements.csv").open("w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(("contact_s", "crop", "mean_luma", "mean_hue_deg", "luma_step", "hue_step_deg"))
        for i, frame in enumerate(frames):
            time = frame["contact_s"]
            assert abs(time - i / 60) < 1e-9, (folder, i)
            with Image.open(folder / frame["file"]) as image:
                for region in REGIONS:
                    box = frame[region]
                    if not box:
                        previous.pop(region, None)
                        writer.writerow((time, region, "", "", "", ""))
                        continue
                    luma, hue = measure(image.crop(box).convert("RGB"))
                    step = []
                    if region in previous:
                        last_luma, last_hue = previous[region]
                        dl = abs(luma - last_luma)
                        dh = abs((hue - last_hue + 180) % 360 - 180)
                        peak = peaks[region]
                        if dl > peak[0]:
                            peak[0:2] = dl, time
                        if dh > peak[2]:
                            peak[2:4] = dh, time
                        step = [dl, dh]
                    writer.writerow((time, region, luma, hue, *step))
                    previous[region] = luma, hue
    return peaks


def main():
    baseline, head, reverted = map(Path, sys.argv[1:])
    results = {
        (label, scale): sequence(folder / scale, scale)
        for label, folder in (("Pre-fix main", baseline), ("Head", head), ("HUD fix reverted", reverted))
        for scale in SCALES
    }
    with (head / "summary.md").open("w") as file:
        print("| Capture | Text scale | Crop | Max luma step (0–255) | At C3 + s | Max hue step (°) | At C3 + s |", file=file)
        print("|---|---:|---|---:|---:|---:|---:|", file=file)
        for (label, scale), peaks in results.items():
            for region, (dl, tl, dh, th) in peaks.items():
                print(f"| {label} | {scale} | {region} | {dl:.2f} | {tl:.3f} | {dh:.2f} | {th:.3f} |", file=file)
        print("\nLuma uses Rec. 709 weights on RGB levels. Hue is the circular mean of chromatic", file=file)
        print("pixels. Each CSV covers C3 through C3+10 s at 60 fps. Hidden crops have empty", file=file)
        print("values. Steps begin with the second consecutive visible frame.", file=file)
        print("The panel crop samples blank paper inside the rule. The portrait crop samples", file=file)
        print("the center of the print inside its oval mount.", file=file)
    for scale in SCALES:
        for region in REGIONS:
            fixed = results["Head", scale][region][0]
            old = results["Pre-fix main", scale][region][0]
            revert = results["HUD fix reverted", scale][region][0]
            assert 0 < fixed < 3 < min(old, revert), (scale, region, fixed, old, revert)
    print("MEASUREMENT PASS: both crops at both scales ease below 3 luma levels per frame; the revert fails that bound")


if __name__ == "__main__":
    main()
