#!/bin/bash
# Pair the two commits inside a single tachi-run GPU reservation.
set -euo pipefail
base=$1
head=$2
out=$3
godot=/Applications/Godot.app/Contents/MacOS/Godot
scratch=$(mktemp -d "${TMPDIR:-/tmp}/edd-f1.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
printf '[ui]\nlanguage="en"\ntext_scale=1.0\nreduced_motion=false\n[video]\nquality="standard"\n[audio]\nmusic_enabled=false\n' > "$scratch/settings.cfg"
export EDD_SETTINGS_PATH="$scratch/settings.cfg" EDD_LOCALE=en
for variant in main candidate; do
    sha=$base
    if [ "$variant" = candidate ]; then sha=$head; fi
    project="$scratch/$variant"
    mkdir -p "$project" "$out/$variant"
    git archive "$sha" -- project.godot icon.svg icon.svg.import assets locale scenes scripts shaders tests tools art/palette.toml |
        tar -x -C "$project"
    mkdir -p "$project/tools/fid_sundy_house"
    git show "$head:tools/fid_sundy_house/capture.gd" > "$project/tools/fid_sundy_house/capture.gd"
    "$godot" --headless --path "$project" --import > "$out/$variant/import.log" 2>&1
    cmd=("$godot" --path "$project" --resolution 1280x720 --fixed-fps 60 --always-on-top
        --script res://tools/fid_sundy_house/capture.gd -- "$out/$variant" --seed=7
        --bench-quality=standard --bench-size=1280x720 --bench-cloud-t=215)
    printf 'EDD_SETTINGS_PATH=%q EDD_LOCALE=en ' "$EDD_SETTINGS_PATH" > "$out/$variant/command.txt"
    printf '%q ' "${cmd[@]}" >> "$out/$variant/command.txt"
    printf '\n' >> "$out/$variant/command.txt"
    "${cmd[@]}" > "$out/$variant/render.log" 2>&1
done
"$HOME/.local/bin/python3" - "$out" "$base" "$head" <<'PY'
import json
import sys
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

out = Path(sys.argv[1])
with (out / "index.md").open("a") as index:
    index.write("\n## Game captures\n\n")
    index.write("Seed 7. Standard quality. Locale en, text scale 1.0, reduced motion false.\n")
    index.write("The still cameras look at the house. Each daylight turn starts at the normal arrival heading ")
    index.write("and rotates left 180° across 240 steps at 60 fps. PNGs retain even-numbered steps.\n")
    rows = {}
    for variant, sha in zip(("main", "candidate"), sys.argv[2:]):
        folder = out / variant
        rows[variant] = {r["bookmark"]: r for r in json.loads((folder / "metrics.json").read_text())}
        index.write(f"\n### {variant.capitalize()} ({sha})\n\n")
        index.write("Exact command is recorded below and in ")
        index.write(f"[command.txt]({variant}/command.txt).\n\n")
        index.write(f"```sh\n{(folder / 'command.txt').read_text()}```\n\n")
        index.write("| Image | State | Size | Written |\n|---|---|---|---|\n")
        files = sorted(folder.glob("*.png"))
        if len(files) != 126:
            raise RuntimeError(f"{variant}: expected 126 PNGs, found {len(files)}")
        for png in files:
            state = "daylight turn" if png.stem.startswith("turn-") else png.stem.split("-", 1)[1]
            t = datetime.fromtimestamp(png.stat().st_mtime, ZoneInfo("Asia/Tokyo"))
            index.write(f"| [{png.name}]({variant}/{png.name}) | {state} | 1280×720 | {t:%F %T %Z} |\n")
    index.write("\n## Frame cost\n\n")
    index.write("| View | Main primitives | Candidate primitives | Main draws | Candidate draws |\n")
    index.write("|---|---:|---:|---:|---:|\n")
    for label, main in rows["main"].items():
        if "primitives" in main:
            head = rows["candidate"][label]
            index.write(f"| {label} | {main['primitives']} | {head['primitives']} | {main['draw_calls']} | {head['draw_calls']} |\n")
    index.write("\nRow 9 shelter totality. Forced-draw p95 over 240 draws per repetition. ")
    index.write("The ×3 device-class estimate follows the slice's existing method.\n\n")
    index.write("| Variant | Three p95 values (ms) | Worst ×3 (ms) | Within 33.33 ms |\n|---|---|---:|---|\n")
    for variant, result in rows.items():
        values = [r["forced_draw_ms_p95"] for k, r in result.items() if k.startswith("shelter-totality")]
        worst = 3 * max(values)
        index.write(f"| {variant} | {', '.join(f'{v:.2f}' for v in values)} | {worst:.2f} | {'Yes' if worst <= 33.33 else 'No'} |\n")
PY
touch "$out/.archive-ready"
