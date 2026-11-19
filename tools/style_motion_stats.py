"""Full-resolution RGB change shares; no Python image dependencies required."""
import csv
import pathlib
import statistics
import subprocess
import sys

out = pathlib.Path(sys.argv[1])
with (out / "camera.tsv").open() as src:
    rows = list(csv.DictReader(src, delimiter="\t"))
assert len(rows) == len(list(out.glob("f_*.png"))) == 960
previous = None
shares = []
with (out / "frames.tsv").open("w") as dst:
    writer = csv.writer(dst, delimiter="\t", lineterminator="\n")
    writer.writerow(list(rows[0]) + ["change", "top", "middle", "bottom"])
    for index, row in enumerate(rows, 1):
        assert abs(float(row["sim_s"]) - index / 60) < 1e-8
        image = out / f"f_{index:05d}.png"
        third = [0.0] * 3
        if previous:
            result = subprocess.check_output([
                "magick", str(previous), str(image), "-alpha", "off",
                "-compose", "difference", "-composite", "-separate",
                "-evaluate-sequence", "max", "-threshold", "10%",
                "-crop", "1280x240", "+repage", "-format", "%[fx:mean]\n", "-write", "info:",
                "-delete", "0--1", str(image), "-format", "%[fx:mean]\n", "info:",
            ], text=True)
            *third, mean = map(float, result.split())
            assert len(third) == 3
        else:
            mean = float(subprocess.check_output([
                "magick", str(image), "-format", "%[fx:mean]", "info:",
            ], text=True))
        assert mean > 0.02, f"black frame: {image} (mean={mean})"
        values = [sum(third) / 3, *third]
        shares.append(values)
        writer.writerow(list(row.values()) + [f"{v:.9f}" for v in values])
        previous = image
# A spike is share minus the median of five neighbours on either side.
ranked = []
for i in range(5, len(shares) - 5):
    neighbours = shares[i - 5:i] + shares[i + 1:i + 6]
    median = statistics.median(v[0] for v in neighbours)
    dominant = ["top", "middle", "bottom"][max(range(3), key=lambda j: shares[i][j + 1])]
    ranked.append((shares[i][0] - median, i + 1, shares[i][0], median, dominant))
with (out / "spikes.tsv").open("w") as dst:
    dst.write("index\tshare\tneighbour_median\texcess\tthird\n")
    for excess, index, share, median, third in sorted(ranked, reverse=True)[:10]:
        dst.write(f"{index}\t{share:.9f}\t{median:.9f}\t{excess:.9f}\t{third}\n")
print("[MOTION] analysed frames=960; spikes.tsv ranks excess over ten-neighbour median")
